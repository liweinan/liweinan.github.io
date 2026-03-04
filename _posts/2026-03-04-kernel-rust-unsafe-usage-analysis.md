---
title: "Linux 内核 Rust 代码中 unsafe 使用场景统计分析"
---

与「只有调用 C 才需要 unsafe」的常见误解不同，但凡涉及硬件或与内核/硬件边界交互（如驱动、MMIO、DMA），在 Rust 里几乎必然要使用 `unsafe`，这与是否通过 FFI 调 C 无必然关系——例如 Embassy 等纯 Rust 裸机/驱动生态里，硬件相关操作同样大量集中在 `unsafe` 中。本文基于对主线 Linux 内核 `rust/` 目录的统计与代码抽样，归纳当前内核 Rust 中 `unsafe` 的实际使用场景，并辅以真实内核代码说明。

## 统计概览

对主线内核 `rust/` 树（约 130 个 `.rs` 文件）的统计结果如下。

| 项目 | 数量 |
|------|------|
| **`unsafe` 出现总次数** | **1891** |
| **`unsafe { ... }` 块** | 约 1252 |
| **`unsafe fn` / `unsafe impl` / `unsafe trait`** | 约 388 |
| **`// SAFETY:` 注释** | 1413 |
| **Rust 源文件数** | 130 |

约 75% 的 `unsafe` 使用配有 `// SAFETY:` 说明，便于审查与维护。

## 使用场景分类

### 1. 调用 C 内核 API（FFI / bindings）

通过 bindgen 生成的 C 内核 API 在 Rust 侧一律通过 `bindings::` 调用，且这些调用均出现在 `unsafe` 块或 `unsafe fn` 内。统计显示 **`bindings::` 出现约 1062 次**，是 `unsafe` 的一大来源。

典型用法：取得 C 结构体指针、解引用其字段作为参数，再调用 C 函数。例如 PHY 寄存器读写的纯「FFI + 裸指针解引用」：

```rust
// rust/kernel/net/phy/reg.rs（节选）
impl Register for C22 {
    fn read(&self, dev: &mut Device) -> Result<u16> {
        let phydev = dev.0.get();
        // SAFETY: `phydev` is pointing to a valid object by the type invariant of `Device`.
        // So it's just an FFI call, open code of `phy_read()` with a valid `phy_device` pointer
        let ret = unsafe {
            bindings::mdiobus_read((*phydev).mdio.bus, (*phydev).mdio.addr, self.0.into())
        };
        to_result(ret)?;
        Ok(ret as u16)
    }

    fn write(&self, dev: &mut Device, val: u16) -> Result {
        let phydev = dev.0.get();
        // SAFETY: ... (同上)
        to_result(unsafe {
            bindings::mdiobus_write((*phydev).mdio.bus, (*phydev).mdio.addr, self.0.into(), val)
        })
    }
}
```

这里 `unsafe` 同时覆盖：**对 C 指针的解引用**（`(*phydev).mdio.bus`）和 **FFI 调用**（`bindings::mdiobus_read` / `mdiobus_write`）。也就是说，与硬件打交道的驱动路径上，即便逻辑是「读/写寄存器」，在 Rust 侧也会体现为「裸指针 + C API」，因而必然落在 `unsafe` 内。

### 2. 硬件与并发语义：volatile 与 READ_ONCE / WRITE_ONCE

与「硬件或外部可写内存」的交互常需要 volatile 或与内核 READ_ONCE/WRITE_ONCE 等价的语义；这类操作在 Rust 中同样必须放在 `unsafe` 里，且**与是否调用 C 无关**——纯 Rust 的 MMIO/寄存器访问（如 Embassy 中的实现）也是如此。

**（1）文件描述符标志：对应 READ_ONCE**

```rust
// rust/kernel/fs/file.rs（节选）
pub fn flags(&self) -> u32 {
    // This `read_volatile` is intended to correspond to a READ_ONCE call.
    //
    // SAFETY: The file is valid because the shared reference guarantees a nonzero refcount.
    //
    // FIXME(read_once): Replace with `read_once` when available on the Rust side.
    unsafe { core::ptr::addr_of!((*self.as_ptr()).f_flags).read_volatile() }
}
```

此处用 `read_volatile` 表达「可能与其他执行上下文共享的字段」的读，避免编译器优化导致的数据竞争未定义行为，语义上对应 C 侧的 `READ_ONCE`。

**（2）DMA 一致内存：与硬件/用户态竞态**

DMA 或与设备/用户态共享的内存，读写同样需要「单次访问不拆、不优化掉」的语义。内核在 `dma.rs` 中通过 `read_volatile` / `write_volatile` 实现，并明确注释其与 READ_ONCE/WRITE_ONCE 的对应关系及适用范围：

```rust
// rust/kernel/dma.rs（节选）
pub unsafe fn field_read<F: FromBytes>(&self, field: *const F) -> F {
    // SAFETY:
    // - By the safety requirements field is valid.
    // - Using read_volatile() here is not sound as per the usual rules, the usage here is
    // a special exception with the following notes in place. When dealing with a potential
    // race from a hardware or code outside kernel (e.g. user-space program), we need that
    // read on a valid memory is not UB. Currently read_volatile() is used for this, and the
    // rationale behind is that it should generate the same code as READ_ONCE() which the
    // kernel already relies on to avoid UB on data races. Note that the usage of
    // read_volatile() is limited to this particular case, it cannot be used to prevent
    // the UB caused by racing between two kernel functions nor do they provide atomicity.
    unsafe { field.read_volatile() }
}

pub unsafe fn field_write<F: AsBytes>(&self, field: *mut F, val: F) {
    // SAFETY: ... (与 READ_ONCE 对应地，此处对应 WRITE_ONCE)
    unsafe { field.write_volatile(val) }
}
```

可见：**只要涉及「硬件或内核外部的竞态」，就需要这类 volatile 访问，并因此使用 `unsafe`**，与是否经过 C 代码无关。

### 3. MMIO / ioremap：资源映射与释放

内存映射 I/O（MMIO）是驱动访问设备寄存器的常见方式。内核 Rust 侧对 `ioremap` / `iounmap` 的封装同样在 `unsafe` 中完成，并配有 SAFETY 注释说明前置条件：

```rust
// rust/kernel/io/mem.rs（节选）
fn ioremap(resource: &Resource) -> Result<Self> {
    // ...
    let addr = if resource.flags().contains(io::resource::Flags::IORESOURCE_MEM_NONPOSTED) {
        // SAFETY:
        // - `res_start` and `size` are read from a presumably valid `struct resource`.
        // - `size` is known not to be zero at this point.
        unsafe { bindings::ioremap_np(res_start, size) }
    } else {
        unsafe { bindings::ioremap(res_start, size) }
    };
    // ...
}

impl<const SIZE: usize> Drop for IoMem<SIZE> {
    fn drop(&mut self) {
        // SAFETY: Safe as by the invariant of `Io`.
        unsafe { bindings::iounmap(self.io.addr() as *mut c_void) }
    }
}
```

这里既有 **FFI（调用 C 的 ioremap/iounmap）**，也有 **对「映射得到的地址」所代表的 I/O 内存的访问约定**，二者都属于与硬件打交道的边界，因此用 `unsafe` 是必然的。

### 4. 裸指针与内存操作

除上述 FFI 与 volatile 外，内核 Rust 中还有大量「裸指针解引用、`ptr::read`/`ptr::write`、`drop_in_place`、`addr_of!`」等用法，分布在：

- **pin-init**：未初始化/固定内存的初始化与析构；
- **kernel/alloc**：自定义分配器、KBox、kvec 等；
- **kernel/sync/arc**、**kernel/list**、**kernel/rbtree** 等：与 C 结构或内核生命周期绑定的共享/链表/树。

这些同样不依赖「是否调 C」：只要涉及未初始化内存、自管理指针或与 C 结构布局的互操作，就需要在 `unsafe` 中手动维护不变式。

### 5. 其他：Pin、transmute、Send/Sync

- **Pin::new_unchecked**、**NonNull::new_unchecked**、pin-init 的闭包初始化等：用于在保证不移动或初始化顺序的前提下构造对象，约 30+ 处。
- **transmute / transmute_copy**：与 C 类型或 ABI 的互转、内部表示转换，约 35 处。
- **unsafe impl Send / Sync**：为内部含裸指针或 FFI 句柄的类型标注可跨线程传递或共享，约 90+ 处。

它们都与「和硬件或 C 边界交互」时的生命周期、布局、并发约定直接相关，是内核 Rust 中 `unsafe` 的组成部分，而不是「可选的风格问题」。

## 按子系统的分布（约）

| 子系统 | `unsafe` 次数 | 说明 |
|--------|----------------|------|
| **kernel/**（整体） | 1644 | 含下列子目录 |
| kernel/sync | 142 | 锁、Arc、RCU、completion 等 |
| kernel/alloc | 109 | 分配器、KBox、kvec 等 |
| kernel/drm | 72 | DRM 驱动、GEM、ioctl 等 |
| kernel/net | 56 | 网络、PHY 寄存器等 |
| kernel/block | 47 | 块层、request、gen_disk 等 |
| kernel/device | 31 | 设备模型、property 等 |
| kernel/io | 19 | ioremap、I/O 资源、mem 等 |

驱动与硬件相关模块（net、block、drm、io、device 等）中 `unsafe` 密集，与「但凡和硬件扯上关系就需要 unsafe」的直观一致；sync/alloc 则多为并发与内存管理抽象本身的边界。

## 小结

- **「和硬件扯上关系就要 unsafe」**：内核 Rust 的现状与之相符。MMIO（io/mem）、PHY 寄存器（net/phy）、DMA 读写（dma.rs）、以及大量通过 `bindings::` 调用的 C 驱动 API，都位于 `unsafe` 中；驱动/硬件路径几乎必然触及 `unsafe`。
- **「和是否调用 C 无关」**：  
  - 调用 C（`bindings::`）约 1062 处，占 `unsafe` 比例很高。  
  - 但 **volatile 访问**（file.rs、dma.rs）、**裸指针解引用**、**Pin/初始化**、**Send/Sync**、**transmute** 等，很多并不依赖「调 C」，而是**内核的硬件与内存模型**本身就需要在 Rust 中通过 `unsafe` 表达。  
  因此：既有大量「因调 C 而 unsafe」，也有大量「因硬件/并发/内存边界而 unsafe」；与 Embassy 等纯 Rust 驱动/裸机生态一致——**与硬件或底层边界打交道的代码，即使用纯 Rust 写，unsafe 仍会集中在这些边界上**。

统计基于主线内核 `rust/` 树，代码片段取自同一树中的实际文件（见文中路径注释）[^1][^2]。

## References

[^1]: [Linux Kernel - Rust support](https://docs.kernel.org/rust/general-information.html) - 内核 Rust 支持与目录结构说明

[^2]: [Rust for Linux](https://rust-for-linux.com/) - 内核内 Rust 支持项目与文档
