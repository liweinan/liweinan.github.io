---
title: supervisord的安装和使用（二）
abstract: 这篇讲解supervisord的基本使用。
---

## {{ page.title }}

上一篇文章里讲了`supervisord`的安装和配置文件，这篇讲解`supervisord`的基本使用方法。

`supervisord`主要用来管理需要长期运行的进程，比如webserver的服务进程，数据库的服务进程等等。最简单的例子可以用`cat`命令来展示，因为`cat`命令会等待用户输入，保持运行在前端：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/mar26/2019-03-26 9.21.51 AM.gif)

因此可以用`cat`命令模拟一个保持运行的服务。然后就是用`supervisord`把这个服务进程给管理起来。

用`supervisord`管理这个服务的方法，是在`supervisord.ini`里面添加和配置这个process。具体的配置如下：

```bash
[program:foo]
command=/bin/cat
```

上面就是`supervisored`的一个基本的进程管理单元，我们配置这个服务叫`foo`，然后它对应的具体的命令是`/bin/cat`。配置好以后，我们可以把`supervisord`的服务启动起来：

```bash
$ supervisord -c /usr/local/etc/supervisord.ini
```

此时可以查看服务是否运行：

```bash
$ ps -xj | head -n 1 ; ps -ef | grep supervisord | grep -v grep
USER   PID  PPID  PGID   SESS JOBC STAT   TT       TIME COMMAND
  501 73176     1   0  9:35AM ??         0:00.02 /usr/local/Cellar/supervisor/3.3.5/libexec/bin/python2.7 /usr/local/bin/supervisord -c /usr/local/etc/supervisord.ini
```

可以看到`supervisord`的进程运行了，并且它的`ppid`，也就是`parentId`是`1`，因此可以判断它自身是个daemon process。此时可以用`supervisorctl`来查看它所管理的进程的状态：

```bash
$ supervisorctl -c /usr/local/etc/supervisord.ini status
foo                              RUNNING   pid 73177, uptime 0:05:45
```

可以看到我们配置的`foo`这个服务，已经是`RUNNING`状态。我们还可以通过`supervisorctl`控制`foo`的启停：

```bash
$ supervisorctl -c /usr/local/etc/supervisord.ini stop foo
foo: stopped
```

此时可以看见`foo`这个服务被停止了。

以上就是`supervisord`和`supervisorctl`的基本使用方法。


