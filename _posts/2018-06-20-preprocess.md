---
title: C的preprocessing过程
abstract: C或者C++的macros都是在preprocessing（预处理）阶段被处理。Preprocessor处理完这些macros以后，会转成C的代码，然后代码才会统一进入到编译阶段。
---

## {{ page.title }}

C或者C++的macros都是在preprocessing（预处理）阶段被处理。Preprocessor处理完这些macros以后，会转成C的代码，然后代码才会统一进入到编译阶段。

下面是代码：

```c
#define foo bar

int main() {
	foo
}
```

上面我们通过`define`  macro定义了一个foo，它的值是bar。注意这个定义是预处理层面的，不是代码阶段被编译。因此，代码中出现的foo，会被简单地被文本替换成bar。

我们可以使用`cc`的`-E`选项来对代码只进行预处理，查看替换后的输出：

```bash
$ cc -E macro_expand.c
# 1 "macro_expand.c"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 341 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "macro_expand.c" 2


int main() {
	bar
}
```

可以看到`define`这个macro command已经消失了，而`foo`已经被替换成了`bar`。因为预处理只是简单的文本替换过程，所以它不检查代码的语法。检查代码语法是编译阶段的事情。

我们可以看看`define`这个macro在实际应用中的作用，比如`assert.h`当中定义的`assert()`函数，其实是一个macro：

```c
#define	assert(e) \
	(__builtin_expect(!(e), 0) ? __assert_rtn(__func__, __FILE__, __LINE__, #e) : (void)0)
```

它会在预处理阶段被扩展成实际的函数定义。

我们接下来再看常用的`include`这个macro command，它的功能就是把一个文件的内容展开到`include`所在位置。下面是代码的例子：

```bash
$ cat foo.h
```

```c
void foo();
```

上面这个`foo.h`是一个header file，我们可以在别的代码文件里通过`#include`来引用它：

```bash
$ cat macro_expand.c
```

```c
#include "foo.h"

int main() {
	foo();
}
```

这样，通过`#include`，在预处理阶段，`foo.h`的内容就会展开到`macro_expand.c`的`#include`所在位置：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/iTerm2ScreenSnapz140.b341d138cf7144c3a2706df6f79388f9.png)

可以看到`#include "foo.h"`被替换成了`foo.h`里面的实际内容。

以上就是对C/C++的预处理过程的一个简单介绍。
