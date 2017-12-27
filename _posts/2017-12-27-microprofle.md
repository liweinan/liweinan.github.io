---
title: 使用Microprofile OpenTracing的JAX-RS实现模块（上）
abstract: Microprofile OpenTracing是Eclipse推的一个分布式的Microservice Instrumenting Standard，本文试用它的JAX-RS模块。
---

## {{ page.title }}

Microprofile OpenTracing是Eclipse推的一个分布式的Microservice Instrumenting Standard。以下是它的官方文档[^spec]给出的定义：

> The OpenTracing project’s purpose is to provide a standard API for instrumenting microservices for distributed tracing.

[^spec]: https://github.com/eclipse/microprofile-opentracing/blob/master/spec/src/main/asciidoc/microprofile-opentracing.asciidoc

这篇文章里试玩一下这个标准的JAX-RS实现模块[^jaxrsimpl]。因为这个项目在我写这篇文章的时候还在开发阶段，所以需要补充一些代码进去，所以我把它fork到了自己的Github空间里[^forkedjaxrsimpl]。这篇文章使用我的这个forked项目。

[^jaxrsimpl]: https://github.com/opentracing-contrib/java-jaxrs
[^forkedjaxrsimpl]: https://github.com/liweinan/java-jaxrs

把这个forked project给forked到本地以后，可以看一下里面的关键代码。在这篇文章里要玩一下项目当中的`example`子项目，可以先看一下这里面的`JerseyConfig`这个class：

```java
package io.opentracing.contrib.jaxrs2.example.spring.boot;

import io.opentracing.Tracer;
import io.opentracing.contrib.jaxrs2.client.ClientTracingFeature.Builder;
import io.opentracing.contrib.jaxrs2.itest.common.rest.TestHandler;
import io.opentracing.contrib.jaxrs2.server.ServerTracingDynamicFeature;
import javax.inject.Inject;
import javax.ws.rs.ApplicationPath;
import javax.ws.rs.client.Client;
import javax.ws.rs.client.ClientBuilder;
import org.glassfish.jersey.server.ResourceConfig;
import org.springframework.stereotype.Component;

/**
 * @author Pavol Loffay
 */
@Component
@ApplicationPath("/")
public class JerseyConfig extends ResourceConfig {

	@Inject
	public JerseyConfig(Tracer tracer) {
		Client client = ClientBuilder.newClient();
		client.register(new Builder(tracer).build());
		packages("io.opentracing.contrib.jaxrs2.example.spring.boot");

		register(new ServerTracingDynamicFeature.Builder(tracer)
				.build());

		register(new TestHandler(tracer, client));
	}
}
```

在上面的代码中，`packages(...)`方法是为了把相关package里面的`HelloResource`给注册进服务器，这样才能进行demo；接下来的`register(...)`方法把`ServerTracingDynamicFeature`给注册进服务器，这样就等于服务端就开启了tracing能力，等下展示例子会看到。

`ServerTracingDynamicFeature`接收一个`tracer`，这个`tracer`是在`Configuration`里面注入的：

```java
package io.opentracing.contrib.jaxrs2.example.spring.boot;

import org.springframework.context.annotation.Bean;

import io.opentracing.Tracer;

/**
 * @author Pavol Loffay
 */
@org.springframework.context.annotation.Configuration
public class Configuration {

	@Bean
	public Tracer tracer() {
		return new LoggingTracer();
	}
}
```

关于`LoggingTracer`，在下篇中给出具体分析。这篇文章最后我们实操一下这个项目。首先是编译整个项目：

```bash
$ mvn install -Dmaven.test.skip=true
...
[INFO] Reactor Summary:
[INFO]
[INFO] io.opentracing.contrib:opentracing-jaxrs-parent .... SUCCESS [  0.207 s]
[INFO] opentracing-jaxrs2 ................................. SUCCESS [  0.679 s]
[INFO] opentracing-jaxrs2-itest-parent .................... SUCCESS [  0.006 s]
[INFO] opentracing-jaxrs2-itest-common .................... SUCCESS [  0.099 s]
[INFO] opentracing-jaxrs2-itest-jersey .................... SUCCESS [  0.126 s]
[INFO] opentracing-jaxrs2-itest-resteasy .................. SUCCESS [  0.107 s]
[INFO] opentracing-jaxrs2-itest-apache-cxf ................ SUCCESS [  0.064 s]
[INFO] opentracing-jaxrs2-itest-auto-discovery ............ SUCCESS [  0.770 s]
[INFO] opentracing-jaxrs2-example-spring-boot ............. SUCCESS [  0.953 s]
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time: 3.264 s
[INFO] Finished at: 2017-12-27T20:50:01+08:00
[INFO] Final Memory: 38M/550M
[INFO] ------------------------------------------------------------------------
```

然后进入`examples/spring-boot`目录，启动并运行spring server：

```bash
$ mvn spring-boot:start
```

运行起来的效果如下：

![]({{ site.url }}/assets/ScreenSnapz1253.png)

服务启动后，使用`curl`来访问服务端：

```bash
$ curl -iv http://localhost:3000/hello
*   Trying ::1...
* TCP_NODELAY set
* Connected to localhost (::1) port 3000 (#0)
> GET /hello HTTP/1.1
> Host: localhost:3000
> User-Agent: curl/7.54.0
> Accept: */*
>
< HTTP/1.1 200
HTTP/1.1 200
< Content-Type: text/xml
Content-Type: text/xml
< Content-Length: 13
Content-Length: 13
< Date: Wed, 27 Dec 2017 12:55:16 GMT
Date: Wed, 27 Dec 2017 12:55:16 GMT

<
* Connection #0 to host localhost left intact
Hello, world!$
```

此时查看服务端的tracing输出：

```txt
extract(Builtin.HTTP_HEADERS, io.opentracing.contrib.jaxrs2.server.ServerHeadersExtractTextMap@280ba5f0)
{
  "context" : {
    "traceId" : 1,
    "spanId" : 2
  },
  "parentId" : 0,
  "startMicros" : 1514379316262000,
  "finishMicros" : 1514379316274000,
  "tags" : {
    "http.url" : "http://localhost:3000/hello",
    "http.status_code" : 200,
    "span.kind" : "server",
    "http.method" : "GET"
  },
  "logs" : [ ],
  "operationName" : "hello"
}
```

可以看到上面的服务端有了json格式的tracing输出内容，这是`LoggingTracer`和它后面的opentracing框架所提供给我们的，在下篇中具体说明。下面是客户端和服务端在我机器上运行的截图：

![]({{ site.url }}/assets/ScreenSnapz1254.png)

上篇先讲这么多，下篇重点介绍opentracing的框架设计，和这个jax-rs tracing项目的具体实现。






