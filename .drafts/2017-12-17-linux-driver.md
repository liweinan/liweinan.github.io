---
title: Linux驱动开发入门（四）
abstract: 这篇文章讲讲如何获取设备的minor number。
---

## {{ page.title }}

（从这篇文章开始，不是旧文了，把这个系列做下去，写点新东西）

{{ page.abstract }}

https://github.com/torvalds/linux/blob/master/include/linux/kdev_t.h

struct inode: http://elixir.free-electrons.com/linux/latest/source/include/linux/fs.h#L565
