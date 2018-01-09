---
title: opentracing.io的API分析
abstract: 分析opentracing的接口设计。
---

## {{ page.title }}


以下是「opentrace-api」[^1]的核心接口的类图：

![]({{ site.url }}/assets/opentrace-api.jpg)

[^1]: https://github.com/opentracing/opentracing-java/tree/master/opentracing-api

opentracing针对上面的API，提供了一些基础的实现，位于「opentrace-util」这个package[^2]里：

[^2]: https://github.com/opentracing/opentracing-java/tree/master/opentracing-util

![]({{ site.url }}/assets/opentrace-util.jpg)



