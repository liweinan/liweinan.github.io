---
title: resteasy-link的架构分析
abstract: 学习restasy-link的设计。
---

# {{ page.title }}


`resteasy-link`的核心设计是三个classes：`LinkResource`，`RESTServiceDiscovery`和`AtomLink`，此外还有一个用来标记的`AddLinks`。下面是类图：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/Class Diagram22.png)

其中`RESTServiceDiscovery`是扩展了`ArrayList`：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/Class Diagram11.png)

`RESTServiceDiscovery`里面装了一堆`AtomLink`。

整个`resteasy-link`的最终输出：

```xml
<?xml version=“1.0” encoding=“UTF-8” standalone=“yes”?>
<scrollableCollection xmlns:atom=“http://www.w3.org/2005/Atom” start=“0” limit=“1” totalRecords=“2”>
    <comments xmlid=“0”>
        <text>great book</text>
        <rest rel=“update” href=“http://localhost:8081/book/foo/comment/0”/>
        <rest rel=“remove” href=“http://localhost:8081/book/foo/comment/0”/>
        <rest rel=“self” href=“http://localhost:8081/book/foo/comment/0”/>
        <rest rel=“collection” href=“http://localhost:8081/book/foo/comment-collection”/>
        <rest rel=“list” href=“http://localhost:8081/book/foo/comments”/>
        <rest rel=“add” href=“http://localhost:8081/book/foo/comments”/>
    </comments>
    <rest rel=“home” href=“http://localhost:8081/“/>
    <rest rel=“collection” href=“http://localhost:8081/book/foo/comment-collection”/>
    <rest rel=“next” href=“http://localhost:8081/book/foo/comment-collection;query=book?start=1&amp;limit=1”/>
    <rest rel=“list” href=“http://localhost:8081/book/foo/comments”/>
    <rest rel=“add” href=“http://localhost:8081/book/foo/comments”/>
</scrollableCollection>
```

上面的输出是`LinkResource`组成的。下面是`LinkResource`的组成：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/Class Diagram10 2.png)

`RESTUtils`负责串起来`LinkResource`，`RESTServiceDiscovery`和`AtomLink`。

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/Class Diagram12.png)

入口方法是`addDiscovery(...)`：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/F0D0933B-43BA-442E-9430-C7A261F65D08.png)

`addDiscovery(...)`会调用`processLinkResources(...)`：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/org.jboss.resteasy.links.impl.RESTUtils.addDiscovery(T, UriInfo, ResourceMethodRegistry).png)

下面是`processLinkResources(...)`方法：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/org.jboss.resteasy.links.impl.RESTUtils.processLinkResources(Method, Object, UriInfo, RESTServiceDiscovery).png)

上面的方法会去调用`processLinkResource(...)`方法：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/org.jboss.resteasy.links.impl.RESTUtils.processLinkResource(Method, Object, UriInfo, RESTServiceDiscovery, LinkResource).png)

上面的方法会调用`addInstanceService(...)`或者`addService(...)`。而`LinkResource`的instance在这里面叫做`service`，其中`service`被用来生成`AtomLink`所需的数据，后续放入`AtomLink`里面。

以`addService(...)`为例：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/org.jboss.resteasy.links.impl.RESTUtils.addService(Method, ResourceFacade___, UriInfo, RESTServiceDiscovery, LinkResource, String).png)

可以看到最终是走到`RESTServiceDiscovery.addLink(...)`方法里面，这个方法就是往`RESTServiceDiscovery`里面添加`AtomLink`，在上面已经有介绍。




