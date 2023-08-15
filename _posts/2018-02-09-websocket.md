---
title: 玩转WebSocket（上）
abstract: 这篇讲解websocket的使用。
---



这篇讲解websocket的使用。

首先是安装`nodejs`的`websocket`模块：

```bash
$ npm install nodejs-websocket 
```

如果你是在MacOS下，可以用Homebrew来安装ruby和nodejs：

```bash
$ brew install ruby
```

```bash
$ brew install nodejs
```

安装完成后，撰写下述服务端js代码，并将文件命名为`ws.js`：

```javascript
var ws = require("nodejs-websocket")

var server = ws.createServer(function (conn) {
    console.log("New connection")
    conn.on("text", function (str) {
        console.log("Received " + str)
        conn.sendText(str.toUpperCase() + "!!!")
    })
    conn.on("close", function (code, reason) {
        console.log("Connection closed")
    })
}).listen(8088)
```

可以看一下上面代码的逻辑，然后启动上面的服务：

```bash
$ node ws.js
```

接下来就是撰写ws客户端，可以使用ruby来实现客户端。

首先用`gem`来安装`faye-websocket`，用于测试：

```bash
$ gem install faye-websocket
```

客户端测试代码如下：

```ruby
require 'faye/websocket'
require 'eventmachine'

EM.run {
    ws = Faye::WebSocket::Client.new('ws://127.0.0.1:8088/')

    ws.on :open do |event|
        p [:open]
        ws.send('Hello, Martian!')
    end

    ws.on :message do |event|
        p [:message, event.data]
    end

    ws.on :close do |event|
        p [:close, event.code, event.reason]
        ws = nil
    end
}
```

执行上面的客户端代码，输出如下：

```bash
$ ruby ws-client.rb
[:open]
[:message, "HELLO, MARTIAN!!!!"]
```

此时服务端的输出如下：

```bash
$ node ws.js
New connection
Received Hello, Martian!
``` 

本篇讲解了websocket的工作流程，下篇中将介绍如何使用httpd来做nodejs的ws服务的代理。
