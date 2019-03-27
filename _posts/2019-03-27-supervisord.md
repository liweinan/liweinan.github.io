---
title: supervisord的安装和使用（三）
abstract: 这篇的内容讲一讲supervisord的web管理端。
---

## {{ page.title }}

这篇的内容讲一讲supervisord的web管理端。

在`supervisord`的配置文件`/usr/local/etc/supervisord.ini`里面，可以打开它自己提供的web管理端：

```txt
[inet_http_server]         ; inet (TCP) server disabled by default
port=127.0.0.1:9001        ; ip_address:port specifier, *:port for all iface
```

这样，`supervisord`就会在`127.0.0.1`的`9001`端口提供一个web管理端。此时启动`supervisord`的服务：

```bash
$ supervisord -c /usr/local/etc/supervisord.ini
```

然后在浏览器打开`supervisord`提供的管理地址：

```url
http://127.0.0.1:9001
```

显示页面如下：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/mar27/D2C84976-1C62-4E66-9A6B-5261519574B3.png)

可以看到`supervisor`提供的一个web管理页面。可以看到`supervisor`还没有管理任何的服务进程，我们需要添加一个需要管理的program。

可以用`ping`命令来作为需要管理的服务：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/mar27/2019-03-27 10.16.08 AM.gif)

`ping`命令会保持在前台持续运行，并且一直输出日志，因此适合用来当作需要管理的服务的demo。下面是`/usr/local/etc/supervisord.ini`里面需要添加的配置：

```txt
[program:ping_baidu]
command=/sbin/ping www.baidu.com
```

注意在`supervisor`里面，要使用命令的完整路径，比如上面的`/sbin/ping`。完成配置后，保存配置文件。此时kill掉`supervisord`的服务：

```bash
$ ps -ef  |grep supervisord
  501 73176     1   0 Tue09AM ??         0:18.47 /usr/local/Cellar/supervisor/3.3.5/libexec/bin/python2.7 /usr/local/bin/supervisord -c /usr/local/etc/supervisord.ini
  501 86868 85645   0 10:44AM ttys001    0:00.01 grep supervisord
$ kill 73176
```

然后重新启动服务：

```bash
$ supervisord -c /usr/local/etc/supervisord.ini
```

此时查看web管理页面：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/mar27/BD0D36F0-7925-40E1-B2B6-932A8245B573.png)

可以看到`ping_baidu`这个服务了，并且在`Action`这边可以看到一些操作，比如`Restart`，`Stop`等等。

以上是对`supervisor`的web管理端的介绍。

∎


