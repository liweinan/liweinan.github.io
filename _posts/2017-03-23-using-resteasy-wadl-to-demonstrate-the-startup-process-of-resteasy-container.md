---
title: Using RESTEasy WADL To Demonstrate The Startup Process Of RESTEasy Container - DRAFT
abstract: RESTEasy WADL is a module that can generate WADL data for the restful resources. It needs to scan the RESTEasy container to get all the resources and methods information to generate the WADL data correctly, so analyzing the RESTEasy WADL intialization process can help us to better understanding the RESTEasy container structure. In this article I will use the codes of RESTEasy WADL for this purpose.
---

## _{{ page.title }}_

{{ page.abstract }}

In the WADL section of RESTEasy document[^doc], it shows the usage of the WADL module. Here is the codes shown in `51.2. RESTEasy WADL support for Sun JDK HTTP Server`:

[^doc]: [http://docs.jboss.org.](http://docs.jboss.org/resteasy/docs/3.1.1.Final/userguide/html_single/index.html#WADL)

```java
org.jboss.resteasy.plugins.server.sun.http.HttpContextBuilder contextBuilder =
	new org.jboss.resteasy.plugins.server.sun.http.HttpContextBuilder();

contextBuilder.getDeployment().getActualResourceClasses()
	.add(ResteasyWadlDefaultResource.class);
```

The above codes show us how the resource classes are added into the `ResteasyDeployment`. The `HttpContextBuilder` is a RESTEasy wrapper class for the Sun JDK HTTP Server, and we don't need to care about its details in this article. We need to understand the `ResteasyWadlDefaultResource` is added into `ResteasyDeployment` from above codes. This tells us the `ResteasyDeployment` class stores all the resource classes. I won't dive into the `ResteasyDeployment` in this article, but you may want to check this article[^core] I've written to have an understanding on RESTEasy core classes.

[^core]: [http://weinan.io.](http://weinan.io/2017/03/15/core-classes-to-implement-resteasy-container.html)

Now we can go on checking the following codes in the document:

```java
  ResteasyWadlDefaultResource.getServices()
  	.put("/",
  		ResteasyWadlGenerator
  			.generateServiceRegistry(contextBuilder.getDeployment()));
```

From above code we can see the `ResteasyWadlGenerator` class is used to create the `ResteasyWadlServiceRegistry`. It will use the `ResteasyDeployment` to get all the resource classes and their methods information. This is reasonable because `ResteasyDeployment` contains all the resources as we see in above. Here are the codes of `ResteasyWadlGenerator`:

```java
public class ResteasyWadlGenerator {

    public static ResteasyWadlServiceRegistry generateServiceRegistry(ResteasyDeployment deployment) {
        ResourceMethodRegistry registry = (ResourceMethodRegistry) deployment.getRegistry();
        ResteasyProviderFactory providerFactory = deployment.getProviderFactory();
        ResteasyWadlServiceRegistry service = new ResteasyWadlServiceRegistry(null, registry, providerFactory, null);
        return service;
    }
}
```

From the above implementation, we can see the `ResourceMethodRegistry` and `ResteasyProviderFactory` are fetched from `ResteasyDeployment`. These two classes are put into `ResteasyWadlServiceRegistry`. So the `ResourceMethodRegistry` and `ResteasyProviderFactory` must contain sufficient information about restful resources, or `ResteasyWadlServiceRegistry` will not get all the necessary information about the  resources. Now let's see the class diagram of `ResteasyWadlServiceRegistry` and the relative classes it contains:

![2017-03-23-ResteasyWadlServiceRegistry.png]({{ site.url }}/assets/2017-03-23-ResteasyWadlServiceRegistry.png)

From the above diagram, we can see `ResteasyWadlServiceRegistry` contains `ResourceMethodRegistry` and `ResteasyProviderFactory`, and we these two classes, it can later fetch all the following classes it needs. 


```java
public class ResteasyWadlGenerator {

    public static ResteasyWadlServiceRegistry generateServiceRegistry(ResteasyDeployment deployment) {
        ResourceMethodRegistry registry = (ResourceMethodRegistry) deployment.getRegistry();
        ResteasyProviderFactory providerFactory = deployment.getProviderFactory();
        ResteasyWadlServiceRegistry service = new ResteasyWadlServiceRegistry(null, registry, providerFactory, null);
        return service;
    }
}
```

### _References_

---
