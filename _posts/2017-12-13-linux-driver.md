---
title: Linux驱动开发入门（一）
abstract: 在Feodra Linux编译驱动非常方便，我们可以使用社区提供好的Package，来进行编译工作。
---

## {{ page.title }}

（这是一篇旧文，内容有所更新。未来会把之前写过的文章慢慢整理到这个博客里面。）

{{ page.abstract }}

Fedora对内核开发提供了一些相关的包，简化了配置流程，在这篇文章里我们来看一下。


首先在系统中安装kernel相关的package：

```bash
$ sudo dnf -y install kernel-devel kernel-headers
```

因为我的机器上已经安装好了这两个包，所以执行上面的命令以后，日志如下：

```baah
$ sudo dnf -y install kernel-devel kernel-headers
[sudo] password for weli:
Last metadata expiration check: 0:14:43 ago on Wed Dec 13 06:31:19 2017.
Package kernel-devel-4.8.6-300.fc25.x86_64 is already installed, skipping.
Package kernel-headers-4.8.6-300.fc25.x86_64 is already installed, skipping.
```                                 

如上所示，这两个包已经在我的机器上安装，如果你的机器上没有安装，则会执行安装过程，并且相关的依赖都会装好。

Fedora会保证内核版本与kernel开发库的代码版本一致。我们可以用命令来确认这一点：

```bash
$ uname -a
Linux f64 4.8.6-300.fc25.x86_64 #1 SMP Tue Nov 1 12:36:38 UTC 2016 x86_64 x86_64 x86_64 GNU/Linux
```

如上所示，在运行的Kernel版本和`kernel-devel`以及`kernel-headers`一致。如果不一致，则需要使用dnf命令把kernel更新到与前两个包一致的版本。dnf命令的具体使用这里就不赘述了，可以查看Fedora Linux社区的文档来学习。

保证了安装的`kernel-devel`及`kernel-headers`版本与在运行的kernel版本一致了以后，我们来创建一个最简单的驱动程序，命名为`helloworld.c`：

```cpp
#include <linux/module.h>       /* Needed by all modules */
#include <linux/kernel.h>       /* Needed for KERN_INFO */
#include <linux/init.h>         /* Needed for the macros */

static int __init hello_start(void)
{
printk(KERN_INFO "Loading hello module...\n");
printk(KERN_INFO "Hello world\n");
return 0;
}

static void __exit hello_end(void)
{
printk(KERN_INFO "Goodbye Mr.\n");
}

module_init(hello_start);
module_exit(hello_end);
```

然后我们再创建一个`Makefile`：

```bash
# Comment/uncomment the following line to disable/enable debugging
#DEBUG = y

# Add your debugging flag (or not) to CFLAGS
ifeq ($(DEBUG),y)
  DEBFLAGS = -O -g # "-O" is needed to expand inlines
else
  DEBFLAGS = -O2
endif

EXTRA_CFLAGS += $(DEBFLAGS) #-I$(LDDINCDIR)

ifneq ($(KERNELRELEASE),)
# call from kernel build system

obj-m	:= helloworld.o

else

KERNELDIR ?= /lib/modules/$(shell uname -r)/build
PWD       := $(shell pwd)

default:
	$(MAKE) -C $(KERNELDIR) M=$(PWD) modules #LDDINCDIR=$(PWD)/../include modules

endif

clean:
	rm -rf *.o *~ core .depend .*.cmd *.ko *.mod.c .tmp_versions

depend .depend dep:
	$(CC) $(CFLAGS) -M *.c > .depend


ifeq (.depend,$(wildcard .depend))
include .depend
endif
```

创建完成后，对代码进行编辑，在上述代码所在目录执行命令如下：

```bash
make
```

编译过程如下：

```bash
make -C /lib/modules/2.6.35.6-45.fc14.i686/build M=/home/liweinan/projs modules #LDDINCDIR=/home/liweinan/projs/../include modules
make[1]: Entering directory `/usr/src/kernels/2.6.35.6-45.fc14.i686'
  CC [M]  /home/liweinan/projs/helloworld.o
  Building modules, stage 2.
  MODPOST 1 modules
  CC      /home/liweinan/projs/helloworld.mod.o
  LD [M]  /home/liweinan/projs/helloworld.ko
make[1]: Leaving directory `/usr/src/kernels/2.6.35.6-45.fc14.i686'
```

`helloworld.ko`就是我们要的module，安装它试试看：

```bash
sudo insmod helloworld.ko
```

如果安装正确则不会有消息返回。看看dmesg里面的日志：

```bash
dmesg | tail
```

可以看到下面的日志：

```bash
[109121.189628] Loading hello module...
[109121.189630] Hello world
```

说明安装成功。

「常见问题」

```bash
-1 Invalid module format
```

这个是在安装模块时可能会遇到的问题，一般是由于使用的kernel library与kernel版本不一致造成。那么可能就需要自己来编译Linux Kernel，Fedora针对内核编译也有十分方便的方法，请参考这篇文档：http://fedoraproject.org/wiki/Docs/CustomKernel

「关于Linux内核及驱动开发的一些有用资源」

- http://www.linuxquestions.org/questions/programming-9/trying-to-compile-hello-world-kernel-module-please-help-439353/

本文中样例代码的来源。

- http://kernelnewbies.org/

面向内核开发新手的网站，不少有用资源。

- http://lwn.net/Articles/2.6-kernel-api/

linux 2.6内核的新版本特性。

- http://lwn.net/Kernel/LDD3/

Linux驱动开发第三版，注意这本书里面的不少代码在最新的2.6内核已经不可用了。比如在书中的样例代码中经常见到的`linux/config.h`在2.6内核版本中已经不再存在。
