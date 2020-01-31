---
title: supervisord的安装和使用（一）
abstract: supervisord是一个进程的管理工具，它可以控制进程的启停，管理进程的状态，可以说是很适合用在容器环境里，管理各种服务进程的有力工具。
---

## {{ page.title }}

supervisord是一个进程的管理工具，它可以控制进程的启停，管理进程的状态，可以说是很适合用在容器环境里，管理各种服务进程的有力工具。

这篇是系列文章的第一篇，简单介绍supervisord的基本安装和使用方法。

## 安装supervisord

首先是安装`supervisord`：

```bash
$ brew install supervisord
```

安装完成后，基本使用方法如下：

```bash
$ supervisord -c /usr/local/etc/supervisord.ini
```

上面的命令里使用了默认生成的配置文件`supervisord.ini`。下面是这个配置文件的内容概要：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/mar25/90A1C231-F5F2-4BC6-8878-904FDE56B345.png)

把上面的配置文件里的重要配置内容提取出来，进行具体分析。

## supervisord.ini

这个文件里的内容分为不同的sections，下面逐一讲解：

```txt
[unix_http_server]
file=/usr/local/var/run/supervisor.sock   ; the path to the socket file
```

上面这个section，定义了supervisord用来进行控制命令接收的socket文件。它自己提供的`supervisorctl`命令会通过这个配置对`supervisord`进行操作。

```txt
[inet_http_server]         ; inet (TCP) server disabled by default
port=127.0.0.1:9001        ; ip_address:port specifier, *:port for all iface
```

上面这个`inet_http_server`提供一个web页面，可以看到supervisord管理的processes运行状态，并进行操作。

```txt
[supervisord]
logfile=/usr/local/var/log/supervisord.log ; main log file; default $CWD/supervisord.log
logfile_maxbytes=50MB        ; max main logfile bytes b4 rotation; default 50MB
logfile_backups=10           ; # of main logfile backups; 0 means none, default 10
loglevel=info                ; log level; default info; others: debug,warn,trace
pidfile=/usr/local/var/run/supervisord.pid ; supervisord pidfile; default supervisord.pid
```

上面的这个section对`supervisord`进行配置，里面包含一些配置信息，比如`logfile`的位置，`pidfile`的位置等等。

```txt
[supervisorctl]
serverurl=unix:///usr/local/var/run/supervisor.sock ; use a unix:// URL  for a unix socket
```

上面的`supervisorctl`命令是`supervisord`提供的命令行管理工具。




