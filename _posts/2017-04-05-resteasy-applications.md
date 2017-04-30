---
title: RESTEasy Application Support
abstract: In this article I'd like to give you a brief introduction on RESTEasy Application Support.
---

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

From the above analysis, we can see the instance of Application will be stored into multiple classes, such as `Dispatcher` and `ResteasyProviderFactory`. Here are the two places that are using `createApplication()` method:

![2017-04-05-create-application.png]({{ site.url }}/assets/2017-04-05-create-application.png)

As the screenshot shown above, one is in `ServletContainerDispatcher.init()`, and the other one is `ResteasyDeployment.start()`. Here is the usage of `createApplication()` method in `ServletContainerDispatcher.init()`:

![2017-04-05-servletcontainerdispatcher.png]({{ site.url }}/assets/2017-04-05-servletcontainerdispatcher.png)

We can see there is a `processApplication()` method after `createApplication()` method. Here is the sequence diagram of the `ServletContainerDispatcher.processApplication()` method:

![2017-04-05-processapplication.png]({{ site.url }}/assets/2017-04-05-processapplication.png)

We can see the `processApplication()` method will fetch the resources from Application instance and register them into various classes. This is the usage of Application in RESTEasy. Next let's see the `createApplication()` method in `ResteasyDeployment.start()`:

![2017-04-05-resteasydeployment.png]({{ site.url }}/assets/2017-04-05-resteasydeployment.png)

Please note RESTEasy doesn't process the `@ApplicationPath` annotation by itself, it's the container's responsibility to deal with it. `WadlUndertowConnector` is a good example:

```java
package org.jboss.resteasy.wadl;

import io.undertow.servlet.api.DeploymentInfo;
import io.undertow.servlet.api.ServletInfo;
import org.jboss.resteasy.plugins.server.servlet.HttpServlet30Dispatcher;
import org.jboss.resteasy.plugins.server.undertow.UndertowJaxrsServer;
import org.jboss.resteasy.spi.ResteasyDeployment;

import javax.ws.rs.ApplicationPath;
import javax.ws.rs.core.Application;

import static io.undertow.servlet.Servlets.servlet;

/**
 * Created by weli on 7/26/16.
 */
public class WadlUndertowConnector {
    public UndertowJaxrsServer deployToServer(UndertowJaxrsServer server, Class<? extends Application> application) {
        ApplicationPath appPath = application.getAnnotation(ApplicationPath.class);
        String path = "/";
        if (appPath != null) path = appPath.value();

        return deployToServer(server, application, path);
    }

    public UndertowJaxrsServer deployToServer(UndertowJaxrsServer server, Class<? extends Application> application, String contextPath) {
        ResteasyDeployment deployment = new ResteasyDeployment();
        deployment.setApplicationClass(application.getName());

        DeploymentInfo di = server.undertowDeployment(deployment);

        ServletInfo resteasyWadlServlet = servlet("ResteasyWadlServlet", ResteasyWadlServlet.class)
                .setAsyncSupported(false)
                .setLoadOnStartup(1)
                .addMapping("/application.xml");
        di.addServlet(resteasyWadlServlet);

        di.setClassLoader(application.getClassLoader());
        di.setContextPath(contextPath);
        di.setDeploymentName("Resteasy" + contextPath);
        return server.deploy(di);
    }
}
```

From the above code, we can see the `ApplicationPath` is extracted from Application instance:

```java
ApplicationPath appPath = application.getAnnotation(ApplicationPath.class);
```

And then it's injected into the Undertow[^undertow] container:

```java
di.setContextPath(contextPath);
```

From the above study, we know that Application can help users to register resources into Servlet container in a cleaner way, nevertheless RESTEasy doesn't rely on Application to register classes. In addition, some RESTEasy non-servlet containers such as Netty4 and Sun JDK HTTP Server doesn't need Application to register resources.

For Servlet Container, RESTEasy provides helper classes such as `ServletContainerDispatcher` to help the container to prepare RESTEasy classes more conveniently. Here are the relative classes:

![2017-04-05-dispatcher.png]({{ site.url }}/assets/2017-04-05-dispatcher.png)

RESTEasy Undertow server is a servlet container, and `UndertowJaxrsServer` uses `ServletContainerDispatcher` like this:

```java
ServletInfo resteasyServlet = servlet("ResteasyServlet", HttpServlet30Dispatcher.class)
        .setAsyncSupported(true)
        .setLoadOnStartup(1)
        .addMapping(mapping);
```

I won't dig into more details in this article, but you should get a good understanding on RESTEasy Application support now.

### _References_

---

[^undertow]: [http://undertow.io.](http://undertow.io/)
