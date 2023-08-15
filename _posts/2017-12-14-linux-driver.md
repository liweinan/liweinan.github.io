---
title: Linux驱动开发入门（二）
abstract: 本文制作一个char设备。
---



（这是一篇旧文，内容有所更新。未来会把之前写过的文章慢慢整理到这个博客里面。）

{{ page.abstract }}

撰写`chardev.c`如下：

```c
/*
 * http://linux.die.net/lkmpg/x569.html
 */

/*
 *  chardev.c: Creates a read-only char device that says how many times
 *  you've read from the dev file
 */

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/fs.h>
#include <asm/uaccess.h>        /* for put_user */

/*  
 *  Prototypes - this would normally go in a .h file
 */
int init_module(void);
void cleanup_module(void);
static int device_open(struct inode *, struct file *);
static int device_release(struct inode *, struct file *);
static ssize_t device_read(struct file *, char *, size_t, loff_t *);
static ssize_t device_write(struct file *, const char *, size_t, loff_t *);

#define SUCCESS 0
#define DEVICE_NAME "chardev"   /* Dev name as it appears in /proc/devices   */
#define BUF_LEN 80              /* Max length of the message from the device */

/*
 * Global variables are declared as static, so are global within the file.
 */

static int Major;               /* Major number assigned to our device driver */
static int Device_Open = 0;     /* Is device open?  
								 * Used to prevent multiple access to device */
static char msg[BUF_LEN];       /* The msg the device will give when asked */
static char *msg_Ptr;

static struct file_operations fops = {
		.read = device_read,
		.write = device_write,
		.open = device_open,
		.release = device_release
};

/*
 * This function is called when the module is loaded
 */
int init_module(void)
{
		Major = register_chrdev(0, DEVICE_NAME, &fops);

		if (Major < 0) {
		  printk(KERN_ALERT "Registering char device failed with %d\n", Major);
		  return Major;
		}

		printk(KERN_INFO "I was assigned major number %d. To talk to\n", Major);
		printk(KERN_INFO "the driver, create a dev file with\n");
		printk(KERN_INFO "'mknod /dev/%s c %d 0'.\n", DEVICE_NAME, Major);
		printk(KERN_INFO "Try various minor numbers. Try to cat and echo to\n");
		printk(KERN_INFO "the device file.\n");
		printk(KERN_INFO "Remove the device file and module when done.\n");

		return SUCCESS;
}

/*
 * This function is called when the module is unloaded
 */
void cleanup_module(void)
{
		/*
		 * Unregister the device
		 */
		unregister_chrdev(Major, DEVICE_NAME);
}

/*
 * Methods
 */

/*
 * Called when a process tries to open the device file, like
 * "cat /dev/mycharfile"
 */
static int device_open(struct inode *inode, struct file *file)
{
		static int counter = 0;

		if (Device_Open)
				return -EBUSY;

		Device_Open++;
		sprintf(msg, "I already told you %d times Hello world!\n", counter++);
		msg_Ptr = msg;
		try_module_get(THIS_MODULE);

		return SUCCESS;
}

/*
 * Called when a process closes the device file.
 */
static int device_release(struct inode *inode, struct file *file)
{
		Device_Open--;          /* We're now ready for our next caller */

		/*
		 * Decrement the usage count, or else once you opened the file, you'll
		 * never get get rid of the module.
		 */
		module_put(THIS_MODULE);

		return 0;
}

/*
 * Called when a process, which already opened the dev file, attempts to
 * read from it.
 */
static ssize_t device_read(struct file *filp,   /* see include/linux/fs.h   */
						   char *buffer,        /* buffer to fill with data */
						   size_t length,       /* length of the buffer     */
						   loff_t * offset)
{
		/*
		 * Number of bytes actually written to the buffer
		 */
		int bytes_read = 0;

		/*
		 * If we're at the end of the message,
		 * return 0 signifying end of file
		 */
		if (*msg_Ptr == 0)
				return 0;

		/*
		 * Actually put the data into the buffer
		 */
		while (length && *msg_Ptr) {

				/*
				 * The buffer is in the user data segment, not the kernel
				 * segment so "*" assignment won't work.  We have to use
				 * put_user which copies data from the kernel data segment to
				 * the user data segment.
				 */
				put_user(*(msg_Ptr++), buffer++);

				length--;
				bytes_read++;
		}

		/*
		 * Most read functions return the number of bytes put into the buffer
		 */
		return bytes_read;
}

/*  
 * Called when a process writes to dev file: echo "hi" > /dev/hello
 */
static ssize_t
device_write(struct file *filp, const char *buff, size_t len, loff_t * off)
{
		printk(KERN_ALERT "Sorry, this operation isn't supported.\n");
		return -EINVAL;
}
```

然后撰写Makefile：

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

obj-m   := chardev.o

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

接下来是生成目标文件：

```bash
$ make
make -C /lib/modules/4.8.6-300.fc25.x86_64/build M=/home/weli/projs/learn-module modules #LDDINCDIR=/home/weli/projs/learn-module/../include modules
make[1]: Entering directory '/usr/src/kernels/4.8.6-300.fc25.x86_64'
  CC [M]  /home/weli/projs/learn-module/chardev.o
  Building modules, stage 2.
  MODPOST 1 modules
  CC      /home/weli/projs/learn-module/chardev.mod.o
  LD [M]  /home/weli/projs/learn-module/chardev.ko
make[1]: Leaving directory '/usr/src/kernels/4.8.6-300.fc25.x86_64'
```

然后是安装驱动，并查看内核的日志输出：

```bash
$ sudo insmod chardev.ko
[sudo] password for weli:
```

```bash
$ dmesg | grep -C 3 chardev
[183424.545073] usblp 1-2:1.0: usblp0: USB Unidirectional printer dev 8 if 0 alt 0 proto 1 vid 0x203A pid 0xFFFA
[188134.526704] I was assigned major number 244. To talk to
[188134.526706] the driver, create a dev file with
[188134.526706] 'mknod /dev/chardev c 244 0'.
[188134.526707] Try various minor numbers. Try to cat and echo to
[188134.526707] the device file.
[188134.526707] Remove the device file and module when done.
```

看到驱动已经成功加载了，并且给出了信息，设备号是`244 0`。这个设备号在你的机器上可能会不一样，因为是动态分配的，要记录下来，等下用。

此时查看设备列表：

```bash
$ cat /proc/devices | grep chardev
244 chardev
```

可以看到设备已经加载了。此时使用`mknod`在dev中安装这个`chardev`设备：

```bash
$ sudo mknod /dev/chardev0 c 244 0
[sudo] password for weli:
```

此时已经可以使用这个设备了：

```bash
$ cat /dev/chardev0
I already told you 1 times Hello world!
$ cat /dev/chardev0
I already told you 2 times Hello world!
$ cat /dev/chardev0
I already told you 3 times Hello world!
$
```

测试完成后，删除设备并卸载驱动：

```bash
$ sudo rm /dev/chardev0
$ sudo rmmod chardev
```

至此，我们过了一遍驱动模块的制作，装载，卸载的流程。
