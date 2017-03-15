---
title: An Analysis Of RESTEasy Core Classes - DRAFT
abstract: RESTEasy has some embedded containers, such as the Netty container, the Sun JDK HTTP Server container, and the Undertow container. For each container, their basic requirement is to initialize the RESTEasy core classes properly so RESTEasy can provide resource classes and URL to method matching properly. In this article, I'd like to show you my researches on RESTEasy core classes.
---

## _{{ page.title }}_

{{ page.abstract }}

Here is the class diagram that shows the core classes of RESTEasy:

![2017-03-15-resteasy-core.png]({{ site.url }}/assets/2017-03-15-resteasy-core.png)

As the diagram shown above, there are three core classes that forms the RESTEasy basic structure: `ReseteasyDeployment`, `ResteasyProviderFactory`, and `ResourceMethodRegistry`. I have written _RESTEasy Implementation of JAX-RS SPEC 2.0 Section 3.7._[^jaxrs-spec3_7] to explain the design of `ResourceMethodRegistry` and the following URL matching classes. You may want to check the article for more details on RESTEasy implementation of URL matching process and method invoking process.

[^jaxrs-spec3_7]: [RESTEasy Implementation of JAX-RS SPEC 2.0 Section 3.7.](http://weinan.io/2017/03/04/jaxrs-spec3_7.html)

Now let's check the `ReseteasyDeployment` class. This is the basic container of the RESTEasy, and it contains `ResteasyProviderFactory` and `ResourceMethodRegistry` classes. The `ResteasyProviderFactory` contains many basic data that will be used during RESTEasy runtime. You can see from the diagram it is a very big class that contains a lot of data. For example, it contains multiple `MessageReader` classes, `MessageWriter` classes, `Filter` classes and `Interceptor` classes.

We can see from the diagram that `ResourceMethodRegistry` uses the `ResteasyProviderFactory`. The following sequence diagram shows the `ResourceMethodRegistry.processMethod()` method call process and its usage of `ResteasyProviderFactory` and other core classes:

![2017-03-15-call-digram.png]({{ site.url }}/assets/2017-03-15-call-digram.png)

From the above diagram, we can see how does `ResourceMethodRegistry` integrates mutliple parts together to prepare RESTEasy container for dealing with requests. We can the info are fetched from `ResteasyProviderFactory`, and we can see `ResourceMethodInvoker` and `ResourceLocatorInvoker` are added into multiple `Node` classes. In this way, the `Node` classes with its `Invoker` classes can be used for later requests matching and processing work. For more details on this part, you can refer to the _RESTEasy Implementation of JAX-RS SPEC 2.0 Section 3.7_.

Now we should check the `ResteasyDeployment` start process. The `ResteasyDeployment.start()` method is the initialisation method of the RESTEasy container. Here is the sequence diagram of the method:

![ResteasyProviderFactory.start.png]({{ site.url }}/assets/ResteasyProviderFactory.start.png)

From the above diagram, we can see `ResteasyDeployment.start()` method will create and initialize `ResteasyProviderFactory`. In addition, it will initialize multiple dispatcher classes. In addition, we can see _Step 1.44_ is a call to `registration()`. This method is to add providers into `ResteasyProviderFactory`, and to add resource classes into `ResourceMethodRegistry`. Here is the sequence diagram of the `registration` method:

![ResteasyProviderFactory.registration.png]({{ site.url }}/assets/ResteasyProviderFactory.registration.png)

After the `ResteasyDeployment.start()` is done, the provider factory and the registry is prepared to use for processing requests. Now let's check the dispatchers. The `Dispatcher` interface is the runtime entry of the RESTEasy container. If you check the `ResteasyHttpHandler`[^handler], then you can see how does it handles the incoming request in its `handle` method:

[^handler]: [ResteasyHttpHandler.java](https://github.com/resteasy/Resteasy/blob/master/server-adapters/resteasy-jdk-http/src/main/java/org/jboss/resteasy/plugins/server/sun/http/ResteasyHttpHandler.java)

![{{ site.url }}/assets/2017-03-15-ResteasyHttpHandler.handle.png]({{ site.url }}/assets/2017-03-15-ResteasyHttpHandler.handle.png)

As the screenshot shown above, the `dispatcher.invoke()` method is the entry of whole processing work. The `ResteasyHttpHandler` class is the request handler of `resteasy-jdk-http` embedded server which uses _Sun JDK HTTP Server_ as the webserver.
