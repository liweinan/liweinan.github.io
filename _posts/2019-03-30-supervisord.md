---
title: supervisord的安装和使用（四）
abstract: 这篇讲supervisord的program配置和日志输出。
---

## {{ page.title }}

这篇讲supervisord的program配置和日志输出。

上一篇里我们配置了一个`ping`的program，这一篇，我们把program的日志输出加上。打开配置文件：

```txt
/usr/local/etc/supervisord.ini
```

调整里面`ping`的program配置如下：

```txt
[program:pingping]
command=/sbin/ping www.baidu.com
redirect_stderr=true
stdout_logfile=/tmp/pingping.log
```

注意这回加上了两行配置，分别是`redirect_stderr`和`stdout_logfile`。其中`stdout_logfile`指定程序`stdout`标准输出的内容保存位置。这里我们指定保存在`/tmp/pingping.log`文件里面。

其次，`redirect_stderr`这个设置为`true`，就是让program把`stderr`也就是错误输出也转向`stdout`，这样程序的正常输出和错误输出就都保存在`/tmp/pingping.log`里面了（关于`stdout`和`stderr`，参考这篇文章：[Understanding Shell Script’s idiom: 2>&1](https://www.brianstorti.com/understanding-shell-script-idiom-redirect/)）。

上面的配置完成后，把`supervisord`重新启动：

```bash
$ supervisord -c /usr/local/etc/supervisord.ini
```

此时查看supervisor的web管理端：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/mar30/EFCB674F-F908-4061-81B2-42DC19FA3FD7.png)

可以看到配置的`pingping`这个服务已经运行了，此时点击这个program右侧的`Tail -f`来查看日志输出：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/mar30/8C87ADBE-FF5E-4781-92CE-62D5C8297882.png)

此时可以看到持续输出的日志了：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/mar30/2019-03-30 8.28.51 AM.gif)

上面的日志输出，其实就是实际显示我们配置的`stdout_logfile `里面的内容，所以直接在终端里面使用`tail`命令来查看是一样的效果：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/mar30/2019-03-30 8.30.48 AM.gif)

可以看到supervisor把ping的输出内容不断更新保存在我们配置的`/tmp/pingping.log`里面了。

以上就是`supervisord`对日志的配置方法。它本身针对program还有大量的配置方法，具体可以查看它的官方配置文档：

* [Configuration File — Supervisor 3.3.5 documentation](http://supervisord.org/configuration.html)

以上就是`supervisord`的配置说明。


