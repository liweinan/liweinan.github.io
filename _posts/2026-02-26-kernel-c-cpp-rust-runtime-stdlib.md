---
title: "内核开发中的语言选择：C、C++ 与 Rust 的运行时与标准库"
---

操作系统内核开发与应用程序开发的核心区别之一，在于运行时与内存管理模型的约束。本文从运行时大小、内存管理模型和标准库依赖三个方面，分析 C、C++、Rust 在内核开发中的差异。

## 运行时大小问题

### C 运行时
C 的运行时几乎可以忽略不计：
- **最小运行时**：C 语言被设计为「接近硬件」，运行时仅提供最基本的启动代码（crt0）和库函数
- **可控性**：内核开发者可以完全避免使用标准库，直接使用系统调用和硬件指令
- **典型例子**：Linux 内核几乎完全用 C 编写，运行时开销极小[^4]

### C++ 运行时
C++ 的运行时较大，原因是：
- **异常处理**：需要 unwind 表和 RTTI（运行时类型信息）
- **标准库**：STL 容器、算法等需要大量初始化代码
- **构造函数**：静态对象的构造需要运行时支持
- **内存管理**：operator new/delete 的默认实现
- **例子**：即使在嵌入式环境中，完整的 C++ 运行时可能增加数百 KB 到数 MB 的开销

### Rust 运行时
Rust 介于两者之间：
- **零成本抽象**：大部分抽象在编译时展开，不增加运行时开销
- **最小运行时**：只需要基本的 panic 处理、内存分配器（若使用）
- **no_std 模式**：可以完全禁用标准库，只使用 core 库，运行时开销与 C 相当[^1][^2]
- **例子**：Redox OS 内核完全用 Rust 编写，使用 no_std 模式[^5]

## 内存管理的核心区别

内存管理模型的差异是另一关键因素。

### C++ 的内存管理问题

1. **构造函数和析构函数**
```cpp
class Device {
    Resource* res;
public:
    Device() { res = allocate_resource(); }  // 可能失败
    ~Device() { release_resource(); }        // 异常可能发生
};
```
- 构造函数无法返回错误码（只能用异常）
- 析构函数中不能抛出异常
- 对象生命周期由编译器自动管理，但在内核中这往往是不可预测的

2. **异常处理**
```cpp
void driver_function() {
    Device d;  // 构造
    // 如果这里发生异常，d 的析构函数会自动调用
    // 但在内核中，这种隐式控制流是危险的
}
```
- 异常展开需要复杂的栈回溯
- 增加了二进制文件大小
- 实时性无法保证

3. **RAII 的局限性与运行时依赖**

RAII（Resource Acquisition Is Initialization）的核心是：资源在对象构造时获取，在对象析构时释放。这一机制在内核中受限，且其实现本身依赖运行时支持。

**为何 RAII 需要运行时支持：**

- **构造与析构的自动调用**：编译器需在正确位置插入构造/析构调用，对象生命周期的管理（何时创建、何时销毁）依赖运行时机制。例如：

```cpp
class FileHandler {
    FILE* file;
public:
    FileHandler(const char* filename) { file = fopen(filename, "r"); }
    ~FileHandler() { if (file) fclose(file); }
};

void processFile() {
    FileHandler fh("data.txt");  // 构造时获取资源
    // 使用文件...
}  // 离开作用域时析构被自动调用
```

- **栈展开（Stack Unwinding）**：异常发生时，需要按与构造相反的顺序自动调用所有已构造局部对象的析构函数，并维护调用栈信息。内核通常禁用异常，因此无法依赖这套机制。

```cpp
void function() {
    FileHandler fh1("a.txt");
    FileHandler fh2("b.txt");
    throw std::runtime_error("error");  // 异常时 fh2、fh1 的析构须被调用
}
```

- **动态内存与智能指针**：`std::vector`、`std::unique_ptr`/`std::shared_ptr` 等依赖堆分配与引用计数，需要在运行时跟踪资源。

- **多态对象的析构**：通过基类指针删除派生类对象时，必须通过虚函数表（vtable）在运行时找到正确的析构函数，同样依赖运行时类型信息。

若纯靠编译时实现，无法处理异常路径下的释放、多态析构和动态资源的引用计数等，因此 RAII 既是 C++ 的核心特性，又离不开运行时支持，这与内核需要的确定性、无异常、显式控制相冲突。

**运行时实现简述**：局部对象的构造/析构由编译器在固定位置插入调用；全局或静态对象由启动代码遍历 `.init_array`（或 `.ctors`）在进程启动时调用构造，退出时按逆序调用析构。异常时的栈展开则依赖 **unwinder**：编译器为每个函数生成 unwind 元数据（如 DWARF 的 `.eh_frame`），描述栈帧与需析构的对象；异常抛出时，运行时库按栈回溯，调用每帧的 personality 函数，按表调用析构并查找 catch。多态析构通过对象的 vtable 在运行时查表得到正确析构函数。这些机制多在编译器运行时（如 libgcc、libstdc++ 的一部分）中实现，与「标准库 STL」不是同一层，但都属 C++ 运行时。

- RAII 假设资源释放是确定性的、无错的
- 内核中可能需要延迟释放、异步释放
- 硬件资源的释放可能非常复杂

4. **模板元编程**
```cpp
template<typename T>
class RingBuffer {
    T buffer[256];  // 类型在编译时确定
    // 但在内核中，可能需要根据硬件配置动态选择类型
};
```
- 过度依赖模板会导致代码膨胀
- 难以处理动态硬件配置

### C 的内存管理优势

1. **显式控制**
```c
struct device *dev = kmalloc(sizeof(*dev), GFP_KERNEL);
if (!dev)
    return -ENOMEM;
dev->ops = &device_ops;
// 所有操作都是显式的，没有隐藏的控制流
```

2. **错误处理直接**
```c
int init_device(struct device *dev) {
    int ret;
    ret = init_resource_a(dev);
    if (ret)
        return ret;
    ret = init_resource_b(dev);
    if (ret) {
        cleanup_resource_a(dev);
        return ret;
    }
    return 0;
}
```
- 所有错误路径都清晰可见
- 没有隐式的资源释放

3. **内存布局可预测**
```c
struct packet {
    uint32_t len;
    char data[0];  // 灵活数组成员
};  // 内存布局完全由程序员控制
```

### 内核 C 的面向对象风格

内核虽然用 C 编写，但大量采用**面向对象式**的写法：用结构体承载「状态」，用函数指针表承载「行为」，多态通过查表调用实现，无需 C++ 的虚函数或异常[^7][^8]。

**1. 函数指针表（类似 vtable）**

例如 VFS 层的 `struct file_operations`（`include/linux/fs.h`）：每个字段是一类操作，由具体驱动/文件系统填不同实现，通用代码通过 `file->f_op->read(...)` 等形式调用，实现多态。`file_operations` 与 inode 等结构的定义与用法可参考本博客[^9]。

```c
// 简化自 linux/fs.h
struct file_operations {
    struct module *owner;
    ssize_t (*read) (struct file *, char __user *, size_t, loff_t *);
    ssize_t (*write) (struct file *, const char __user *, size_t, loff_t *);
    int (*open) (struct inode *, struct file *);
    int (*release) (struct inode *, struct file *);
    // ...
};

// 驱动侧：实现“类”并挂到 file 上
static struct file_operations my_fops = {
    .owner = THIS_MODULE,
    .read  = my_read,
    .write = my_write,
    .open  = my_open,
    .release = my_release,
};
```

同类结构还有 `inode_operations`、`dentry_operations`、`super_operations`、各类 `*_ops` 等，内核中有大量这种「操作表」[^4]。

**2. “继承”通过结构体嵌入**

子类型通过**在结构体里嵌入父类型**复用共同字段，并可用 `container_of` 从父指针反推子指针。例如设备模型里 `struct device` 内嵌 `struct kobject`，子设备再内嵌 `struct device`，形成层次与共同生命周期管理。

```c
// 概念上：子结构体包含“基类”
struct my_device {
    struct device dev;   // 内嵌，相当于“继承” device 的字段
    int my_private_data;
};

// 从通用 device* 得到 my_device*
struct my_device *mdev = container_of(dev, struct my_device, dev);
```

**3. “方法”约定：首参为对象指针**

很多内核 API 的「方法」形态是：第一个参数为操作对象，例如 `int (*open)(struct inode *, struct file *)`。调用方持有 `struct file *`，通过 `f_op->open(inode, filp)` 调用，等价于「对 file 做 open」，与 OO 的 `obj->method(args)` 对应。

综上，内核 C 用「结构体 + 函数指针表 + 嵌入 + 显式首参」实现接口抽象和多态，无需 C++ 的运行时（异常、vtable 展开、构造/析构顺序），仍能保持清晰的层次与可扩展性。

### Rust 的创新解决方案

Rust 通过所有权系统和生命周期来平衡安全性和控制力：

```rust
struct Device {
    resource: Resource,
}

impl Device {
    fn new() -> Result<Self, Error> {
        let res = Resource::new()?;  // 显式错误处理
        Ok(Device { resource: res })
    }
}  // Drop trait 提供确定性析构，但比 C++ 更可控

// 所有权确保资源只有一个所有者
fn use_device(dev: Device) {  // 获得所有权
    // 使用设备
}  // 这里自动释放，但行为是确定的
```

Rust 解决了 C++ 的几个关键问题：
1. **无异常**：使用 Result 类型进行显式错误处理
2. **所有权系统**：资源释放是确定性的
3. **零成本抽象**：无运行时开销
4. **内存安全**：编译时检查，无 GC 开销

## 为什么内核不能使用标准库

### 1. 标准库依赖操作系统服务

标准库本质上是操作系统功能的封装：

```rust
// 标准库的实现依赖系统调用
// std::fs::File::open("test.txt") 最终会调用：
// Linux: openat() 系统调用
// Windows: NtCreateFile() 系统调用

// 但在内核中：
// 1. 没有文件系统（或文件系统实现不同）
// 2. 没有当前工作目录的概念
// 3. 没有用户态/内核态的转换机制
```

### 2. 内核需要裸机环境

```c
// 用户态程序可以这样：
#include <stdio.h>
int main() {
    printf("Hello\n");  // 依赖操作系统的标准输出
    return 0;
}

// 内核只能这样：
void kernel_entry() {
    // 没有 main 函数，没有标准库
    // 需要直接操作硬件
    char *video_memory = (char*)0xb8000;
    *video_memory = 'H';  // 直接写入显存
}
```

## 各语言在没有标准库时的表现

### C 语言：裸机编程的典范

```c
// 内核中常见的 C 代码
static void serial_putc(char c) {
    // 直接操作硬件寄存器
    while (!(inb(COM1 + 5) & 0x20));
    outb(COM1, c);
}

// 自己实现需要的功能
void* memcpy(void* dest, const void* src, size_t n) {
    char* d = dest;
    const char* s = src;
    while (n--) *d++ = *s++;
    return dest;
}
```

C 语言的特点：
- **语言本身与运行时分离**：语法不依赖标准库
- **freestanding environment**：C 标准明确支持无标准库环境
- **最小依赖**：甚至连 `memcpy` 都可以自己实现

### C++：标准库依赖严重

```cpp
// 不能用的 C++ 特性：
#include <vector>      // 需要动态内存分配和异常
#include <string>      // 需要内存分配和字符处理
#include <iostream>    // 需要操作系统支持
#include <thread>      // 需要线程库支持
#include <mutex>       // 需要同步原语

// 即使不用标准库，语言特性本身也有问题：
class Device {
    std::string name;  // 错误：string 需要标准库
public:
    Device() { /* 构造函数不能失败？ */ }
    ~Device() { /* 析构函数不能抛异常？ */ }
};

// 尝试不用标准库：
class Device {
    char name[32];  // 固定大小，但不够灵活
    int fd;
public:
    Device() : fd(-1) {}  // 两阶段构造（anti-pattern）
    bool init(const char* n) { /* 真正的初始化 */ }
    void deinit() { /* 手动释放 */ }
};
// 但这违背了 RAII 原则
```

C++ 的问题：
- **语言特性隐含依赖**：即使不用标准库，异常、RTTI 等也需要运行时支持
- **STL 无法移植**：容器都假设有堆内存管理和操作系统服务
- **构造函数限制**：无法优雅处理初始化失败

**澄清**：离开标准库并不等于「所有 C++ 特性都用不了」。RAII（自己的类）、虚函数、vtable、重载 `operator new/delete` 都是**语言特性**，不依赖标准库；异常则依赖 unwinder 等**运行时**（多在编译器运行时库里），与 STL 是不同层。内核里通常还禁用异常（`-fno-exceptions`）和 RTTI（`-fno-rtti`），因此异常和 `dynamic_cast`/`typeid` 不可用，RAII 在异常路径上的保障也随之消失。

**假设内核用 C++：去掉标准库并加上常见限制（如 -fno-exceptions、-fno-rtti、禁止复杂全局构造）后，功能退化可概括为：**

| 情况 | 功能 | 说明 |
|------|------|------|
| **完全不可用** | STL 容器/算法、std::string、标准智能指针、iostream | 依赖标准库，内核不链接 |
| | 异常 (throw/catch) | 通常 -fno-exceptions，且不愿携带 unwinder |
| | RTTI (dynamic_cast, typeid) | 通常 -fno-rtti |
| **语义退化** | RAII | 构造不能返回错误 → 退化为两阶段 init；无异常则「任意路径都析构」的保证弱化；析构常被要求只做简单、确定性释放 |
| | 全局/静态对象（非平凡构造） | 依赖 .init_array 与启动顺序，内核中多禁止或极简使用 |
| **仍可用但受限** | new/delete | 可重载到 kmalloc/kfree；有的规范禁止全局 new，仅允许 placement new + 内核分配器 |
| | 虚函数 / vtable、模板、类与继承 | 不依赖标准库；风格上常限制深继承与过度模板 |
| | const、引用、重载、命名空间 | 纯语言特性，无退化 |

整体上 C++ 会退化成「带类、模板和虚函数的 C」：语法和类型系统仍在，错误处理回到返回码，资源管理更显式，不能依赖异常与标准库。

### Rust：no_std 模式[^1]

```rust
// 指定不使用标准库
#![no_std]

// 只能使用 core 库（无操作系统依赖）
use core::panic::PanicInfo;

// 需要自己处理 panic
#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

// 需要自己实现内存分配（如果需要）
#[global_allocator]
static ALLOCATOR: MyAllocator = MyAllocator;

// 可以安全地使用大部分语言特性
#[repr(C)]
struct Device {
    base_addr: usize,
    irq: u32,
}

impl Device {
    const fn new() -> Self {  // const fn 可以在编译时执行
        Device { base_addr: 0, irq: 0 }
    }

    fn read_reg(&self, offset: usize) -> u32 {
        // 直接操作内存映射 IO
        unsafe { (self.base_addr as *const u32).add(offset).read_volatile() }
    }
}
```

Rust 的优势[^1]：
- **core 库**：提供语言核心功能，无操作系统依赖。core 中**不包含与操作系统相关的 I/O 能力**：文件、标准输入/输出（stdin/stdout）、网络（TcpStream 等）均在 `std` 中；core 里仅有极少的 I/O 相关 trait/类型定义（如 `BorrowedBuf`），不提供实际读写，因此 `#![no_std]` 下无法使用 `println!`、`File`、`std::net` 等，需自行实现或依赖其他库。
- **语言特性零成本**：所有权、借用检查都在编译期
- **明确的 unsafe**：硬件操作需要显式标记
- **const fn**：可以在编译时执行函数

## 实际代码对比

### 实现一个简单的串口驱动

**C 版本**：
```c
// serial.h
struct serial_port {
    uint16_t port;
    int initialized;
};

void serial_init(struct serial_port *sp, uint16_t port);
void serial_putc(struct serial_port *sp, char c);

// serial.c
void serial_init(struct serial_port *sp, uint16_t port) {
    sp->port = port;
    sp->initialized = 1;
    outb(port + 1, 0x00);  // 关闭中断
    outb(port + 3, 0x80);  // 设置波特率
    outb(port + 0, 0x03);
    outb(port + 1, 0x00);
    outb(port + 3, 0x03);
    outb(port + 2, 0xC7);
    outb(port + 4, 0x0B);
}

void serial_putc(struct serial_port *sp, char c) {
    while ((inb(sp->port + 5) & 0x20) == 0);
    outb(sp->port, c);
}
```

**C++ 版本（有问题）**：
```cpp
// 尝试用 C++ 风格
class SerialPort {
private:
    uint16_t port;
    bool initialized;

public:
    SerialPort(uint16_t port) : port(port) {
        // 构造函数中初始化，但如果失败？
        init();  // 不能返回错误码
    }

    ~SerialPort() {
        // 析构函数中清理
    }

    void putc(char c) {
        while ((inb(port + 5) & 0x20) == 0);
        outb(port, c);
    }

private:
    void init() {
        // 如果这里失败，只能抛异常
        // 但内核中不能使用异常
        outb(port + 1, 0x00);
        // ...
    }
};
```

**Rust 版本**（内存映射 I/O 风格）：
```rust
#![no_std]

use core::ptr::{read_volatile, write_volatile};

#[repr(C)]
pub struct SerialPort {
    port: u16,
    initialized: bool,
}

impl SerialPort {
    pub fn new(port: u16) -> Result<Self, &'static str> {
        let mut sp = SerialPort {
            port,
            initialized: false,
        };
        sp.init()?;
        Ok(sp)
    }

    fn init(&mut self) -> Result<(), &'static str> {
        unsafe {
            write_volatile((self.port + 1) as *mut u8, 0x00);
            write_volatile((self.port + 3) as *mut u8, 0x80);
            write_volatile((self.port + 0) as *mut u8, 0x03);
            write_volatile((self.port + 1) as *mut u8, 0x00);
            write_volatile((self.port + 3) as *mut u8, 0x03);
            write_volatile((self.port + 2) as *mut u8, 0xC7);
            write_volatile((self.port + 4) as *mut u8, 0x0B);
        }
        self.initialized = true;
        Ok(())
    }

    pub fn putc(&self, c: u8) {
        unsafe {
            while (read_volatile((self.port + 5) as *const u8) & 0x20) == 0 {}
            write_volatile(self.port as *mut u8, c);
        }
    }
}
```

上述 Rust 示例为**内存映射 I/O** 风格（例如常见于 ARM 等平台）；在 x86 上 COM 口为**端口 I/O**，需使用 inb/outb 或 `x86_64::instructions::port::Port` 等封装。

## 标准库 vs no_std 的生态差异

### 可用功能对比

| 功能 | 标准库 | no_std | 说明 |
|------|--------|--------|------|
| Vec/String | ✅ | ❌ | 需要内存分配器 |
| Box/Rc/Arc | ✅ | ⚠️ | 需要内存分配器 |
| HashMap | ✅ | ❌ | 需要随机数源 |
| println! | ✅ | ❌ | 需要 IO（core 无具体 I/O 实现） |
| 文件操作 | ✅ | ❌ | 需要文件系统 |
| 线程 | ✅ | ❌ | 需要调度器 |
| Mutex | ✅ | ⚠️ | 需要原子操作支持 |
| 迭代器 | ✅ | ✅ | 纯语言特性 |
| match | ✅ | ✅ | 语言特性 |
| trait | ✅ | ✅ | 语言特性 |
| 闭包 | ✅ | ✅ | 语言特性 |

### 实际影响

在裸机环境中：
- **C**：完全掌控，需要什么写什么
- **C++**：大量特性受限，变成「更好的 C」
- **Rust**：通过 no_std + core 保留大部分语言能力[^1]

## 实际内核开发的选择

- **Linux**：C 语言，完全掌控内存和运行时；近年来开始接纳 Rust 编写的子系统[^3][^6]
- **Windows**：混合，内核主要用 C，部分驱动用 C++
- **Redox OS**：Rust，展示现代语言也能做内核[^5]
- **鸿蒙**：混合，内核用 C，上层用 C++/Rust

## 总结

从运行时与内存管理看，C++ 不适合内核开发的主要原因在于**内存管理模型的差异**：异常处理、隐式构造/析构、RAII 等与内核需要的确定性和显式控制相冲突；Rust 则用所有权系统在零成本抽象与内存安全之间取得折中。从标准库看，内核不能使用标准库：**C** 失去的很少（语言本身不依赖库），**C++** 失去核心优势（STL、异常、部分 RAII），**Rust** 失去便利性（集合类型、格式化输出）但保留安全性。因此 Linux 选择 C（简单、可控、最小依赖，Rust 作为补充逐步引入[^6]），Windows 内核主要用 C、部分驱动用 C++ 且限制特性，Redox 选择 Rust（no_std 提供安全性与表达能力的最佳平衡[^5]）。

## References

[^1]: [The Embedded Rust Book - no_std](https://docs.rust-embedded.org/book/intro/no-std.html) - Rust 裸机/内核开发中的 no_std 与 core 库说明

[^2]: [Rust RFC 1184: Stabilize no_std](https://rust-lang.github.io/rfcs/1184-stabilize-no_std.html) - no_std 稳定化与 libcore 范围

[^3]: [Linux Kernel - Rust support](https://docs.kernel.org/rust/general-information.html) - 内核 Rust 支持说明（仅链接 libcore，无 std）

[^4]: [Linux Kernel Source (torvalds/linux)](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git) - 官方内核源码（C 为主，含 Rust 子系统）

[^5]: [Redox OS](https://www.redox-os.org/) - 使用 Rust no_std 编写的操作系统

[^6]: [Rust for Linux](https://rust-for-linux.com/) - 内核内 Rust 支持项目与文档

[^7]: [Object-oriented design patterns in the kernel, part 1](https://lwn.net/Articles/444910/) - LWN，方法分派与 vtable（file_operations、inode_operations 等）模式

[^8]: [Object-oriented design patterns in the kernel, part 2](https://lwn.net/Articles/446317/) - LWN，数据继承与结构体内嵌（container_of）模式

[^9]: [Linux驱动开发入门（四）](https://weinan.io/2017/12/17/linux-driver.html) - 本博客，file_operations / inode 等内核数据结构与驱动示例
