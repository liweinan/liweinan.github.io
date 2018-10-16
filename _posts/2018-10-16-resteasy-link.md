---
title: resteasy-link中RESTEasyServiceDiscovery的功用
abstract: 分析`RESTEasyServiceDiscovery`的功能。
---

# {{ page.title }}

分析`RESTEasyServiceDiscovery`的功能。

使用resteasy的源代码自带的`TestLinks.testLinks()`：

![]({{ site.url }}/assets/6AF4FC21-6786-4893-9C43-87B9952BA3EC.png)

在上面的测试代码里加了一行：

```java
Thread.currentThread().join();
```

这样服务端可以保持运行。此时向服务器发起请求：

```bash
$ http http://127.0.0.1:8081/book/foo
```

可以得到运行结果：

```bash
HTTP/1.1 200 OK
Content-Type: application/xml;charset=UTF-8
connection: keep-alive
transfer-encoding: chunked

<?xml version="1.0" encoding="UTF-8" standalone="yes"?><book xmlns:atom="http://www.w3.org/2005/Atom" author="bar" title="foo"><rest rel="update" href="http://127.0.0.1:8081/book/foo"/><rest rel="remove" href="http://127.0.0.1:8081/book/foo"/><rest rel="self" href="http://127.0.0.1:8081/book/foo"/><rest rel="add" href="http://127.0.0.1:8081/books"/><rest rel="list" href="http://127.0.0.1:8081/books"/><rest rel="comment-collection" href="http://127.0.0.1:8081/book/foo/comment-collection"/><rest rel="comments" href="http://127.0.0.1:8081/book/foo/comments"/></book>
```

把XML数据给格式化一下：

```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<book xmlns:atom="http://www.w3.org/2005/Atom" author="bar" title="foo">
    <rest rel="update" href="http://127.0.0.1:8081/book/foo"/>
    <rest rel="remove" href="http://127.0.0.1:8081/book/foo"/>
    <rest rel="self" href="http://127.0.0.1:8081/book/foo"/>
    <rest rel="add" href="http://127.0.0.1:8081/books"/>
    <rest rel="list" href="http://127.0.0.1:8081/books"/>
    <rest rel="comment-collection" href="http://127.0.0.1:8081/book/foo/comment-collection"/>
    <rest rel="comments" href="http://127.0.0.1:8081/book/foo/comments"/>
</book>
```

也可以请求json格式的数据：

```bash
$ http -v --json http://127.0.0.1:8081/book/foo

GET /book/foo HTTP/1.1
Accept: application/json, */*
Accept-Encoding: gzip, deflate
Connection: keep-alive
Content-Type: application/json
Host: 127.0.0.1:8081
User-Agent: HTTPie/0.9.9

HTTP/1.1 200 OK
Content-Type: application/json
connection: keep-alive
transfer-encoding: chunked

{
    "book": {
        "@author": "bar",
        "@title": "foo",
        "rest": [
            {
                "@href": "http://127.0.0.1:8081/book/foo",
                "@rel": "update"
            },
            {
                "@href": "http://127.0.0.1:8081/book/foo",
                "@rel": "remove"
            },
            {
                "@href": "http://127.0.0.1:8081/book/foo",
                "@rel": "self"
            },
            {
                "@href": "http://127.0.0.1:8081/books",
                "@rel": "add"
            },
            {
                "@href": "http://127.0.0.1:8081/books",
                "@rel": "list"
            },
            {
                "@href": "http://127.0.0.1:8081/book/foo/comment-collection",
                "@rel": "comment-collection"
            },
            {
                "@href": "http://127.0.0.1:8081/book/foo/comments",
                "@rel": "comments"
            }
        ]
    }
}

$
```

上面的数据当中，`update`，`remove`，`self`，`add`……这些是定义在`@LinkResource`里面的：

![]({{ site.url }}/assets/9F96EA36-FD02-4E98-BC39-CCF73CD52855.png)

上面的"`TestLinks.testLinks()`这个testcase涉及到两个classes，分别是`Book`和`Comment`：

Class Diagram14.png

可以看到，`Book`包含`Comment`，而这两个classes里面都包含`RESTServiceDiscovery`。

这个`RESTServiceDiscovery`会按照convention，像上面给出的XML和JSON数据一样，默认生成一套URLs。如果我们去掉`Book`里面的`rest`，就可以看到差别。把`Book`里面的`rest`注释掉：

![]({{ site.url }}/assets/D7F5F140-C249-417E-B314-A097EA4DBFBB.png)

注释掉`rest`后，重新启动测试：

![]({{ site.url }}/assets/0612C1AB-184E-41DF-A366-9D5569EEA717.png)

![]({{ site.url }}/assets/C6B5CFCB-3DF0-44DD-ADB8-2FF039A54960.png)

测试启动后，重新进行请求：

```bash
$ http -v --json http://127.0.0.1:8081/book/foo
GET /book/foo HTTP/1.1
Accept: application/json, */*
Accept-Encoding: gzip, deflate
Connection: keep-alive
Content-Type: application/json
Host: 127.0.0.1:8081
User-Agent: HTTPie/0.9.9



HTTP/1.1 200 OK
Content-Type: application/json
connection: keep-alive
transfer-encoding: chunked

{
    "book": {
        "@author": "bar",
        "@title": "foo"
    }
}

$
```

可以看到只剩下`Book`自身的信息。比对前后的区别：

![]({{ site.url }}/assets/D2DB50AF-16C1-4DF2-A2C3-4AB429A002A8.png)

可以看到`rest`为我们默认添加了一些资源链接，同时`comment`的相关操作地址也加进来了。

注意`RESTServiceDiscovery`是自动生成一套atom links，而不管你的服务有没有实现这些links。比如我们可以测试其中一个url：

```bash
$ http --json --pretty all http://127.0.0.1:8081/book/comments
HTTP/1.1 204 No Content
connection: keep-alive
```

可以看到这个link并没有被我们的service实现。

∎
