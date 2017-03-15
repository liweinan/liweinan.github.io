---
title: An Analysis Of RESTEasy Core Classes - DRAFT
abstract: RESTEasy has some embedded containers, such as the Netty container, the Sun JDK HTTP Server container, and the Undertow container. For each container, their basic requirement is to initialize the RESTEasy core classes properly so RESTEasy can provide resource classes and URL to method matching properly. In this article, I'd like to show you my researches on RESTEasy core classes.
---

## _{{ page.title }}_

{{ page.abstract }}


Here is the class diagram that shows the core part of RESTEasy:

![2017-03-15-resteasy-core.png]({{ site.url }}/assets/2017-03-15-resteasy-core.png)
