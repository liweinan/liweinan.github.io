---
title: "How C Calls Rust in Linux Kernel: Module Lifecycle Deep Dive"
abstract: "A comprehensive technical analysis of how C kernel code calls Rust functions through the module loading mechanism. Using actual Linux kernel source code (6.x), this article reveals the complete evidence chain: from Rust's #[no_mangle] attribute to C's function pointer invocation, from ELF symbol binding to the actual call flow. We demonstrate that C→Rust calls are not theoretical but a production reality implemented through standard module lifecycle management."
---

{{ page.abstract }}

## Introduction: The Question

In discussions about Rust in the Linux kernel, a fundamental architectural question often arises:

**"Can C kernel code call Rust functions?"**

This isn't just an academic question. Understanding the call direction between C and Rust is crucial for grasping:
- The integration architecture
- ABI stability requirements
- Future evolution possibilities
- Security and safety boundaries

Many assume that Rust only wraps C APIs (unidirectional), making Rust purely a "consumer" of C services. However, **actual kernel source code reveals a different reality**: C does call Rust functions, specifically for module lifecycle management.

This article provides a complete evidence chain based on Linux kernel 6.x source code.

## The Answer: Yes, Through Module Lifecycle

**C kernel code DOES call Rust functions** for:
- ✅ Module initialization (`init_module()`, `__<name>_init()`)
- ✅ Module cleanup (`cleanup_module()`, `__<name>_exit()`)

**C kernel code does NOT call Rust for**:
- ❌ Data processing or utility functions
- ❌ Core subsystem services
- ❌ General-purpose APIs

The scope is **strictly limited to module lifecycle management**, but this is a critical integration point that enables all Rust drivers to work.

## Evidence 1: Rust Generates C-Compatible Symbols

Every Rust module automatically generates C-callable functions via the `module!` macro family. Here's the actual code from `rust/macros/module.rs`:

```rust
// rust/macros/module.rs (lines 260-290)

// For loadable modules (.ko files)
#[cfg(MODULE)]
#[doc(hidden)]
#[no_mangle]
#[link_section = ".init.text"]
pub unsafe extern "C" fn init_module() -> ::kernel::ffi::c_int {
    // SAFETY: This function is inaccessible to the outside due to the double
    // module wrapping it. It is called exactly once by the C side via its
    // unique name.
    unsafe { __init() }
}

#[cfg(MODULE)]
#[doc(hidden)]
#[no_mangle]
#[link_section = ".exit.text"]
pub extern "C" fn cleanup_module() {
    // SAFETY:
    // - This function is inaccessible to the outside due to the double
    //   module wrapping it. It is called exactly once by the C side via its
    //   unique name,
    // - furthermore it is only called after `init_module` has returned `0`
    //   (which delegates to `__init`).
    unsafe { __exit() }
}

// For built-in modules (compiled into kernel)
#[cfg(not(MODULE))]
#[doc(hidden)]
#[no_mangle]
pub extern "C" fn __<ident>_init() -> ::kernel::ffi::c_int {
    // SAFETY: This function is inaccessible to the outside due to the double
    // module wrapping it. It is called exactly once by the C side via its
    // placement above in the initcall section.
    unsafe { __init() }
}

#[cfg(not(MODULE))]
#[doc(hidden)]
#[no_mangle]
pub extern "C" fn __<ident>_exit() {
    unsafe { __exit() }
}
```

### Key Mechanisms Explained

**1. `#[no_mangle]` Attribute**

Without this attribute, Rust applies name mangling:
```
init_module → _ZN7mymodule11init_module17h<hash>E
```

With `#[no_mangle]`, the symbol name remains:
```
init_module → init_module
```

This allows C code to find the function by its expected standard name.

**2. `extern "C"` Calling Convention**

This ensures:
- Parameters passed according to C ABI (System V on x86_64)
- Stack frame layout matches C expectations
- Register usage follows C calling convention
- No Rust-specific calling overhead

**3. `#[link_section = ".init.text"]`**

Places the function in the ELF `.init.text` section, where the C kernel expects to find initialization code. This section can be freed after initialization completes.

## Evidence 2: C Kernel's Module Structure

The C kernel defines a standard module structure that holds a function pointer to the init function:

```c
// include/linux/module.h (line 470)
struct module {
    const char *name;

    // ... many fields omitted ...

    /* Startup function. */
    int (*init)(void);  // ← Function pointer to init_module

    struct module_memory mem[MOD_MEM_NUM_TYPES] __module_memory_align;

    // ... more fields ...
};
```

The `init` field is a **function pointer** that will be invoked during module loading.

## Evidence 3: C Kernel Calls the Function Pointer

When loading a module, the C kernel explicitly calls `mod->init`:

```c
// kernel/module/main.c (lines 2989-3020)
static noinline int do_init_module(struct module *mod)
{
    int ret = 0;
    struct mod_initfree *freeinit;

    // ... setup code omitted ...

    freeinit = kmalloc(sizeof(*freeinit), GFP_KERNEL);
    if (!freeinit) {
        ret = -ENOMEM;
        goto fail;
    }

    freeinit->init_text = mod->mem[MOD_INIT_TEXT].base;
    freeinit->init_data = mod->mem[MOD_INIT_DATA].base;
    freeinit->init_rodata = mod->mem[MOD_INIT_RODATA].base;

    do_mod_ctors(mod);

    /* Start the module */
    if (mod->init != NULL)
        ret = do_one_initcall(mod->init);  // ← CALLS THE FUNCTION POINTER

    if (ret < 0) {
        goto fail_free_freeinit;
    }

    // ... post-init code ...

    mod->state = MODULE_STATE_LIVE;

    // ...
}
```

**Key observation**: `do_one_initcall(mod->init)` invokes the function pointer, which points to Rust's `init_module()` for Rust modules.

## Evidence 4: How mod->init Gets Set

**Critical question**: How does `mod->init` point to the Rust function?

**Answer**: Through ELF symbol binding at link time, not runtime lookup.

### The ELF Module Structure Layout

When compiling a kernel module (C or Rust), the linker creates a special section:

```
.gnu.linkonce.this_module
```

This section contains the **complete binary layout** of `struct module`, including:
- Module name
- Module version
- **Init function pointer** (already resolved to `init_module` address)
- Cleanup function pointer
- Other metadata

### Module Loading Process

```c
// kernel/module/main.c (line 2901)
static struct module *layout_and_allocate(struct load_info *info, int flags)
{
    struct module *mod;
    // ... layout calculation ...

    /* Module has been copied to its final place now: return it. */
    mod = (void *)info->sechdrs[info->index.mod].sh_addr;
    // ↑ Direct memory mapping - the module struct is already complete!

    kmemleak_load_module(mod, info);
    return mod;
}
```

The kernel **does NOT** manually assign each field. Instead:
1. The `.gnu.linkonce.this_module` section is mapped into memory
2. This section IS the `struct module`
3. All fields, including `init`, are **already set by the linker**

### Symbol Resolution at Link Time

When linking a Rust module:

```bash
# Simplified linking process
ld -r \
  -o rcpufreq_dt.ko \
  rcpufreq_dt.o \
  --build-id
```

The linker:
1. Finds the `init_module` symbol (address 0xXXXX)
2. Writes this address into `module.init` field
3. Embeds the complete struct in `.gnu.linkonce.this_module` section
4. Writes everything to the `.ko` file

## Evidence 5: Real Rust Driver Example

Every Rust driver uses a macro that generates these functions. For example:

```rust
// drivers/cpufreq/rcpufreq_dt.rs (lines 215-221)
module_platform_driver! {
    type: CPUFreqDTDriver,
    name: "cpufreq-dt",
    author: "Viresh Kumar <viresh.kumar@linaro.org>",
    description: "Generic CPUFreq DT driver",
    license: "GPL v2",
}
```

This macro expands to:
```rust
// Generated code (conceptual)
#[no_mangle]
pub unsafe extern "C" fn init_module() -> i32 {
    // Register CPUFreqDTDriver as platform driver
    cpufreq::Registration::<CPUFreqDTDriver>::new_foreign_owned(/*...*/)
}

#[no_mangle]
pub extern "C" fn cleanup_module() {
    // Unregister driver
}
```

## Complete Call Flow

Let's trace what happens when loading a Rust module:

```
1. User executes:
   $ insmod rcpufreq_dt.ko

2. Kernel syscall:
   SYSCALL_DEFINE3(init_module, void __user *, umod, ...)
   ↓

3. Copy module to kernel memory:
   copy_module_from_user(umod, len, &info)
   ↓

4. Parse ELF and allocate:
   mod = layout_and_allocate(&info, flags)
   ↓ (maps .gnu.linkonce.this_module section)

5. mod struct is now complete:
   mod->init = &init_module  // ← Already set by linker
   mod->name = "cpufreq-dt"
   // ... all fields populated ...
   ↓

6. Call initialization:
   do_init_module(mod)
   ↓

7. Invoke the function pointer:
   ret = do_one_initcall(mod->init)
   ↓ (Calls through function pointer)

8. EXECUTION TRANSFERS TO RUST:
   init_module() in Rust code executes
   ↓

9. Rust driver initializes:
   CPUFreqDTDriver::probe() registers driver
   ↓

10. Module is live:
    mod->state = MODULE_STATE_LIVE
```

**Critical insight**: The C→Rust call at step 7 is a **standard indirect function call** through a function pointer, exactly the same as calling a C module's init function.

## Symbol Naming Convention

The kernel expects specific symbol names:

| Module Type | Init Symbol | Cleanup Symbol |
|-------------|-------------|----------------|
| Loadable (.ko) | `init_module` | `cleanup_module` |
| Built-in | `__<name>_init` | `__<name>_exit` |

Both C and Rust modules must follow this convention. Example:

**C module**:
```c
// drivers/example/example_c.c
static int __init my_init(void)
{
    // ...
}

static void __exit my_exit(void)
{
    // ...
}

module_init(my_init);  // Expands to create init_module
module_exit(my_exit);  // Expands to create cleanup_module
```

**Rust module**:
```rust
// drivers/example/example_rust.rs
module_platform_driver! {
    type: MyDriver,
    // ...
}
// Macro generates init_module and cleanup_module
```

Both produce the **same ELF symbols** that the kernel expects.

## Verification Methods

If you have a compiled Rust kernel module, you can verify this mechanism directly:

### 1. Check Symbol Table

```bash
$ nm drivers/cpufreq/rcpufreq_dt.ko | grep init_module
0000000000000000 T init_module
```

The `T` indicates a symbol in the `.text` section (code). Address `0000000000000000` is relative to the module's base.

### 2. Examine ELF Sections

```bash
$ readelf -S drivers/cpufreq/rcpufreq_dt.ko | grep -E "\.init\.text|\.gnu\.linkonce"
  [12] .init.text        PROGBITS         0000000000000000  00001000
  [23] .gnu.linkonce.th  PROGBITS         0000000000000000  00003400
```

The `.gnu.linkonce.this_module` section contains the `struct module`.

### 3. Disassemble Init Function

```bash
$ objdump -d drivers/cpufreq/rcpufreq_dt.ko | grep -A20 "<init_module>:"
0000000000000000 <init_module>:
   0:   push   %rbx
   1:   mov    %rsp,%rbx
   4:   sub    $0x10,%rsp
   # ... actual Rust code ...
```

This shows the compiled Rust code at the `init_module` symbol.

### 4. Verify Module Structure

```bash
$ readelf -x .gnu.linkonce.this_module drivers/cpufreq/rcpufreq_dt.ko
# Displays hex dump of the struct module
# Bytes 0x470-0x478 (on 64-bit) contain the init function pointer
```

## Counter-Proof: What If C Didn't Call Rust?

If the C kernel did NOT call Rust's `init_module()`, then:

**Expected failures**:
- ❌ `insmod rcpufreq_dt.ko` would fail
- ❌ Module would not initialize
- ❌ Driver would not register with the subsystem
- ❌ Device would not be managed by the driver
- ❌ `lsmod` would not show the module as loaded

**Actual reality**:
- ✅ Rust modules load successfully
- ✅ Drivers initialize and register
- ✅ Devices are managed correctly
- ✅ `lsmod` shows the module

**Conclusion**: C must be calling Rust's `init_module()`, otherwise none of this would work.

## Why Limited to Module Lifecycle?

The current design restricts C→Rust calls to module initialization and cleanup because:

### 1. Well-Defined Interface

Module lifecycle has a simple, stable signature:
```c
int (*init)(void);     // No parameters, returns error code
void (*exit)(void);    // No parameters, no return value
```

This simplicity means:
- No complex ABI negotiations
- No data structure marshaling
- No lifetime management across boundary
- Clear success/failure semantics

### 2. ABI Stability

Only the **entry points** need stable ABI:
- `init_module` signature: fixed forever
- Internal Rust code: can evolve freely
- No internal Rust APIs exposed to C

If C depended on internal Rust APIs, those APIs would need eternal ABI stability.

### 3. Minimal Coupling

The C kernel core does NOT depend on Rust for functionality:
- C kernel can load C modules without Rust support
- Rust support is purely additive
- Disabling Rust doesn't break core kernel

This keeps the dependency graph clean:
```
C kernel core (independent)
    ↓ (can load)
C modules (independent)
    ↓ (can load)
Rust modules (depend on C kernel APIs)
```

### 4. Standard Module Pattern

Both C and Rust modules follow the **same loading mechanism**:
- Parse ELF
- Map sections
- Resolve relocations
- Call `mod->init()`

This uniformity means:
- No special-case code for Rust
- Same security checks apply
- Same debugging tools work
- Same performance characteristics

## Future Expansion Possibilities

While currently limited to module lifecycle, C→Rust calls could expand:

### 1. Callback Registration (2027-2028)

```rust
// Future possibility
#[no_mangle]
pub extern "C" fn rust_timer_callback(data: *mut c_void) {
    // Safe Rust timer handler
}
```

```c
// C code registers Rust callback
setup_timer(&timer, rust_timer_callback, data);
```

**Challenges**:
- Lifetime management (who owns the data?)
- Error propagation (panic handling)
- ABI stability (callback signatures must be stable)

### 2. Subsystem Interfaces (2028-2030)

If a core subsystem is rewritten in Rust:

```rust
// Future: Rust scheduler interface
#[no_mangle]
pub extern "C" fn sched_yield_to(task: *mut task_struct) -> c_int {
    // Safe scheduler implementation
}
```

```c
// C code calls Rust scheduler
ret = sched_yield_to(next_task);
```

**Requirements**:
- Proven stability in production
- Performance validation
- Gradual migration path
- Fallback to C implementation

### 3. Utility Functions (2026-2027)

```rust
// Future: Safe allocator
#[no_mangle]
pub extern "C" fn rust_safe_kmalloc(
    size: usize,
    flags: gfp_t
) -> *mut c_void {
    // Memory-safe allocation with compile-time checks
}
```

**Benefits**:
- Gradual safety improvements
- No need to rewrite entire subsystems
- Easy to benchmark and validate

## Current Production Reality (2026)

As of Linux kernel 6.x, C→Rust calls are **production reality**:

**Active Rust drivers**:
- `drivers/net/phy/ax88796b_rust.ko` - Network PHY driver
- `drivers/net/phy/qt2025.ko` - Marvell PHY driver
- `drivers/cpufreq/rcpufreq_dt.ko` - CPU frequency driver
- `drivers/block/rnull.ko` - Null block device
- `drivers/gpu/drm/nova/*.ko` - NVIDIA GPU driver (13 modules)

**Every one of these is loaded by C calling Rust's `init_module()`.**

You can verify this on a running system:
```bash
$ lsmod | grep _rust
ax88796b_rust          16384  0
$ modinfo ax88796b_rust
filename:       /lib/modules/.../ax88796b_rust.ko
license:        GPL
description:    Rust Asix PHYs driver
author:         FUJITA Tomonori
# This module's init_module() was called by C kernel
```

## Architectural Significance

Understanding that C calls Rust reveals important architectural truths:

### 1. Bidirectional Integration

The integration is not purely "Rust wraps C":
```
Rust → C: For kernel services (most common)
C → Rust: For module lifecycle (critical integration point)
```

### 2. Standard ABI Compliance

Rust doesn't require a special loader or runtime. It complies with:
- Standard ELF module format
- Standard System V ABI
- Standard symbol conventions
- Standard linking process

### 3. Production-Grade Engineering

The `#[no_mangle]` + `extern "C"` pattern shows:
- Careful ABI design
- Clear separation of concerns
- Pragmatic integration approach
- No magic or special-casing

### 4. Evolution Path

The module lifecycle integration establishes:
- Proven mechanism for C→Rust calls
- Template for future expansion
- Trust in production environment
- Foundation for deeper integration

## Conclusion

**Yes, C kernel code calls Rust functions** - this is not theoretical but a production reality.

**Mechanism**: Standard ELF symbol binding and function pointers
- Rust generates C-compatible symbols via `#[no_mangle]` and `extern "C"`
- Linker resolves symbols and populates `struct module`
- C kernel calls through function pointers
- No runtime lookup, no special handling

**Scope**: Currently limited to module lifecycle
- ✅ Module initialization (`init_module`, `__<name>_init`)
- ✅ Module cleanup (`cleanup_module`, `__<name>_exit`)
- ❌ Not used for data processing or core services (yet)

**Evidence**:
- Source code in `rust/macros/module.rs` generates the functions
- C code in `kernel/module/main.c` calls the functions
- Real drivers (`rcpufreq_dt.ko`, `ax88796b_rust.ko`) rely on this mechanism
- Working Rust modules prove C must be calling Rust

**Future**: The infrastructure exists for expansion
- Callback registration
- Subsystem interfaces
- Utility functions

But for now (2022-2026 phase), the focus is on proving Rust's reliability in controlled scenarios before expanding the C→Rust interface.

**The key insight**: Rust in Linux is not just a consumer of C APIs - it's a cooperative participant where both languages call each other through well-defined, standard mechanisms.

---

# C如何调用Rust：Linux内核模块生命周期深度剖析

**摘要**：本文对C内核代码如何通过模块加载机制调用Rust函数进行全面技术分析。基于Linux内核6.x的实际源代码，本文揭示了完整的证据链：从Rust的#[no_mangle]属性到C的函数指针调用，从ELF符号绑定到实际调用流程。我们证明C→Rust调用不是理论而是通过标准模块生命周期管理实现的生产现实。

## 引言：问题

在关于Rust在Linux内核中的讨论中，经常出现一个基本的架构问题：

**"C内核代码能调用Rust函数吗？"**

这不仅仅是学术问题。理解C和Rust之间的调用方向对于理解以下内容至关重要：
- 集成架构
- ABI稳定性要求
- 未来演进可能性
- 安全和安全边界

许多人认为Rust只是封装C API（单向），使Rust纯粹是C服务的"消费者"。然而，**实际内核源代码揭示了不同的现实**：C确实会调用Rust函数，特别是用于模块生命周期管理。

本文基于Linux内核6.x源代码提供完整的证据链。

## 答案：是的，通过模块生命周期

**C内核代码确实调用Rust函数**用于：
- ✅ 模块初始化（`init_module()`、`__<name>_init()`）
- ✅ 模块清理（`cleanup_module()`、`__<name>_exit()`）

**C内核代码不调用Rust用于**：
- ❌ 数据处理或工具函数
- ❌ 核心子系统服务
- ❌ 通用API

范围**严格限制于模块生命周期管理**，但这是使所有Rust驱动工作的关键集成点。

## 证据1：Rust生成C兼容符号

每个Rust模块通过`module!`宏系列自动生成C可调用函数。这是`rust/macros/module.rs`中的实际代码：

```rust
// rust/macros/module.rs (260-290行)

// 对于可加载模块（.ko文件）
#[cfg(MODULE)]
#[doc(hidden)]
#[no_mangle]
#[link_section = ".init.text"]
pub unsafe extern "C" fn init_module() -> ::kernel::ffi::c_int {
    // 安全性：由于双层模块包装，此函数对外部不可访问。
    // C侧通过其唯一名称恰好调用一次。
    unsafe { __init() }
}

#[cfg(MODULE)]
#[doc(hidden)]
#[no_mangle]
#[link_section = ".exit.text"]
pub extern "C" fn cleanup_module() {
    // 安全性：
    // - 由于双层模块包装，此函数对外部不可访问。
    //   C侧通过其唯一名称恰好调用一次，
    // - 而且仅在`init_module`返回`0`后调用（委托给`__init`）。
    unsafe { __exit() }
}

// 对于内置模块（编译到内核中）
#[cfg(not(MODULE))]
#[doc(hidden)]
#[no_mangle]
pub extern "C" fn __<ident>_init() -> ::kernel::ffi::c_int {
    // 安全性：由于双层模块包装，此函数对外部不可访问。
    // C侧通过其在上述initcall段中的位置恰好调用一次。
    unsafe { __init() }
}

#[cfg(not(MODULE))]
#[doc(hidden)]
#[no_mangle]
pub extern "C" fn __<ident>_exit() {
    unsafe { __exit() }
}
```

### 关键机制解释

**1. `#[no_mangle]` 属性**

没有此属性，Rust会应用名称改编：
```
init_module → _ZN7mymodule11init_module17h<hash>E
```

使用`#[no_mangle]`，符号名保持为：
```
init_module → init_module
```

这使C代码能够通过其预期的标准名称找到函数。

**2. `extern "C"` 调用约定**

这确保：
- 参数按照C ABI传递（x86_64上的System V）
- 栈帧布局符合C预期
- 寄存器使用遵循C调用约定
- 没有Rust特定的调用开销

**3. `#[link_section = ".init.text"]`**

将函数放在ELF `.init.text`段中，C内核期望在此找到初始化代码。此段可在初始化完成后释放。

## 证据2：C内核的模块结构

C内核定义了一个标准模块结构，持有指向init函数的函数指针：

```c
// include/linux/module.h (第470行)
struct module {
    const char *name;

    // ... 省略许多字段 ...

    /* Startup function. */
    int (*init)(void);  // ← 指向init_module的函数指针

    struct module_memory mem[MOD_MEM_NUM_TYPES] __module_memory_align;

    // ... 更多字段 ...
};
```

`init`字段是一个**函数指针**，将在模块加载期间被调用。

## 证据3：C内核调用函数指针

加载模块时，C内核显式调用`mod->init`：

```c
// kernel/module/main.c (2989-3020行)
static noinline int do_init_module(struct module *mod)
{
    int ret = 0;
    struct mod_initfree *freeinit;

    // ... 省略设置代码 ...

    freeinit = kmalloc(sizeof(*freeinit), GFP_KERNEL);
    if (!freeinit) {
        ret = -ENOMEM;
        goto fail;
    }

    freeinit->init_text = mod->mem[MOD_INIT_TEXT].base;
    freeinit->init_data = mod->mem[MOD_INIT_DATA].base;
    freeinit->init_rodata = mod->mem[MOD_INIT_RODATA].base;

    do_mod_ctors(mod);

    /* Start the module */
    if (mod->init != NULL)
        ret = do_one_initcall(mod->init);  // ← 调用函数指针

    if (ret < 0) {
        goto fail_free_freeinit;
    }

    // ... 初始化后代码 ...

    mod->state = MODULE_STATE_LIVE;

    // ...
}
```

**关键观察**：`do_one_initcall(mod->init)`调用函数指针，对于Rust模块，它指向Rust的`init_module()`。

## 证据4：mod->init如何被设置

**关键问题**：`mod->init`如何指向Rust函数？

**答案**：通过链接时的ELF符号绑定，而非运行时查找。

### ELF模块结构布局

编译内核模块（C或Rust）时，链接器创建一个特殊段：

```
.gnu.linkonce.this_module
```

此段包含`struct module`的**完整二进制布局**，包括：
- 模块名
- 模块版本
- **Init函数指针**（已解析为`init_module`地址）
- 清理函数指针
- 其他元数据

### 模块加载过程

```c
// kernel/module/main.c (第2901行)
static struct module *layout_and_allocate(struct load_info *info, int flags)
{
    struct module *mod;
    // ... 布局计算 ...

    /* Module has been copied to its final place now: return it. */
    mod = (void *)info->sechdrs[info->index.mod].sh_addr;
    // ↑ 直接内存映射 - 模块结构体已经完整！

    kmemleak_load_module(mod, info);
    return mod;
}
```

内核**不会**手动分配每个字段。相反：
1. `.gnu.linkonce.this_module`段被映射到内存
2. 此段**就是**`struct module`
3. 所有字段，包括`init`，**已由链接器设置**

### 链接时符号解析

链接Rust模块时：

```bash
# 简化的链接过程
ld -r \
  -o rcpufreq_dt.ko \
  rcpufreq_dt.o \
  --build-id
```

链接器：
1. 找到`init_module`符号（地址0xXXXX）
2. 将此地址写入`module.init`字段
3. 将完整结构体嵌入`.gnu.linkonce.this_module`段
4. 将所有内容写入`.ko`文件

## 证据5：真实Rust驱动示例

每个Rust驱动都使用生成这些函数的宏。例如：

```rust
// drivers/cpufreq/rcpufreq_dt.rs (215-221行)
module_platform_driver! {
    type: CPUFreqDTDriver,
    name: "cpufreq-dt",
    author: "Viresh Kumar <viresh.kumar@linaro.org>",
    description: "Generic CPUFreq DT driver",
    license: "GPL v2",
}
```

此宏展开为：
```rust
// 生成的代码（概念）
#[no_mangle]
pub unsafe extern "C" fn init_module() -> i32 {
    // 注册CPUFreqDTDriver为平台驱动
    cpufreq::Registration::<CPUFreqDTDriver>::new_foreign_owned(/*...*/)
}

#[no_mangle]
pub extern "C" fn cleanup_module() {
    // 注销驱动
}
```

## 完整调用流程

让我们追踪加载Rust模块时发生的事情：

```
1. 用户执行：
   $ insmod rcpufreq_dt.ko

2. 内核系统调用：
   SYSCALL_DEFINE3(init_module, void __user *, umod, ...)
   ↓

3. 复制模块到内核内存：
   copy_module_from_user(umod, len, &info)
   ↓

4. 解析ELF并分配：
   mod = layout_and_allocate(&info, flags)
   ↓ (映射.gnu.linkonce.this_module段)

5. mod结构体现在完整：
   mod->init = &init_module  // ← 已由链接器设置
   mod->name = "cpufreq-dt"
   // ... 所有字段已填充 ...
   ↓

6. 调用初始化：
   do_init_module(mod)
   ↓

7. 调用函数指针：
   ret = do_one_initcall(mod->init)
   ↓ (通过函数指针调用)

8. 执行转移到RUST：
   Rust代码中的init_module()执行
   ↓

9. Rust驱动初始化：
   CPUFreqDTDriver::probe()注册驱动
   ↓

10. 模块已激活：
    mod->state = MODULE_STATE_LIVE
```

**关键洞察**：步骤7的C→Rust调用是通过函数指针的**标准间接函数调用**，与调用C模块的init函数完全相同。

## 符号命名约定

内核期望特定的符号名：

| 模块类型 | Init符号 | 清理符号 |
|----------|----------|----------|
| 可加载（.ko） | `init_module` | `cleanup_module` |
| 内置 | `__<name>_init` | `__<name>_exit` |

C和Rust模块都必须遵循此约定。

## 验证方法

如果您有已编译的Rust内核模块，可以直接验证此机制：

### 1. 检查符号表

```bash
$ nm drivers/cpufreq/rcpufreq_dt.ko | grep init_module
0000000000000000 T init_module
```

`T`表示`.text`段（代码）中的符号。地址`0000000000000000`相对于模块基址。

### 2. 检查ELF段

```bash
$ readelf -S drivers/cpufreq/rcpufreq_dt.ko | grep -E "\.init\.text|\.gnu\.linkonce"
  [12] .init.text        PROGBITS         0000000000000000  00001000
  [23] .gnu.linkonce.th  PROGBITS         0000000000000000  00003400
```

`.gnu.linkonce.this_module`段包含`struct module`。

### 3. 反汇编Init函数

```bash
$ objdump -d drivers/cpufreq/rcpufreq_dt.ko | grep -A20 "<init_module>:"
0000000000000000 <init_module>:
   0:   push   %rbx
   1:   mov    %rsp,%rbx
   4:   sub    $0x10,%rsp
   # ... 实际Rust代码 ...
```

这显示了`init_module`符号处编译的Rust代码。

## 反证：如果C不调用Rust会怎样？

如果C内核不调用Rust的`init_module()`，那么：

**预期失败**：
- ❌ `insmod rcpufreq_dt.ko`会失败
- ❌ 模块不会初始化
- ❌ 驱动不会向子系统注册
- ❌ 设备不会由驱动管理
- ❌ `lsmod`不会显示已加载的模块

**实际现实**：
- ✅ Rust模块成功加载
- ✅ 驱动初始化并注册
- ✅ 设备被正确管理
- ✅ `lsmod`显示模块

**结论**：C必定调用了Rust的`init_module()`，否则这些都不会工作。

## 为何限于模块生命周期？

当前设计将C→Rust调用限制于模块初始化和清理，因为：

### 1. 良好定义的接口

模块生命周期具有简单、稳定的签名：
```c
int (*init)(void);     // 无参数，返回错误码
void (*exit)(void);    // 无参数，无返回值
```

这种简单性意味着：
- 无需复杂的ABI协商
- 无需数据结构编组
- 无需跨边界生命周期管理
- 清晰的成功/失败语义

### 2. ABI稳定性

只有**入口点**需要稳定的ABI：
- `init_module`签名：永远固定
- 内部Rust代码：可以自由演进
- 无内部Rust API暴露给C

如果C依赖内部Rust API，这些API将需要永久的ABI稳定性。

### 3. 最小耦合

C内核核心不依赖Rust的功能：
- C内核可以加载C模块而无需Rust支持
- Rust支持纯粹是增量的
- 禁用Rust不会破坏核心内核

这保持了依赖图的清晰：
```
C内核核心（独立）
    ↓ (可以加载)
C模块（独立）
    ↓ (可以加载)
Rust模块（依赖C内核API）
```

### 4. 标准模块模式

C和Rust模块遵循**相同的加载机制**：
- 解析ELF
- 映射段
- 解析重定位
- 调用`mod->init()`

这种统一性意味着：
- Rust无需特殊处理代码
- 应用相同的安全检查
- 相同的调试工具有效
- 相同的性能特性

## 未来扩展可能性

虽然目前限于模块生命周期，C→Rust调用可能扩展：

### 1. 回调注册（2027-2028）

```rust
// 未来可能性
#[no_mangle]
pub extern "C" fn rust_timer_callback(data: *mut c_void) {
    // 安全的Rust定时器处理程序
}
```

```c
// C代码注册Rust回调
setup_timer(&timer, rust_timer_callback, data);
```

**挑战**：
- 生命周期管理（谁拥有数据？）
- 错误传播（panic处理）
- ABI稳定性（回调签名必须稳定）

### 2. 子系统接口（2028-2030）

如果核心子系统用Rust重写：

```rust
// 未来：Rust调度器接口
#[no_mangle]
pub extern "C" fn sched_yield_to(task: *mut task_struct) -> c_int {
    // 安全的调度器实现
}
```

```c
// C代码调用Rust调度器
ret = sched_yield_to(next_task);
```

**要求**：
- 在生产中证明稳定性
- 性能验证
- 渐进式迁移路径
- 回退到C实现

### 3. 工具函数（2026-2027）

```rust
// 未来：安全分配器
#[no_mangle]
pub extern "C" fn rust_safe_kmalloc(
    size: usize,
    flags: gfp_t
) -> *mut c_void {
    // 具有编译时检查的内存安全分配
}
```

**好处**：
- 渐进式安全改进
- 无需重写整个子系统
- 易于基准测试和验证

## 当前生产现实（2026）

截至Linux内核6.x，C→Rust调用是**生产现实**：

**活跃的Rust驱动**：
- `drivers/net/phy/ax88796b_rust.ko` - 网络PHY驱动
- `drivers/net/phy/qt2025.ko` - Marvell PHY驱动
- `drivers/cpufreq/rcpufreq_dt.ko` - CPU频率驱动
- `drivers/block/rnull.ko` - Null块设备
- `drivers/gpu/drm/nova/*.ko` - NVIDIA GPU驱动（13个模块）

**这些都是通过C调用Rust的`init_module()`加载的。**

您可以在运行的系统上验证：
```bash
$ lsmod | grep _rust
ax88796b_rust          16384  0
$ modinfo ax88796b_rust
filename:       /lib/modules/.../ax88796b_rust.ko
license:        GPL
description:    Rust Asix PHYs driver
author:         FUJITA Tomonori
# 此模块的init_module()由C内核调用
```

## 架构意义

理解C调用Rust揭示了重要的架构真相：

### 1. 双向集成

集成不是纯粹的"Rust封装C"：
```
Rust → C：用于内核服务（最常见）
C → Rust：用于模块生命周期（关键集成点）
```

### 2. 标准ABI合规

Rust不需要特殊加载器或运行时。它符合：
- 标准ELF模块格式
- 标准System V ABI
- 标准符号约定
- 标准链接过程

### 3. 生产级工程

`#[no_mangle]` + `extern "C"`模式显示：
- 精心的ABI设计
- 清晰的关注点分离
- 务实的集成方法
- 无魔法或特殊处理

### 4. 演进路径

模块生命周期集成建立了：
- 经过验证的C→Rust调用机制
- 未来扩展的模板
- 在生产环境中的信任
- 更深入集成的基础

## 结论

**是的，C内核代码调用Rust函数** - 这不是理论而是生产现实。

**机制**：标准ELF符号绑定和函数指针
- Rust通过`#[no_mangle]`和`extern "C"`生成C兼容符号
- 链接器解析符号并填充`struct module`
- C内核通过函数指针调用
- 无运行时查找，无特殊处理

**范围**：目前限于模块生命周期
- ✅ 模块初始化（`init_module`、`__<name>_init`）
- ✅ 模块清理（`cleanup_module`、`__<name>_exit`）
- ❌ 尚未用于数据处理或核心服务

**证据**：
- `rust/macros/module.rs`中的源代码生成函数
- `kernel/module/main.c`中的C代码调用函数
- 真实驱动（`rcpufreq_dt.ko`、`ax88796b_rust.ko`）依赖此机制
- 工作的Rust模块证明C必定调用Rust

**未来**：扩展基础设施已存在
- 回调注册
- 子系统接口
- 工具函数

但目前（2022-2026阶段），重点是在扩展C→Rust接口之前，在受控场景中证明Rust的可靠性。

**关键洞察**：Linux中的Rust不仅仅是C API的消费者 - 它是一个合作参与者，两种语言通过良好定义的标准机制相互调用。
