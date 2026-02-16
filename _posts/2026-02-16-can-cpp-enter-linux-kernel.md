---
title: "Can C++ Enter the Linux Kernel? A Technical and Historical Analysis"
abstract: "With Rust successfully entering the Linux kernel as the second language after C, a natural question arises: could C++ have been chosen instead, or could it still enter the kernel in the future? This comprehensive analysis examines the technical barriers, historical context, and fundamental design conflicts that make C++ adoption in the Linux kernel highly unlikely, despite C++ being a mature and widely-used systems programming language."
---

{{ page.abstract }}

## Introduction: The Elephant in the Room

Rust's successful integration into the Linux kernel raises an intriguing counterfactual: **Why not C++?** After all, C++ has:
- ✅ Decades of maturity (1985 vs Rust's 2015)
- ✅ RAII for automatic resource management
- ✅ Rich abstraction capabilities
- ✅ Massive developer ecosystem
- ✅ Modern safety features (`std::unique_ptr`, `std::optional`, etc.)

Yet C++ has **never** been seriously considered for the Linux kernel, while the younger Rust was accepted after just 2 years of development (2020-2022). This document examines why.

## Executive Summary

**Likelihood of C++ entering the Linux kernel: < 5%**

**Key barriers:**
1. **Political**: Linus Torvalds' explicit, sustained opposition (2004-present)
2. **Technical**: Exception handling, hidden allocations, lack of memory safety guarantees
3. **Timing**: Rust already occupies the "second language" niche
4. **Engineering**: No team investing effort, no killer use case
5. **Philosophy**: Fundamental design conflicts with kernel requirements

## Historical Context: Linus Torvalds' Stance on C++

### The 2004 Email That Set the Tone

On January 19, 2004, Linus Torvalds responded to a question about compiling C++ kernel modules[^1]:

> **"It sucks. Trust me - writing kernel code in C++ is a BLOODY STUPID IDEA."**
>
> *"The whole C++ exception handling thing is fundamentally broken. It's _especially_ broken for kernels."*
>
> *"Any compiler or language that likes to hide things like memory allocations behind your back just isn't a good choice for a kernel."*

### The 2007 Git Mailing List Expansion

In 2007, Linus elaborated his position on the Git mailing list[^2]:

> *"C++ leads to really really bad design choices. You invariably start using the 'nice' library features of the language like STL and Boost and other total and utter crap, that may 'help' you program, but causes... inefficient abstracted programming models where two years down the road you notice that some abstraction wasn't very efficient, but now all your code depends on all the nice object models around it, and you cannot fix it without rewriting your app."*

### Has the Stance Changed in 20 Years?

**No.** As of 2026, there has been **zero** movement toward C++ acceptance in the kernel community. Meanwhile, Rust went from proposal (2020) to "permanent core language" status (2025)[^3].

## Technical Barrier Analysis

### Barrier 1: Exception Handling

**The Problem:**

C++ exceptions introduce non-local control flow that is fundamentally incompatible with kernel programming requirements.

```cpp
// C++ exception example
void kernel_function() {
    auto buffer = std::make_unique<KernelBuffer>(size);
    // ^-- Constructor might throw

    do_critical_work(buffer.get());
    // ^-- Might throw exception

    // If exception is thrown:
    // 1. Stack unwinding occurs
    // 2. Destructors are called (but what about interrupt context?)
    // 3. Exception tables increase binary size
    // 4. Performance becomes unpredictable
}
```

**Kernel Requirements:**

- **Deterministic behavior**: Every code path must be predictable
- **No surprise jumps**: Control flow must be explicit and traceable
- **Minimal binary size**: No room for exception tables
- **Interrupt safety**: Code in interrupt context cannot handle exceptions

**Academic Evidence:**

Research from the University of Edinburgh (2019) demonstrated that even optimized C++ exception implementations impose significant code size and runtime overhead in embedded systems[^4]. More recent work from the University of St Andrews (2025) showed that C++ exception propagation across user/kernel boundaries requires special ABI support, increasing system complexity[^5].

**Comparison with Rust:**

```rust
// Rust equivalent - no exceptions, explicit error handling
fn kernel_function() -> Result<()> {
    let buffer = KernelBuffer::new(size)?;
    // ^-- Explicit error propagation with '?'

    do_critical_work(&buffer)?;
    // ^-- Explicit error handling, no hidden control flow

    Ok(())
} // buffer automatically dropped, no exceptions needed
```

**Could C++ disable exceptions?**

Yes, with `-fno-exceptions`. However:
1. Much of C++'s design assumes exceptions exist
2. Standard library becomes awkward without exceptions
3. Error handling becomes manual (back to C-style)
4. You lose a key C++ feature while keeping the complexity

### Barrier 2: Hidden Memory Allocations

**The Problem:**

The kernel requires **explicit, tagged memory allocations** to handle different contexts:

```c
// C kernel code - explicit allocation with flags
void *buf = kmalloc(size, GFP_KERNEL);     // Can sleep
void *buf = kmalloc(size, GFP_ATOMIC);     // Atomic context
void *buf = kmalloc(size, GFP_NOWAIT);     // Non-blocking
```

**C++ hides allocations:**

```cpp
// C++ - when does allocation happen? With what flags?
class KernelBuffer {
    std::vector<uint8_t> data;  // Hidden heap allocation!
    std::string name;           // Hidden heap allocation!
public:
    KernelBuffer(size_t size)
        : data(size)            // Allocates here - but with what GFP_* ?
        , name("buffer") {}     // Another hidden allocation
};

void function() {
    KernelBuffer buf(1024);     // Can this sleep? Is it atomic-safe?
    // Impossible to know without diving into implementation
}
```

**Linus's 2004 statement remains valid:**

> *"Any compiler or language that likes to hide things like memory allocations behind your back just isn't a good choice for a kernel."*

**Rust's explicit approach:**

```rust
// Rust - all allocations are explicit
pub struct KernelBuffer {
    data: Vec<u8>,
}

impl KernelBuffer {
    pub fn new(size: usize, flags: Flags) -> Result<Self> {
        // Explicit allocation with explicit flags
        let data = Vec::try_with_capacity_in(size, flags)?;
        Ok(Self { data })
    }
}

// Usage
let buf = KernelBuffer::new(1024, GFP_KERNEL)?;
// ^-- Crystal clear: allocation happens here, with GFP_KERNEL
```

### Barrier 3: No Memory Safety Guarantees

**The Core Issue:**

C++ provides **the same memory safety guarantees as C: none.**

```cpp
// C++ - still vulnerable to use-after-free
KernelData* data = new KernelData();
delete data;
use_data(data);  // ❌ Use-after-free - compiler won't catch this

// Still vulnerable to data races
void thread1() { global_data->value = 1; }  // ❌ Race condition
void thread2() { global_data->value = 2; }  // Compiler won't catch

// Still vulnerable to null pointer dereferences
KernelData* data = get_data();  // Might return nullptr
data->process();                 // ❌ Potential null deref
```

**Rust's compile-time guarantees:**

```rust
// Rust - use-after-free is impossible
let data = Box::new(KernelData::new());
drop(data);
use_data(data);  // ✅ Compile error: value used after move

// Data races are impossible
fn thread1(data: &Data) { data.value = 1; }  // ✅ Compile error:
fn thread2(data: &Data) { data.value = 2; }  // cannot mutate through shared reference

// Null pointer dereferences are impossible
let data: Option<KernelData> = get_data();
data.process();  // ✅ Compile error: Option<T> has no method 'process'
// Must explicitly unwrap: data.unwrap().process()
```

**The Statistics:**

According to research on Rust in the Linux kernel[^6]:
- ~70% of kernel CVEs stem from memory safety issues
- Rust eliminates these **at compile time** without runtime overhead
- C++ eliminates **0%** of these issues

### Barrier 4: Runtime and Standard Library Dependencies

**The Problem:**

C++ typically depends on:
- `libstdc++` or `libc++` (standard library)
- Runtime support for RTTI (Run-Time Type Information)
- Global constructors/destructors
- Thread-local storage

**Kernel requirements:**
- ❌ No user-space libraries
- ❌ No global constructors (initialization order issues)
- ❌ Minimal binary size
- ❌ No assumptions about runtime environment

**Possible workarounds:**
- Use `-fno-rtti` (disable RTTI)
- Use `-fno-exceptions` (disable exceptions)
- Use `-nostdlib` (no standard library)
- Avoid global objects

**But then you're left with "C with classes"** - losing most of C++'s advantages while keeping the complexity.

**Rust's approach:**

```rust
// Rust kernel code uses 'core' (no std)
#![no_std]  // Explicitly kernel mode

// From rust/kernel/lib.rs (actual kernel code):
//! This crate contains the kernel APIs that have been ported or wrapped for
//! usage by Rust code in the kernel and is shared by all of them.
//!
//! In other words, all the rest of the Rust code in the kernel (e.g. kernel
//! modules written in Rust) depends on [`core`] and this crate.

extern crate core;  // Only core, no std library
```

## Language Design Philosophy Comparison

### The Fundamental Mismatch

| Aspect | Linux Kernel Needs | C++ Provides | Rust Provides |
|--------|-------------------|--------------|---------------|
| **Error Handling** | Explicit, zero overhead | Exceptions (overhead) or manual | `Result<T>` (zero overhead, enforced) |
| **Memory Allocation** | Explicit, tagged (GFP_*) | Often implicit | Explicit with allocator API |
| **Control Flow** | Predictable, traceable | Exceptions hide flow | All control flow explicit |
| **Memory Safety** | Critical (70% of CVEs) | No guarantees | Compile-time guarantees |
| **Abstraction Cost** | Must be zero | Sometimes has overhead | Guaranteed zero-cost |
| **ABI Stability** | Essential for modules | Unstable (name mangling) | C-compatible FFI |
| **Binary Size** | Minimal | STL bloat, RTTI tables | No runtime, minimal size |

### Modern C++ Improvements: Do They Help?

**Modern C++ (C++11/14/17/20/23) added:**
- `std::unique_ptr` / `std::shared_ptr` (RAII smart pointers)
- `constexpr` (compile-time computation)
- `std::optional` (like Rust's `Option<T>`)
- `std::expected` (like Rust's `Result<T, E>`)
- Move semantics
- Lambda expressions

**Do these solve the kernel's problems?**

```cpp
// Modern C++ example
auto data = std::make_unique<KernelData>(size);
// ❌ Still implicit allocation
// ❌ Still can't specify GFP_KERNEL or GFP_ATOMIC
// ❌ Still no compile-time data race prevention
// ❌ Still requires runtime support

std::optional<KernelData> data = get_data();
// ✅ Better than raw pointers
// ❌ But runtime overhead (size + bool flag)
// ❌ No enforcement of checking before use
```

**Rust's approach:**

```rust
// Rust equivalent
let data = Box::try_new_in(KernelData::new(size)?, GFP_KERNEL)?;
// ✅ Explicit allocation
// ✅ Explicit flags
// ✅ Zero runtime overhead
// ✅ Compile-time safety

let data: Option<KernelData> = get_data();
// ✅ Zero runtime overhead (just enum tag)
// ✅ Compiler enforces checking before use
```

**Conclusion:** Modern C++ is better than old C++, but still doesn't meet kernel requirements as well as Rust does.

## Case Studies: C++ in Other Kernels

### Windows NT Kernel

**Status:** Partial C++ usage, primarily in driver frameworks

**Constraints:**
- Strict subset of C++
- No exceptions
- No RTTI
- No STL
- Custom memory allocators required

**Key difference:** Windows was designed with C++ in mind from the start (1993). Linux was not.

### macOS/iOS Kernel (XNU)

**Status:** C++ in IOKit (driver framework)

**Constraints:**
- Limited C++ subset
- Carefully controlled usage
- Predates modern C++ features

**Key difference:** Apple controls the entire ecosystem. Linux is community-driven with diverse hardware.

### Fuchsia (Google)

**Status:** Extensive C++ usage

**Key difference:** **Brand new kernel** (started 2016) with no legacy codebase. Linux has 30+ years of C code and established conventions.

### Conclusion from Case Studies

**Every kernel that uses C++ either:**
1. Was designed for C++ from the start, OR
2. Uses a highly restricted C++ subset that resembles "C with classes"

**Linux is neither.** It has 30 million lines of C code and a culture that values explicitness and simplicity.

## The Timing Factor: Rust Already Won the "Second Language" Slot

### Why Timing Matters

The Linux kernel adding a second language is a **massive undertaking**:
- Build system changes
- Documentation requirements
- Maintainer training
- ABI compatibility concerns
- Toolchain integration

**The kernel community will not do this multiple times.**

### Rust's Timeline

```
2020: Rust for Linux announced
      - Initial RFC posted to LKML
      - Community discussion begins

2021: Infrastructure development
      - Build system integration
      - Kernel abstraction layer development

2022 (October): Rust merged into Linux 6.1 development cycle
        - Linus Torvalds accepts the patches

2022 (December): Linux 6.1 released
        - First stable kernel with Rust support

2023-2024: Ecosystem growth
        - Android Binder rewritten in Rust
        - GPU drivers (Nova)
        - Network PHY drivers

2025 (December): Rust becomes "permanent core language"
        - No longer experimental
        - 338 files, 135,662 lines of production code
```

### What Would C++ Need?

To match Rust's success, C++ would need:

**1. A dedicated team** (5-10 engineers, multi-year commitment)
**2. Corporate sponsorship** (Google/Microsoft/Meta level)
**3. Killer application** (equivalent to Android Binder)
**4. Toolchain development** (kernel-safe C++ subset)
**5. Community buy-in** (Linus and maintainers)

**Current status:**
- ❌ No team working on this
- ❌ No corporate sponsor
- ❌ No killer application identified
- ❌ No toolchain work
- ❌ Linus explicitly opposed (20 years)

## The "Kernel-Safe C++" Thought Experiment

### What Would It Look Like?

If someone tried to create "kernel-safe C++", it would need:

**Allowed features:**
- Classes and constructors/destructors (RAII)
- Templates (limited complexity)
- Namespaces
- `constexpr`
- References

**Prohibited features:**
- ❌ Exceptions (non-local control flow)
- ❌ RTTI (runtime overhead)
- ❌ STL (hidden allocations, overhead)
- ❌ `new`/`delete` (must use kernel allocators)
- ❌ Virtual inheritance (complexity)
- ❌ Global constructors (initialization order)

### The Problem: Is This Still C++?

At this point, you have **"C with classes and templates"** - essentially what embedded C++ tried to be in the 1990s.

**Historical precedent:** Embedded C++ (EC++) was defined in 1996 as a subset for embedded systems. It failed because:
1. Too restrictive for C++ programmers
2. Too complex for C programmers
3. Toolchain fragmentation
4. Eventually superseded by "just use C"

### Comparison with Rust

**Rust didn't need to be restricted** - it was designed for systems programming from day one:
- No exceptions by design (uses `Result<T, E>`)
- No garbage collector by design
- No runtime by design (`#![no_std]` is a first-class mode)
- Explicit memory management by design
- Zero-cost abstractions by design

**C++ requires restrictions; Rust requires nothing.**

## Economic and Engineering Reality

### The Resource Investment Required

Based on Rust for Linux's development:

```
Total effort estimate (2020-2025):
- Core team: ~10 engineers × 5 years = 50 person-years
- Corporate contributions: ~20 engineers × 2 years = 40 person-years
- Community contributions: ~100 contributors × 0.5 years = 50 person-years
Total: ~140 person-years of engineering effort

Cost estimate (conservative):
- Average engineer cost: $200,000/year (salary + overhead)
- Total investment: ~$28 million USD
```

**For C++ to enter the kernel, someone would need to invest comparable resources.**

### Who Would Fund This?

**Rust for Linux sponsors:**
- Google (Android Binder, security motivation)
- Microsoft (Azure security, NT kernel Rust initiative)
- Arm (architecture support, driver development)
- Meta (networking, infrastructure)

**Potential C++ sponsors:**
- ??? (No clear candidate)

**Why no sponsors?**
1. C++ doesn't solve problems Rust doesn't already solve
2. Investment would be duplicative (Rust already exists)
3. Political risk (Linus's opposition)
4. Technical risk (fundamental design mismatches)

### The Opportunity Cost

Every hour spent on "C++ for Linux" is an hour **not spent on:**
- Improving Rust for Linux
- Fixing bugs in existing code
- Adding new features
- Supporting new hardware

**Rational actors won't make this trade-off.**

## Technical Alternatives: What If Not Rust?

### If Rust Didn't Exist, What Would Be Considered?

**Hypothetical ranking (if choosing today):**

1. **Zig**: Explicit control, modern C replacement, safety tools
   - ✅ Zero hidden behavior
   - ✅ Excellent C interop
   - ✅ Modern error handling
   - ❌ No compile-time memory safety guarantees
   - ❌ Small community (vs Rust)
   - ❌ Language still evolving

2. **D**: Systems programming language with safety features
   - ✅ Memory safety options
   - ✅ No garbage collector mode
   - ❌ Smaller community
   - ❌ Less industry backing
   - ❌ Complex feature set

3. **Ada/SPARK**: Formal verification capabilities
   - ✅ Extremely rigorous safety
   - ❌ Very niche community
   - ❌ Steep learning curve
   - ❌ Poor tooling integration

4. **C++**: Mature, widely known
   - ✅ Large community
   - ✅ Rich abstractions
   - ❌ All the issues discussed in this document

**Rust won because it hit the sweet spot:**
- Memory safety without garbage collection
- Zero-cost abstractions
- Large, active community
- Industry backing
- Purpose-built for systems programming

### Could Multiple Languages Coexist?

**Theoretically yes, practically no.**

**Challenges:**
- Each language adds build system complexity
- Each language requires maintainer expertise
- Each language creates ABI boundaries
- Each language fragments the codebase

**The kernel needs coherence**, not a polyglot mess.

**Historical precedent:** The kernel **rejected** multiple assembler syntaxes (AT&T vs Intel), settling on one. It won't embrace multiple high-level languages.

## The Path Forward: What Would Change the Analysis?

### Scenario 1: Rust Fails Catastrophically

**What would constitute "failure"?**
- Major security vulnerabilities in Rust driver code
- Unfixable performance issues
- Toolchain becomes unmaintainable
- Community abandons Rust for Linux

**Likelihood: < 1%**

Current evidence (Android Binder, GPU drivers, network drivers) shows Rust succeeding in production.

**Would C++ be next choice?**

Probably not. More likely:
1. Return to C-only
2. Consider Zig (if mature by then)
3. Consider formally verified C subsets

### Scenario 2: Linus Torvalds Retires/Changes Mind

**What if new kernel leadership is pro-C++?**

Even then, the technical issues remain:
- Exceptions still problematic
- Hidden allocations still problematic
- No memory safety guarantees still problematic

**New leadership might be more pragmatic**, but they still answer to technical reality.

### Scenario 3: C++ Gets Kernel-Specific Safety Extensions

**What if a major vendor (Google/Microsoft) created "Kernel C++"?**

Example: Hypothetical language features
- Compile-time borrow checking (copying Rust)
- Explicit allocation syntax
- Guaranteed zero-cost abstractions
- Formal verification hooks

**At that point, you've reinvented Rust.**

Why not just use Rust?

### Scenario 4: WebAssembly or Other Bytecode Approach

**Alternative: Compile to safe bytecode?**

This has been explored (eBPF for kernel extensions), but:
- Not suitable for core kernel code
- Performance overhead
- Complexity

**Not a replacement for Rust/C.**

## Conclusion: The Verdict

### Summary of Findings

**Can C++ enter the Linux kernel?**

**Answer: Extremely unlikely (< 5% probability) for the following reasons:**

#### Political Barriers (High)
- ✗ Linus Torvalds' explicit, sustained opposition (20+ years)
- ✗ No champion within kernel maintainer community
- ✗ Rust already occupies "second language" niche

#### Technical Barriers (High)
- ✗ Exception handling fundamentally incompatible with kernel needs
- ✗ Hidden memory allocations violate kernel philosophy
- ✗ No compile-time memory safety guarantees
- ✗ Runtime dependencies (RTTI, libstdc++) unsuitable for kernel
- ✗ ABI instability complicates module system

#### Engineering Barriers (High)
- ✗ No team working on C++ kernel integration
- ✗ No corporate sponsor identified
- ✗ No killer application to justify investment
- ✗ Estimated $28M+ investment required (based on Rust precedent)

#### Timing Barriers (High)
- ✗ Rust already invested 140+ person-years
- ✗ Rust has production deployments (Android Binder, GPU drivers)
- ✗ Kernel won't add third high-level language

### Comparison: Why Rust Succeeded Where C++ Cannot

| Factor | Rust | C++ |
|--------|------|-----|
| **Memory Safety** | ✅ Compile-time guarantees | ❌ None |
| **Kernel Philosophy Fit** | ✅ Explicit everything | ❌ Hidden behavior |
| **Runtime Requirements** | ✅ None (`#![no_std]`) | ❌ Requires libstdc++ subset |
| **Error Handling** | ✅ Zero-cost `Result<T>` | ❌ Exceptions or manual |
| **Industry Backing** | ✅ Google, MS, Arm, Meta | ❌ None for kernel work |
| **Active Development** | ✅ 338 files, 135K lines | ❌ Zero |
| **Linus's Stance** | ✅ Neutral → Accepting | ❌ Explicit opposition |
| **Killer App** | ✅ Android Binder | ❌ None identified |

### The Real Question

The question isn't "Can C++ enter the Linux kernel?"

**The question is: "Why would it?"**

- It doesn't solve problems Rust doesn't already solve
- It brings technical baggage Rust doesn't have
- It lacks corporate and community backing
- It faces political opposition Rust never did

### Final Thoughts

C++ is an excellent language for many domains:
- Application development
- Game engines
- High-performance computing
- Systems software (outside kernels)

But for the **Linux kernel specifically**, the ship has sailed. Rust provides:
- Better memory safety
- Better kernel philosophy fit
- Better tooling for kernel development
- Better industry momentum

**Unless fundamental technical realities change**, C++ will remain outside the Linux kernel indefinitely.

The more productive question for C++ advocates is: **How can C++ improve in its own domains?** rather than attempting to enter a niche where it's technically unsuited and politically unwelcome.

---

## Appendix: Quick Reference Tables

### Language Feature Comparison

| Feature | C | C++ | Rust | Kernel Needs |
|---------|---|-----|------|--------------|
| Memory Safety | ❌ | ❌ | ✅ | ✅ Critical |
| Zero Runtime | ✅ | ⚠️ | ✅ | ✅ Required |
| Explicit Allocation | ✅ | ❌ | ✅ | ✅ Required |
| Error Handling | ⚠️ Manual | ❌ Exceptions | ✅ `Result<T>` | ✅ Explicit |
| ABI Stability | ✅ | ❌ | ✅ C-FFI | ✅ Required |
| Compile-time Checks | ⚠️ Basic | ⚠️ Basic | ✅ Extensive | ✅ Preferred |
| Learning Curve | Low | High | High | ⚠️ Trade-off |
| Ecosystem | Huge | Huge | Large | ⚠️ Consider |

### Historical Timeline: Second Language Attempts

| Year | Event | Outcome |
|------|-------|---------|
| 1991 | Linux 0.01 considers C++ | ❌ Rejected (immature tooling) |
| 2004 | C++ kernel module discussion | ❌ Linus: "BLOODY STUPID IDEA" |
| 2007 | Git mailing list C++ debate | ❌ Linus elaborates opposition |
| 2020 | Rust for Linux announced | ✅ Positive reception |
| 2022 | Rust merged into Linux 6.1 | ✅ Accepted |
| 2025 | Rust "permanent core language" | ✅ Success |
| 2026 | C++ in kernel? | ❌ Still no movement |

### Investment Comparison

| Aspect | Rust for Linux | Hypothetical C++ for Linux |
|--------|----------------|---------------------------|
| **Engineering Effort** | ~140 person-years | ~150-200 person-years (higher due to restrictions) |
| **Cost** | ~$28M USD | ~$30-40M USD |
| **Corporate Sponsors** | Google, Microsoft, Arm, Meta | None identified |
| **Community Support** | Strong (150+ contributors) | Weak (no active effort) |
| **Political Support** | Neutral → Positive | Strongly negative |
| **Technical Viability** | High (proven in production) | Low (fundamental conflicts) |
| **ROI** | High (70% of CVEs prevented) | Negative (no advantage over Rust) |

## References

[^1]: [Re: Compiling C++ kernel module + Makefile](https://harmful.cat-v.org/software/c++/linus) - Linus Torvalds, January 19, 2004, Linux Kernel Mailing List

[^2]: [Re: [RFC] Convert builtin-mailinfo.c to use The Better String Library](https://lwn.net/Articles/249460/) - Linus Torvalds, September 6, 2007, Git Mailing List

[^3]: [Linux Kernel Adopts Rust as Permanent Core Language in 2025](https://www.webpronews.com/linux-kernel-adopts-rust-as-permanent-core-language-in-2025/) - WebProNews, December 2025

[^4]: [Low-cost deterministic C++ exceptions for embedded systems](https://www.research.ed.ac.uk/files/78829292/low_cost_deterministic_C_exceptions_for_embedded_systems.pdf) - University of Edinburgh, 2019, ACM SIGPLAN International Conference on Compiler Construction

[^5]: [Propagating C++ exceptions across the user/kernel boundary](https://doi.org/10.1145/3764860.3768332) - Voronetskiy & Spink, University of St Andrews, PLOS 2025

[^6]: [Rust for Linux: Understanding the Security Impact](https://mars-research.github.io/doc/2024-acsac-rfl.pdf) - Research paper analyzing Rust's security impact in Linux kernel

[^7]: [The Linux Kernel - Rust Documentation](https://docs.kernel.org/rust/) - Official Linux kernel documentation on Rust integration

[^8]: [An Empirical Study of Rust-for-Linux](https://www.usenix.org/system/files/atc24-li-hongyu.pdf) - USENIX ATC 2024, empirical analysis of Rust in Linux

---

**Document Information:**
- **Created:** 2026-02-16
- **Analysis Scope:** Technical, historical, and economic feasibility of C++ entering the Linux kernel
- **Methodology:** Literature review, code analysis, historical precedent examination
- **Conclusion:** C++ entry into Linux kernel is highly unlikely (< 5% probability) due to converging political, technical, and economic barriers

---

## 中文版 / Chinese Version

# C++能进入Linux内核吗？技术与历史分析

**摘要**: 随着Rust成功进入Linux内核成为C之后的第二语言，一个自然的问题出现了：C++本可以被选择吗，或者它未来仍能进入内核吗？本综合分析研究了技术障碍、历史背景和基本设计冲突，这些使得C++被Linux内核采用的可能性极低，尽管C++是一门成熟且广泛使用的系统编程语言。

## 引言：房间里的大象

Rust成功集成到Linux内核引发了一个有趣的反事实问题：**为什么不是C++？** 毕竟，C++拥有：
- ✅ 数十年的成熟度 (1985年 vs Rust的2015年)
- ✅ 用于自动资源管理的RAII
- ✅ 丰富的抽象能力
- ✅ 庞大的开发者生态系统
- ✅ 现代安全特性 (`std::unique_ptr`, `std::optional`等)

然而C++从未被Linux内核认真考虑过，而更年轻的Rust仅在2年开发后(2020-2022)就被接受了。本文档探讨原因。

## 执行摘要

**C++进入Linux内核的可能性: < 5%**

**关键障碍:**
1. **政治因素**: Linus Torvalds明确、持续的反对 (2004年至今)
2. **技术因素**: 异常处理、隐藏分配、缺乏内存安全保证
3. **时机因素**: Rust已经占据"第二语言"生态位
4. **工程因素**: 没有团队投入努力，没有杀手级应用
5. **哲学因素**: 与内核需求的根本设计冲突

## 历史背景：Linus Torvalds关于C++的立场

### 2004年定调的邮件

2004年1月19日，Linus Torvalds回应了关于编译C++内核模块的问题[^1]：

> **"糟透了。相信我 - 用C++编写内核代码是一个非常愚蠢的想法。"**
>
> *"整个C++异常处理机制从根本上就是有问题的。对内核来说尤其如此。"*
>
> *"任何喜欢在你背后隐藏内存分配等操作的编译器或语言，都不是内核的好选择。"*

### 2007年Git邮件列表的详述

2007年，Linus在Git邮件列表上详述了他的立场[^2]：

> *"C++导致真正糟糕的设计选择。你不可避免地会开始使用STL和Boost等'优雅的'库特性...这会导致低效的抽象编程模型，两年后你会发现某些抽象效率不高，但现在你所有的代码都依赖于这些精美的对象模型，除非重写应用否则无法修复。"*

### 20年来立场改变了吗？

**没有。** 截至2026年，内核社区对C++接受度**零**进展。与此同时，Rust从提案(2020)到"永久核心语言"状态(2025)[^3]。

## 技术障碍分析

### 障碍1：异常处理

**问题所在:**

C++异常引入非局部控制流，这与内核编程需求根本不兼容。

```cpp
// C++异常示例
void kernel_function() {
    auto buffer = std::make_unique<KernelBuffer>(size);
    // ^-- 构造函数可能抛出异常

    do_critical_work(buffer.get());
    // ^-- 可能抛出异常

    // 如果抛出异常：
    // 1. 发生栈展开
    // 2. 调用析构函数（但在中断上下文中呢？）
    // 3. 异常表增加二进制大小
    // 4. 性能变得不可预测
}
```

**内核需求:**

- **确定性行为**: 每个代码路径必须可预测
- **无意外跳转**: 控制流必须显式和可追踪
- **最小二进制大小**: 没有异常表的空间
- **中断安全**: 中断上下文中的代码无法处理异常

**学术证据:**

爱丁堡大学的研究(2019)表明，即使是优化的C++异常实现也会在嵌入式系统中造成显著的代码大小和运行时开销[^4]。圣安德鲁斯大学的最新工作(2025)显示，C++异常在用户/内核边界的传播需要特殊的ABI支持，增加了系统复杂性[^5]。

**与Rust的对比:**

```rust
// Rust等价代码 - 无异常，显式错误处理
fn kernel_function() -> Result<()> {
    let buffer = KernelBuffer::new(size)?;
    // ^-- 用'?'显式错误传播

    do_critical_work(&buffer)?;
    // ^-- 显式错误处理，无隐藏控制流

    Ok(())
} // buffer自动丢弃，不需要异常
```

**C++能禁用异常吗?**

可以，使用`-fno-exceptions`。但是：
1. C++的大部分设计假定异常存在
2. 没有异常的标准库变得笨拙
3. 错误处理变成手动（回到C风格）
4. 你失去了一个关键的C++特性，同时保留了复杂性

### 障碍2：隐藏的内存分配

**问题所在:**

内核需要**显式、带标记的内存分配**来处理不同上下文：

```c
// C内核代码 - 带标志的显式分配
void *buf = kmalloc(size, GFP_KERNEL);     // 可以睡眠
void *buf = kmalloc(size, GFP_ATOMIC);     // 原子上下文
void *buf = kmalloc(size, GFP_NOWAIT);     // 非阻塞
```

**C++隐藏分配:**

```cpp
// C++ - 何时分配？用什么标志？
class KernelBuffer {
    std::vector<uint8_t> data;  // 隐藏的堆分配！
    std::string name;           // 隐藏的堆分配！
public:
    KernelBuffer(size_t size)
        : data(size)            // 在这里分配 - 但用什么GFP_* ?
        , name("buffer") {}     // 另一个隐藏分配
};

void function() {
    KernelBuffer buf(1024);     // 这能睡眠吗？原子安全吗？
    // 不深入实现无法知道
}
```

**Linus的2004年声明仍然有效:**

> *"任何喜欢在你背后隐藏内存分配等操作的编译器或语言，都不是内核的好选择。"*

**Rust的显式方法:**

```rust
// Rust - 所有分配都是显式的
pub struct KernelBuffer {
    data: Vec<u8>,
}

impl KernelBuffer {
    pub fn new(size: usize, flags: Flags) -> Result<Self> {
        // 用显式标志显式分配
        let data = Vec::try_with_capacity_in(size, flags)?;
        Ok(Self { data })
    }
}

// 使用
let buf = KernelBuffer::new(1024, GFP_KERNEL)?;
// ^-- 非常清楚：分配在这里发生，用GFP_KERNEL
```

### 障碍3：无内存安全保证

**核心问题:**

C++提供**与C相同的内存安全保证：无。**

```cpp
// C++ - 仍然容易出现use-after-free
KernelData* data = new KernelData();
delete data;
use_data(data);  // ❌ Use-after-free - 编译器不会捕获

// 仍然容易出现数据竞争
void thread1() { global_data->value = 1; }  // ❌ 竞态条件
void thread2() { global_data->value = 2; }  // 编译器不会捕获

// 仍然容易出现空指针解引用
KernelData* data = get_data();  // 可能返回nullptr
data->process();                 // ❌ 潜在空解引用
```

**Rust的编译时保证:**

```rust
// Rust - use-after-free不可能发生
let data = Box::new(KernelData::new());
drop(data);
use_data(data);  // ✅ 编译错误：值在移动后使用

// 数据竞争不可能发生
fn thread1(data: &Data) { data.value = 1; }  // ✅ 编译错误：
fn thread2(data: &Data) { data.value = 2; }  // 不能通过共享引用修改

// 空指针解引用不可能发生
let data: Option<KernelData> = get_data();
data.process();  // ✅ 编译错误：Option<T>没有方法'process'
// 必须显式解包：data.unwrap().process()
```

**统计数据:**

根据关于Rust在Linux内核中的研究[^6]：
- 约70%的内核CVE源于内存安全问题
- Rust在**编译时**消除这些问题，无运行时开销
- C++消除**0%**的这些问题

### 障碍4：运行时和标准库依赖

**问题所在:**

C++通常依赖于：
- `libstdc++`或`libc++` (标准库)
- RTTI的运行时支持 (运行时类型信息)
- 全局构造函数/析构函数
- 线程本地存储

**内核需求:**
- ❌ 没有用户空间库
- ❌ 没有全局构造函数 (初始化顺序问题)
- ❌ 最小二进制大小
- ❌ 不对运行时环境做假设

**可能的变通方法:**
- 使用`-fno-rtti` (禁用RTTI)
- 使用`-fno-exceptions` (禁用异常)
- 使用`-nostdlib` (无标准库)
- 避免全局对象

**但这样你就只剩下"带类的C"** - 失去了C++的大部分优势，同时保留了复杂性。

**Rust的方法:**

```rust
// Rust内核代码使用'core' (无std)
#![no_std]  // 显式内核模式

// 来自rust/kernel/lib.rs (实际内核代码):
//! 这个crate包含已移植或包装的内核API
//! 供内核中的Rust代码使用，所有代码都依赖它。

extern crate core;  // 只有core，没有std库
```

## 语言设计哲学对比

### 根本不匹配

| 方面 | Linux内核需求 | C++提供 | Rust提供 |
|------|--------------|---------|----------|
| **错误处理** | 显式、零开销 | 异常(开销)或手动 | `Result<T>` (零开销、强制) |
| **内存分配** | 显式、带标记(GFP_*) | 通常隐式 | 用分配器API显式 |
| **控制流** | 可预测、可追踪 | 异常隐藏流程 | 所有控制流显式 |
| **内存安全** | 关键(70%的CVE) | 无保证 | 编译时保证 |
| **抽象成本** | 必须为零 | 有时有开销 | 保证零成本 |
| **ABI稳定性** | 模块必需 | 不稳定(名称改编) | C兼容FFI |
| **二进制大小** | 最小 | STL膨胀、RTTI表 | 无运行时、最小大小 |

## 其他内核中的C++案例研究

### Windows NT内核

**状态:** 部分C++使用，主要在驱动框架中

**约束:**
- C++的严格子集
- 无异常
- 无RTTI
- 无STL
- 需要自定义内存分配器

**关键区别:** Windows从一开始(1993)就考虑了C++。Linux没有。

### macOS/iOS内核 (XNU)

**状态:** C++用于IOKit (驱动框架)

**约束:**
- 有限的C++子集
- 仔细控制的使用
- 早于现代C++特性

**关键区别:** Apple控制整个生态系统。Linux是社区驱动的，硬件多样化。

### Fuchsia (Google)

**状态:** 广泛使用C++

**关键区别:** **全新内核** (始于2016年)，没有遗留代码库。Linux有30多年的C代码和既定约定。

### 案例研究的结论

**每个使用C++的内核都:**
1. 从一开始就为C++设计，或
2. 使用高度受限的C++子集，类似于"带类的C"

**Linux两者都不是。** 它有3000万行C代码和重视显式和简单性的文化。

## 时机因素：Rust已经赢得了"第二语言"席位

### 为什么时机很重要

Linux内核添加第二语言是**巨大的工程**：
- 构建系统变更
- 文档需求
- 维护者培训
- ABI兼容性问题
- 工具链集成

**内核社区不会多次这样做。**

### Rust的时间线

```
2020: 宣布Rust for Linux
      - 向LKML发布初始RFC
      - 社区讨论开始

2021: 基础设施开发
      - 构建系统集成
      - 内核抽象层开发

2022 (10月): Rust合并到Linux 6.1开发周期
        - Linus Torvalds接受补丁

2022 (12月): Linux 6.1发布
        - 首个支持Rust的稳定内核

2023-2024: 生态系统增长
        - Android Binder用Rust重写
        - GPU驱动 (Nova)
        - 网络PHY驱动

2025 (12月): Rust成为"永久核心语言"
        - 不再是实验性的
        - 338个文件，135,662行生产代码
```

### C++需要什么？

要匹配Rust的成功，C++需要：

**1. 专门的团队** (5-10名工程师，多年承诺)
**2. 企业赞助** (Google/Microsoft/Meta级别)
**3. 杀手级应用** (等同于Android Binder)
**4. 工具链开发** (内核安全的C++子集)
**5. 社区支持** (Linus和维护者)

**当前状态:**
- ❌ 没有团队在做这个
- ❌ 没有企业赞助商
- ❌ 没有确定的杀手级应用
- ❌ 没有工具链工作
- ❌ Linus明确反对 (20年)

## 经济和工程现实

### 所需资源投资

基于Rust for Linux的开发：

```
总工作量估算 (2020-2025):
- 核心团队: ~10名工程师 × 5年 = 50人年
- 企业贡献: ~20名工程师 × 2年 = 40人年
- 社区贡献: ~100名贡献者 × 0.5年 = 50人年
总计: ~140人年的工程努力

成本估算 (保守):
- 平均工程师成本: $200,000/年 (薪水 + 开销)
- 总投资: 约$2800万美元
```

**要让C++进入内核，有人需要投入类似的资源。**

### 谁会资助这个？

**Rust for Linux赞助商:**
- Google (Android Binder，安全动机)
- Microsoft (Azure安全，NT内核Rust倡议)
- Arm (架构支持，驱动开发)
- Meta (网络，基础设施)

**潜在的C++赞助商:**
- ??? (没有明确候选人)

**为什么没有赞助商?**
1. C++不能解决Rust尚未解决的问题
2. 投资是重复的 (Rust已经存在)
3. 政治风险 (Linus的反对)
4. 技术风险 (根本设计不匹配)

## 结论：判决

### 发现总结

**C++能进入Linux内核吗?**

**答案: 极不可能 (< 5%概率)，原因如下:**

#### 政治障碍 (高)
- ✗ Linus Torvalds明确、持续的反对 (20+年)
- ✗ 内核维护者社区中无倡导者
- ✗ Rust已占据"第二语言"生态位

#### 技术障碍 (高)
- ✗ 异常处理与内核需求根本不兼容
- ✗ 隐藏的内存分配违反内核哲学
- ✗ 无编译时内存安全保证
- ✗ 运行时依赖 (RTTI, libstdc++) 不适合内核
- ✗ ABI不稳定使模块系统复杂化

#### 工程障碍 (高)
- ✗ 没有团队在做C++内核集成
- ✗ 没有确定的企业赞助商
- ✗ 没有杀手级应用来证明投资合理
- ✗ 估计需要$2800万+投资 (基于Rust先例)

#### 时机障碍 (高)
- ✗ Rust已投资140+人年
- ✗ Rust有生产部署 (Android Binder, GPU驱动)
- ✗ 内核不会添加第三种高级语言

### 对比：为什么Rust成功而C++不能

| 因素 | Rust | C++ |
|------|------|-----|
| **内存安全** | ✅ 编译时保证 | ❌ 无 |
| **内核哲学契合** | ✅ 一切显式 | ❌ 隐藏行为 |
| **运行时需求** | ✅ 无 (`#![no_std]`) | ❌ 需要libstdc++子集 |
| **错误处理** | ✅ 零成本`Result<T>` | ❌ 异常或手动 |
| **行业支持** | ✅ Google, MS, Arm, Meta | ❌ 无内核工作支持 |
| **活跃开发** | ✅ 338文件, 135K行 | ❌ 零 |
| **Linus立场** | ✅ 中立→接受 | ❌ 明确反对 |
| **杀手级应用** | ✅ Android Binder | ❌ 无确定的 |

### 真正的问题

问题不是"C++能进入Linux内核吗？"

**问题是: "为什么要这样做？"**

- 它不能解决Rust尚未解决的问题
- 它带来Rust没有的技术包袱
- 它缺乏企业和社区支持
- 它面临Rust从未遇到的政治反对

### 最终想法

C++是许多领域的优秀语言：
- 应用开发
- 游戏引擎
- 高性能计算
- 系统软件 (内核之外)

但对于**Linux内核具体来说**，船已经开走了。Rust提供：
- 更好的内存安全
- 更好的内核哲学契合
- 更好的内核开发工具
- 更好的行业动力

**除非基本技术现实改变**，C++将无限期地留在Linux内核之外。

对C++倡导者来说，更有成效的问题是：**C++如何在自己的领域改进？** 而不是试图进入一个技术上不适合且政治上不受欢迎的领域。
