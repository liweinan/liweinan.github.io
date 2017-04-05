---
title: RESTEasy Applications Support - DRAFT
abstract: In this article I'd like to give you a brief introduction on RESTEasy Application Support.
---

## _{{ page.title }}_

{{ page.abstract }}

Application is an JAX-RS spec defined feature that support users to register restful resources into containers. Here are the descriptions to the Application in section `2.3.2 Servlet` of the `jsr339-jaxrs-2.0-final-spec`:

![2016-04-05-spec1.png]({{ site.url }}/assets/2016-04-05-spec1.png)

![2016-04-05-spec2.png]({{ site.url }}/assets/2016-04-05-spec2.png)

![2016-04-05-spec3.png]({{ site.url }}/assets/2016-04-05-spec3.png)

![2016-04-05-spec4.png]({{ site.url }}/assets/2016-04-05-spec4.png)

Please note Application is used with Servlet container, that means, not all the containers need to follow this Application workflow to register resources. For example, `resteasy-netty4` container doesn't need Application to work. Here is an example to use `resteasy-netty4`:

```java
ResteasyDeployment deployment = new ResteasyDeployment();

netty = new NettyJaxrsServer();
netty.setDeployment(deployment);
netty.setPort(port);
netty.setRootResourcePath("");
netty.setSecurityDomain(null);
netty.start();

deployment.getRegistry().addPerRequestResource(BasicResource.class);
```

As the example shown above, we can see that the `BasicResource` is added into `Registry` directly, and `Registry` is contained in `ResteasyDeployment`. We can see the whole process doesn't involve Application. This makes us understanding two things: The first one is that Application is just a way to provide root resource path and resources to the container; The second thing is that RESTEasy can directly accept resource classes and store it in its classes.

Now let's check how does RESTEasy deals with the Application. There is a `createApplication()` method defined in `ResteasyDeployment`:

```java
public static Application createApplication(String applicationClass, Dispatcher dispatcher, ResteasyProviderFactory providerFactory) {
    Class<?> clazz = null;
    try {
        clazz = Thread.currentThread().getContextClassLoader().loadClass(applicationClass);
    } catch (ClassNotFoundException e) {
        throw new RuntimeException(e);
    }

    Application app = (Application) providerFactory.createProviderInstance(clazz);
    dispatcher.getDefaultContextObjects().put(Application.class, app);
    ResteasyProviderFactory.pushContext(Application.class, app);
    PropertyInjector propertyInjector = providerFactory.getInjectorFactory().createPropertyInjector(clazz, providerFactory);
    propertyInjector.inject(app);
    return app;
}
```

From the above code, we can see the method will create an Application class instance from the `String applicationClass` defined by user, so it will be the user extended Application class. The following is the sequence diagram of above code:

![2016-04-05-org.jboss.resteasy.spi.ResteasyDeployment.createApplication.png]({{ site.url }}/assets/2016-04-05-org.jboss.resteasy.spi.ResteasyDeployment.createApplication.png)

Here are the two places that are using `createApplication()` method:

![2017-04-05-create-application.png]({{ site.url }}/assets/2017-04-05-create-application.png)

As the screenshot shown above, one is in `ServletContainerDispatcher.init()`, and the other one is `ResteasyDeployment.start()`. Here is the usage of `createApplication()` method in `ServletContainerDispatcher.init()`:

![2017-04-05-servletcontainerdispatcher.png]({{ site.url }}/assets/2017-04-05-servletcontainerdispatcher.png)

Here is the usage in `ResteasyDeployment.start()`:

![2017-04-05-resteasydeployment.png]({{ site.url }}/assets/2017-04-05-resteasydeployment.png)
