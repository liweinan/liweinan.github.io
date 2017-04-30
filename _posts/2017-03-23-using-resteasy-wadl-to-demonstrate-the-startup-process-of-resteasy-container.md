---
title: Using RESTEasy WADL To Demonstrate The Startup Process Of RESTEasy Container
abstract: RESTEasy WADL is a module that can generate WADL data for the restful resources. It needs to scan the RESTEasy container to get all the resources and methods information to generate the WADL data correctly, so analyzing the RESTEasy WADL intialization process can help us to better understanding the RESTEasy container structure. In this article I will use the code of RESTEasy WADL for this purpose.
---

{{ page.abstract }}

In the WADL section of RESTEasy document[^doc], it shows the usage of the WADL module. Here is the code shown in `51.2. RESTEasy WADL support for Sun JDK HTTP Server`:

[^doc]: [http://docs.jboss.org.](http://docs.jboss.org/resteasy/docs/3.1.1.Final/userguide/html_single/index.html#WADL)

```java
org.jboss.resteasy.plugins.server.sun.http.HttpContextBuilder contextBuilder =
	new org.jboss.resteasy.plugins.server.sun.http.HttpContextBuilder();

contextBuilder.getDeployment().getActualResourceClasses()
	.add(ResteasyWadlDefaultResource.class);
```

The above code show us how the resource classes are added into the `ResteasyDeployment`. The `HttpContextBuilder` is a RESTEasy wrapper class for the Sun JDK HTTP Server, and we don't need to care about its details in this article. We need to understand the `ResteasyWadlDefaultResource` is added into `ResteasyDeployment` from above code. This tells us the `ResteasyDeployment` class stores all the resource classes. I won't dive into the `ResteasyDeployment` in this article, but if you'd like to learn more about the core classes of RESTEasy you can check this[^core].

[^core]: [http://weinan.io.](http://weinan.io/2017/03/15/core-classes-to-implement-resteasy-container.html)

Now we can go on checking the following code in the document:

```java
  ResteasyWadlDefaultResource.getServices()
  	.put("/",
  		ResteasyWadlGenerator
  			.generateServiceRegistry(contextBuilder.getDeployment()));
```

From above code we can see the `ResteasyWadlGenerator` class is used to create the `ResteasyWadlServiceRegistry`. It will use the `ResteasyDeployment` to get all the resource classes and their method information. This is reasonable because `ResteasyDeployment` contains all the resources as we see above. Here is the code of `ResteasyWadlGenerator`:

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

From the above implementation, we can see the `ResourceMethodRegistry` and `ResteasyProviderFactory` are fetched from `ResteasyDeployment`. These two classes are put into `ResteasyWadlServiceRegistry`, so the `ResourceMethodRegistry` and `ResteasyProviderFactory` must contain sufficient information about restful resources, or `ResteasyWadlServiceRegistry` will not get all the necessary information about the  resources. Now let's see the class diagram of `ResteasyWadlServiceRegistry` and the relative classes it contains:

![2017-03-23-ResteasyWadlServiceRegistry.png]({{ site.url }}/assets/2017-03-23-ResteasyWadlServiceRegistry.png)

From the above diagram, we can see `ResteasyWadlServiceRegistry` contains `ResourceMethodRegistry` and `ResteasyProviderFactory`, and with these two classes, it can later fetch all the following classes it needs. Please note `ResteasyWadlServiceRegistry` stores two kinds of resources. The first kind is `resources`:

```java
private Map<String, ResteasyWadlResourceMetaData> resources;
```

From the above `Map` data structure, we can guess the resources contain url <-> class entries, and `ResteasyWadlResourceMetaData` is used to store resource class information. The second kind is `locators`:

```java
private List<ResteasyWadlServiceRegistry> locators;
```

This one contains resource locators, because resource locators are actually nested resources, so they are a list of `ResteasyWadlServiceRegistry` itself. We can check the `scanRegistry()` method of `ResteasyWadlServiceRegistry` to see how it fetches, processes and stores the resources information:

![2017-03-24-scanRegistry.png]({{ site.url }}/assets/2017-03-24-scanRegistry.png)

From the above sequence diagram we can see how `ResteasyWadlServiceRegistry` deals with two types of resources. If the resource type is `ResourceMethodInvoker`, then it will create `ResteasyWadlMethodMetaData` and `ResteasyWadlResourceMetaData` to store the resource classes and methods information. The name of this class is misleading, it should be called `ResourceClassAndMethodInvoker`, because it contains both resource class their methods information. Here is the relative code in `scanRegistry()` method:

```java
if (invoker instanceof ResourceMethodInvoker) {
		ResteasyWadlMethodMetaData methodMetaData = new ResteasyWadlMethodMetaData(this, (ResourceMethodInvoker) invoker);
		ResteasyWadlResourceMetaData resourceMetaData = resources.get(methodMetaData.getKlassUri());
		if (resourceMetaData == null) {
				resourceMetaData = new ResteasyWadlResourceMetaData(methodMetaData.getKlassUri());
				resources.put(methodMetaData.getKlassUri(), resourceMetaData);
		}
		resourceMetaData.addMethodMetaData(methodMetaData);
}
```

On other hand, if the resource type is `ResourceLocator`, then it will add the locator into the `locators` array. Here is the relative code:

```java
else if (invoker instanceof ResourceLocator) {
	ResourceMethodRegistry locatorRegistry = new ResourceMethodRegistry(providerFactory);
	locatorRegistry.addResourceFactory(null, null, locatorResourceType);
	locators.add(new ResteasyWadlServiceRegistry(this, locatorRegistry, providerFactory, locator));
}
```

The name of `ResourceMethodRegistry` is also misleading, it might be better called `ResourceClassAndMethodRegistry` because it also contains both resource classes and methods information. The instance of `ResourceMethodRegistry` is `locatorRegistry`, and it is passed to the constructor of `ResteasyWadlServiceRegistry`, and the created `ResteasyWadlServiceRegistry` is added into `locators`. This is the line of code that does this:

```java
locators.add(new ResteasyWadlServiceRegistry(this, locatorRegistry, providerFactory, locator));
```

Please note the constructor of `ResteasyWadlServiceRegistry` will call the `scanRegistry()` method, so here we have a recursive call of `scanRegistry()` for resource locators. This implementation reflects the fact that resource locator is a kind of nested resource. Now let's check the `ResteasyWadlResourceMetaData` and `ResteasyWadlMethodMetaData`:

![ResteasyWadlMethodMetaData.png]({{ site.url }}/assets/ResteasyWadlMethodMetaData.png)

From the above diagram, we can see `ResteasyWadlResourceMetaData` has a list of `ResteasyWadlMethodMetaData`, and `ResteasyWadlMethodMetaData` contains the `ResourceMethodInvoker`, and the `ResourceMethodInvoker` is the implementation class to do the actual resource method invocations. Now we can check how `ResteasyWadlWriter` uses `ResteasyWadlResourceMetaData` and `ResteasyWadlMethodMetaData` to convert resource classes and methods to WADL data:

![2017-03-24-processWadl.png]({{ site.url }}/assets/2017-03-24-processWadl.png)

From the above sequence diagram we can see how `resourceMetaDataEntry` and `methodMetaData` are used in `processWadl` method. Here is the relative code:

```java
for (Map.Entry<String, ResteasyWadlResourceMetaData> resourceMetaDataEntry : serviceRegistry.getResources().entrySet()) {
	resourceClass.setPath(resourceMetaDataEntry.getKey());
	root.getResource().add(resourceClass);

	for (ResteasyWadlMethodMetaData methodMetaData : resourceMetaDataEntry.getValue().getMethodsMetaData()) {
		Method method = new Method();
	}
}
```

In addition, at the end of the `processWadl` method, it deals with the resource locators in a recursive way:

```java
for (ResteasyWadlServiceRegistry subService : serviceRegistry.getLocators())
		processWadl(subService, root);
```

We can see again from here that the resource locators are just nested resources.

### _References_

---
