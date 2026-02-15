---
title: "为什么Linux内核选择了Rust而不是Zig？"
abstract: "当Linux内核在2022年宣布支持Rust作为第二语言时，系统编程社区引发了热烈的讨论。本文深入分析了Linux内核选择Rust而非Zig的核心原因，包括时机、语言特性差异、社区生态等多个维度，并探讨了两种语言在系统编程领域的不同定位。"
---

# {{ page.title }}

{{ page.abstract }}

## 引言

在众多现代系统编程语言中，为什么是Rust获得了Linux内核"第二语言"的席位，而同样优秀的Zig却未能入选？这个问题的答案，远比表面看起来要复杂得多。

最直接的原因可以概括为：**当内核在2022年底正式引入Rust时，Zig还没准备好；而当Zig逐渐成熟时，内核的"第二语言"席位已经被Rust占据**。

这背后是工程决策、语言特性和社区生态共同作用的结果。

## 核心原因分析

### ⏳ 时机与行业背书

在2019-2020年内核讨论引入第二语言时，Zig（2015年诞生）还处于早期，而Rust背后有**Mozilla、微软、谷歌**等巨头的投入，并在Linux 6.1版本中正式被采纳[^1]。到2025年12月，Rust已正式从"实验性"状态转为Linux内核的核心组成部分[^2]。

### 🔧 语言特性的根本差异

Rust和Zig的设计哲学存在本质差异，这决定了它们与内核需求的匹配度。

**Rust：激进的安全卫士**

核心目标是在**编译期消除内存错误**。它通过**所有权、生命周期**等机制，在编译阶段就堵死空指针、数据竞争等漏洞，这直击了内核安全最核心的痛点。研究表明，约70%的内核安全问题源于内存安全，而Rust可以自动消除其中的大部分[^3]。宏和RAII特性也被驱动开发者视为处理复杂硬件逻辑的利器。

**Zig：现代的C语言替代者**

旨在成为C的现代升级版，强调**对底层操作的完全掌控**和**"零隐式行为"**[^4]。它没有Rust那样复杂的编译器，依靠**显式的错误处理**和**编译期执行**来提升C的安全性。但对于内核开发者，这意味着需要**手动管理资源**，并可能面临段错误。

### 🌍 社区与生态的门槛

对Linux这样的超大规模项目，生态是关键。Rust拥有庞大的用户群和库，这为内核的长期维护和人才储备提供了保障[^8]。相比之下，Zig在2015年才诞生，其生态系统和开发者社区规模相对较小，语言本身也仍在快速演进中，这在一定程度上增加了项目采纳的风险。

## 💡 Zig的现状与角色

尽管没能成为内核的"第二语言"，Zig在Linux生态中正找到一个独特的切入点。Zig凭借其出色的**交叉编译能力**和**精细的内存控制**，正成为优化系统工具和基础设施的有力选择[^5]。其内置的构建系统和工具链，即使在传统的C/C++项目中也展现出显著的优势。

## 深入理解：什么是RAII？

在讨论Rust的优势时，RAII是一个绕不开的话题。

RAII是**R**esource **A**cquisition **I**s **I**nitialization（资源获取即初始化）的缩写。它在C++中普及，并被Rust等语言继承和发展，是管理内存、文件句柄、锁等系统资源的核心范式。

核心思想是：**将资源的生命周期，与对象的生命周期严格绑定**。

### 工作原理

简单来说，RAII通过构造函数和析构函数这对"钩子"，实现了资源的自动管理：

- **获取（初始化时）**：当你创建一个对象时，它的构造函数会自动获取资源（如分配内存、打开文件）
- **释放（销毁时）**：当对象离开作用域被销毁时，它的析构函数会自动释放资源

这确保了资源绝不会泄漏，即使发生异常，只要对象被销毁，析构函数就一定会被调用，实现**异常安全**。

**Rust中的自动释放机制**

Rust通过`Drop` trait实现析构函数[^6]。当变量离开作用域时，Rust编译器会自动调用该类型的`drop`方法。以自旋锁为例：

```rust
// 简化的SpinLockGuard实现
impl<'a, T> Drop for SpinLockGuard<'a, T> {
    fn drop(&mut self) {
        // 当guard被销毁时，这个方法会自动调用
        self.lock.unlock(); // 释放锁
    }
}
```

关键机制包括：

1. **作用域规则**：变量在离开其作用域（通常由花括号`{}`界定）时被销毁[^7]
2. **自动调用**：编译器在编译时就确定在哪里插入`drop()`调用，这是零成本抽象
3. **异常安全**：即使发生`panic`或提前返回，`drop`也会被调用，确保资源释放

```rust
{
    let mut guard = spinlock.lock(); // 获取锁

    if error_condition {
        return; // 提前返回
        // guard在此离开作用域，drop被自动调用，锁被释放
    }

    do_something(&mut guard)?; // 如果出错
    // guard在此离开作用域，drop被自动调用，锁被释放

} // 正常情况下，guard在此离开作用域，锁被释放
```

这就是为什么说"开发者无法忘记解锁" - 不是靠记忆力或代码审查，而是**编译器强制保证**的。

### 在内核开发中的价值

对于Linux内核这样的底层系统，RAII的价值巨大。传统C语言使用`goto`语句集中处理错误，容易遗漏。而RAII可以彻底解决这个痛点。

以Rust代码为例，它展示了如何安全地管理一个内核自旋锁：

```rust
// 解锁动作被自动"绑定"到了guard对象上
let mut guard = spinlock.lock(); // `lock()`获取锁，返回一个guard对象
do_something(&mut guard);         // 通过guard访问数据
// guard在此处被销毁，锁被自动释放
```

开发者无法忘记解锁，即使在`do_something`中发生错误，锁也会被正确释放。这对于构建高可靠的驱动和内核模块至关重要。

### Rust的RAII与所有权

相比C++，Rust将RAII提升到了语言核心位置。通过**所有权（Ownership）**机制，Rust强制要求每个资源有唯一的所有者。当所有者离开作用域，资源被自动释放，从根本上杜绝了悬空指针和重复释放的问题。

### Zig的资源管理方式

Zig采取了不同的设计哲学。虽然Zig提供了`defer`关键字来简化资源清理（类似Go），但它强调"零隐式行为"[^4]，资源释放需要开发者显式编写，由编译器在编译期验证控制流：

```zig
const file = try std.fs.cwd().openFile("file.txt", .{});
defer file.close(); // 必须显式写defer
```

这种方式给了开发者最大的控制权和可预测性，但在规模庞大、错误路径复杂的Linux内核中，需要人工确保每个分支都正确处理资源释放，审查负担相对较大。

相比之下，Rust的RAII通过类型系统和编译器强制保证资源释放，提供了"自动、安全、无法遗忘"的资源管理能力，更符合内核对安全性的极致要求。

## 深入理解：Zig相比C的实质性提升

有人可能会认为"Zig相比C提升不大"，这个说法**并不准确**。如果Zig相比C提升不大，它不会在系统编程社区获得越来越多的关注。

更准确的表述是：**Zig在"显式控制"路径上做到了极致，而Rust在"安全抽象"路径上做到了极致**。两者都远超C，只是方向不同。

### 1. 编译期执行（Comptime）

这是Zig最革命性的特性，C完全没有：

```zig
// 泛型数据结构 - C需要void*或宏，极其别扭
fn List(comptime T: type) type {
    return struct {
        items: []T,
        len: usize,
    };
}

// 使用
var int_list = List(i32){};
var string_list = List([]u8){};
```

在C语言中，这要么用宏写出难以调试的代码，要么用`void*`牺牲类型安全。

### 2. 真正的错误处理

C的错误处理靠返回值+`errno`，极易被忽略：

```c
// C - 容易忘记检查返回值
FILE *f = fopen("file.txt", "r");
fread(buf, 1, size, f);  // 如果fopen失败？崩溃！
```

```zig
// Zig - 错误必须处理
const file = try std.fs.cwd().openFile("file.txt", .{});
// 如果openFile失败，try会向上传播错误，不会默默继续
defer file.close();
```

Zig通过语言机制强制处理错误，但又不像Java的异常那样有运行时开销。

### 3. 真正的无未定义行为

C语言充满了未定义行为：有符号整数溢出、空指针解引用、缓冲区溢出等。编译器会基于"未定义行为不会发生"做激进优化，导致隐蔽的bug。

Zig定义了所有操作的语义：
- 有符号整数溢出是**明确定义的wrapping行为**（或可以通过`@addWithOverflow`检查）
- 数组访问有**边界检查**（release快速模式下可关闭）
- 整数转换是**显式的**，不会隐式截断

### 4. 交叉编译是一等公民

C的交叉编译是噩梦：需要配置工具链、头文件路径、库路径等。

```bash
# Zig - 直接指定目标
zig build-exe --target riscv64-linux-gnu myapp.zig
# 无需安装任何东西，Zig内置了目标平台的libc
```

### 5. 构建系统内置，告别make

```zig
// build.zig - 这是Zig代码，不是DSL
const exe = b.addExecutable("myapp", "src/main.zig");
exe.linkLibC();
exe.addIncludePath("/usr/include");
```

C语言从诞生至今都没有语言层面的标准构建系统，依然依赖于`make`、`cmake`、`autotools`等第三方工具。

### 为什么说"提升不大"的错觉存在？

这种印象主要来自**内存安全**这个最受关注的维度：

| 方面 | C | Zig | Rust |
|-----|-----|-----|------|
| 内存安全 | ❌ 全靠人工 | ⚠️ 更好的工具（可选检查、显式控制） | ✅ 编译器强制保证 |
| 错误处理 | ❌ 易忽略 | ✅ 语言级强制 | ✅ 语言级强制 |
| 泛型编程 | ⚠️ 宏/`void*` | ✅ comptime | ✅ 泛型+trait |
| 元编程 | ⚠️ 宏预处理器 | ✅ comptime | ✅ 宏 |
| 学习曲线 | 低 | 中等 | 高 |
| 对现有C代码 | - | ✅ 良好兼容 | ⚠️ 需要FFI绑定 |

**关键区别**：Rust说"我替你管，你别操心"，Zig说"我给你最好的工具，你来管"。

### Linux内核场景的结论

回到最初的问题：Linux内核为什么没选Zig？

不是Zig不够好，而是**内核的需求更匹配Rust的安全哲学**：

1. **内核的代价不同**：用户态程序的内存漏洞可能导致进程崩溃；内核的内存漏洞则可能导致权限提升、系统崩溃等严重安全问题
2. **C代码的常见缺陷**：内核维护者指出，大量bug源于"C语言中那些愚蠢的小陷阱"，包括内存覆写、错误路径清理遗漏、忘记检查错误值和use-after-free错误[^9]，而这些在Rust中完全不存在
3. **审查负担**：Rust让编译器承担了大部分内存安全审查工作[^10]；而Zig虽然提供了更好的工具，但仍需要人工审查每一处潜在的内存安全问题

Zig相比C的**提升很大**，只是在"内存安全"这个特定维度上，它选择了和C类似的路径——给开发者强大的工具，但不强制安全。这让它成为：
- 需要精细控制嵌入式系统的理想选择
- C代码库渐进式改进的绝佳桥梁
- 工具链、构建系统等基础设施的重写利器

但在Linux内核这种对**绝对安全**有极致要求的场景，Rust的强制保证确实更胜一筹。

## 总结

Linux内核选择Rust而非Zig，是在那个时间点上，对**安全性、成熟度和生态**的综合考量。Rust的编译期内存安全保证、成熟的工具链和庞大的社区，使其成为内核"第二语言"的最佳选择。

而Zig虽然没有进入内核核心，但也凭借其在**资源效率和C互操作性**上的优势，在Linux生态的外围找到了用武之地。两种语言都在推动系统编程的发展，只是选择了不同的路径。

## 参考资料

[^1]: [Rust for Linux](https://rust-for-linux.com/) - Rust for Linux项目官方网站

[^2]: [Linux Kernel Adopts Rust as Permanent Core Language in 2025](https://www.webpronews.com/linux-kernel-adopts-rust-as-permanent-core-language-in-2025/) - WebProNews, 2025年12月报道

[^3]: [Rust for Linux: Understanding the Security Impact of Rust in the Linux Kernel](https://mars-research.github.io/doc/2024-acsac-rfl.pdf) - 研究论文，分析了Rust在Linux内核中的安全影响

[^4]: [Why Zig When There is Already C++, D, and Rust?](https://ziglang.org/learn/why_zig_rust_d_cpp/) - Zig官方文档对比分析

[^5]: [Comparing Rust vs. Zig: Performance, safety, and more](https://blog.logrocket.com/comparing-rust-vs-zig-performance-safety-more/) - LogRocket技术博客深度对比

[^6]: [Running Code on Cleanup with the Drop Trait](https://doc.rust-lang.org/book/ch15-03-drop.html) - Rust官方文档，详细介绍Drop trait的工作原理

[^7]: [RAII - Rust By Example](https://doc.rust-lang.org/rust-by-example/scope/raii.html) - Rust官方示例，解释RAII模式

[^8]: [Rust Integration in Linux Kernel Faces Challenges but Shows Progress](https://thenewstack.io/rust-integration-in-linux-kernel-faces-challenges-but-shows-progress/) - The New Stack关于Rust在Linux内核中的进展报道

[^9]: [Linux Driver Development with Rust](https://www.apriorit.com/dev-blog/rust-for-linux-driver) - Apriorit关于Rust驱动开发的分析，引用内核维护者的观点

[^10]: [How Rust's Debut in the Linux Kernel is Shoring Up System Stability](https://www.linuxjournal.com/content/how-rusts-debut-linux-kernel-shoring-system-stability) - Linux Journal关于Rust如何提升内核稳定性

### 延伸阅读

- [The Linux Kernel - Rust Documentation](https://docs.kernel.org/rust/index.html) - Linux内核官方Rust文档
- [Rust Kernel Policy](https://rust-for-linux.com/rust-kernel-policy) - Rust在Linux内核中的集成政策
- [An Empirical Study of Rust-for-Linux](https://www.usenix.org/system/files/atc24-li-hongyu.pdf) - USENIX ATC 2024论文，对Rust-for-Linux的实证研究
- [Rusty Linux: Advances in Rust for Linux Kernel Development](https://arxiv.org/html/2407.18431v1) - arXiv论文，深入分析Rust在Linux内核开发中的进展
