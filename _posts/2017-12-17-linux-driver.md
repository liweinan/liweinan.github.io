---
title: Linux驱动开发入门（四）
abstract: 这篇文章讲讲如何获取设备的minor number。
---

## {{ page.title }}

（从这篇文章开始，不是旧文了，把这个系列做下去，写点新东西）

{{ page.abstract }}

这篇文章里学习内核里面一些和设备相关的数据结构。首先是`file_operations`的定义，可以在`linux/fs.h`[^1]里面找到。下面是相关定义：

```c
struct file_operations {
	struct module *owner;
	loff_t (*llseek) (struct file *, loff_t, int);
	ssize_t (*read) (struct file *, char __user *, size_t, loff_t *);
	ssize_t (*write) (struct file *, const char __user *, size_t, loff_t *);
	ssize_t (*read_iter) (struct kiocb *, struct iov_iter *);
	ssize_t (*write_iter) (struct kiocb *, struct iov_iter *);
	int (*iterate) (struct file *, struct dir_context *);
	int (*iterate_shared) (struct file *, struct dir_context *);
	unsigned int (*poll) (struct file *, struct poll_table_struct *);
	long (*unlocked_ioctl) (struct file *, unsigned int, unsigned long);
	long (*compat_ioctl) (struct file *, unsigned int, unsigned long);
	int (*mmap) (struct file *, struct vm_area_struct *);
	int (*open) (struct inode *, struct file *);
	int (*flush) (struct file *, fl_owner_t id);
	int (*release) (struct inode *, struct file *);
	int (*fsync) (struct file *, loff_t, loff_t, int datasync);
	int (*fasync) (int, struct file *, int);
	int (*lock) (struct file *, int, struct file_lock *);
	ssize_t (*sendpage) (struct file *, struct page *, int, size_t, loff_t *, int);
	unsigned long (*get_unmapped_area)(struct file *, unsigned long, unsigned long, unsigned long, unsigned long);
	int (*check_flags)(int);
	int (*flock) (struct file *, int, struct file_lock *);
	ssize_t (*splice_write)(struct pipe_inode_info *, struct file *, loff_t *, size_t, unsigned int);
	ssize_t (*splice_read)(struct file *, loff_t *, struct pipe_inode_info *, size_t, unsigned int);
	int (*setlease)(struct file *, long, struct file_lock **, void **);
	long (*fallocate)(struct file *file, int mode, loff_t offset,
			  loff_t len);
	void (*show_fdinfo)(struct seq_file *m, struct file *f);
#ifndef CONFIG_MMU
	unsigned (*mmap_capabilities)(struct file *);
#endif
	ssize_t (*copy_file_range)(struct file *, loff_t, struct file *,
			loff_t, size_t, unsigned int);
	int (*clone_file_range)(struct file *, loff_t, struct file *, loff_t,
			u64);
	ssize_t (*dedupe_file_range)(struct file *, u64, u64, struct file *,
			u64);
}
```

在上面的定义当中，可以看到我们在上一篇文章的代码当中用到的几个定义：

```c
...
ssize_t (*read) (struct file *, char __user *, size_t, loff_t *);
ssize_t (*write) (struct file *, const char __user *, size_t, loff_t *);
int (*open) (struct inode *, struct file *);
...
```

在上面的定义里，可以看到`open()`函数接受的第一个参数是`inode`类型的。`inode`的定义也在`linux/fs.h`里面，代码如下：

```c
/*
 * Keep mostly read-only and often accessed (especially for
 * the RCU path lookup and 'stat' data) fields at the beginning
 * of the 'struct inode'
 */
struct inode {
	umode_t			i_mode;
	unsigned short		i_opflags;
	kuid_t			i_uid;
	kgid_t			i_gid;
	unsigned int		i_flags;

#ifdef CONFIG_FS_POSIX_ACL
	struct posix_acl	*i_acl;
	struct posix_acl	*i_default_acl;
#endif

	const struct inode_operations	*i_op;
	struct super_block	*i_sb;
	struct address_space	*i_mapping;

#ifdef CONFIG_SECURITY
	void			*i_security;
#endif

	/* Stat data, not accessed from path walking */
	unsigned long		i_ino;
	/*
	 * Filesystems may only read i_nlink directly.  They shall use the
	 * following functions for modification:
	 *
	 *    (set|clear|inc|drop)_nlink
	 *    inode_(inc|dec)_link_count
	 */
	union {
		const unsigned int i_nlink;
		unsigned int __i_nlink;
	};
	dev_t			i_rdev;
	loff_t			i_size;
	struct timespec		i_atime;
	struct timespec		i_mtime;
	struct timespec		i_ctime;
	spinlock_t		i_lock;	/* i_blocks, i_bytes, maybe i_size */
	unsigned short          i_bytes;
	unsigned int		i_blkbits;
	enum rw_hint		i_write_hint;
	blkcnt_t		i_blocks;

#ifdef __NEED_I_SIZE_ORDERED
	seqcount_t		i_size_seqcount;
#endif

	/* Misc */
	unsigned long		i_state;
	struct rw_semaphore	i_rwsem;

	unsigned long		dirtied_when;	/* jiffies of first dirtying */
	unsigned long		dirtied_time_when;

	struct hlist_node	i_hash;
	struct list_head	i_io_list;	/* backing dev IO list */
#ifdef CONFIG_CGROUP_WRITEBACK
	struct bdi_writeback	*i_wb;		/* the associated cgroup wb */

	/* foreign inode detection, see wbc_detach_inode() */
	int			i_wb_frn_winner;
	u16			i_wb_frn_avg_time;
	u16			i_wb_frn_history;
#endif
	struct list_head	i_lru;		/* inode LRU list */
	struct list_head	i_sb_list;
	struct list_head	i_wb_list;	/* backing dev writeback list */
	union {
		struct hlist_head	i_dentry;
		struct rcu_head		i_rcu;
	};
	u64			i_version;
	atomic_t		i_count;
	atomic_t		i_dio_count;
	atomic_t		i_writecount;
#ifdef CONFIG_IMA
	atomic_t		i_readcount; /* struct files open RO */
#endif
	const struct file_operations	*i_fop;	/* former ->i_op->default_file_ops */
	struct file_lock_context	*i_flctx;
	struct address_space	i_data;
	struct list_head	i_devices;
	union {
		struct pipe_inode_info	*i_pipe;
		struct block_device	*i_bdev;
		struct cdev		*i_cdev;
		char			*i_link;
		unsigned		i_dir_seq;
	};

	__u32			i_generation;

#ifdef CONFIG_FSNOTIFY
	__u32			i_fsnotify_mask; /* all events this inode cares about */
	struct fsnotify_mark_connector __rcu	*i_fsnotify_marks;
#endif

#if IS_ENABLED(CONFIG_FS_ENCRYPTION)
	struct fscrypt_info	*i_crypt_info;
#endif

	void			*i_private; /* fs or device private pointer */
};
```

在`inode`的结构定义当中，所包含的这两个类型的数据是我们在写驱动的时候要经常用到的：

```c
dev_t			i_rdev;
struct cdev		*i_cdev;
```

上面这两个类型的数据里面，其中`dev_t i_rdev`包含了设备的major number和minor number，然后`cdev`类型的数据包含了char device的相关信息。

这篇文章我们可以使用一下`i_rdev`，从里面取得我们的char device的minor number。重复使用上一篇文章里面的`chardev_rw.c`，在里面的`device_open()`函数中加入一行：

```c
printk(KERN_INFO "minor number: %d", (int) MINOR(inode->i_rdev));
```

如上所示，我们使用`MINOR` macro从`inode->i_rdev`里面拿到设备的minor number。这个`MINOR` macro定义在`linux/kdev_t.h`[^2]当中，代码如下：

```c
#define MINORBITS	20
#define MINORMASK	((1U << MINORBITS) - 1)

#define MAJOR(dev)	((unsigned int) ((dev) >> MINORBITS))
#define MINOR(dev)	((unsigned int) ((dev) & MINORMASK))
#define MKDEV(ma,mi)	(((ma) << MINORBITS) | (mi))
```

从上面的代码中可以看到，设备的major号和minor号一起保存在`dev`这个数据里面，也就是传入的`i_rdev`。然后，`MAJOR`就是从`dev`里面取出`MINORBITS`这么多bit的数据，作为major number，然后`MINOR`就是从`dev`剩下的bits里面取出。

通过`MINORBITS`的定义，可以知道major number占用`dev`的20bit数据，而`dev`本身是`unsigned int`类型，总共32 bits(4 bytes)，所以minor number就是剩下的16 bits。

理解了这些macro定义后，我们重新编译并加载`chardev_rw`这个设备，命令如下：

```bash
$ sudo make reinstall
[sudo] password for weli:
rmmod chardev_rw.ko
rm /dev/cdev_rw*
rm -rf *.order *.symvers *.o *~ core .depend .*.cmd *.ko *.mod.c .tmp_versions
make -C /lib/modules/4.8.6-300.fc25.x86_64/build M=/home/weli/projs/chardev_rw modules #LDDINCDIR=/home/weli/projs/chardev_rw/../include modules
make[1]: Entering directory '/usr/src/kernels/4.8.6-300.fc25.x86_64'
  CC [M]  /home/weli/projs/chardev_rw/chardev_rw.o
  Building modules, stage 2.
  MODPOST 1 modules
  CC      /home/weli/projs/chardev_rw/chardev_rw.mod.o
  LD [M]  /home/weli/projs/chardev_rw/chardev_rw.ko
make[1]: Leaving directory '/usr/src/kernels/4.8.6-300.fc25.x86_64'
insmod chardev_rw.ko
```

完成`insmod`以后，再重新建立设备文件。因为设备重新加载以后的设备号会有变化，所以要在`dmesg`里面查看一下这个设备的输出，看看新的设备号：

```bash
$ dmesg
...
[171416.747881] Unregistering char device
[171417.961331] I was assigned major number 245. To talk to
[171417.961334] the driver, create a dev file with
[171417.961335] 'mknod /dev/cdev_rw c 245 0'.
[171417.961335] Try various minor numbers. Try to cat and echo to
[171417.961335] the device file.
[171417.961335] Remove the device file and module when done.
```

我这次得到的设备号仍然是`245`，于是就照着上面日志里给出的命令创建设备文件，但是这次要使用不同的minor number试试看：

```bash
$ sudo mknod /dev/cdev_rw c 245 12
```

如上所示，我这回建立了一个minor number为`12`的设备文件。读取一下这个设备文件：

```bash
$ cat /dev/cdev_rw
```

然后查看内核输出：

```bash
$ dmesg
...
[172150.075141] cdev->device_opened
[172150.075144] minor number: 12
```

可以看到，通过读取设备，我们调用了`device_opened()`函数，激活了里面的关于`MINOR` macro的输出，然后得到了设备的minor number。






[^1]: http://elixir.free-electrons.com/linux/latest/source/include/linux/fs.h#L565
[^2]: https://github.com/torvalds/linux/blob/master/include/linux/kdev_t.h
