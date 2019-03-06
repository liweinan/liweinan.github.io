---
title: resteasy-link的scrollable atom links
abstract: resteasy-link提供复杂的标记支持并提供了测试用例作为例子。
---

# {{ page.title }}

resteasy-link提供复杂的标记支持并提供了测试用例作为例子：

![]({{ site.url }}/assets/3A5CFA98-BC42-4DDF-928C-90A7177C229C.png)

启动测试，并进行请求：

```bash
$ http --json "http://127.0.0.1:8081/book/foo/comment-collection;query=book"
```

得到返回结果：

```bash
HTTP/1.1 200 OK
Content-Type: application/json
connection: keep-alive
transfer-encoding: chunked

{
    "scrollableCollection": {
        "@limit": 1,
        "@start": 0,
        "@totalRecords": 2,
        "comments": {
            "@xmlid": 0,
            "rest": [
                {
                    "@href": "http://127.0.0.1:8081/book/foo/comment/0",
                    "@rel": "self"
                },
                {
                    "@href": "http://127.0.0.1:8081/book/foo/comment/0",
                    "@rel": "update"
                },
                {
                    "@href": "http://127.0.0.1:8081/book/foo/comment/0",
                    "@rel": "remove"
                },
                {
                    "@href": "http://127.0.0.1:8081/book/foo/comment-collection",
                    "@rel": "collection"
                },
                {
                    "@href": "http://127.0.0.1:8081/book/foo/comments",
                    "@rel": "add"
                },
                {
                    "@href": "http://127.0.0.1:8081/book/foo/comments",
                    "@rel": "list"
                }
            ],
            "text": "great book"
        },
        "rest": [
            {
                "@href": "http://127.0.0.1:8081/",
                "@rel": "home"
            },
            {
                "@href": "http://127.0.0.1:8081/book/foo/comment-collection",
                "@rel": "collection"
            },
            {
                "@href": "http://127.0.0.1:8081/book/foo/comment-collection;query=book?start=1&limit=1",
                "@rel": "next"
            },
            {
                "@href": "http://127.0.0.1:8081/book/foo/comments",
                "@rel": "add"
            },
            {
                "@href": "http://127.0.0.1:8081/book/foo/comments",
                "@rel": "list"
            }
        ]
    }
}
```

注意上面的link里面，有`next`这一项：

![]({{ site.url }}/assets/EE029F4F-8D83-474A-8D81-17408F909E99.png)

我们可以使用提供的这个link：

```bash
$ http --json --pretty all "http://127.0.0.1:8081/book/foo/comment-collection;query=book?start=1&limit=1"
```

得到数据内容如下：

```bash
HTTP/1.1 200 OK
Content-Type: application/json
connection: keep-alive
transfer-encoding: chunked

{
    "scrollableCollection": {
        "@limit": 1,
        "@start": 1,
        "@totalRecords": 2,
        "comments": {
            "@xmlid": 1,
            "rest": [
                {
                    "@href": "http://127.0.0.1:8081/book/foo/comment/1",
                    "@rel": "update"
                },
                {
                    "@href": "http://127.0.0.1:8081/book/foo/comment/1",
                    "@rel": "remove"
                },
                {
                    "@href": "http://127.0.0.1:8081/book/foo/comment/1",
                    "@rel": "self"
                },
                {
                    "@href": "http://127.0.0.1:8081/book/foo/comment-collection",
                    "@rel": "collection"
                },
                {
                    "@href": "http://127.0.0.1:8081/book/foo/comments",
                    "@rel": "list"
                },
                {
                    "@href": "http://127.0.0.1:8081/book/foo/comments",
                    "@rel": "add"
                }
            ],
            "text": "terrible book"
        },
        "rest": [
            {
                "@href": "http://127.0.0.1:8081/",
                "@rel": "home"
            },
            {
                "@href": "http://127.0.0.1:8081/book/foo/comment-collection",
                "@rel": "collection"
            },
            {
                "@href": "http://127.0.0.1:8081/book/foo/comment-collection?start=0&limit=1",
                "@rel": "prev"
            },
            {
                "@href": "http://127.0.0.1:8081/book/foo/comments",
                "@rel": "list"
            },
            {
                "@href": "http://127.0.0.1:8081/book/foo/comments",
                "@rel": "add"
            }
        ]
    }
}
```

上面的数据里于是有了`prev`这一项：

![]({{ site.url }}/assets/57C71C71-A15C-42E2-BC90-DE16CA12B4F1.png)

上面这些数据是通过`ScrollableCollection`产生的：

![]({{ site.url }}/assets/93727E31-84B5-4247-8784-0E38E0861150.png)

以下是`BookStore.java`的文字部分：

```java
@Produces({"application/xml", "application/json"})
@AddLinks
@LinkResources({
  @LinkResource(value = Book.class, rel="comment-collection"),
  @LinkResource(value = Comment.class, rel="collection"),
  @LinkResource(value = ScrollableCollection.class, rel = "prev", constraint = "${this.start - this.limit >= 0}", queryParameters = {
        @ParamBinding(name = "start", value = "${this.start - this.limit}"),
        @ParamBinding(name = "limit", value = "${this.limit}") }),
  @LinkResource(value = ScrollableCollection.class, rel = "next", constraint = "${this.start + this.limit < this.totalRecords}", queryParameters = {
        @ParamBinding(name = "start", value = "${this.start + this.limit}"),
        @ParamBinding(name = "limit", value = "${this.limit}")
  }, matrixParameters = {@ParamBinding(name = "query", value = "${this.query}")})
})
@GET
@Path("book/{id}/comment-collection")
public ScrollableCollection getScrollableComments(@Context UriInfo uriInfo, @PathParam("id") String id, @QueryParam("start") int start, @QueryParam("limit") @DefaultValue("1") int limit, @MatrixParam("query") String query)
```

上面的`LinkResources`是针对`ScrollableCollection`而进行标记的。`ScrollableCollection`的class diagram如下：

![]({{ site.url }}/assets/Class Diagram17.png)

`ScrollableCollection `通过实现`ResourceFacade`接口，来绑定annotations里面的`@ParamBinding`的一些参数，并注入到`ScrollableCollection`的相关属性里面去。

而这些参数的具体使用，取决于代码的实现本身。比如`BookStore.getScrollableComments()`对参数的使用：

```java
@Produces({"application/xml", "application/json"})
@AddLinks
@LinkResources({
  @LinkResource(value = Book.class, rel="comment-collection"),
  @LinkResource(value = Comment.class, rel="collection"),
  @LinkResource(value = ScrollableCollection.class, rel = "prev", constraint = "${this.start - this.limit >= 0}", queryParameters = {
        @ParamBinding(name = "start", value = "${this.start - this.limit}"),
        @ParamBinding(name = "limit", value = "${this.limit}") }),
  @LinkResource(value = ScrollableCollection.class, rel = "next", constraint = "${this.start + this.limit < this.totalRecords}", queryParameters = {
        @ParamBinding(name = "start", value = "${this.start + this.limit}"),
        @ParamBinding(name = "limit", value = "${this.limit}")
  }, matrixParameters = {@ParamBinding(name = "query", value = "${this.query}")})
})
@GET
@Path("book/{id}/comment-collection")
public ScrollableCollection getScrollableComments(@Context UriInfo uriInfo, @PathParam("id") String id, @QueryParam("start") int start, @QueryParam("limit") @DefaultValue("1") int limit, @MatrixParam("query") String query){
  List<Comment> comments = new ArrayList<Comment>();
  for (Comment comment : books.get(id).getComments()) {
     if (comment.getText().contains(query)) {
        comments.add(comment);
     }
  }
  start = start < 0 ? 0 : start;
  limit = limit < 1 ? 1 : limit;
  limit = (start + limit) > comments.size() ? comments.size() - start : limit;
  ScrollableCollection result = new ScrollableCollection(id, start, limit, comments.size(), comments.subList(start, start + limit), query);

  RESTServiceDiscovery discovery = new RESTServiceDiscovery();
  discovery.addLink(uriInfo.getBaseUriBuilder().build(), "home");
  result.setRest(discovery);

  return result;
}
```

上面的代码就会生成文章开始时候请求到的json数据了。

