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

下文「同一套 top of stack 语义」指：**线程内核栈布局里那一份 `task_pt_regs(current)` / `task_top_of_stack(current)` 约定**，由 `cpu_current_top_of_stack` / `current_top_of_stack()` 表达；**不包含** `TSS.RSP0` 指向的 entry trampoline 栈。

---

## 5. 与博文「三类事件」及各入口的对应关系

博文里区分 **syscall**、**经 IDT 的软/硬中断与异常** 等；此处从**栈顶约定**把它们与 `cpu_current_top_of_stack` / `sync_regs` / `TSS.RSP0` 对齐说明。下列「是否用到同一套语义」均相对上文定义而言。

| 入口类型 | 是否用到「同一套 top of stack 语义」 | 说明 |
|---------|--------------------------------------|------|
| **`syscall`** | ✅ | 汇编 **`movq PER_CPU_VAR(cpu_current_top_of_stack), %rsp`**（[`entry_64.S`](https://github.com/torvalds/linux/blob/master/arch/x86/entry/entry_64.S) **`entry_SYSCALL_64`**）；与上下文切换里 **`raw_cpu_write(cpu_current_top_of_stack, task_top_of_stack(next))`**（[`process_64.c`](https://github.com/torvalds/linux/blob/master/arch/x86/kernel/process_64.c)）写入的值**同源**。不经 IDT，**不使用** `TSS.RSP0`。 |
| **用户态 IDT**（`INT $0x80`、外设 IRQ、多数 **`IST = 0`** 的异常） | ✅（在走到 **`sync_regs`** 并完成对齐时） | 硬件先从用户态切到 **`TSS.RSP0`**（entry trampoline 栈）；`idtentry` → **`error_entry`** → **`sync_regs`** 里 **`regs = (struct pt_regs *)current_top_of_stack() - 1`**，即 **`task_pt_regs(current)`**。入口帧若在 trampoline 上与 `regs` 不一致，则 **`*regs = *eregs`** 拷到线程栈标准槽位（[`traps.c`](https://github.com/torvalds/linux/blob/master/arch/x86/kernel/traps.c) **`sync_regs`**）。 |
| **`TSS.RSP0` / entry trampoline** | ❌（**另一套**） | **`load_sp0((unsigned long)(cpu_entry_stack(cpu) + 1))`**（[`cpu/common.c`](https://github.com/torvalds/linux/blob/master/arch/x86/kernel/cpu/common.c) **`cpu_init` / `native_load_sp0`**）只表示** ring0 的第一段栈指针**；**不是** `task_top_of_stack(current)`，也不等同于 `task_pt_regs` 所在进程栈。 |
| **IST 异常** | 硬件：**不同栈**；软件对齐目标：**仍** `task_pt_regs(current)` | 向量带 **IST≠0** 时，CPU 先把栈切到 **IST** 栈，与当前线程内核栈不同。`sync_regs` 注释写明可处理 **IST 或 trampoline** 上的 handler 帧：若 **`eregs` ≠ `regs`**，仍把 **`eregs`** 拷到 **`current_top_of_stack() - 1`** 所指 **`regs`**（线程栈上的标准 `pt_regs`），故**软件侧「目的槽」仍是同一套 top-of-stack 语义**；差别在**硬件先落哪里**。 |
| **内核态**被中断 / 异常 | ⚠️ **不能**与用户态 IDT 路径一概而论 | **`error_entry`** 在内核态入口可能**不**走用户态那条 **`jmp sync_regs`**（例如 paranoid、或帧本来就在内核栈上）；是否再迁到「线程栈上的标准 **`task_pt_regs`**」取决于向量与 **`USER`** / **`PARANOID`** 等宏分支。不能与「用户态 IRQ / `INT $0x80` + `sync_regs`」等同表述为同一套路径。 |

---

## 6. 与 `TSS.RSP0` / entry trampoline 的并存关系（细读）

- **`cpu_init()` → `load_sp0((unsigned long)(cpu_entry_stack(cpu) + 1))`** 把 **`TSS.RSP0`** 设为 **per-CPU entry trampoline stack**：仅供 **ring3 → ring0** 特权切换时硬件选中的**第一站**栈。
- **用户态 → 内核经 IDT**：硬件必然先用到 **`RSP0`**（与 `cpu_current_top_of_stack` **无关**）；随后在 `idtentry` / `error_entry` / `sync_regs` 中把状态落到**进程**的 **`task_pt_regs(current)`**。
- **`syscall`**：不经过上述 IDT+RSP0 序列，直接用 **`cpu_current_top_of_stack`** 设 **`%rsp`**，回到 §3、§5 表格第一行。

---

## 7. 术语与宏对照（速查）

| 概念 | 含义 |
|------|------|
| `task_pt_regs(task)` | 任务内核栈布局中 **`struct pt_regs*`**（[`processor.h`](https://github.com/torvalds/linux/blob/master/arch/x86/include/asm/processor.h)） |
| `task_top_of_stack(task)` | **`(unsigned long)(task_pt_regs(task) + 1)`**，与 **`pt_regs`** 相邻的栈顶一端 |
| `cpu_current_top_of_stack`（per-CPU） | 运行中缓存 **`task_top_of_stack(current)`** |
| `current_top_of_stack()` | 读该 per-CPU 变量；**不是**读 `TSS.sp0` |
| `syscall` | 汇编加载 **`cpu_current_top_of_stack` → %rsp**，再压栈构帧 |
| `sync_regs()` | **`(struct pt_regs *)current_top_of_stack() - 1`** 作为线程栈上的目标 **`regs`** |

---

## 8. 例外与边界（避免过度概括）

- **仅当** 从用户态进入且最终进入 **`sync_regs`** 并完成 **`regs`/`eregs`** 对齐时，才可以说与 **`syscall`** 共用**同一条「`task_pt_regs(current)` 槽位」语义**。
- **IST≠0**：硬件落栈与线程栈不同；**软件**仍把 **`pt_regs` 内容对齐到 **`current_top_of_stack()-1`**（见 §5 表 IST 行）。若实现或配置导致某条路径**不进** `sync_regs`，则需单独跟踪该向量（本笔记不替代码写死分支表）。
- **内核态**：见 §5 表末行；需按 **`entry_64.S`** / **`traps.c`** 里具体宏与标签区分，避免把 **`cpu_current_top_of_stack`** 误当成所有异常上下文的唯一栈指针。

---

## 参考锚点（便于在树里 `grep`）

`cpu_current_top_of_stack`、`current_top_of_stack`、`task_top_of_stack`、`task_pt_regs`、`sync_regs`、`entry_SYSCALL_64`、`native_load_sp0` / `load_sp0`、`cpu_entry_stack`、`idtentry`、`error_entry`、`paranoid`、`eregs`。
