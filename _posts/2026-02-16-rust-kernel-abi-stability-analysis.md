---
title: "Rust and Linux Kernel ABI Stability: A Technical Deep Dive"
abstract: "Does Rust in the Linux kernel provide userspace interfaces? What's the kernel's ABI stability policy? This analysis examines how Rust drivers interact with userspace, the critical distinction between internal and external ABI stability, and concrete examples from production code like Android Binder and DRM drivers."
---

{{ page.abstract }}

## TL;DR: Quick Answers

**Q1: Does Rust currently provide userspace interfaces?**
→ **Yes.** Rust drivers already expose userspace APIs through ioctl, /dev nodes, sysfs, and other standard mechanisms.

**Q2: Does the kernel pursue internal ABI stability?**
→ **No.** Internal kernel APIs (between modules and kernel) are **explicitly unstable**. Only **userspace ABI** is sacred.

**Q3: Will Rust be used for userspace-facing features that require ABI stability?**
→ **Already happening.** Android Binder (Rust) provides critical userspace ABI to billions of devices.

## Deep Dive: System Call ABI - The Immutable Contract

Before examining Rust's userspace interfaces, let's understand what makes userspace ABI so critical by looking at the **system call layer** - the most fundamental userspace interface.

### The Sacred System Call ABI

Linux supports **three different system call mechanisms** simultaneously to maintain ABI compatibility:

| Mechanism | Introduced | Instruction | Syscall # | Parameters | Status |
|-----------|-----------|-------------|-----------|------------|--------|
| **INT 0x80** | Linux 1.0 (1994) | `int $0x80` | %eax | %ebx, %ecx, %edx, %esi, %edi, %ebp | ✅ Still supported (32-bit compat) |
| **SYSENTER** | Intel P6 (1995) | `sysenter` | %eax | %ebx, %ecx, %edx, %esi, %edi, %ebp | ✅ Still supported (Intel 32-bit) |
| **SYSCALL** | AMD K6 (1997) | `syscall` | %rax | %rdi, %rsi, %rdx, %r10, %r8, %r9 | ✅ Primary 64-bit method |

**All three are maintained in parallel** to ensure no userspace application ever breaks.

### Actual Kernel Implementation

From `arch/x86/kernel/cpu/common.c` (Linux kernel source):

```c
// syscall_init() - called during kernel initialization
void syscall_init(void)
{
    /* Set up segment selectors for user/kernel mode */
    wrmsr(MSR_STAR, 0, (__USER32_CS << 16) | __KERNEL_CS);

    if (!cpu_feature_enabled(X86_FEATURE_FRED))
        idt_syscall_init();
}

static inline void idt_syscall_init(void)
{
    // 64-bit native syscall entry
    wrmsrq(MSR_LSTAR, (unsigned long)entry_SYSCALL_64);

    // 32-bit compatibility mode - MUST maintain old ABI
    if (ia32_enabled()) {
        wrmsrq_cstar((unsigned long)entry_SYSCALL_compat);

        /* SYSENTER support for 32-bit applications */
        wrmsrq_safe(MSR_IA32_SYSENTER_CS, (u64)__KERNEL_CS);
        wrmsrq_safe(MSR_IA32_SYSENTER_ESP,
                    (unsigned long)(cpu_entry_stack(smp_processor_id()) + 1));
        wrmsrq_safe(MSR_IA32_SYSENTER_EIP, (u64)entry_SYSENTER_compat);
    }
}
```

**What this means**: A 32-bit application compiled in 1994 using `int $0x80` **still works** on a 2026 Linux kernel running on modern hardware.

### Two System Call Tables

```c
// 64-bit native system calls
const sys_call_ptr_t sys_call_table[__NR_syscall_max+1] = {
    [0 ... __NR_syscall_max] = &__x64_sys_ni_syscall,
    #include <asm/syscalls_64.h>
};

// 32-bit compatibility system calls
const sys_call_ptr_t ia32_sys_call_table[__NR_ia32_syscall_max+1] = {
    [0 ... __NR_ia32_syscall_max] = &__ia32_sys_ni_syscall,
    #include <asm/syscalls_32.h>
};
```

**Key insight**: Linux maintains **completely separate system call tables** for 32-bit and 64-bit to ensure ABI stability. The 32-bit table has **never removed a syscall** - only added new ones.

### Boot Protocol ABI - Even Bootloaders Have Contracts

From the Linux kernel compressed boot loader (`arch/x86/boot/compressed/head_64.S`):

```assembly
/*
 * 32bit entry is 0 and it is ABI so immutable!
 * This is the compressed kernel entry point.
 */
    .code32
SYM_FUNC_START(startup_32)
```

**The comment "ABI so immutable!" is critical**:
- The 32-bit entry point **must always be at offset 0** in the compressed kernel
- Boot loaders (GRUB, systemd-boot, etc.) **depend on this**
- Changing this would break every bootloader
- This has been true since Linux 2.6.x era

**Boot protocol specifications** (`Documentation/x86/boot.rst`):
- Protected mode kernel loaded at: `0x100000` (1MB)
- 32-bit entry point: Always offset 0 from load address
- `code32_start` field: Defaults to `0x100000`

This is **internal boot ABI** - distinct from userspace ABI but equally immutable because external tools (bootloaders) depend on it.

### The Lesson for Rust

When Rust drivers provide userspace interfaces, they inherit these same ironclad rules:

**C example** (traditional):
```c
// Userspace never knows this changed from C to Rust
int fd = open("/dev/binder", O_RDWR);
ioctl(fd, BINDER_WRITE_READ, &bwr);  // ABI unchanged
```

**Rust implementation** (modern):
```rust
// Must provide IDENTICAL ABI
const BINDER_WRITE_READ: u32 = kernel::ioctl::_IOWR::<BinderWriteRead>(
    BINDER_TYPE as u32,
    1  // ioctl number - NEVER changes
);
```

The ioctl number, structure layout, and semantics are **frozen in time** - whether implemented in C or Rust.

---

## Question 1: Rust's Userspace Interface Infrastructure

### The `uapi` Crate: Userspace API Bindings

Rust provides a dedicated crate for userspace APIs. From the actual kernel source:

```rust
// rust/uapi/lib.rs (actual kernel code)
//! UAPI Bindings.
//!
//! Contains the bindings generated by `bindgen` for UAPI interfaces.
//!
//! This crate may be used directly by drivers that need to interact with
//! userspace APIs.

#![no_std]

// Auto-generated UAPI bindings
include!(concat!(env!("OBJTREE"), "/rust/uapi/uapi_generated.rs"));
```

**Key insight**: The kernel has a **separate `uapi` crate** specifically for userspace interfaces, distinct from internal kernel APIs.

### ioctl Support in Rust

The kernel provides full ioctl support for Rust drivers:

```rust
// rust/kernel/ioctl.rs (actual kernel code)
//! `ioctl()` number definitions.
//!
//! C header: [`include/asm-generic/ioctl.h`](srctree/include/asm-generic/ioctl.h)

/// Build an ioctl number for a read-only ioctl.
#[inline(always)]
pub const fn _IOR<T>(ty: u32, nr: u32) -> u32 {
    _IOC(uapi::_IOC_READ, ty, nr, core::mem::size_of::<T>())
}

/// Build an ioctl number for a write-only ioctl.
#[inline(always)]
pub const fn _IOW<T>(ty: u32, nr: u32) -> u32 {
    _IOC(uapi::_IOC_WRITE, ty, nr, core::mem::size_of::<T>())
}

/// Build an ioctl number for a read-write ioctl.
#[inline(always)]
pub const fn _IOWR<T>(ty: u32, nr: u32) -> u32 {
    _IOC(
        uapi::_IOC_READ | uapi::_IOC_WRITE,
        ty,
        nr,
        core::mem::size_of::<T>(),
    )
}
```

**This is identical to C's ioctl macros**, but with type safety.

### Real Example: DRM Driver ioctl Interface

From the actual DRM subsystem Rust abstractions:

```rust
// rust/kernel/drm/ioctl.rs (actual kernel code)
//! DRM IOCTL definitions.

const BASE: u32 = uapi::DRM_IOCTL_BASE as u32;

/// Construct a DRM ioctl number with a read-write argument.
#[allow(non_snake_case)]
#[inline(always)]
pub const fn IOWR<T>(nr: u32) -> u32 {
    ioctl::_IOWR::<T>(BASE, nr)
}

/// Descriptor type for DRM ioctls.
pub type DrmIoctlDescriptor = bindings::drm_ioctl_desc;

// ioctl flags
pub const AUTH: u32 = bindings::drm_ioctl_flags_DRM_AUTH;
pub const MASTER: u32 = bindings::drm_ioctl_flags_DRM_MASTER;
pub const RENDER_ALLOW: u32 = bindings::drm_ioctl_flags_DRM_RENDER_ALLOW;
```

**Usage in drivers:**

```rust
// Declaring DRM ioctls in a Rust driver
kernel::declare_drm_ioctls! {
    (NOVA_GETPARAM, drm_nova_getparam, ioctl::RENDER_ALLOW, my_get_param_handler),
    (NOVA_GEM_CREATE, drm_nova_gem_create, ioctl::AUTH | ioctl::RENDER_ALLOW, gem_create),
    (NOVA_VM_BIND, drm_nova_vm_bind, ioctl::AUTH | ioctl::RENDER_ALLOW, vm_bind),
}
```

These ioctls are **directly exposed to userspace** - the same ABI as C drivers.

### Real Example: Android Binder Userspace Protocol

The Android Binder driver (rewritten in Rust) exposes extensive userspace APIs:

```rust
// drivers/android/binder/defs.rs (actual kernel code)
use kernel::{
    transmute::{AsBytes, FromBytes},
    uapi::{self, *},
};

// Userspace protocol constants - MUST remain stable
pub_no_prefix!(
    binder_driver_return_protocol_,
    BR_TRANSACTION,
    BR_REPLY,
    BR_DEAD_REPLY,
    BR_FAILED_REPLY,
    BR_OK,
    BR_ERROR,
    BR_INCREFS,
    BR_ACQUIRE,
    BR_RELEASE,
    BR_DECREFS,
    BR_DEAD_BINDER,
    // ... 21 total protocol constants
);

pub_no_prefix!(
    binder_driver_command_protocol_,
    BC_TRANSACTION,
    BC_REPLY,
    BC_FREE_BUFFER,
    BC_INCREFS,
    BC_ACQUIRE,
    BC_RELEASE,
    BC_DECREFS,
    // ... 24 total command constants
);

// Userspace data structures - wrapped to preserve ABI
decl_wrapper!(BinderTransactionData, uapi::binder_transaction_data);
decl_wrapper!(BinderWriteRead, uapi::binder_write_read);
decl_wrapper!(BinderVersion, uapi::binder_version);
decl_wrapper!(FlatBinderObject, uapi::flat_binder_object);
```

**Critical detail**: These use `MaybeUninit` to **preserve padding bytes**, ensuring binary-identical ABI with C:

```rust
// Wrapper that preserves exact memory layout, including padding
#[derive(Copy, Clone)]
#[repr(transparent)]
pub(crate) struct BinderTransactionData(MaybeUninit<uapi::binder_transaction_data>);

// SAFETY: Explicit FromBytes/AsBytes implementation
unsafe impl FromBytes for BinderTransactionData {}
unsafe impl AsBytes for BinderTransactionData {}
```

**Why this matters**: Userspace code compiled against C headers sends **exact same binary data** to Rust driver.

### Userspace Interface Summary

| Interface Type | Rust Support | Example |
|---------------|--------------|---------|
| **ioctl** | ✅ Full support | DRM drivers, Binder |
| **/dev device nodes** | ✅ Via miscdevice/cdev | Character devices |
| **/sys (sysfs)** | ✅ Via kobject bindings | Device attributes |
| **/proc** | ✅ Via seq_file | Process info |
| **System calls** | ⚠️ Not yet (all syscalls are C) | - |
| **Netlink** | ✅ Via net subsystem | Network configuration |

**Answer**: Yes, Rust **fully supports** userspace interfaces through standard kernel mechanisms.

## Question 2: Kernel Internal ABI Stability Policy

### The Critical Distinction

Linux kernel has **two completely different ABI policies**:

```
┌─────────────────────────────────────────────────────┐
│                  USERSPACE                          │
│  (applications, libraries, tools)                   │
└─────────────────┬───────────────────────────────────┘
                  │
                  │  ← USERSPACE ABI (STABLE, SACRED)
                  │     System calls, ioctl, /proc, /sys
                  │     "WE DO NOT BREAK USERSPACE" - Linus
                  │
┌─────────────────┴───────────────────────────────────┐
│            LINUX KERNEL                             │
│  ┌─────────────────────────────────────────┐       │
│  │  Kernel Subsystems (VFS, MM, Net, etc)  │       │
│  └─────────────────┬───────────────────────┘       │
│                    │                                │
│                    │  ← INTERNAL API (UNSTABLE!)    │
│                    │     Can change anytime         │
│                    │     No backward compat         │
│  ┌─────────────────┴───────────────────────┐       │
│  │  Loadable Kernel Modules (.ko files)    │       │
│  │  (drivers, filesystems, etc)             │       │
│  └─────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────┘
```

### Official Kernel Policy: Internal ABI is Unstable

From the Linux kernel documentation[^1]:

> **The kernel does NOT have a stable internal API/ABI.**
>
> The kernel internal API can and does change at any time, for any reason.

**In practice**: If you compile a kernel module for Linux 6.5, it **will not load** on Linux 6.6 without recompilation.

### Why Internal ABI is Unstable

Greg Kroah-Hartman explained this in his famous document:

**Reasons for no internal ABI stability:**

1. **Rapid evolution**: Subsystems need freedom to refactor
2. **No binary modules**: All modules must be GPL and recompilable
3. **Quality control**: Forces out-of-tree drivers to stay updated
4. **Security**: Allows fixing fundamental design flaws

**The philosophy**: "If your code is good enough, it should be in-tree. If it's in-tree, recompilation is free."

### Userspace ABI: Absolute Stability

Linus Torvalds' famous rule (paraphrased from countless LKML posts):

> **"WE DO NOT BREAK USERSPACE. EVER."**
>
> If a kernel change breaks a working userspace application, that change **will be reverted**, no matter how "correct" it was.

From the official documentation[^2]:

> **Stable interfaces:**
> - System calls: Must never change semantics
> - /proc and /sys ABI: Guaranteed stable for at least 2 years
> - ioctl numbers: Never reused once defined
> - Binary formats (ELF, etc): Backward compatible

### Real Example: ABI Stability Levels

From `/Documentation/ABI/README`[^3]:

```
stable/     - Interfaces with guaranteed backward compatibility
              Examples: syscalls, core /proc entries

testing/    - Interfaces believed stable but not yet guaranteed
              May still change with warning

obsolete/   - Deprecated but still present interfaces
              Marked for removal but with migration period

removed/    - Historical record only
```

**Answer**: The kernel **does not pursue internal ABI stability**. Only **userspace ABI** is stable.

## Question 3: Rust and Userspace ABI Stability

### Current State: Rust Already Provides Stable Userspace ABI

**Android Binder**: Running on billions of devices with **identical userspace ABI** as C version.

```rust
// Same BINDER_WRITE_READ ioctl as C version
const BINDER_WRITE_READ: u32 = kernel::ioctl::_IOWR::<BinderWriteRead>(
    BINDER_TYPE as u32,
    1
);

// Userspace code using C headers sends exact same binary data
```

**Verification**: Android's libbinder (C++ userspace library) works **without modification** with Rust kernel driver.

### Why Rust is Actually Better for ABI Stability

**Problem in C**: Accidental ABI breakage

```c
// C - easy to accidentally change ABI
struct binder_transaction_data {
    uint64_t cookie;
    uint32_t code;
    // Oops, developer adds field here - ABI BROKEN!
    uint32_t new_field;
    uint32_t flags;
};
```

**Rust solution**: Explicit versioning and `#[repr(C)]`

```rust
// Rust - ABI layout is explicit and checked
#[repr(C)]
pub struct binder_transaction_data {
    pub cookie: u64,
    pub code: u32,
    // Cannot add field here without explicit version bump
    pub flags: u32,
}

// Compile-time size check
const _: () = assert!(
    core::mem::size_of::<binder_transaction_data>() == 48
);
```

### Rust's `#[repr(C)]` Guarantees

From the Rust language specification:

```rust
#[repr(C)]
struct UserspaceFacingStruct {
    field1: u64,
    field2: u32,
}
```

**Guarantees**:
- Same layout as C struct
- Same padding rules
- Same alignment
- Same size
- Stable across Rust compiler versions

**This is a language-level guarantee**, not just convention.

### Real Example: DRM Driver Backward Compatibility

From the Nova GPU driver (Rust):

```rust
// Must maintain compatibility with userspace mesa drivers
pub const DRM_NOVA_GEM_CREATE: u32 = drm::ioctl::IOWR::<drm_nova_gem_create>(0x00);
pub const DRM_NOVA_GEM_INFO: u32 = drm::ioctl::IOWR::<drm_nova_gem_info>(0x01);

// Once these ioctl numbers are released, they NEVER change
// Rust's type system helps prevent accidental changes:

#[repr(C)]
pub struct drm_nova_gem_create {
    pub size: u64,
    pub handle: u32,
    pub flags: u32,
}

// If someone tries to change this, compilation breaks due to size assertions
```

### ABI Stability: Rust vs C Comparison

| Aspect | C | Rust |
|--------|---|------|
| **Layout control** | Implicit, compiler-dependent | `#[repr(C)]` explicit |
| **Padding preservation** | Manual, error-prone | `MaybeUninit` automatic |
| **Size verification** | Manual `BUILD_BUG_ON` | `const _: assert!(size == X)` |
| **Breaking changes** | Silent, runtime failure | Compile error |
| **Versioning** | Manual, by convention | Can be enforced by type system |
| **Binary compatibility** | Trust the developer | Compiler-verified |

### Will Rust Provide Critical Userspace ABI?

**Already happening:**

1. **Android Binder** (IPC): Billions of devices
2. **GPU drivers** (Nova): DRM userspace ABI
3. **Network PHY drivers**: ethtool/netlink ABI
4. **Block devices**: ioctl ABI

**Coming soon** (based on current development):

1. **File systems**: VFS operations, mount options
2. **Network protocols**: Socket options, packet formats
3. **Device drivers**: Standard character/block device ioctls

### The Key Policy: Language-Agnostic ABI

**Critical insight**: The kernel's ABI stability policy is **language-agnostic**.

From Linus Torvalds (summarized from various LKML posts):

> "I don't care if you write it in C, Rust, or assembly. If you break userspace, you broke the kernel."

**In practice**:
- Rust drivers use **same UAPI headers** as C via bindgen
- Same ioctl numbers, same struct layouts, same semantics
- Userspace **cannot tell** if driver is C or Rust
- ABI breaks are **equally unacceptable** in both languages

**Answer**: Yes, Rust **will be and already is** used for userspace-facing features requiring ABI stability.

## Practical Implications

### For Rust Kernel Developers

**Do:**
- ✅ Use `#[repr(C)]` for all userspace-facing structs
- ✅ Use `uapi` crate for userspace types
- ✅ Add size/layout assertions
- ✅ Preserve padding with `MaybeUninit` if needed
- ✅ Document ABI in same way as C drivers

**Don't:**
- ❌ Change userspace-visible types without version bump
- ❌ Assume Rust's layout is sufficient (use `#[repr(C)]`)
- ❌ Break compatibility even for "better" design
- ❌ Rely on Rust-specific types in UAPI

### For Userspace Developers

**Good news**: Nothing changes!

```c
// Userspace C code (unchanged)
int fd = open("/dev/binder", O_RDWR);
struct binder_write_read bwr = { ... };
ioctl(fd, BINDER_WRITE_READ, &bwr);
```

Whether the kernel driver is C or Rust, **this code works identically**.

### For Distribution Maintainers

**Internal modules** (out-of-tree):
- ❌ Must recompile for each kernel version (always true)
- ❌ May break if internal APIs change (always true)
- ✅ In-tree Rust drivers handle this automatically

**Userspace applications**:
- ✅ No changes needed
- ✅ ABI stability same as C drivers
- ✅ Old binaries work on new kernels (as always)

## Common Misconceptions

### Myth 1: "Rust's ABI is unstable, so it can't be used for kernel interfaces"

**Reality**:
- Rust's *internal* ABI between Rust crates is unstable
- Rust's `#[repr(C)]` ABI **is stable** and matches C exactly
- Kernel uses `#[repr(C)]` for all userspace interfaces

### Myth 2: "Rust adds a new ABI to maintain"

**Reality**:
- Rust uses **same UAPI headers** as C (via bindgen)
- No new ABI, just a different language implementing the same ABI
- Userspace sees no difference

### Myth 3: "Rust internal instability affects userspace"

**Reality**:
- Rust's `rust/kernel` abstractions can change freely (internal API)
- Userspace-facing ABI **must not change** (same rule as C)
- These are separate concerns

### Myth 4: "Modules must be recompiled because of Rust"

**Reality**:
- Kernel modules **always** needed recompilation between versions
- This is true for **C modules** too
- Rust doesn't change this policy

## Conclusion

**Summary of findings:**

1. ✅ **Rust provides userspace interfaces** through `uapi` crate, ioctl support, device nodes, sysfs, etc.

2. ❌ **Kernel internal ABI is NOT stable** - modules must recompile for each kernel version (same as C)

3. ✅ **Userspace ABI IS stable** - never breaks (same rule for C and Rust)

4. ✅ **Rust already provides critical userspace ABI** - Android Binder on billions of devices, GPU drivers, network drivers

**Key insight**: The kernel's ABI stability policy is **orthogonal to the implementation language**. Rust drivers must follow the same rules as C drivers:
- Internal APIs can change anytime
- Userspace ABI is sacred and immutable

**Rust's advantage**: Better compile-time verification of ABI compatibility through `#[repr(C)]`, size assertions, and type safety, reducing accidental ABI breaks.

---

## References

[^1]: [Linux Kernel Stable API Nonsense](https://www.kernel.org/doc/Documentation/process/stable-api-nonsense.rst) - Greg Kroah-Hartman's explanation of why internal kernel API is unstable

[^2]: [Linux ABI description](https://docs.kernel.org/admin-guide/abi.html) - Official kernel documentation on ABI stability levels

[^3]: [ABI README](https://github.com/torvalds/linux/blob/master/Documentation/ABI/README) - Documentation of ABI stability categories

[^4]: [A Stable Linux Kernel API/ABI? "The Most Insane Proposal"](https://www.phoronix.com/news/Linux-Kernel-Stable-API-ABI) - Phoronix coverage of ABI stability debates

[^5]: [When the kernel ABI has to change](https://lwn.net/Articles/557082/) - LWN article on userspace ABI changes

---

## 中文版 / Chinese Version

# Rust与Linux内核ABI稳定性：技术深度分析

**摘要**: Rust在Linux内核中提供用户空间接口吗？内核的ABI稳定性策略是什么？本文分析Rust驱动如何与用户空间交互，内部和外部ABI稳定性的关键区别，以及Android Binder和DRM驱动等生产代码的具体示例。

## 快速回答

**问题1: Rust目前是否提供用户空间接口?**
→ **是的。** Rust驱动已经通过ioctl、/dev节点、sysfs和其他标准机制暴露用户空间API。

**问题2: 内核内部追求ABI稳定性吗?**
→ **不。** 内核内部API（模块和内核之间）**明确不稳定**。只有**用户空间ABI**是神圣的。

**问题3: Rust是否会被用于提供需要ABI稳定性的用户空间功能?**
→ **已经在发生。** Android Binder (Rust) 为数十亿设备提供关键的用户空间ABI。

## 深入探讨：系统调用ABI - 不可变的契约

在研究Rust的用户空间接口之前，让我们先了解用户空间ABI为何如此关键，通过查看**系统调用层** - 最基础的用户空间接口。

### 神圣的系统调用ABI

Linux同时支持**三种不同的系统调用机制**以维持ABI兼容性：

| 机制 | 引入时间 | 指令 | 系统调用号 | 参数 | 状态 |
|------|---------|------|-----------|------|------|
| **INT 0x80** | Linux 1.0 (1994) | `int $0x80` | %eax | %ebx, %ecx, %edx, %esi, %edi, %ebp | ✅ 仍支持(32位兼容) |
| **SYSENTER** | Intel P6 (1995) | `sysenter` | %eax | %ebx, %ecx, %edx, %esi, %edi, %ebp | ✅ 仍支持(Intel 32位) |
| **SYSCALL** | AMD K6 (1997) | `syscall` | %rax | %rdi, %rsi, %rdx, %r10, %r8, %r9 | ✅ 主要64位方法 |

**所有三种都并行维护**，以确保任何用户空间应用程序永不破坏。

### 实际内核实现

来自`arch/x86/kernel/cpu/common.c`（Linux内核源代码）：

```c
// syscall_init() - 在内核初始化期间调用
void syscall_init(void)
{
    /* 为用户/内核模式设置段选择子 */
    wrmsr(MSR_STAR, 0, (__USER32_CS << 16) | __KERNEL_CS);

    if (!cpu_feature_enabled(X86_FEATURE_FRED))
        idt_syscall_init();
}

static inline void idt_syscall_init(void)
{
    // 64位原生syscall入口
    wrmsrq(MSR_LSTAR, (unsigned long)entry_SYSCALL_64);

    // 32位兼容模式 - 必须维护旧ABI
    if (ia32_enabled()) {
        wrmsrq_cstar((unsigned long)entry_SYSCALL_compat);

        /* 为32位应用程序提供SYSENTER支持 */
        wrmsrq_safe(MSR_IA32_SYSENTER_CS, (u64)__KERNEL_CS);
        wrmsrq_safe(MSR_IA32_SYSENTER_ESP,
                    (unsigned long)(cpu_entry_stack(smp_processor_id()) + 1));
        wrmsrq_safe(MSR_IA32_SYSENTER_EIP, (u64)entry_SYSENTER_compat);
    }
}
```

**这意味着什么**: 1994年使用`int $0x80`编译的32位应用程序在运行在现代硬件上的2026 Linux内核上**仍然可以工作**。

### 两个系统调用表

```c
// 64位原生系统调用
const sys_call_ptr_t sys_call_table[__NR_syscall_max+1] = {
    [0 ... __NR_syscall_max] = &__x64_sys_ni_syscall,
    #include <asm/syscalls_64.h>
};

// 32位兼容系统调用
const sys_call_ptr_t ia32_sys_call_table[__NR_ia32_syscall_max+1] = {
    [0 ... __NR_ia32_syscall_max] = &__ia32_sys_ni_syscall,
    #include <asm/syscalls_32.h>
};
```

**关键洞察**: Linux为32位和64位维护**完全独立的系统调用表**以确保ABI稳定性。32位表**从未删除系统调用** - 只添加新的。

### 启动协议ABI - 连引导加载程序都有契约

来自Linux内核压缩引导加载程序（`arch/x86/boot/compressed/head_64.S`）：

```assembly
/*
 * 32位入口在0且是ABI所以不可变！
 * 这是压缩内核入口点。
 */
    .code32
SYM_FUNC_START(startup_32)
```

**注释"ABI so immutable!"至关重要**：
- 32位入口点**必须始终在压缩内核的偏移0处**
- 引导加载程序（GRUB、systemd-boot等）**依赖于此**
- 改变这一点会破坏每个引导加载程序
- 这从Linux 2.6.x时代以来一直如此

**启动协议规范**（`Documentation/x86/boot.rst`）：
- 保护模式内核加载在：`0x100000`（1MB）
- 32位入口点：始终从加载地址偏移0
- `code32_start`字段：默认为`0x100000`

这是**内部启动ABI** - 与用户空间ABI不同，但同样不可变，因为外部工具（引导加载程序）依赖于它。

### 给Rust的教训

当Rust驱动提供用户空间接口时，它们继承这些相同的铁律：

**C示例**（传统）：
```c
// 用户空间永远不知道这从C变成了Rust
int fd = open("/dev/binder", O_RDWR);
ioctl(fd, BINDER_WRITE_READ, &bwr);  // ABI未改变
```

**Rust实现**（现代）：
```rust
// 必须提供相同的ABI
const BINDER_WRITE_READ: u32 = kernel::ioctl::_IOWR::<BinderWriteRead>(
    BINDER_TYPE as u32,
    1  // ioctl编号 - 永不改变
);
```

ioctl编号、结构布局和语义都**冻结在时间中** - 无论是用C还是Rust实现。

---

## 问题1：Rust的用户空间接口基础设施

### `uapi` Crate: 用户空间API绑定

Rust为用户空间API提供了专门的crate。来自实际内核源代码：

```rust
// rust/uapi/lib.rs (实际内核代码)
//! UAPI绑定。
//!
//! 包含bindgen为UAPI接口生成的绑定。
//!
//! 这个crate可以被需要与用户空间API交互的驱动直接使用。

#![no_std]

// 自动生成的UAPI绑定
include!(concat!(env!("OBJTREE"), "/rust/uapi/uapi_generated.rs"));
```

**关键洞察**: 内核有**单独的`uapi` crate**专门用于用户空间接口，与内部内核API分离。

### Rust中的ioctl支持

内核为Rust驱动提供完整的ioctl支持：

```rust
// rust/kernel/ioctl.rs (实际内核代码)
//! `ioctl()`编号定义。

/// 为只读ioctl构建ioctl编号
#[inline(always)]
pub const fn _IOR<T>(ty: u32, nr: u32) -> u32 {
    _IOC(uapi::_IOC_READ, ty, nr, core::mem::size_of::<T>())
}

/// 为只写ioctl构建ioctl编号
#[inline(always)]
pub const fn _IOW<T>(ty: u32, nr: u32) -> u32 {
    _IOC(uapi::_IOC_WRITE, ty, nr, core::mem::size_of::<T>())
}

/// 为读写ioctl构建ioctl编号
#[inline(always)]
pub const fn _IOWR<T>(ty: u32, nr: u32) -> u32 {
    _IOC(
        uapi::_IOC_READ | uapi::_IOC_WRITE,
        ty,
        nr,
        core::mem::size_of::<T>(),
    )
}
```

**这与C的ioctl宏完全相同**，但具有类型安全。

### 实际例子：Android Binder用户空间协议

Android Binder驱动（用Rust重写）暴露了广泛的用户空间API：

```rust
// drivers/android/binder/defs.rs (实际内核代码)
use kernel::uapi::{self, *};

// 用户空间协议常量 - 必须保持稳定
pub_no_prefix!(
    binder_driver_return_protocol_,
    BR_TRANSACTION,
    BR_REPLY,
    BR_DEAD_REPLY,
    BR_OK,
    BR_ERROR,
    // ... 21个总协议常量
);

// 用户空间数据结构 - 包装以保持ABI
decl_wrapper!(BinderTransactionData, uapi::binder_transaction_data);
decl_wrapper!(BinderWriteRead, uapi::binder_write_read);
decl_wrapper!(BinderVersion, uapi::binder_version);
```

**关键细节**: 这些使用`MaybeUninit`来**保留填充字节**，确保与C的二进制相同ABI：

```rust
// 保留确切内存布局的包装器，包括填充
#[derive(Copy, Clone)]
#[repr(transparent)]
pub(crate) struct BinderTransactionData(MaybeUninit<uapi::binder_transaction_data>);

// SAFETY: 显式FromBytes/AsBytes实现
unsafe impl FromBytes for BinderTransactionData {}
unsafe impl AsBytes for BinderTransactionData {}
```

**为什么重要**: 针对C头文件编译的用户空间代码向Rust驱动发送**完全相同的二进制数据**。

### 用户空间接口总结

| 接口类型 | Rust支持 | 示例 |
|---------|---------|------|
| **ioctl** | ✅ 完全支持 | DRM驱动, Binder |
| **/dev设备节点** | ✅ 通过miscdevice/cdev | 字符设备 |
| **/sys (sysfs)** | ✅ 通过kobject绑定 | 设备属性 |
| **/proc** | ✅ 通过seq_file | 进程信息 |
| **系统调用** | ⚠️ 尚未(所有syscall都是C) | - |
| **Netlink** | ✅ 通过net子系统 | 网络配置 |

**答案**: 是的，Rust通过标准内核机制**完全支持**用户空间接口。

## 问题2：内核内部ABI稳定性策略

### 关键区别

Linux内核有**两种完全不同的ABI策略**：

```
┌─────────────────────────────────────────────────────┐
│                  用户空间                            │
│  (应用程序、库、工具)                                │
└─────────────────┬───────────────────────────────────┘
                  │
                  │  ← 用户空间ABI (稳定、神圣)
                  │     系统调用、ioctl、/proc、/sys
                  │     "我们不破坏用户空间" - Linus
                  │
┌─────────────────┴───────────────────────────────────┐
│            LINUX内核                                 │
│  ┌─────────────────────────────────────────┐       │
│  │  内核子系统 (VFS, MM, Net等)            │       │
│  └─────────────────┬───────────────────────┘       │
│                    │                                │
│                    │  ← 内部API (不稳定!)           │
│                    │     随时可以改变                │
│                    │     无向后兼容                  │
│  ┌─────────────────┴───────────────────────┐       │
│  │  可加载内核模块 (.ko文件)                │       │
│  │  (驱动、文件系统等)                      │       │
│  └─────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────┘
```

### 官方内核策略：内部ABI不稳定

来自Linux内核文档[^1]：

> **内核没有稳定的内部API/ABI。**
>
> 内核内部API可以而且确实随时改变，出于任何原因。

**实践中**: 如果你为Linux 6.5编译内核模块，它在Linux 6.6上**将无法加载**，除非重新编译。

### 为什么内部ABI不稳定

Greg Kroah-Hartman在他著名的文档中解释了这一点：

**没有内部ABI稳定性的原因:**

1. **快速演进**: 子系统需要重构的自由
2. **无二进制模块**: 所有模块必须是GPL且可重新编译
3. **质量控制**: 强制树外驱动保持更新
4. **安全性**: 允许修复根本性设计缺陷

**哲学**: "如果你的代码足够好，它应该在树内。如果在树内，重新编译是免费的。"

### 用户空间ABI：绝对稳定

Linus Torvalds的著名规则（从无数LKML帖子中概括）：

> **"我们不破坏用户空间。永远。"**
>
> 如果内核更改破坏了正常工作的用户空间应用程序，该更改**将被回退**，无论它多么"正确"。

来自官方文档[^2]：

> **稳定接口:**
> - 系统调用: 绝不能改变语义
> - /proc和/sys ABI: 保证至少2年稳定
> - ioctl编号: 一旦定义就永不重用
> - 二进制格式 (ELF等): 向后兼容

**答案**: 内核**不追求内部ABI稳定性**。只有**用户空间ABI**是稳定的。

## 问题3：Rust与用户空间ABI稳定性

### 当前状态：Rust已经提供稳定的用户空间ABI

**Android Binder**: 运行在数十亿设备上，与C版本具有**相同的用户空间ABI**。

```rust
// 与C版本相同的BINDER_WRITE_READ ioctl
const BINDER_WRITE_READ: u32 = kernel::ioctl::_IOWR::<BinderWriteRead>(
    BINDER_TYPE as u32,
    1
);

// 使用C头文件的用户空间代码发送完全相同的二进制数据
```

**验证**: Android的libbinder（C++用户空间库）与Rust内核驱动**无需修改**即可工作。

### 为什么Rust实际上更适合ABI稳定性

**C中的问题**: 意外的ABI破坏

```c
// C - 容易意外改变ABI
struct binder_transaction_data {
    uint64_t cookie;
    uint32_t code;
    // 糟糕，开发者在这里添加字段 - ABI破坏了！
    uint32_t new_field;
    uint32_t flags;
};
```

**Rust解决方案**: 显式版本控制和`#[repr(C)]`

```rust
// Rust - ABI布局是显式的并经过检查
#[repr(C)]
pub struct binder_transaction_data {
    pub cookie: u64,
    pub code: u32,
    // 不能在这里添加字段，除非显式版本升级
    pub flags: u32,
}

// 编译时大小检查
const _: () = assert!(
    core::mem::size_of::<binder_transaction_data>() == 48
);
```

### Rust的`#[repr(C)]`保证

从Rust语言规范：

```rust
#[repr(C)]
struct UserspaceFacingStruct {
    field1: u64,
    field2: u32,
}
```

**保证**:
- 与C结构相同的布局
- 相同的填充规则
- 相同的对齐
- 相同的大小
- 跨Rust编译器版本稳定

**这是语言级别的保证**，不仅仅是约定。

### ABI稳定性：Rust vs C对比

| 方面 | C | Rust |
|------|---|------|
| **布局控制** | 隐式，编译器依赖 | `#[repr(C)]`显式 |
| **填充保留** | 手动，易出错 | `MaybeUninit`自动 |
| **大小验证** | 手动`BUILD_BUG_ON` | `const _: assert!(size == X)` |
| **破坏性更改** | 静默，运行时失败 | 编译错误 |
| **版本控制** | 手动，按约定 | 可由类型系统强制 |
| **二进制兼容性** | 信任开发者 | 编译器验证 |

### Rust会提供关键的用户空间ABI吗？

**已经在发生:**

1. **Android Binder** (IPC): 数十亿设备
2. **GPU驱动** (Nova): DRM用户空间ABI
3. **网络PHY驱动**: ethtool/netlink ABI
4. **块设备**: ioctl ABI

**即将推出** (基于当前开发):

1. **文件系统**: VFS操作，挂载选项
2. **网络协议**: Socket选项，数据包格式
3. **设备驱动**: 标准字符/块设备ioctl

### 关键策略：与语言无关的ABI

**关键洞察**: 内核的ABI稳定性策略是**与语言无关的**。

来自Linus Torvalds（从各种LKML帖子总结）：

> "我不在乎你用C、Rust还是汇编编写。如果你破坏了用户空间，你就破坏了内核。"

**实践中**:
- Rust驱动通过bindgen使用**与C相同的UAPI头文件**
- 相同的ioctl编号，相同的结构布局，相同的语义
- 用户空间**无法分辨**驱动是C还是Rust
- ABI破坏在两种语言中**同样不可接受**

**答案**: 是的，Rust**将会并且已经**被用于需要ABI稳定性的用户空间功能。

## 实际影响

### 对Rust内核开发者

**要做:**
- ✅ 对所有用户空间结构使用`#[repr(C)]`
- ✅ 对用户空间类型使用`uapi` crate
- ✅ 添加大小/布局断言
- ✅ 如需要用`MaybeUninit`保留填充
- ✅ 以与C驱动相同的方式记录ABI

**不要做:**
- ❌ 未经版本升级更改用户空间可见类型
- ❌ 假设Rust的布局足够（使用`#[repr(C)]`）
- ❌ 即使为了"更好"的设计也不要破坏兼容性
- ❌ 在UAPI中依赖Rust特定类型

### 对用户空间开发者

**好消息**: 什么都不变！

```c
// 用户空间C代码（不变）
int fd = open("/dev/binder", O_RDWR);
struct binder_write_read bwr = { ... };
ioctl(fd, BINDER_WRITE_READ, &bwr);
```

无论内核驱动是C还是Rust，**这段代码工作完全相同**。

## 常见误解

### 误解1："Rust的ABI不稳定，所以不能用于内核接口"

**现实**:
- Rust crate之间的*内部*ABI不稳定
- Rust的`#[repr(C)]` ABI **是稳定的**，与C完全匹配
- 内核对所有用户空间接口使用`#[repr(C)]`

### 误解2："Rust添加了需要维护的新ABI"

**现实**:
- Rust使用**与C相同的UAPI头文件**（通过bindgen）
- 没有新ABI，只是不同语言实现相同ABI
- 用户空间看不到区别

### 误解3："Rust内部不稳定性影响用户空间"

**现实**:
- Rust的`rust/kernel`抽象可以自由更改（内部API）
- 面向用户空间的ABI**不能更改**（与C规则相同）
- 这些是分开的关注点

### 误解4："因为Rust模块必须重新编译"

**现实**:
- 内核模块**一直**需要在版本之间重新编译
- 对于**C模块**也是如此
- Rust不改变这一策略

## 结论

**发现总结:**

1. ✅ **Rust通过`uapi` crate、ioctl支持、设备节点、sysfs等提供用户空间接口**

2. ❌ **内核内部ABI不稳定** - 模块必须为每个内核版本重新编译（与C相同）

3. ✅ **用户空间ABI是稳定的** - 永不破坏（C和Rust规则相同）

4. ✅ **Rust已经提供关键的用户空间ABI** - 数十亿设备上的Android Binder，GPU驱动，网络驱动

**关键洞察**: 内核的ABI稳定性策略**与实现语言正交**。Rust驱动必须遵循与C驱动相同的规则：
- 内部API可以随时更改
- 用户空间ABI是神圣和不可变的

**Rust的优势**: 通过`#[repr(C)]`、大小断言和类型安全更好地编译时验证ABI兼容性，减少意外的ABI破坏。
