# x86_64 Linux：`cpu_current_top_of_stack` 与各类内核入口的栈顶约定

本文档说明：**系统调用 (`syscall`)、经 IDT 的用户态异常/中断（含 `INT $0x80`、外设 IRQ）、以及 `sync_regs`** 在「当前线程内核栈顶 / `pt_regs` 落点」上是否共用**同一套内核逻辑**；并明确与 **`TSS.RSP0` / entry trampoline** 的区别。  
源码以 Linux 主线为参照，链接指向 [`torvalds/linux`](https://github.com/torvalds/linux) 上对应文件（行号会随版本漂移，以链接内行为准）。

---

## 1. 权威定义：线程栈上的 `pt_regs` 与 `task_top_of_stack`

每个可运行任务有独立**线程内核栈**；`struct pt_regs` 放在该栈的固定布局位置。相关宏在 [`arch/x86/include/asm/processor.h`](https://github.com/torvalds/linux/blob/master/arch/x86/include/asm/processor.h)：

- **`task_pt_regs(task)`**：由 `task_stack_page(task) + THREAD_SIZE - TOP_OF_KERNEL_STACK_PADDING` 推导出**指向该任务 `pt_regs` 的指针**（在栈的“高址”一侧按布局约定放置）。
- **`task_top_of_stack(task)`**：定义为 `(unsigned long)(task_pt_regs(task) + 1)`，即**紧挨在 `pt_regs` 之上的地址**，用作“该任务内核栈顶”的约定（与 x86 栈向低址增长配合使用）。

这是**与 `TSS.sp0` 无关**的、纯软件对**任务栈**的约定。

---

## 2. 运行期缓存：`cpu_current_top_of_stack` 与 `current_top_of_stack()`

```c
// 概念：per-CPU 上缓存「当前正在本 CPU 上跑的任务」的 task_top_of_stack
// 声明见 processor.h：cpu_current_top_of_stack
```

- [`current_top_of_stack()`](https://github.com/torvalds/linux/blob/master/arch/x86/include/asm/processor.h) 内联函数读取 **per-CPU 的 `cpu_current_top_of_stack`**（或 const 别名），**不**从 `TSS.sp0` 读。注释明确：x86_64 上 **`sp0` 是 entry trampoline**，不能代表当前任务 `pt_regs` 位置。

- 在**上下文切换**时，新任务被切上该 CPU 时写入，例如 [`arch/x86/kernel/process_64.c`](https://github.com/torvalds/linux/blob/master/arch/x86/kernel/process_64.c) 中：

  `raw_cpu_write(cpu_current_top_of_stack, task_top_of_stack(next_p));`

因此：**`current_top_of_stack()` 的数值与 `task_top_of_stack(current)` 一致**（在有效任务、正常切换路径下）。

---

## 3. `syscall` 快速路径：直接用 `cpu_current_top_of_stack` 设 `RSP`

[`entry_SYSCALL_64`](https://github.com/torvalds/linux/blob/master/arch/x86/entry/entry_64.S) 在 `swapgs`、切内核 `CR3` 等之后，用：

`movq PER_CPU_VAR(cpu_current_top_of_stack), %rsp`

把 **%rsp** 设到**当前任务**在 §1 中约定的那一格**栈顶**上，再向下压栈构造 `pt_regs`。

**这里不调用** `current_top_of_stack()` 的 C 内联函数，但**读的是同一 per-CPU 变量、同一套 `task_top_of_stack` 语义**。

---

## 4. 经 `idtentry` + `error_entry` + `sync_regs`：`current_top_of_stack()` 决定目的 `pt_regs`

[`sync_regs()`](https://github.com/torvalds/linux/blob/master/arch/x86/kernel/traps.c)：

```c
struct pt_regs *regs = (struct pt_regs *)current_top_of_stack() - 1;
```

因 **`current_top_of_stack()` == `(unsigned long)(task_pt_regs(current) + 1)`**，故 **`current_top_of_stack() - 1`** 即为 **`task_pt_regs(current)`**，也就是**当前任务线程栈上那本 `struct pt_regs` 的指针**。

若入口帧当前在 **entry trampoline 栈或 IST 栈**上（`eregs` 指针与 `regs` 不同），则 **`*regs = *eregs`** 把帧拷到线程栈的标准槽位。

因此：**异常 / `INT $0x80` / 外设 IRQ**，只要从用户态走上这条路径并最终进入 `sync_regs`，**目标栈顶语义与 `syscall` 一致**：都是 **`task_pt_regs(current)`** 对应区域。

---

## 5. 与 `TSS.RSP0` / entry trampoline 的区别（必读）

- **`cpu_init()` → `load_sp0((unsigned long)(cpu_entry_stack(cpu) + 1))`**（[`arch/x86/kernel/cpu/common.c`](https://github.com/torvalds/linux/blob/master/arch/x86/kernel/cpu/common.c)）把 **`TSS.RSP0`** 设为 **per-CPU entry trampoline stack**，用于**特权级切换的第一站**，与 **`task_pt_regs`** 所在的**进程内核栈**不是同一概念。
- **`syscall`** **不经过** IDT，也**不使用** `TSS.RSP0`；它直接 **`cpu_current_top_of_stack`**。
- **用户态 → 内核经 IDT** 时硬件先用 **`RSP0`**（entry stack），再在软件路径上 **`sync_regs`** 对齐到 **`task_pt_regs(current)`**。

---

## 6. 简要对照表

| 概念 | 含义 |
|------|------|
| `task_pt_regs(task)` | 任务内核栈布局中 **`struct pt_regs*`** |
| `task_top_of_stack(task)` | **`task_pt_regs(task) + 1`** 的地址数值 |
| `cpu_current_top_of_stack`（per-CPU） | 缓存 **`task_top_of_stack(current)`** |
| `current_top_of_stack()` | 读取上述 per-CPU 值 |
| `syscall` | 汇编 **`mov …, cpu_current_top_of_stack`** → `%rsp` |
| `sync_regs()` | **`(struct pt_regs *)(current_top_of_stack() - 1)`** 作为线程栈目的槽 |

---

## 7. 例外与边界（避免过度概括）

- **内核态**正在执行时被中断 / 异常：**`error_entry`** 可能不走用户态那条 **`jmp sync_regs`**；栈上状态与是否再迁到“线程栈上的标准 `pt_regs`”需按具体向量与宏（如 paranoid、IST）单独看，不能一律等同用户态路径。
- **IST≠0** 的异常：硬件先落在 **IST** 栈；**`sync_regs`** 注释说明其帮助处理 **IST 或 entry trampoline** 上的 handler，最终仍对齐到 **`current_top_of_stack()-1`** 所指的线程栈槽位（与主线实现意图一致时）。

---

## 参考锚点（便于在树里 `grep`）

`cpu_current_top_of_stack`、`current_top_of_stack`、`task_top_of_stack`、`task_pt_regs`、`sync_regs`、`entry_SYSCALL_64`、`native_load_sp0` / `load_sp0`、`cpu_entry_stack`。
