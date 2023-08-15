---
title: resteasy-link中RESTEasyServiceDiscovery的功用
abstract: 分析`RESTEasyServiceDiscovery`的功能。
---

# {{ page.title }}

分析`RESTEasyServiceDiscovery`的功能。

使用resteasy的源代码自带的`TestLinks.testLinks()`：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/6AF4FC21-6786-4893-9C43-87B9952BA3EC.png)

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

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/9F96EA36-FD02-4E98-BC39-CCF73CD52855.png)

上面的"`TestLinks.testLinks()`这个testcase涉及到两个classes，分别是`Book`和`Comment`：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/Class Diagram14.png)

可以看到，`Book`包含`Comment`，而这两个classes里面都包含`RESTServiceDiscovery`。

这个`RESTServiceDiscovery`会按照convention，像上面给出的XML和JSON数据一样，默认生成一套URLs。如果我们去掉`Book`里面的`rest`，就可以看到差别。把`Book`里面的`rest`注释掉：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/D7F5F140-C249-417E-B314-A097EA4DBFBB.png)

注释掉`rest`后，重新启动测试：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/0612C1AB-184E-41DF-A366-9D5569EEA717.png)

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/C6B5CFCB-3DF0-44DD-ADB8-2FF039A54960.png)

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

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/D2DB50AF-16C1-4DF2-A2C3-4AB429A002A8.png)

可以看到`rest`为我们默认添加了一些资源链接，同时`comment`的相关操作地址也加进来了。

上面这些links是从具体的service服务中来，分别是`BookStore`和`BookStoreMinimal`：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/46FCA5A1-1D2C-4C37-87A6-86D83B82D3FC.png)

这两个classes的类图：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/Class Diagram15.png)

用来调用服务的客户端接口是`BookStoreService`：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/Class Diagram16.png)

如果我们只使用`BookStore`或者只使用`BookStoreMinimal`：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/1011BB81-5593-460A-8579-C7547C08B74F.png)

实际的输出结果不变：

```bash
$ http --json --pretty all http://127.0.0.1:8081/book/foo
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
                "@rel": "self"
            },
            {
                "@href": "http://127.0.0.1:8081/book/foo",
                "@rel": "update"
            },
            {
                "@href": "http://127.0.0.1:8081/book/foo",
                "@rel": "remove"
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
```

比对`BookStore`和`BookStoreMinimal`的区别：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/566BDA96-9136-4972-B704-BC960D310A0C.png)

可以看到就是`@LinkResource`标记里面的内容更加完整。

我们在测试里面只使用`BookStoreMinimal`：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/B7C003D4-F823-407B-BBD4-432FFCAD8E4B.png)

然后把`BookStoreMinimal`里的`@LinkResource`全部都注释掉：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/A4F57A8C-DAFD-41FB-A2C6-F6D687790DD8.png)

然后重新启动测试：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/EEAB375D-D305-43D6-A110-398B9E1E78F5.png)

然后执行客户端的请求：

```bash
$ http --json --pretty all http://127.0.0.1:8081/book/foo
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
```

此时可以看到所有的atom links信息都没有了。

如果我们重新用`@AddLinks`标记一个方法：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/C1444237-8394-4768-BFF2-6353F59D19E3.png)

然后重新启动测试，并进行请求：

```bash
$ http --json --pretty all http://127.0.0.1:8081/book/foo
HTTP/1.1 200 OK
Content-Type: application/json
connection: keep-alive
transfer-encoding: chunked

{
    "book": {
        "@author": "bar",
        "@title": "foo",
        "rest": {
            "@href": "http://127.0.0.1:8081/books",
            "@rel": "list"
        }
    }
}
```

此时可以看到相关方法的atom link回来了。

如果此时去掉`@AddLinks`的标记：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/C1A9B668-54DB-4C55-B0CC-D68363437B98.png)

然后再次重新启动测试，并重新请求：

```bash
$ http --json --pretty all http://127.0.0.1:8081/book/foo
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
```

可以看到`Book`里面的`rest`并没有被注入：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/9170E8D3-BA5F-46E0-99CA-700102BAB355.png)

通过以上过程，就理清楚了`AtomLink`和`LinkResource`的功能：

- `LinkResource`用来标记需要在atom links里出现的方法，并保存在`RESTServiceDiscovery`的instance里面。
- `AtomLink`用来标记方法，把返回类型的instance里面注入`RESTServiceDiscovery`的instance。但是返回类型要像上面的`Book`一样，里面包含`RESTServiceDiscovery`的instance，比如`rest`。

下面给出`LinkResource`和`AtomLink`的完整的文档：

```java
/**
 * <p>
 * This holds a list of atom links describing the REST service discovered. This will
 * be injected by RESTEasy on any entity in the response if the JAX-RS method was
 * annotated with {@link AddLinks @AddLinks} if your entity declares a field of this
 * type.
 * </p>
 * <p>
 * For this to work you need to add {@link LinkResource @LinkResource} annotations on
 * all the JAX-RS methods you want to be discovered.
 * </p>
 * @author <a href="mailto:stef@epardaud.fr">Stéphane Épardaud</a>
 */
@XmlRootElement
@XmlAccessorType(XmlAccessType.NONE)
public class RESTServiceDiscovery extends ArrayList<RESTServiceDiscovery.AtomLink>
```

```java
/**
 * Use on any JAX-RS method if you want RESTEasy to inject the RESTServiceDiscovery
 * to every entity in the response. This will only inject RESTServiceDiscovery instances
 * on entities that have a field of this type, but it will be done recursively on the response's
 * entity.
 * @author <a href="mailto:stef@epardaud.fr">Stéphane Épardaud</a>
 */
@Target( { ElementType.TYPE, ElementType.METHOD, ElementType.PARAMETER,
      ElementType.FIELD })
@Retention(RetentionPolicy.RUNTIME)
@Decorator(processor = LinkDecorator.class, target = Marshaller.class)
@Documented
public @interface AddLinks
```

以上是完整的分析过程。


