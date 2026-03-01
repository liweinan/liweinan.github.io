---
title: "为什么「语言速度」是伪命题：I/O、并发、内存与内核"
---

在现代环境中，单纯比较语言的“执行速度”远远不够——就像在拥挤的城市街道上比较两辆赛车的极速，意义有限。真正决定系统表现的是 **I/O 如何被处理、并发如何利用多核、内存如何与内核交互**，以及运行时与生态的取舍。本文从技术内因（I/O、并发、内存与系统调用）、运行时成本（VM 与 AOT）以及非技术因素三方面梳理，并辅以 Linux 内核与用户态代码示例。

## 1. 为什么「语言速度」是伪命题？（技术内因）

### 1.1 I/O 是天花板

绝大多数时间 CPU 在等 I/O：网络往返或磁盘读写是毫秒级，而一条加法指令是纳秒级，语言层面的“谁更快”会被 I/O 等待完全淹没。**真正的差异在于：语言/框架如何做 I/O**——阻塞还是非阻塞？是否用好操作系统提供的异步接口（如 **epoll**、**io_uring**）？

**epoll**：一次系统调用可监听大量 fd，就绪时再处理，避免“每个连接问一次”的轮询。Linux 内核实现见 **`fs/eventpoll.c`**，入口为 `epoll_create1`、`epoll_ctl`、`epoll_wait` 等系统调用[^1][^5]。

```c
// 用户态：epoll 一次 wait 可返回多个就绪 fd，减少 syscall 次数
int epfd = epoll_create1(0);
struct epoll_event ev = { .events = EPOLLIN, .data.fd = sockfd };
epoll_ctl(epfd, EPOLL_CTL_ADD, sockfd, &ev);

#define MAX_EVENTS 64
struct epoll_event events[MAX_EVENTS];
for (;;) {
    int n = epoll_wait(epfd, events, MAX_EVENTS, -1);  /* 一次 syscall，多 fd */
    for (int i = 0; i < n; i++)
        handle(events[i].data.fd);
}
```

**io_uring**：更现代的异步 I/O 接口，提交与完成通过共享 ring buffer 与内核交互，进一步减少系统调用与拷贝。内核实现见 **`io_uring/io_uring.c`**，如 `SYSCALL_DEFINE2(io_uring_setup, ...)`[^2][^6]。

### 1.2 并发模型与多核利用

多核时代，**并发模型**决定能多“轻松”地压榨多核与掩盖 I/O 等待：

- **Go**：**Goroutine** 是极轻量的并发单位（栈起小、调度在用户态），便于写出高并发程序，从而更好利用多核并应对 I/O。
- **Java**：**虚拟线程**（Project Loom）意在解决“每请求一线程”带来的内存与上下文切换成本。

差别不在“单线程谁更快”，而在于**能否用低成本抽象把并发写出来**。

### 1.3 内存管理与内核的博弈

语言如何从内核要内存、何时释放，对延迟和常驻内存影响很大：

- **有 GC 的语言**（Java、Go）：向内核申请大块堆，自行管理。优点是开发效率高，缺点是 GC 的 Stop-The-World 或回收不及时会导致与内核的交互不可预测；若长期不把内存还给 OS，常驻内存会偏高。
- **无 GC 的语言**（Rust、C++）：可精细控制何时释放回 OS。例如 glibc 下可用 **`malloc_trim(0)`** 把空闲页归还内核，降低进程 RSS；Rust 的所有权在编译期约束生命周期，减少运行时开销[^3]。

```c
// 释放堆上未用内存回内核，降低 RSS（glibc）
#include <malloc.h>
void release_unused_heap(void) {
    malloc_trim(0);   /* 将 free list 中的空闲页归还内核 */
}
```

内核侧：用户态堆扩展通过 **`brk`**/ **`mmap`** 与 VMA 管理，物理页按需分配（缺页时再给）。本博客在[《栈为什么比堆快》](https://weinan.io/2026/03/01/stack-vs-heap-why-stack-faster.html)中已有梳理[^4]。

### 1.4 用户态与内核态的壁垒

每次**系统调用**都是一次模式切换，成本远高于用户态几条指令。因此：

- **内存池**：在用户态维护一块已申请的内存，反复复用，减少频繁 `brk`/`mmap`。这本质上是在减少「从内核到用户态」的申请次数，与本博客[《栈为什么比堆快》](https://weinan.io/2026/03/01/stack-vs-heap-why-stack-faster.html)里说的「批发-零售」链条一致：少向内核要、多在用户态复用，摊薄单次分配成本[^4]。
- **批量 I/O**：如 epoll 一次 `epoll_wait` 返回多个就绪 fd；io_uring 一次 submit 可提交多个 I/O。

语言“跑得快”若伴随大量 syscall，实际表现可能反而不如“跑得慢一点但少进内核”的实现。

---

## 2. 运行时的“隐藏成本”：VM 与 AOT

- **有 VM 的语言**（Java、C#、Erlang）：带来跨平台和 JIT 等优化，但冷启动慢、VM 自身占内存，在 Serverless 或短生命周期任务中可能成为瓶颈。
- **AOT 编译、无传统 VM**（Go、Rust、C++）：直接生成二进制，启动快、内存占用小。Go 的运行时（GC、调度）是链接进二进制的一部分，而非独立 VM。

因此“谁更快”还要看**启动与常驻成本**是否在你的场景里被放大。

---

## 3. 非技术因素的“一票否决权”

在工程选型中，非技术因素往往权重更高：

- **市场与招聘**：企业级后端仍以 Java/C# 为主流，Rust 等虽优但人力与梯队成本高。
- **生态与投资**：大厂与社区投入决定库的成熟度；“开箱即用”的组件是否覆盖你的业务，比单语言性能更关键。
- **历史债务**：很多系统沿用 Java/PHP 等，只因存量代码如此。除非有颠覆性收益，否则“稳定可用”常优于“换语言重构”。

---

## 总结

选语言不是在选“谁跑得快”，而是在选**谁的运行时哲学和生态，最匹配你的业务场景和团队能力**。

- **技术收益**：在 I/O 密集或 CPU 密集场景下，能否通过并发模型和内存控制，把硬件与内核的潜力发挥出来。
- **业务成本**：招聘难度、开发效率、生态成熟度与长期维护的可控性。

**语言速度只是众多维度之一；I/O、并发、内存与内核的交互方式，以及 VM/AOT 与生态，往往更能决定实际表现与可维护性。**

---

## 扩展阅读（内核与接口）

- **epoll**：Linux 内核 **`fs/eventpoll.c`**，`epoll_create1`、`epoll_ctl`、`epoll_wait` 等[^1]。一次 `epoll_wait` 可返回多个就绪 fd，减少系统调用次数。
- **io_uring**：**`io_uring/io_uring.c`**，`io_uring_setup`、提交与完成队列；适合高 IOPS、低 syscall 场景[^2]。
- **用户态堆与内核**：`brk`/`mmap`、VMA、缺页与零页见本博客[《栈为什么比堆快》](https://weinan.io/2026/03/01/stack-vs-heap-why-stack-faster.html)[^4]。内核 `mm/mmap.c`（`sys_brk`）、`mm/vma.c`（`do_brk_flags`）。

---

## References

[^1]: Linux 内核 **fs/eventpoll.c**：epoll 实现，`SYSCALL_DEFINE1(epoll_create1,...)`、`epoll_ctl`、`epoll_wait` 等。[Bootlin - eventpoll.c](https://elixir.bootlin.com/linux/latest/source/fs/eventpoll.c)

[^2]: Linux 内核 **io_uring/io_uring.c**：io_uring 实现，`SYSCALL_DEFINE2(io_uring_setup,...)` 等。[Bootlin - io_uring.c](https://elixir.bootlin.com/linux/latest/source/io_uring/io_uring.c)、[io_uring 文档](https://kernel.dk/io_uring.pdf)

[^3]: [malloc_trim(3)](https://man7.org/linux/man-pages/man3/malloc_trim.3.html) - 将 free 列表中的空闲页归还内核

[^4]: 本博客 [栈为什么比堆快：从分配方式到「批发-零售」链条](https://weinan.io/2026/03/01/stack-vs-heap-why-stack-faster.html) - brk/mmap、VMA、缺页与零页

[^5]: [epoll(7)](https://man7.org/linux/man-pages/man7/epoll.7.html) - Linux 手册：epoll 概述与 API

[^6]: [Efficient IO with io_uring](https://kernel.dk/io_uring.pdf) - Jens Axboe，io_uring 设计说明（PDF）
