---
title: "IDT 与 SYSCALL：差异、演化、Linux 实现与性能"
---

{% include mermaid.html %}

全文分三部分：

1. **IDT 与 `SYSCALL` 的机制差异与历史脉络**  
2. **x86-64 Linux 上从 `syscall` 指令到内核服务的执行路径**（对照 SDM 与 `arch/x86`）  
3. **经 IDT 的入核与 `SYSCALL` 入核在开销与实现上的对比**

硬件叙述以 Intel *Software Developer’s Manual*（Volume 3A 等）为准，软件以 Linux 主线 `arch/x86` 为准；引用标号见文末 **References**。

---

## 主题一：IDT 与 `SYSCALL` 的区别与演化

### 1.1 谁在决定内核入口

- **异常、硬件中断、`INT n`**：CPU 用 **IDT（Interrupt Descriptor Table）** 按 **向量号** 取门描述符，再按架构规则完成特权级与栈等处理；OS 负责 **填表** 并用 **`LIDT`** 之类加载 **IDTR**。该路径与一组 **MSR** 配合编程的 **`SYSCALL` 入核**是两套并存机制[^1][^2]。
- **`SYSCALL`（64 位长模式下的系统调用主路径之一）**：CPU 根据 **`IA32_STAR`、`IA32_LSTAR`、`IA32_FMASK`** 等 **MSR** 切到 ring 0 并跳转到 **`IA32_LSTAR` 指向的 RIP**，**不查 IDT**[^3][^4]。

二者都是架构规定的入口协议，但针对的事件类别不同：前者服务 **异步/异常类事件** 的统一交付，后者服务 **用户态主动发起的系统调用** 的专用快速通道。

### 1.2 64 位模式下的 IDT 索引

在 **64-bit / IA-32e** 下，门描述符为 **16 字节**；向量 *k* 对应表项在 IDT 中的字节偏移为 **k × 16**（与 legacy 模式下 8 字节项不同）[^1]。

手册在 64-bit mode IDT gate 处写道[^11]：

> In 64-bit mode, the IDT index is formed by scaling the interrupt vector by 16. The first eight bytes (bytes 7:0) of a 64-bit mode interrupt gate are similar but not identical to legacy 32-bit interrupt gates. The type field (bits 11:8 in bytes 7:4) is described in Table 3-2. The Interrupt Stack Table (IST) field (bits 4:0 in bytes 7:4) is used by the stack switching mechanisms described in Section 6.14.5, “Interrupt Stack Table.” Bytes 11:8 hold the upper 32 bits of the target RIP (interrupt segment offset) in canonical form.

### 1.3 对照表

| 特性 | 经 IDT 的路径 | `SYSCALL` 路径 |
| :--- | :--- | :--- |
| 典型触发 | 硬件中断、CPU 异常、`INT n`（含历史上的 `int 0x80`） | 用户态执行 **`syscall`** |
| 入口定位 | CPU 按向量查 **IDT 门** | CPU 读 **`IA32_LSTAR` 等 MSR** |
| 门/MSR 语义 | 类型、DPL、IST、段选择子等 **由 CPU 解释** | **`STAR`/`LSTAR`/`FMASK` 组合**，由 OS 预编程 |
| 是否使用 IDT | 是 | **否**（本条目不讨论 FRED 等后续扩展）

### 1.4 与“系统调用号 → 内核函数”的关系

抽象上都可说成 **编号映射到处理逻辑**：IDT 用 **中断向量**，系统调用用 **`RAX` 中的调用号**。  
**差别在于**：IDT 的查表与跳转是 **CPU 事件交付的一部分**；而 **`RAX → __x64_sys_*`** 属于 **内核在进入 `do_syscall_64` 之后的纯软件分发**，处理器并不解析“系统调用号”的语义。

### 1.4.1 三条不同的“表/入口/快车道”

把机制拆成三层，可与草稿中的对照并行阅读：

1. **IDT（及经其投递的中断/异常/`INT n`）**  
   由 CPU 规定、面向**全体异步与异常事件**的 **通用交付协议**：功能全、约束多，不以“最短一次用户主动系统调用”为唯一优化目标[^1][^2]。

2. **系统调用分发（软件）**  
   Linux 仍保留 **`sys_call_table[]`**，方便 **trace** 等子系统解析符号地址；**64 位主路径**上则由 **`x64_sys_call()` 的 `switch (nr)`** 落到 **`__x64_sys_*`**。无论数组还是 **`switch`**，都属于 **`syscall` 已经进核之后** 的普通控制流，**不是 CPU 替代的 IDT 查表**[^10]。

3. **系统调用硬件快车道（`SYSCALL` + 若干 MSR）**  
   **入口 `RIP` 与 `CS`/`SS`/`RFLAGS` 掩码**由 **`STAR`/`LSTAR`/`FMASK`（及 `EFER.SCE`）** 预编程；这是在 **不进 IDT** 的前提下完成的 **`ring 3 → ring 0` 专用序列**[^3][^11]。**分发 `__x64_sys_*`** 则接在这一序列之后，相当于“车到内核后再查业务分机”。

### 1.5 一条简化的演化脉络（x86 / Linux 相关）

1. **80386 及保护模式**：**IDT** 与 **`INT n`** 成为统一的异常/中断/软中断交付入口；内核通过设置向量 *n* 的门，把控制流交给对应处理例程。
2. **32 位 Linux**：用户态系统调用长期使用 **`int 0x80`**，即 **CPU 查 IDT 向量 0x80** 进入内核（仍属 IDT 路径）[^5]。
3. **约 Pentium II / Pro 一代**：Intel 引入 **`SYSENTER`/`SYSEXIT`**，配合 **MSR** 提供另一条 **不经 IDT 门描述符的** 快速进核通道（Linux 在 **32 位兼容路径**等场景仍会碰到与 **`SYSENTER`/`SYSCALL`** 相关的入口约定）[^6]。
4. **x86-64（AMD64 / Intel 64）**：架构在 **长模式**下提供 **`SYSCALL`/`SYSRET`**（由 **`IA32_EFER.SCE`** 等控制使能，细节以 SDM 为准）。**64 位 Linux 用户态**通常通过 **glibc 等内联 `syscall`**，内核入口落在 **`entry_SYSCALL_64`**[^3][^7]。
5. **并存**：今日 64 位内核仍可能为 **32 位进程** 保留 **`int 0x80` / `SYSENTER` / 兼容入口**（向量与实现见内核头文件与 `entry_64_compat` 等）；**本文明细以 64 位 `syscall` 主线为主**。

---

## 主题二：x86-64 Linux 上 `syscall` 从 CPU 到内核的完整机制

### 2.1 三层结构（总览）

1. **CPU（SDM）**：用户态约定 **`RAX`=调用号**、参数寄存器后执行 **`syscall`**。硬件将 **`RIP → RCX`、`RFLAGS → R11`**，按 **MSR** 加载 **`CS`/`SS`/`RIP`**，并令 **`RFLAGS <- RFLAGS & ~IA32_FMASK`**；**不保存 `RSP`**、不向栈压帧。  
2. **内核入口 `entry_SYSCALL_64`**（`arch/x86/entry/entry_64.S`）：**`swapgs`**、切换到 **per-CPU 内核栈**，在栈上构造 **`struct pt_regs`**，再 **`call do_syscall_64`**。  
3. **分发与返回**：**`do_syscall_64`** → **`x64_sys_call`** 的 **`switch (nr)`** → 各 **`__x64_sys_*`**。返回时若满足契约则 **`SYSRET`**，否则 **`IRET`**。

对比 **IDT 路径**：**IDT** 处理「向量 → 硬件按门交付」；**`syscall`** 处理「寄存器约定 + **MSR** 指定 **`RIP`** → **软件**补全栈帧再交付」。

### 2.1.1 `SYSCALL` 与 MSR：多寄存器协同，而非单一 `LSTAR`

**MSR（Model Specific Register）** 指通过 **`RDMSR`/`WRMSR`** 访问的 **按编号独立编址** 的一类寄存器；体系结构里与 `SYSCALL` 相关的常量名 **`IA32_STAR`、`IA32_LSTAR`、`IA32_FMASK`** 等各自对应不同 MSR 地址与语义。长模式下执行 **`SYSCALL`** 时，处理器按 **`IA32_EFER.SCE`** 判定该机制是否可用，再从 **`STAR`/`LSTAR`/`FMASK`** 读出 CS/SS、目标 RIP 与 RFLAGS 掩码[^3][^11]。

SDM 在 **`STAR`/`LSTAR`/`FMASK` 布局**处写明[^11]：

> See Figure 5-14 for the layout of IA32_STAR, IA32_LSTAR and IA32_FMASK.

并在同一节给出 **`RIP` 取自 `IA32_LSTAR`、`RFLAGS` 与 `IA32_FMASK` 的组合关系**（正文 **§2.3** 另有逐句引文）。

Linux 在 **64 位内核引导路径**中与上述分工对齐：**`syscall_init()`** 写 **`MSR_STAR`**（用户/内核段选择子约定），再调用 **`idt_syscall_init()`** 写 **`MSR_LSTAR`**（`entry_SYSCALL_64`）与 **`MSR_SYSCALL_MASK`**（对应 **`IA32_FMASK`**）[^8]：

```c
void syscall_init(void)
{
	/* The default user and kernel segments */
	wrmsr(MSR_STAR, 0, (__USER32_CS << 16) | __KERNEL_CS);

	if (!cpu_feature_enabled(X86_FEATURE_FRED))
		idt_syscall_init();
}
```

```c
static inline void idt_syscall_init(void)
{
	wrmsrq(MSR_LSTAR, (unsigned long)entry_SYSCALL_64);
	/* ia32_enabled() / SYSENTER_* / MSR_CSTAR 分支：见 common.c 全文 */
	wrmsrq(MSR_SYSCALL_MASK,
	       X86_EFLAGS_CF|X86_EFLAGS_PF|X86_EFLAGS_AF|
	       X86_EFLAGS_ZF|X86_EFLAGS_SF|X86_EFLAGS_TF|
	       X86_EFLAGS_IF|X86_EFLAGS_DF|X86_EFLAGS_OF|
	       X86_EFLAGS_IOPL|X86_EFLAGS_NT|X86_EFLAGS_RF|
	       X86_EFLAGS_AC|X86_EFLAGS_ID);
}
```

内核里 **`MSR_SYSCALL_MASK`** 与手册 **`IA32_FMASK`** 对应同一类编程接口；**`idt_syscall_init()`** 在 **`MSR_LSTAR` 与兼容路径 MSRs** 之间的分支仍以 `arch/x86/kernel/cpu/common.c` 为准，**§2.5** 给出与当前主线一致的更长摘录。

从机制上概括：**`IA32_LSTAR` 只给出 ring-0 入口 `RIP`**；**`IA32_STAR` 给出 `SYSCALL`/`SYSRET` 使用的 CS/SS 选择子场**；**`IA32_FMASK` 规定 `RFLAGS` 在进入时被清除的位**；**`IA32_EFER.SCE` 使能整条 `SYSCALL`/`SYSRET` 路径**[^3][^11]。三颗 MSR 与总开关共同构成 SDM **Figure 5-14** 所描述的配置平面，操作系统需一并初始化，而不是仅写 **`LSTAR`** 一项。

### 2.2 端到端序列（示意）

```mermaid
sequenceDiagram
    participant User as 用户态进程
    participant CPU as CPU硬件
    participant Kernel as Linux内核
    User->>User: 1）RAX 系统调用号 nr，RDI RSI RDX R10 R8 R9 为 arg0 至 arg5
    User->>CPU: 2）执行 syscall
    CPU->>CPU: 3）RCX 存返回点 RIP，R11 存 RFLAGS
    CPU->>CPU: 4）RIP 取 IA32_LSTAR，RFLAGS 按 IA32_FMASK 清零若干位
    CPU->>Kernel: 5）进入 entry_SYSCALL_64
    Kernel->>Kernel: 6）swapgs，切内核栈，推 pt_regs
    Kernel->>Kernel: 7）do_syscall_64，x64_sys_call 按 nr 分发
    Kernel->>Kernel: 8）写回 RAX 返回值或负 errno
    Kernel->>Kernel: 9）可 SYSRET 则 SYSRET，否则 IRET
    CPU->>User: 10）回到用户态，自 RCX 所指指令继续
```

### 2.3 CPU 侧（与 Vol.3A §5.8.8 等一致）

1. **`RIP`（下一条指令）→ `RCX`**；**`RFLAGS` → `R11`**[^3]。  
2. **`RIP`** 来自 **`IA32_LSTAR`**；**`CS`/`SS`** 的选择子与 **`IA32_STAR`** 的位域布局按 SDM Figure 5-14[^3]。  
3. **`RFLAGS <- RFLAGS & ~IA32_FMASK`**。Linux 在 **`arch/x86/kernel/cpu/common.c`** 的 **`idt_syscall_init()`** 中向 **`MSR_SYSCALL_MASK`** 写入含 **`X86_EFLAGS_IF`** 等位，使进入内核后 **`IF` 通常被清除**[^3][^8]。  
4. **`SYSCALL` 不改变 `RSP`**；**`SYSRET` 也不恢复 `RSP`**，栈由内核显式管理[^3][^4]。

同一节（§5.8.8）对 `SYSCALL`/`SYSRET` 的英文原文可对照如下[^11]：

> For SYSCALL, the processor saves RFLAGS into R11 and the RIP of the next instruction into RCX; it then gets the privilege-level 0 target code segment, instruction pointer, stack segment, and flags as follows:
>
> Target instruction pointer — Reads a 64-bit address from IA32_LSTAR. (The WRMSR instruction ensures that the value of the IA32_LSTAR MSR is canonical.)  
> Flags — The processor sets RFLAGS to the logical-AND of its current value with the complement of the value in the IA32_FMASK MSR.

> The SYSCALL instruction does not save the stack pointer, and the SYSRET instruction does not restore it. It is likely that the OS system-call handler will change the stack pointer from the user stack to the OS stack. If so, it is the responsibility of software first to save the user stack pointer.

（手册在「gets the … as follows」之后对 **Target code segment**、**Stack segment** 等另有逐条说明，此处摘入与 **`LSTAR`/`FMASK`** 及 **RSP** 最直接相关的句子；完整列举见 [^1] 中 **§5.8.8** 与 **Figure 5-14**。）

### 2.4 Linux 侧（源码锚点）

| 内容 | 文件与要点 |
|------|------------|
| **`STAR`/`LSTAR`/`SYSCALL_MASK` 初始化** | `arch/x86/kernel/cpu/common.c`：`syscall_init()`、`idt_syscall_init()` |
| **入口汇编** | `arch/x86/entry/entry_64.S`：`entry_SYSCALL_64`（`swapgs`、`pt_regs`、`do_syscall_64`、若可则 `sysretq`） |
| **C 分发与 `SYSRET`/`IRET` 判定** | `arch/x86/entry/syscall_64.c`：`do_syscall_64`、`x64_sys_call`；**`sys_call_table[]`** 仍存在于镜像中，**主路径分发**为 **`switch`** |

### 2.5 内核源码摘录（与上表对应）

下列片段与主线 Linux 树一致，便于和 SDM 对照阅读[^8][^9][^10]。

`arch/x86/kernel/cpu/common.c` — `idt_syscall_init()` 中写入 **`MSR_LSTAR`** 与 **`MSR_SYSCALL_MASK`**：

```c
static inline void idt_syscall_init(void)
{
	wrmsrq(MSR_LSTAR, (unsigned long)entry_SYSCALL_64);
	/* ... IA32_SYSENTER_* and ia32_enabled() branches omitted ... */
	/*
	 * Flags to clear on syscall; clear as much as possible
	 * to minimize user space-kernel interference.
	 */
	wrmsrq(MSR_SYSCALL_MASK,
	       X86_EFLAGS_CF|X86_EFLAGS_PF|X86_EFLAGS_AF|
	       X86_EFLAGS_ZF|X86_EFLAGS_SF|X86_EFLAGS_TF|
	       X86_EFLAGS_IF|X86_EFLAGS_DF|X86_EFLAGS_OF|
	       X86_EFLAGS_IOPL|X86_EFLAGS_NT|X86_EFLAGS_RF|
	       X86_EFLAGS_AC|X86_EFLAGS_ID);
}
```

`arch/x86/entry/entry_64.S` — `entry_SYSCALL_64` 入口（硬件不压栈后，由这里构造 **`pt_regs`** 并调用 **`do_syscall_64`**）：

```asm
SYM_CODE_START(entry_SYSCALL_64)
	swapgs
	movq	%rsp, PER_CPU_VAR(cpu_tss_rw + TSS_sp2)
	SWITCH_TO_KERNEL_CR3 scratch_reg=%rsp
	movq	PER_CPU_VAR(cpu_current_top_of_stack), %rsp
	/* Construct struct pt_regs on stack */
	pushq	$__USER_DS				/* pt_regs->ss */
	pushq	PER_CPU_VAR(cpu_tss_rw + TSS_sp2)	/* pt_regs->sp */
	pushq	%r11					/* pt_regs->flags */
	pushq	$__USER_CS				/* pt_regs->cs */
	pushq	%rcx					/* pt_regs->ip */
	pushq	%rax					/* pt_regs->orig_ax */
	PUSH_AND_CLEAR_REGS rax=$-ENOSYS
	movq	%rsp, %rdi
	movslq	%eax, %esi
	call	do_syscall_64		/* returns with IRQs disabled */
```

`arch/x86/entry/syscall_64.c` — **`sys_call_table[]` 注释**与 **`x64_sys_call()`** 的 **`switch`** 分发：

```c
/*
 * The sys_call_table[] is no longer used for system calls, but
 * kernel/trace/trace_syscalls.c still wants to know the system
 * call address.
 */
#define __SYSCALL(nr, sym) case nr: return __x64_##sym(regs);
long x64_sys_call(const struct pt_regs *regs, unsigned int nr)
{
	switch (nr) {
	#include <asm/syscalls_64.h>
	default: return __x64_sys_ni_syscall(regs);
	}
}
```

同文件 **`do_syscall_64()`** — 前半dispatch、末尾返回值决定 **`SYSRET`** 与 **`IRET`**（以下与中版内核树连续片段一致，仅删去空白行以便排版）：

```c
/* Returns true to return using SYSRET, or false to use IRET */
__visible noinstr bool do_syscall_64(struct pt_regs *regs, int nr)
{
	add_random_kstack_offset();
	nr = syscall_enter_from_user_mode(regs, nr);
	instrumentation_begin();
	if (!do_syscall_x64(regs, nr) && !do_syscall_x32(regs, nr) && nr != -1) {
		regs->ax = __x64_sys_ni_syscall(regs);
	}
	instrumentation_end();
	syscall_exit_to_user_mode(regs);
	if (cpu_feature_enabled(X86_FEATURE_XENPV))
		return false;
	if (unlikely(regs->cx != regs->ip || regs->r11 != regs->flags))
		return false;
	if (unlikely(regs->cs != __USER_CS || regs->ss != __USER_DS))
		return false;
	if (unlikely(regs->ip >= TASK_SIZE_MAX))
		return false;
	if (unlikely(regs->flags & (X86_EFLAGS_RF | X86_EFLAGS_TF)))
		return false;
	return true;
}
```

---

## 主题三：经 IDT 的路径与 `SYSCALL` 路径的性能与开销

**`syscall` 相对 `int` + IDT 更快，主要不是因为“少查一次内存里的表”**，而是因为 **`int` 走 IDT 门与异常/中断类交付**，含 **门与特权相关检查、中断帧布局**，返回侧又常配合 **`IRET`**；**`SYSCALL`/`SYSRET`** 针对系统调用做了裁剪。内核里的 **调用号分发**发生在两条路径**入核之后**，不是整体差距的主因。

### 3.1 路径对比（示意）

```mermaid
graph TD
    subgraph 快路径_syscall
    A[用户态] -->|1. syscall| B[CPU]
    B -->|2. 读取 LSTAR/STAR/FMASK| C[内核入口 entry_SYSCALL_64]
    C -->|3. do_syscall_64 + x64_sys_call| D[__x64_sys_*]
    end

    subgraph 传统路径_int0x80
    E[用户态] -->|1. int 0x80| F[CPU]
    F -->|2. 通过 IDT 向量门进入| G[中断门入口]
    G -->|3. 中断类交付与返回语义| H[内核处理]
    end
```

```mermaid
graph TD
    subgraph 快路径_syscall
    A1[用户态] -->|1. syscall| B1[CPU]
    B1 -->|2. 从 MSR 取入口| C1[内核入口]
    C1 -->|3. 软件分发到具体例程| D1[__x64_sys_* 等]
    end

    subgraph 慢路径_int_idt
    E1[用户态] -->|1. int 0x80| F1[CPU]
    F1 -->|2. 硬件查 IDT| G1[IDT 门]
    G1 -->|3. 特权与栈等检查 + 转入处理程序| H1[内核入口]
    H1 -->|4. 同样要再做软件分发| I1[具体例程]
    end
```

### 3.2 机制层对比

| 特性 | **`int 0x80` + IDT** | **`syscall` + MSR** |
| :--- | :--- | :--- |
| 核心机制 | 软件中断，走 **异常/中断类交付** | **系统调用专用指令** |
| 入口 | CPU **按向量查 IDT 门** | CPU **从 MSR 取目标 `RIP` 等** |
| 特权与门 | **DPL、门类型** 等 | **不经同一套 IDT 门** |
| 硬件保存的现场 | **中断/异常帧**（含段与标志等，因事件与模式而异） | **主要为 `RCX`/`R11` 的返回契约** |
| 返回 | 常见 **`IRET`** | 条件满足时 **`SYSRET`**，否则 **`IRET`** |

### 3.3 单次查表与整条路径

**硬件对 IDT 的一次访问**与 **内核对 `switch (nr)` 的几条指令**各自都很快；差别主要来自 **整条入核/出核**：多保存了哪些状态、是否经过 **IDT 门语义**、返回是 **`IRET` 全功能**还是 **`SYSRET` 窄契约**、以及 Linux 在出口是否 **回退到 `IRET`**。

### 3.4 入核与出核：`int 0x80` 与 `syscall` 的步骤对照

下表沿用在 **IDT + `IRET`** 与 **`SYSCALL` + `SYSRET`（及 Linux 可能回退的 `IRET`）** 之间做对照的常见写法；其中 **`int` 路径的栈帧**以 **64 位长模式**下向内核栈压入的字段为准（**SS、RSP、RFLAGS、CS、RIP** 及可能的错误码等）[^1]，与 legacy 保护模式下部分教材中的“多段寄存器”示意图并不完全同形。

| 动作 | **`int 0x80`（经 IDT，`IRET` 返回）** | **`syscall`（`SYSRET` 快路径；条件不满足则 `IRET`）** | 性能与实现上的含义 |
| :--- | :--- | :--- | :--- |
| **特权级切换** | Ring 3 → Ring 0 | Ring 3 → Ring 0 | **两者都必须发生**；不是时间差的主要来源。 |
| **栈切换** | 与 **TSS / IST** 等绑定的 **中断交付** 语义下切到 **内核栈** | **`swapgs`**，再由软件把 **`RSP`** 切到 **per-CPU 内核栈顶**[^9] | `int` 走通用中断模型的硬件路径；`syscall` 由内核显式维护 **`RSP`**，与 **“`SYSCALL` 不改 `RSP`”** 的硬件契约一致[^3]。 |
| **硬件自动保存** | **向栈压中断帧**（长模式典型含 **SS、RSP、RFLAGS、CS、RIP**；另视向量压错误码）[^1] | **不向栈压帧**；仅用 **`RCX`/`R11`** 等约定配合 **MSR** 改变 **`RIP`/特权级/`RFLAGS` 掩码**[^3] | `int` 在硬件一侧完成较多现场记录；`syscall` 把栈上工作留到 **`entry_SYSCALL_64`**。 |
| **软件补全现场** | 入口例程继续保存其余寄存器、建 **`pt_regs`** | **`PUSH_AND_CLEAR_REGS` 等**补齐 **`pt_regs`**[^9] | 进入 **C 分发**前，两条路径通常都要把通用寄存器镜像补全。 |
| **权限 / 门检查** | **IDT 门**的 **DPL、类型** 等与 **`INT n`** 相关的一致检查 | **不经**与 **`int` 同一条** 门描述符路径 | `int` 多一层 **IDT 门禁** 语义的固定成本。 |
| **返回时现场恢复** | **`IRET`** 从栈帧恢复 **SS、RSP、RFLAGS、CS、RIP** 等 | **`SYSRET`**：**`RIP←RCX`、`RFLAGS←R11`**（窄）；否则走 **`IRET`**[^10] | **`IRET`** 通用、重；**`SYSRET`** 轻，但 Linux 在 **`do_syscall_64`** 中细查与 **`SYSRET` 契约**是否仍可满足[^10]。 |

同一组维度在 **`syscall` 专题**里也可以压缩理解：宏观上都要完成 **ring 切换与寄存器约定**，微观上 **`SYSCALL`/`SYSRET` 把可由专用指令“包办”的部分收紧**，**`int`/IDT/`IRET`** 为覆盖全体中断/异常类型保留更宽的默认行为。

### 3.4.1 草稿中三条机制说明的收束（无比喻，对齐 64 位语义）

下列三点对应草稿里“段寄存器 / DPL / `IRET` vs `SYSRET`”的直觉，但用语与**长模式**栈帧、当代内核实现一致：

1. **硬件记录的“现场”形态不同**  
   **`int` + IDT** 走 **通用中断交付**：在 **64 位长模式**下，典型地向内核栈压入 **SS、RSP、RFLAGS、CS、RIP**（及可能的错误码）等，以与**全体向量**共用同一套出/入栈约定[^1]。**`SYSCALL`** 则 **不压栈**，仅用 **`RCX`/`R11`** 保存返回用 **`RIP`/`RFLAGS`**，余下由 **`entry_SYSCALL_64`** 建 **`pt_regs`**[^3][^9]。在 OS 采用 **平坦段模型**、许多段相关差异在逻辑上“折叠”掉的背景下，**`int` 仍承担与通用中断兼容的栈上开销**；**`syscall` 则把一部分现场推迟到软件路径**。

2. **门 / DPL 检查是否发生**  
   **`INT n`** 命中 **IDT 门**时，CPU 执行与 **描述符特权级（DPL）**、门类型等相关的**一致性检查**[^1]。**`SYSCALL`** **不经该扇门**，转入 ring 0 的规则改由 **`STAR`/`LSTAR`/`FMASK`** 与 **`IA32_EFER.SCE`** 描述[^3][^11]。两条路径的“安全检查模型”不同，不能简单地说某一边“没有安全”，只能说 **机制分配在硬件协议层与 OS 初始化层之间发生了位移**。

3. **返回指令的恢复面**  
   **`IRET`** 从 **中断帧**恢复 **SS、RSP、RFLAGS、CS、RIP** 等，能力完整、路径通用[^1]。**`SYSRET`**（`REX.W` 形式）在契约成立时 **仅从 `RCX`/`R11` 窄恢复 `RIP`/`RFLAGS`**，并配合 **`STAR`** 场加载用户 **`CS`/`SS`** 选择子语义[^4]；Linux 在 **`do_syscall_64`** 中若检测到与 **`SYSRET` 契约**不一致或存在历史/安全约束，则 **回退 `IRET`**[^10]。

### 3.5 数量级举例

在常见 x86-64 桌面平台上，对 **`getpid` 类极短系统调用**做周期计数，**`int 0x80`** 有时可达约 **二百周期**量级，**`syscall`** 多在约 **数十至百余周期**量级，可差数倍。结果强依赖 **CPU、微架构、是否实际走 `SYSRET` 与测量方法**；定量的结论应在目标机上用 **`perf` 等**重复测量。

### 3.6 小结

- **IDT**：通用 **事件交付** 机制，优先保证覆盖面与一致性，**不以最短系统调用为唯一目标**。  
- **系统调用分发**：**`x64_sys_call` 的 `switch`** 为主路径；**`sys_call_table[]`** 仍服务 **观测/枚举** 等需求；二者都在 **`syscall` 已进核之后** 执行。  
- **`SYSCALL` + MSR**：系统调用 **专用**硬件入口协议；真正缩短的是 **经 MSR 的入核与在条件允许时的 `SYSRET` 返回**，不是“少做一次 C 层分发”。  
- **Linux**：即便从 **`syscall`** 入核，仍可能在出口选用 **`IRET`**，与 **`SYSRET` 契约**及历史、安全问题有关[^10]。

---

## 建议的自修顺序

1. SDM：**中断/异常与 IDT**、**`SYSCALL`/`SYSRET`**。  
2. Linux：**`common.c`（MSR）→ `entry_64.S` → `syscall_64.c`**。  
3. 对照阅读：`entry_64.S` 与 `syscall_64.c`，结合文末 References。

## References

[^1]: [Intel® 64 and IA-32 Architectures SDM — Combined Volumes](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html) - 官方总入口（含 Volume 3 系统编程）；文中 IDT 64-bit 描述与中断/异常机制以此为准  
[^2]: [OSDev Wiki — Interrupt Descriptor Table](https://wiki.osdev.org/Interrupt_Descriptor_Table) - IDT 结构与模式差异的教学索引  
[^3]: [x86 Instruction Reference — SYSCALL](https://www.felixcloutier.com/x86/syscall) - 指令级语义（`RCX`/`R11`、`LSTAR`、`FMASK`、`RSP` 不保存）  
[^4]: [x86 Instruction Reference — SYSRET](https://www.felixcloutier.com/x86/sysret) - `SYSRET` 返回语义与 `RSP` 处理约束  
[^5]: [Linux Kernel Documentation — entry_64](https://www.kernel.org/doc/html/latest/arch/x86/entry_64.html) - x86 多入口说明（含 `entry_INT80_compat`、`system_call` 等）  
[^6]: [Intel x86 Instruction Set Reference — SYSENTER](https://www.felixcloutier.com/x86/sysenter) - `SYSENTER/SYSEXIT` 的历史快速调用路径  
[^7]: [man7 — syscall(2)](https://man7.org/linux/man-pages/man2/syscall.2.html) - Linux 用户态系统调用 ABI 与调用约定说明  
[^8]: [Linux Source — arch/x86/kernel/cpu/common.c](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/arch/x86/kernel/cpu/common.c) - `syscall_init()` / `idt_syscall_init()` 与 `MSR_SYSCALL_MASK` 初始化  
[^9]: [Linux Source — arch/x86/entry/entry_64.S](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/arch/x86/entry/entry_64.S) - `entry_SYSCALL_64` 路径（`swapgs`、`pt_regs`、`sysretq`）  
[^10]: [Linux Source — arch/x86/entry/syscall_64.c](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/arch/x86/entry/syscall_64.c) - `do_syscall_64`、`x64_sys_call` 与 `SYSRET/IRET` 判定  
[^11]: 正文所引 **Intel SDM 英文原文**出自 *Intel® 64 and IA-32 Architectures Software Developer’s Manual, Volume 3A: System Programming Guide, Part 1*（约 **§6.14** 64-bit IDT gate、**§5.8.8** `SYSCALL`/`SYSRET`）；完整手册见 [^1] 的官方下载入口  
