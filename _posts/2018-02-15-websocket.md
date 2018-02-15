---
title: 玩转WebSocket（下）
abstract: 这篇对websocket进行协议分析，并介绍如何使用httpd做为websocket的代理。
---

## {{ page.title }}

接上篇，我们看一下客户端和服务端的通信数据。客户端和服务端的数据通信过程可以用Wireshark来捕获：

![]({{ site.url }}/assets/51594ce5b0f741aeaa7e5e5004578771.png)

如图中所示，我们可以看到websocket的upgrade请求：

```txt
GET / HTTP/1.1
Host: 127.0.0.1:8088
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Key: lkUx3lTpjFwO5OI7xY3+1Q==
Sec-WebSocket-Version: 13
```

然后服务端处理了这个upgrade请求并返回给客户端如下内容：

```txt
HTTP/1.1 101 Switching Protocols
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Accept: 2T9o4TGeL7V6QJ/PnOsqmx4nEBk=
```

接下来就是实际的websocket数据传输阶段：

![]({{ site.url }}/assets/f80cca51665d472bad965711bde8bccf.png)

通过上面的分析过程我们可以粗略理解websocket的通信过程。特别是理解了websocket的初始请求协议格式，我们可以用cURL来手动组装一个请求：

```bash
$ curl -v -i -N -H "Connection: Upgrade" -H "Upgrade: websocket" -H "Host: 127.0.0.1:8088" -H "Sec-WebSocket-Key: lkUx3lTpjFwO5OI7xY3+1Q==" -H "Sec-WebSocket-Version: 13" http://127.0.0.1:8088/
* Hostname was NOT found in DNS cache
*   Trying 127.0.0.1...
* Connected to 127.0.0.1 (127.0.0.1) port 8088 (#0)
> GET / HTTP/1.1
> User-Agent: curl/7.37.1
> Accept: */*
> Connection: Upgrade
> Upgrade: websocket
> Host: 127.0.0.1:8088
> Sec-WebSocket-Key: lkUx3lTpjFwO5OI7xY3+1Q==
> Sec-WebSocket-Version: 13
>
< HTTP/1.1 101 Switching Protocols
HTTP/1.1 101 Switching Protocols
< Upgrade: websocket
Upgrade: websocket
< Connection: Upgrade
Connection: Upgrade
< Sec-WebSocket-Accept: 2T9o4TGeL7V6QJ/PnOsqmx4nEBk=
Sec-WebSocket-Accept: 2T9o4TGeL7V6QJ/PnOsqmx4nEBk=
```

通过上面的cURL命令，我们自己撰写了所需的HTTP Header来提交一个websocket初始化请求。可以看到服务端接受了这个请求并返回了`Sec-WebSocket-Accept`。

> 使用httpd作为nodejs的websocket服务代理

从httpd2.4开始，加入了一个新的模块叫做`mod_proxy_wstunnel`。它可以把websocket请求转到实际的websocket服务器。因此我们可以使用httpd2.4来转发请求至nodejs的websocket服务。

首先要在httpd中打开`mod_proxy_wstunnel`模块：

```txt
LoadModule proxy_wstunnel_module modules/mod_proxy_wstunnel.so
```

然后是设置将指向httpd的`/ws`位置的请求转发至nodejs的websocket服务：

```txt
ProxyPass /ws/  ws://127.0.0.1:8088/
ProxyPassReverse /ws/  ws://127.0.0.1:8088/
```

最后将httpd的日志级别调为debug方便调试：

```txt
LogLevel debug
```

然后我们将ruby写的客户端代码改一下，把地址从直接访问nodejs的websocket服务变成访问http的代理地址：

```txt
ws = Faye::WebSocket::Client.new('http://127.0.0.1/ws/')
```

启动httpd服务后，执行客户端代码：

```bash
$ ruby ws-client.rb
[:open]
[:message, "HELLO, MARTIAN!!!!"]
```

可以看到请求被正确转发至后端的nodejs服务，并且从httpd的代理得到了返回结果。下面是httpd的日志：

```txt
[Mon Jan 12 22:50:57.097895 2015] [proxy_wstunnel:debug] [pid 23014] mod_proxy_wstunnel.c(331): [client 127.0.0.1:46872] AH02451: serving URL ws://127.0.0.1:8088/
[Mon Jan 12 22:50:57.097902 2015] [proxy:debug] [pid 23014] proxy_util.c(2020): AH00942: WS: has acquired connection for (127.0.0.1)
[Mon Jan 12 22:50:57.097933 2015] [proxy:debug] [pid 23014] proxy_util.c(2072): [client 127.0.0.1:46872] AH00944: connecting ws://127.0.0.1:8088/ to 127.0.0.1:8088
[Mon Jan 12 22:50:57.098021 2015] [proxy:debug] [pid 23014] proxy_util.c(2194): [client 127.0.0.1:46872] AH00947: connected / to 127.0.0.1:8088
[Mon Jan 12 22:50:57.098225 2015] [proxy:debug] [pid 23014] proxy_util.c(2598): AH00962: WS: connection complete to 127.0.0.1:8088 (127.0.0.1)
```

从日志中我们可以看到`mod_proxy_wstunnel`的工作过程。

> 小结

这篇文章我们粗略了解了websocket协议的工作原理，并且用nodejs作为websocket服务端，ruby撰写的客户端，以及httpd作为websocket代理实际部署了一个websocket的使用场景。本文可以作为学习websocket的一个起始点，希望对大家有所帮助。

