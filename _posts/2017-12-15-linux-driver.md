---
title: Linux驱动开发入门（三）
abstract: 做一个可读写的char设备。
---

## {{ page.title }}

（这是一篇旧文，内容有所更新。未来会把之前写过的文章慢慢整理到这个博客里面。）

{{ page.abstract }}

在上一篇文章中，我们制作了一个char设备，但是它是只读的。在这一篇文章中，我们做一个可读写的char设备。下面是设备的源代码，可以命名为`chardev_rw.c`

```c
/*
 * http://linux.die.net/lkmpg/x569.html
 * http://appusajeev.wordpress.com/2011/06/18/writing-a-linux-character-device-driver/
 */

/*
 *  chardev.c: Creates a read-only char device that says how many times
 *  you've read from the dev file
 */

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/fs.h>
#include <asm/uaccess.h>    /* for put_user */

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
#define DEVICE_NAME "cdev_rw"    /* Dev name as it appears in /proc/devices   */
#define BUF_LEN 80        /* Max length of the message from the device */

/*
 * Global variables are declared as static, so are global within the file.
 */

static int major;        /* major number assigned to our device driver */
static int device_opened = 0;    /* Is device open?
				 * Used to prevent multiple access to device */
static char my_data[BUF_LEN];    /* The msg the device will give when asked */
static char *msg_ptr;


static struct file_operations fops = {
        .read = device_read,
        .write = device_write,
        .open = device_open,
        .release = device_release
};

/*
 * This function is called when the module is loaded
 */
int init_module(void) {
    major = register_chrdev(0, DEVICE_NAME, &fops);

    if (major < 0) {
        printk(KERN_ALERT "Registering char device failed with %d\n", major);
        return major;
    }

    printk(KERN_INFO "I was assigned major number %d. To talk to\n", major);
    printk(KERN_INFO "the driver, create a dev file with\n");
    printk(KERN_INFO "'mknod /dev/%s c %d 0'.\n", DEVICE_NAME, major);
    printk(KERN_INFO "Try various minor numbers. Try to cat and echo to\n");
    printk(KERN_INFO "the device file.\n");
    printk(KERN_INFO "Remove the device file and module when done.\n");

    return SUCCESS;
}

/*
 * This function is called when the module is unloaded
 */
void cleanup_module(void) {
    /*
     * Unregister the device
     */
    unregister_chrdev(major, DEVICE_NAME);

    printk(KERN_INFO "Unregistering char device");
}

/*
 * Methods
 */

/*
 * Called when a process tries to open the device file, like
 * "cat /dev/mycharfile"
 */
static int device_open(struct inode *inode, struct file *file) {
    if (device_opened)
        return -EBUSY;

    device_opened++;
    msg_ptr = my_data;

    try_module_get(THIS_MODULE);
    printk(KERN_INFO "cdev->device_opened");
    return SUCCESS;
}

/*
 * Called when a process closes the device file.
 */
static int device_release(struct inode *inode, struct file *file) {
    device_opened--;        /* We're now ready for our next caller */

    /*
     * Decrement the usage count, or else once you opened the file, you'll
     * never get get rid of the module.
     */
    module_put(THIS_MODULE);
    printk(KERN_INFO "cdev->device_release");
    return 0;
}

/*
 * Called when a process, which already opened the dev file, attempts to
 * read from it.
 */
static ssize_t device_read(struct file *filp,    /* see include/linux/fs.h   */
                           char *buffer,    /* buffer to fill with data */
                           size_t len,    /* length of the buffer     */
                           loff_t *offset) {
    /*
     * Number of bytes actually written to the buffer
     */
    int bytes_read = 0;

    /*
     * If we're at the end of the message,
     * return 0 signifying end of file
     */
    if (*msg_ptr == 0)
        return 0;

    /*
     * Actually put the data into the buffer
     */
    while (len && *msg_ptr) {

        /*
         * The buffer is in the user data segment, not the kernel
         * segment so "*" assignment won't work.  We have to use
         * put_user which copies data from the kernel data segment to
         * the user data segment.
         */
        put_user(*(msg_ptr++), buffer++);

        len--;
        bytes_read++;
    }

    printk(KERN_INFO "cdev->device_read: %s", my_data);

    return bytes_read;

}

/*  
 * Called when a process writes to dev file: echo "hi" > /dev/hello
 */
static ssize_t
device_write(struct file *filp, const char *buff, size_t len, loff_t *off) {
    short idx = 0;
    while (idx < len) {
        my_data[idx] = buff[idx]; //copy the given string to the driver but in reverse
        idx++;
    }
    my_data[idx] = '\0';
    printk(KERN_INFO "cdev->device_write: %s", my_data);
    return len;
}
```

然后制作`Makefile`：

```bash
#Comment/uncomment the following line to disable/enable debugging
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

obj-m	:= chardev_rw.o

else

KERNELDIR ?= /lib/modules/$(shell uname -r)/build
PWD       := $(shell pwd)

default:
	$(MAKE) -C $(KERNELDIR) M=$(PWD) modules #LDDINCDIR=$(PWD)/../include modules

endif

uninstall:
	-rmmod chardev_rw.ko
	-rm /dev/cdev_rw*

reinstall: uninstall clean default
	-insmod chardev_rw.ko

clean:
	rm -rf *.order *.symvers *.o *~ core .depend .*.cmd *.ko *.mod.c .tmp_versions

depend .depend dep:
	$(CC) $(CFLAGS) -M *.c > .depend


ifeq (.depend,$(wildcard .depend))
include .depend
endif

.PHONY: uninstall clean default
```

接下来是编译这个设备：

```bash
$ make
make -C /lib/modules/4.8.6-300.fc25.x86_64/build M=/home/weli/projs/chardev_rw modules #LDDINCDIR=/home/weli/projs/chardev_rw/../include modules
make[1]: Entering directory '/usr/src/kernels/4.8.6-300.fc25.x86_64'
  CC [M]  /home/weli/projs/chardev_rw/chardev_rw.o
  Building modules, stage 2.
  MODPOST 1 modules
  CC      /home/weli/projs/chardev_rw/chardev_rw.mod.o
  LD [M]  /home/weli/projs/chardev_rw/chardev_rw.ko
make[1]: Leaving directory '/usr/src/kernels/4.8.6-300.fc25.x86_64'
```

然后是加载编译好的`.ko`文件：

```bash
$ sudo insmod chardev_rw.ko
[sudo] password for weli:
```

加载后，用`dmesg`命令查看一下设备输出的日志：

```bash
$ dmesg | tail -n 6
[13892.634944] I was assigned major number 245. To talk to
[13892.634945] the driver, create a dev file with
[13892.634946] 'mknod /dev/cdev_rw c 245 0'.
[13892.634946] Try various minor numbers. Try to cat and echo to
[13892.634946] the device file.
[13892.634947] Remove the device file and module when done.
```

从日志里得到了设备号以后，就可以挂装这个设备：

```bash
$ sudo mknod /dev/cdev_rw c 245 0
```

为了向这个设备写入内容，我们要变更一下设备文件的权限，让所有人可读写：

```bash
$ sudo chmod a+rw /dev/cdev_rw
```

确认一下`cdev_rw`文件已经设定好:

```bash
$ ls -l /dev/cdev_rw
crw-rw-rw- 1 root root 245, 0 Dec 15 19:54 /dev/cdev_rw
```

设置好了设备文件，我们往设备里面写入字串试试看：

```bash
$ echo "Hello, world!" > /dev/cdev_rw
```

此时查看Linux的内核输出：

```bash
[ 1843.529688] cdev->device_opened
[ 1843.529698] cdev->device_write: Hello, world!
```

从上面的日志可以看到，我们的数据已经写入设备的`my_data`这一小块内存里面去了。但是此时的日志中没有`device_release()`的日志输出，说明内核还没有调用`device_close()`函数。也就是说，内核并没有在执行完`device_open()`，`device_write()`后马上执行`device_release()`。

接下来我们读这个设备：

```bash
$ cat /dev/cdev_rw
Hello, world!
```

此时我们写入内核的数据被读出来了。此时查看内核的日志：

```bash
[ 1843.529688] cdev->device_opened
[ 1843.529698] cdev->device_write: Hello, world!
[ 1843.529701] cdev->device_release
[ 2236.527340] cdev->device_opened
[ 2236.527349] cdev->device_read: Hello, world!
```
