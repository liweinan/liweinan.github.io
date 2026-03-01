---
title: "栈为什么比堆快：从分配方式到「批发-零售」链条"
---

在同一个进程内，栈和堆使用相同的内存硬件，访问速度本身没有区别。真正的性能差异来自内核在分配和管理内存时为两者采取的不同策略。本文从分配方式、物理内存管理、缓存友好性三个角度说明原因，并借 sbrk、Slab、malloc 梳理从内核到用户态的内存「批发-零售」链条；最后讨论「栈比堆快」这一经验法则的适用边界。

## 1. 内存分配方式

### 栈：近乎零成本

栈上分配只需修改**栈指针寄存器**。在 x86-64 上，函数序言用 `sub rsp, N` 预留空间（如 `sub rsp, 0x10` 即 16 字节），一条 CPU 指令、不涉及内核，成本极低[^1][^2]。

```asm
; x86-64 函数序言示例：分配 0x20 字节栈帧
    push    rbp
    mov     rbp, rsp
    sub     rsp, 0x20
```

### 堆：系统调用的开销

通过 `malloc` 申请内存时，若分配器内部池子不足，会通过 **`brk`** 或 **`mmap`** 等**系统调用**向内核申请。用户态/内核态切换带来微秒级开销，相比一条 `sub rsp` 可高出数百倍甚至更多[^3]。

## 2. 物理内存管理

### 栈：缺页异常与按需映射

内核为栈预留虚拟地址空间，但未必一开始就分配物理页。首次访问栈上地址时，CPU 触发**缺页异常**（#PF），内核在异常处理中分配物理页并建立映射，对开发者透明，且只在首次触及该页时发生一次[^2]。

需要强调的是：**在发生缺页的那一刻**，栈和堆走的是同一条内核路径（#PF → 分配物理页 → 建立映射，必要时清零），单看这一次缺页本身，**栈并不比堆快**。栈的「快」体现在：分配虚拟空间无需系统调用（§1）；缺页通常只在首次触及该页时发生一次，成本被摊薄；一旦物理页已常驻，栈与堆的访问就是普通内存访问，没有差别。

### 堆：mmap 与安全清零

通过 `mmap` 获取匿名内存时，内核会保证进程看到的是「零填充」：要么在缺页时分配并清零，要么先映射到全局零页，写时再分配（copy-on-write），避免读到其他进程残留数据[^4][^9]。Gorman《Understanding the Linux Virtual Memory Manager》Ch4 对用户态区段的描述[^9]：

> With a process, space is simply reserved in the linear address space by pointing a page table entry to a read-only globally visible page filled with zeros. On writing, a page fault is triggered which results in a new page being allocated, filled with zeros, placed in the page table entry and marked writable.

无论哪种方式都会在首次写时产生分配/清零或 COW 开销。`malloc` 往往通过 `mmap` 或 `sbrk` 拿到大块后再在用户态切分、复用，以摊薄这类成本。

## 3. 缓存友好性

### 栈：局部性更好

栈的访问模式是典型的 LIFO，当前活跃的局部变量多集中在栈顶附近，容易落在 CPU 的 L1/L2 缓存中，命中率高。

### 堆：访问模式更分散

堆上对象由程序显式管理，链表、树等结构容易在地址空间内分散，导致缓存行利用率低、更多访问主存。

---

## 4. 从内核到用户态：「批发-零售」链条

结合 **sbrk**、**Slab** 和 **malloc**，可以把内存分配看成一条从内核到 CPU 的链条；栈之所以「快」，是因为它处在链条末端，几乎不经中间层。

### 4.1 一级批发：内核 Buddy（伙伴系统）

物理内存以**页**（通常 4KB）为最小单位管理，由伙伴系统负责分配和回收：按 2^order 页块管理，不足时分裂大块、释放时与伙伴合并。粒度较粗，不适合直接满足「几十字节」的小请求[^5][^9]。

### 4.2 二级批发：内核 Slab

**Slab 分配器**从伙伴系统拿到整页，再切成固定大小的对象并缓存，主要服务内核自身（如 `task_struct`、`inode` 等）。对象用完后可留在 Slab 中复用，减少对伙伴系统的调用，并缓解内碎片、提高缓存利用率[^5][^9]。

### 4.3 用户态代理：malloc 与 sbrk

用户程序通过 **`malloc`** 获取堆内存。当内部池不足时，`malloc` 会调用 **`sbrk`** 或 **`mmap`**：

- **`sbrk`** 调整 program break，向内核「圈」出一块新的虚拟地址空间，本身是一次系统调用，成本较高；内核用 `mm->brk` 与 VMA 管理堆顶[^8][^9]。
- **`malloc`** 把拿到的大块在用户态切分、合并、复用，承担「零售」角色，带来管理开销和可能的碎片。

### 4.4 栈：无中间商的「自家后院」

栈不经过上述任何一层：分配就是改栈指针，无需系统调用；物理页在首次访问时按需分配（§2），LIFO 访问模式又利于缓存。因此处在链条最末端，面向 CPU，成本最低。

### 4.5 开销大致顺序（从慢到快）

| 层级 | 机制 | 特点 |
|------|------|------|
| 最慢 | 系统调用（sbrk/mmap） | 用户态/内核态切换，微秒级 |
| 中等 | 用户态堆管理（malloc/free） | 无模式切换，但有锁与查找 |
| 较快 | 内核 Slab（kmem_cache_alloc） | 内核内复用，无系统调用 |
| 最快 | 栈指针调整（sub rsp） | 纯用户态指令，纳秒级 |

---

## 5. 「栈比堆快」的边界

单纯比较「栈和堆谁快」容易误导，因为两者不在同一维度：栈更多是「使用已就绪内存」，堆还涉及「获取」和「管理」。

### 5.1 分配模式才是关键

若**事先在堆上分配好一块内存，再反复读写**，其访问速度与栈上同规模数据可以非常接近——此时差异主要在「分配方式」，而非「存储介质」。

```c
// 栈：分配 + 使用
void stack_func(void) {
    int arr[1000];   // 分配：改栈指针
    arr[0] = 42;     // 使用：普通内存访问
}

// 堆：一次性分配，反复使用
static int *heap_arr;

void heap_init(void) {
    heap_arr = malloc(1000 * sizeof(int));  // 仅此一次有系统调用/分配器开销
}

void heap_func(void) {
    heap_arr[0] = 42;   // 使用：与栈上访问同属「已就绪内存」
}
```

### 5.2 堆可以模拟栈的分配模式

Arena、pool 等分配器本质是在堆上**模拟栈**：一次性向系统要一大块，用指针顺序分配，最后整体释放。在这种模式下，堆上的「分配」成本可以接近栈。

### 5.3 值得关注的维度

| 维度 | 栈 | 堆 |
|------|-----|-----|
| 分配速度 | 固定、极快 | 视是否命中缓存、是否触发系统调用而定 |
| 可预测性 | 高 | 可能受碎片、锁竞争影响 |
| 适用场景 | 小数据、生命周期与调用栈一致 | 大数据、生命周期动态 |

栈的「快」是用**约束**换来的：大小有限、生命周期必须 LIFO。堆的灵活则伴随分配与管理开销。工程上更值得关心的是：在给定场景下，应优先用栈、对象池还是堆。

### 5.4 缺页路径上栈与堆等价

若只比较「第一次访问某页、触发缺页」的那条路径，栈和堆没有区别：都是 #PF → 内核分配物理页 → 映射（堆上匿名区还可能多一步清零或 COW）。因此**在缺页场景下，栈并不比堆快**。「栈比堆快」指的是分配虚拟空间的成本（栈几乎为零、堆可能涉及系统调用）以及缺页发生频率的摊薄（栈往往早已 fault in），而不是指单次缺页处理本身。

---

## 总结

1. **同一进程内，栈和堆的「访问」速度无本质差别**；差异主要来自**分配方式**与**物理页的建立方式**（栈按需缺页，堆常伴随清零或 COW）。
2. **在缺页发生的那一刻**，栈与堆走同一条内核路径，栈并不比堆快；**栈的快**体现在分配虚拟空间几乎零成本（改栈指针）、缺页通常只发生一次且易被摊薄、以及 LIFO 带来的良好局部性。
3. 从内核 Buddy → Slab → sbrk/mmap → malloc 到栈，是一条「批发-零售」链；栈在末端、无中间层，分配成本最低。
4. **「栈比堆快」**是有用的经验法则，但不是普适真理；工程上更值得关心的是「为什么快」和「在什么情况下快」，再按场景选择栈、池或堆。

## 扩展阅读

### Intel SDM Vol.3A 第 6 章[^2]

§6.14.2「64-Bit Mode Stack Frame」原文：

> In IA-32e mode, the RSP is aligned to a 16-byte boundary before pushing the stack frame. The stack frame itself is aligned on a 16-byte boundary when the interrupt handler is called.

§6.15「Exception and Interrupt Reference」中 **Interrupt 14—Page-Fault Exception (#PF)**：Exception Class 为 **Fault**；P=0、权限/写/保留位等触发。SDM 原文：

> The exception handler can recover from page-not-present conditions and restart the program or task without any loss of program continuity.

### Mel Gorman《Understanding the Linux Virtual Memory Manager》[^9]

- **Ch4 Process Address Space**：`mm_struct` 中堆与栈的字段（见下内核代码）；用户态零页与写时缺页见正文 §2 引用。
- **Ch6 Physical Page Allocation**：Binary Buddy、`free_area_t`（Gorman 书为 2.4/2.6 的 `free_list`+`map`）、order 分裂/合并。
- **Ch8 Slab Allocator**：三目标（硬件缓存、对象缓存、内碎片）、slab coloring、`kmem_cache_alloc`、slabs_full/partial/free、per-CPU 缓存。

### Linux 内核源码（代码片段与文件说明）

**1. 进程地址空间：堆与栈的起止**（`include/linux/mm_types.h`）

`mm_struct` 中描述堆与栈的字段；`sys_brk` 通过 `mm->brk`、`mm->start_brk` 管理堆顶[^8][^9]。

```c
// 简化自 include/linux/mm_types.h（约 1100 行起）
struct mm_struct {
    // ...
    unsigned long start_code, end_code, start_data, end_data;
    unsigned long start_brk, brk, start_stack;   /* 堆起止、栈底 */
    unsigned long arg_start, arg_end, env_start, env_end;
    // ...
};
```

**2. Buddy：zone 与 free_area**（`include/linux/mmzone.h`、`mm/page_alloc.c`）

每 zone 有 `free_area[NR_PAGE_ORDERS]`，按 2^order 页块管理；分配入口为 `__alloc_pages()`[^7]。

```c
// 简化自 include/linux/mmzone.h（约 133 行）
struct free_area {
    struct list_head free_list[MIGRATE_TYPES];
    unsigned long    nr_free;
};

// 每个 zone 含（同文件约 980 行）：
// struct free_area free_area[NR_PAGE_ORDERS];
```

**3. sys_brk 系统调用**（`mm/mmap.c`）

用户态 `brk`/`sbrk` 的内核入口；通过 `mm->brk`、`mm->start_brk` 与 VMA 扩展堆[^8]。

```c
// 简化自 mm/mmap.c（约 115 行起）
SYSCALL_DEFINE1(brk, unsigned long, brk)
{
    struct mm_struct *mm = current->mm;
    // ...
    origbrk = mm->brk;
    min_brk = mm->start_brk;   /* 堆起始 */
    // ...
    newbrk = PAGE_ALIGN(brk);
    oldbrk = PAGE_ALIGN(mm->brk);
    if (oldbrk == newbrk) {
        mm->brk = brk;
        goto success;
    }
    // 扩展或收缩堆 VMA...
}
```

**4. Slab 分配接口**（`mm/slub.c`）

当前默认 Slab 实现；`kmem_cache_alloc` 从指定 cache 取对象（如 `task_struct`、`vm_area_struct` 等）[^6]。

```c
// 简化自 mm/slub.c（约 4202 行）
void *kmem_cache_alloc_noprof(struct kmem_cache *s, gfp_t gfpflags)
{
    void *ret = slab_alloc_node(s, NULL, gfpflags, NUMA_NO_NODE, _RET_IP_,
                                s->object_size);
    trace_kmem_cache_alloc(_RET_IP_, ret, s, gfpflags, NUMA_NO_NODE);
    return ret;
}
EXPORT_SYMBOL(kmem_cache_alloc_noprof);
```

本文引用已用 pdftotext 与本地 kernel 源码校对。

## References

[^1]: [System V ABI - AMD64 - Register and Stack Layout](https://www.sra.uni-hannover.de/Lehre/SS25/V_BSB/doc/x86-abi.html) - x86-64 调用约定与栈布局（RSP、red zone、16 字节对齐）

[^2]: [Intel® 64 and IA-32 Architectures Software Developer's Manual, Vol. 3A](https://www.intel.com/content/www/us/en/content-details/868146/intel-64-and-ia-32-architectures-software-developer-s-manual-volume-3a-system-programming-guide-part-1.html) - 第 6 章 Interrupt and Exception Handling、§6.14.2/§6.15 #PF

[^3]: [mmap(2) - Linux manual page](https://man7.org/linux/man-pages/man2/mmap.2.html) - mmap 系统调用；[brk(2)](https://man7.org/linux/man-pages/man2/brk.2.html) - 堆顶与 sbrk/brk

[^4]: [What is the purpose of MAP_ANONYMOUS in mmap?](https://stackoverflow.com/questions/34042915/what-is-the-purpose-of-map-anonymous-flag-in-mmap-system-call) - 匿名映射与零填充语义；匿名区采用 demand paging，读时映射零页或分配并清零，写时 COW/分配

[^5]: [Memory Management - The Linux Kernel documentation](https://www.kernel.org/doc/html/latest/mm/slab.html) - Slab 分配器；[Understanding the Linux Virtual Memory Manager - Slab 附录](https://www.kernel.org/doc/gorman/html/understand/understand025.html) - Buddy 与 Slab 概述

[^6]: Linux 内核 **mm/slub.c**（`kmem_cache_alloc`）、**mm/slab.c**、**include/linux/sched.h**。[Bootlin - slub.c](https://elixir.bootlin.com/linux/latest/source/mm/slub.c)

[^7]: Linux 内核 **mm/page_alloc.c**（`__alloc_pages`、`zone->free_area`）、**include/linux/mmzone.h**（`struct free_area`）。[Bootlin - page_alloc.c](https://elixir.bootlin.com/linux/latest/source/mm/page_alloc.c)

[^8]: Linux 内核 **mm/mmap.c**（`SYSCALL_DEFINE1(brk,...)`、`mm->brk`/`mm->start_brk`）。[Bootlin - mmap.c](https://elixir.bootlin.com/linux/latest/source/mm/mmap.c)

[^9]: Mel Gorman, **Understanding the Linux® Virtual Memory Manager**。[kernel.org PDF](https://www.kernel.org/doc/gorman/pdf/understand.pdf)、[HTML 目录](https://www.kernel.org/doc/gorman/html/understand/)。Ch4/6/8 见扩展阅读
