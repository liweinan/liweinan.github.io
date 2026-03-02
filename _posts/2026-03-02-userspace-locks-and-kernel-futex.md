---
title: "用户态锁与内核：谁在管理「等待」与 futex"
---

从底层实现看，**用户态（userspace）的锁机制，其核心的阻塞与唤醒功能，最终依赖于内核提供的同步原语**。可以用一个比喻理解：用户态的锁像大楼里每个房间的门锁（轻便、快速），内核的同步则像大楼的主门与安防（全局、负责调度）。多数时候大家只用房间门锁（用户态原子操作或自旋），但当线程需要「离开大楼」或「被叫醒」时，必须经过主门——即通过系统调用进入内核。本文说明这一依赖关系、**futex（Fast Userspace Mutex）** 如何作为桥梁，并辅以 Linux 内核源码与参考文献；关于锁的误用如何导致性能问题，见本博客[《为什么「语言速度」是伪命题》](https://weinan.io/2026/03/01/why-language-speed-is-misleading.html)中的「锁的误用与性能」一节[^1]。

## 1. 谁在管理「等待」？

用户态程序**无法直接控制 CPU 的调度**，只有内核才有权暂停一个线程（让出 CPU）并在未来某刻恢复它。内核能获得这一能力，依赖两类入口：**系统调用**（线程主动进入内核，例如调用 `futex` 后在内核里执行 `schedule()` 让出 CPU）与**定时中断**（周期性的时钟中断让内核有机会更新运行时间、设置「需要调度」标志，从而在返回用户态前或下次进入内核时执行 `schedule()`，实现抢占或时间片轮转）。定时中断路径在 Linux 上的实现大致为：时钟事件驱动 **`tick_periodic()`**（传统周期 tick）或 **`tick_nohz_handler()`**（高分辨率/动态 tick）→ **`update_process_times()`**（`kernel/time/timer.c`）→ **`sched_tick()`**（`kernel/sched/core.c`）；`sched_tick()` 的注释写明 “This function gets called by the timer code, with HZ frequency”，在其中更新 runqueue 时钟、调用当前任务所属调度类的 **`task_tick`**，并可能调用 **`resched_curr()`** 标记需要重新调度，从而在适当时机触发 **`__schedule()`** 切换任务[^9]。

- **若锁被占用且等待时间可能较长**：线程需要**阻塞**——主动放弃 CPU、进入睡眠，直到锁被释放。这个「让出 CPU 并睡眠」的动作必须通过内核提供的系统调用来完成，在 Linux 上即 **`futex`** 等[^2][^3]。
- **若锁只被短暂占用**：线程可以选择**自旋**，即原地循环检查锁状态，不进入内核；线程一直占着 CPU。这仅适用于多核且持锁时间极短的场景，否则会浪费 CPU。

因此：**能「睡下去」和「被唤醒」的锁，一定依赖内核。**

## 2. 关键桥梁：futex (Fast Userspace Mutex)

在现代 Linux 上，几乎所有高性能用户态锁（如 NPTL 的 `pthread_mutex`、`pthread_cond`）底层都依赖 **futex**。其设计哲学正是「大部分时间在用户态解决，必要时才进内核」[^2][^3]。

### 2.1 无竞争时（Fast Path）

线程尝试加锁时，若锁空闲，只需在**用户态**用一条原子指令（如 CAS）把锁变量从 0 改为 1。**全程无系统调用，极快。**

### 2.2 有竞争时（Slow Path）

1. **用户态**：尝试加锁的线程发现锁已被占用，将自身标记为「等待」，然后调用 **`futex` 系统调用**进入内核。
2. **内核态**：内核把该线程放入与该 futex 对应的**等待队列**，并调度其他线程运行，当前线程阻塞。
3. **释放与唤醒**：持锁线程释放时，在用户态用原子指令把锁变量改回 0，并检查是否有等待者；若有，再调用 **`futex`** 通知内核唤醒。
4. **内核响应**：内核从等待队列中唤醒被阻塞的线程，该线程得以继续运行并再次尝试获取锁。

因此，**futex 本质上是内核提供的「等待队列管理器」**，锁的值（0/1）由用户态维护，阻塞与唤醒由内核完成。内核实现见 **`kernel/futex/`**：系统调用入口为 **`SYSCALL_DEFINE6(futex, ...)`**，根据 `op` 分发到 **`futex_wait`** / **`futex_wake`** 等[^3][^4]。

## 3. CPU 层面的锁机制：原子指令与内存序

用户态「无竞争时一条原子指令加锁」依赖 **CPU 提供的原子读-改-写（RMW）与内存序保证**；否则多核下既无法保证互斥，也无法保证临界区内的写对其他核可见。以下为两种常见架构的要点与权威出处。

### 3.1 x86：LOCK 前缀与原子性

在 x86 上，**LOCK** 前缀（opcode F0）可使特定指令在多核下**原子**执行：目标为内存操作数时，会断言 LOCK# 信号（或等价机制），使该次读-改-写不可被其他 CPU 打断。可加 LOCK 的指令包括 **CMPXCHG**（比较并交换）、**XCHG**（与内存交换）、**ADD/SUB/INC/DEC** 等；**XCHG** 在目标为内存时即使不加前缀也会具有锁语义。现代 x86（P6 及以后）对已缓存的地址通常采用 **cache locking**（依赖 MESI 等缓存一致性协议），而非锁总线，从而减少延迟[^7]。

LOCK 前缀还带来**内存序**效果：带 LOCK 的指令与其它 LOCK 指令之间存在全序；普通 load/store 不能与 LOCK 指令重排。因此「加锁」可用带 acquire 语义的原子操作（如 CMPXCHG 成功后相当于 acquire），「解锁」用带 release 语义的写（如原子 store 0），能保证临界区内的修改在解锁后对其它核可见、且其它核的修改在加锁后对本核可见。详见 Intel SDM Vol 3A 第 8 章（Multiple-Processor Management）及 Vol 2A 对 LOCK 的说明[^7]。

### 3.2 ARM：独占加载/存储（LDXR/STXR）与 Exclusive Monitor

ARM 没有像 x86 那样的「单条指令原子 RMW」，而是用 **Load-Exclusive / Store-Exclusive** 实现：**LDXR**（Load Exclusive Register）从某地址加载并让该地址被本核的 **exclusive monitor** 标记；**STXR**（Store Exclusive Register）仅在该地址仍被本核独占时写入并返回 0，否则写入失败、返回非 0，由软件重试。这样一对 LDXR + STXR 可实现「读-改-写」的原子性，是用户态自旋锁、CAS 等的基础。ARMv8 还提供 **LDAXR/STLXR** 等带 **acquire/release** 语义的变种，在实现 mutex 时保证临界区前后的可见性[^8]。

Exclusive monitor 是硬件状态：若其它 CPU 在该地址上产生了 store 或其它使独占失效的访问，当前核的 STXR 会失败，从而避免多核同时写。软件需保证在 LDXR 与 STXR 之间不插入会破坏独占性的操作（如显式访问该地址、某些系统寄存器或 cache 维护指令）。详见 ARM 架构参考手册中「Load-Exclusive and Store-Exclusive」与「Synchronization and semaphores」[^8]。

### 3.3 与 futex 的关系

- **无竞争**：用户态用上述原子指令（x86 的 CMPXCHG/XCHG，ARM 的 LDXR/STXR 或 LDAXR/STLXR）完成「尝试加锁 / 解锁」，**不进入内核**，因此极快。
- **有竞争**：原子尝试失败后，若选择阻塞，再通过 **futex** 系统调用进入内核、挂入等待队列。

内核自身在实现 futex 的哈希桶、等待队列时，同样依赖各架构的原子与内存屏障；Linux 内核文档 **atomic_t.txt**、**memory-barriers.txt** 对原子 RMW、acquire/release 变种及与锁的配合有统一说明[^8]。

## 4. 为什么不能完全在用户态实现「阻塞」锁？

若完全在用户态实现，当线程拿不到锁时只有两种选择：

1. **自旋（忙等）**：一直循环检查。持锁时间一长就会白占 CPU，浪费严重。
2. **sleep + 轮询**：调用 `sleep()` 睡一会儿再起来看。延迟不可控（可能刚睡下锁就释放了），且无法做到「锁一释放就立刻被唤醒」。

要实现「锁释放时立刻唤醒」的语义，**必须有一个全局的调度者管理线程状态**，这个角色只能是操作系统内核。

## 5. 完全在用户态的锁

有，但适用场景受限：

- **自旋锁**：基于原子操作，预期持锁时间仅几条指令时可用。**完全不依赖内核**，代价是：若锁被长时间持有，CPU 会空转。内核与用户态都常用；用户态自旋锁不涉及 futex。
- **序列锁（seqlock）** 等乐观并发：主要在用户态通过内存序与版本号完成，但冲突激烈时可能需重试或退化为等待，仍可能依赖内核。

关于**何时用自旋、何时用可睡眠的锁**，以及**粗粒度锁、持锁做 I/O** 对性能的影响，见本博客[《为什么「语言速度」是伪命题》](https://weinan.io/2026/03/01/why-language-speed-is-misleading.html)#锁的误用与性能[^1]。

## 6. 总结

- **上层（用户态）**：用原子指令快速尝试获取锁，无竞争时避免任何内核开销。
- **下层（内核）**：通过 **futex** 等原语提供「等待队列 + 调度」，处理阻塞与唤醒。

**用户态锁的「快」，是因为无竞争时绕过了内核；它之所以能成为通用的、可阻塞的锁，是因为有竞争时有内核的兜底。**

---

## 扩展阅读（内核与接口）

- **futex 系统调用**：**`kernel/futex/syscalls.c`** 中 **`SYSCALL_DEFINE6(futex, ...)`** 与 **`do_futex()`**，根据 `op`（如 `FUTEX_WAIT`、`FUTEX_WAKE`）分发到 **`kernel/futex/waitwake.c`** 的 **`futex_wait()`**、**`futex_wake()`**[^3][^4]。
- **等待与唤醒逻辑**：**`waitwake.c`** 中 `futex_wait_setup()` 将当前任务入队，`__futex_wait()` 调用 `futex_do_wait()` 进入调度；`futex_wake()` 在哈希桶中查找等待者并 `wake_up_q()`[^4][^5]。
- **futex 设计**：**`kernel/futex/core.c`** 文件头注释（Rusty Russell 等）对 Fast Userspace Mutex 的由来与设计有简要说明；LWN 多篇文章介绍其演进与优化[^2][^6]。
- **CPU 原子与内存序**：x86 LOCK 前缀与多核原子见 Intel SDM Vol 2A/Vol 3A；ARM 独占加载/存储见 ARM ARM；Linux 内核 **atomic_t.txt**、**memory-barriers.txt** 对原子 RMW 与 acquire/release 的说明[^7][^8]。
- **定时中断与调度**：**`kernel/time/timer.c`** 中 **`update_process_times()`** 由时钟中断路径调用，内部调用 **`sched_tick()`**；**`kernel/time/tick-common.c`** 的 **`tick_periodic()`**、**`kernel/time/tick-sched.c`** 的 **`tick_nohz_handler()`** → **`tick_sched_handle()`** 均会调用 **`update_process_times()`**；**`kernel/sched/core.c`** 中 **`sched_tick()`** 以 HZ 频率被 timer 代码调用，负责更新 rq 时钟与 **`task_tick`**、必要时 **`resched_curr()`**[^9]。

---

## 内核代码片段（与正文对应）

**1. futex 系统调用入口与分发**（`kernel/futex/syscalls.c`）

用户态调用 `futex(uaddr, op, ...)` 时，内核根据 `op & FUTEX_CMD_MASK` 分发到 `futex_wait` 或 `futex_wake` 等；`FUTEX_WAIT` / `FUTEX_WAKE` 走 `do_futex()`[^3][^4]。

```c
// 简化自 kernel/futex/syscalls.c（约 84–106 行、160 行）
long do_futex(u32 __user *uaddr, int op, u32 val, ktime_t *timeout,
              u32 __user *uaddr2, u32 val2, u32 val3)
{
    unsigned int flags = futex_to_flags(op);
    int cmd = op & FUTEX_CMD_MASK;
    // ...
    switch (cmd) {
    case FUTEX_WAIT:
    case FUTEX_WAIT_BITSET:
        return futex_wait(uaddr, flags, val, timeout, val3);
    case FUTEX_WAKE:
    case FUTEX_WAKE_BITSET:
        return futex_wake(uaddr, flags, val, val3);
    // ...
    }
}

SYSCALL_DEFINE6(futex, u32 __user *, uaddr, int, op, u32, val,
                const struct __kernel_timespec __user *, utime,
                u32 __user *, uaddr2, u32, val3)
{
    // 超时处理等 ...
    return do_futex(uaddr, op, val, tp, uaddr2, (unsigned long)utime, val3);
}
```

**2. 等待与唤醒：入队与 schedule**（`kernel/futex/waitwake.c`）

`__futex_wait()` 通过 `futex_wait_setup()` 准备并入队，再调用 `futex_do_wait()` 进入睡眠；`futex_wake()` 根据 uaddr 算哈希桶，在桶内链表中找到匹配的等待者并唤醒[^4][^5]。

```c
// 简化自 kernel/futex/waitwake.c
// __futex_wait()（约 666–687 行）：准备等待、入队、进入 schedule
int __futex_wait(u32 __user *uaddr, unsigned int flags, u32 val,
                 struct hrtimer_sleeper *to, u32 bitset)
{
    struct futex_q q = futex_q_init;
    // ...
    ret = futex_wait_setup(uaddr, val, flags, &q, NULL, current);  /* 入队等 */
    if (ret)
        return ret;
    futex_do_wait(&q, to);   /* 在此 schedule，让出 CPU */
    // ...
}

// futex_wake()（约 155–199 行）：查哈希桶、唤醒 nr_wake 个等待者
int futex_wake(u32 __user *uaddr, unsigned int flags, int nr_wake, u32 bitset)
{
    // get_futex_key, futex_hash 得到 hb (hash bucket)
    spin_lock(&hb->lock);
    plist_for_each_entry_safe(this, next, &hb->chain, list) {
        if (futex_match(&this->key, &key)) {
            this->wake(&wake_q, this);
            if (++ret >= nr_wake)
                break;
        }
    }
    spin_unlock(&hb->lock);
    wake_up_q(&wake_q);   /* 真正唤醒等待线程 */
    return ret;
}
```

**3. core.c 中的设计说明**（`kernel/futex/core.c`）

文件头注释说明 futex 的由来（Rusty Russell 等）、「hashed waitqueues」等设计，与正文「内核管理等待队列」对应[^3]。

```c
// kernel/futex/core.c 文件头（约 1–32 行）
/*
 *  Fast Userspace Mutexes (which I call "Futexes!").
 *  (C) Rusty Russell, IBM 2002
 *  ...
 *  Thanks to Ben LaHaise for yelling "hashed waitqueues" loudly enough at me...
 */
```

---

## References

[^1]: 本博客 [为什么「语言速度」是伪命题：I/O、并发、内存与内核](https://weinan.io/2026/03/01/why-language-speed-is-misleading.html) - §1.5 锁的误用与性能：细粒度锁、持锁时间、自旋与睡眠取舍

[^2]: [A futex overview and update](https://lwn.net/Articles/360699/) - LWN，futex 概述与无竞争 fast path、有竞争时进内核

[^3]: Linux 内核 **kernel/futex/core.c**（futex 设计与 hashed waitqueues）、**kernel/futex/syscalls.c**（`SYSCALL_DEFINE6(futex,...)`、`do_futex`）。[Bootlin - core.c](https://elixir.bootlin.com/linux/latest/source/kernel/futex/core.c)、[Bootlin - syscalls.c](https://elixir.bootlin.com/linux/latest/source/kernel/futex/syscalls.c)

[^4]: Linux 内核 **kernel/futex/syscalls.c**（`do_futex` 中 `FUTEX_WAIT`→`futex_wait`、`FUTEX_WAKE`→`futex_wake`）、**kernel/futex/waitwake.c**（`futex_wait`、`__futex_wait`、`futex_wake`、入队与 `wake_up_q`）。[Bootlin - waitwake.c](https://elixir.bootlin.com/linux/latest/source/kernel/futex/waitwake.c)

[^5]: **kernel/futex/waitwake.c** 文件头注释：waiter 读用户态 futex 值、调用 `futex_wait()` 后入队并 `schedule()`；waker 改用户态值后调用 `futex_wake()` 在哈希桶中查找并唤醒。说明了用户态「锁变量」与内核「等待队列」的协作。

[^6]: [In pursuit of faster futexes](https://lwn.net/Articles/685769/) - LWN，futex 性能与竞争路径优化；[Robust futexes - The Linux Kernel documentation](https://docs.kernel.org/locking/robust-futexes.html) - 健壮 futex 与进程退出时的清理

[^7]: **Intel® 64 and IA-32 Architectures Software Developer’s Manual**：Vol 2A 中 **LOCK**（Instruction set reference）说明 LOCK 前缀可施加的指令及多核原子性；Vol 3A 第 8 章 **Multiple-Processor Management** 涉及 LOCK#、总线与缓存锁定及内存序。可查 [Intel SDM 索引](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html) 或 [felixcloutier x86 LOCK](https://www.felixcloutier.com/x86/lock)。

[^8]: **ARM**：架构参考手册中 **Load-Exclusive and Store-Exclusive**（如 LDXR/STXR、LDAXR/STLXR）与 **Synchronization and semaphores** 说明独占监视器与原子 RMW。[ARM Architecture Reference Manual](https://developer.arm.com/documentation/ddi0487/latest)。**Linux 内核**：**Documentation/atomic_t.txt** 描述 atomic RMW API 与 acquire/release 变种；**Documentation/memory-barriers.txt** 描述内存屏障与锁的配对。[atomic_t.txt](https://www.kernel.org/doc/html/latest/core-api/atomic_t.html)、[memory-barriers.txt](https://www.kernel.org/doc/html/latest/core-api/wrappers/memory-barriers.html)

[^9]: **定时中断与调度**：时钟中断路径调用 **`update_process_times()`**（`kernel/time/timer.c`），其内调用 **`sched_tick()`**；`sched_tick()` 在 **`kernel/sched/core.c`** 中实现，注释写明 “gets called by the timer code, with HZ frequency”，内部执行 `update_rq_clock(rq)`、`donor->sched_class->task_tick(rq, donor, 0)` 及条件性的 `resched_curr(rq)`，从而在定时中断上下文中为抢占/时间片提供入口。Tick 入口见 **`kernel/time/tick-common.c`**（`tick_periodic`）与 **`kernel/time/tick-sched.c`**（`tick_nohz_handler` → `tick_sched_handle` → `update_process_times`）。[Bootlin - timer.c](https://elixir.bootlin.com/linux/latest/source/kernel/time/timer.c)、[Bootlin - core.c](https://elixir.bootlin.com/linux/latest/source/kernel/sched/core.c)（搜索 sched_tick）
