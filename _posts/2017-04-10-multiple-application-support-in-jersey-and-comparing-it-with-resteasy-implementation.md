---
title: Multiple Application Support In Jersey And Comparing It With RESTEasy Implementation
abstract: Jersey supports multiple Application classes to be registered, on the other side currently RESTEasy doesn't support multiple Application classes deployment yet. In this article I'd like to give a brief introduction on Jersey implementation and compare it with RESTEasy current design.
---

{{ page.abstract }}

Firstly, we can see `ResteasyDeployment` doesn’t store multiple `Application` classes:

```java
ResteasyDeployment deployment = new ResteasyDeployment();
deployment.setApplicationClass(application.getName());
```

The `applicationClass` will be used to create an `Application` instance. Here is the relative code in `ResteasyDeployment.start()`:

```java
 if (applicationClass != null)
 {
     application = createApplication(applicationClass, dispatcher, providerFactory);
 }
```

From the above code we can see `createApplication()` method accepts the `applicationClass`, `dispatcher` and `providerFactory` as parameters, and here is the internal process of `createApplication()`:

```java
clazz = Thread.currentThread().getContextClassLoader().loadClass(applicationClass);
Application app = (Application)providerFactory.createProviderInstance(clazz);
dispatcher.getDefaultContextObjects().put(Application.class, app);
ResteasyProviderFactory.pushContext(Application.class, app);
PropertyInjector propertyInjector = providerFactory.getInjectorFactory().createPropertyInjector(clazz, providerFactory);
propertyInjector.inject(app);
```

From the above code, we can see RESTEasy stores a single `Application` instance internally. The data structure needs to be modified to store multiple `Application` instances. In Jersey, the `JerseyServletContainerInitializer` class accepts multiple `Application` definitions. Here is the relative code in `onStartupImpl()` method[^1]:

```java
for (final Class<? extends Application> applicationClass : getApplicationClasses(classes)) {
    addServletWithExistingRegistration(servletContext, servletRegistration, applicationClass, classes);
}
```

From the above code we can see Jersey accepts multiple `Application` classes with `getApplicationClasses()` method and deals with them in a loop. Here is the implementation of `getApplicationsClasses()` method:

```java
private static Set<Class<? extends Application>> getApplicationClasses(final Set<Class<?>> classes) {
    final Set<Class<? extends Application>> s = new LinkedHashSet<>();
    for (final Class<?> c : classes) {
        if (Application.class != c && Application.class.isAssignableFrom(c)) {
            s.add(c.asSubclass(Application.class));
        }
    }

    return s;
}
```

Now we can go back to `addServletWithExistingRegistration()` method to see how does it deals with `Application` class:

```java
// create a new servlet container for a given app.
final ResourceConfig resourceConfig = ResourceConfig.forApplicationClass(clazz, classes)
    .addProperties(getInitParams(registration))
    .addProperties(Utils.getContextParams(context));
```

The main logic of `addServletWithExistingRegistration()` is shown above. It will create an instance of `ResourceConfig` class[^2]. This class contains `Application` and the resource classes registered under the `Application`. Here is the class diagram of the `ResourceConfig`:

![2017-04-10-ResourceConfig.png]({{ site.url }}/assets/2017-04-10-ResourceConfig.png)

From the above diagram, we can see `WrappingResourceConfig` contains `application : javax.ws.rs.core.Application` and `defaultClasses : java.util.Set<Class<?>> = new HashSet<>()`, this provides the `application -> resources` mapping. If RESTEasy wants to support multiple `Application` deployment, it also needs to have a data structure to record the relationship between each Application instance and its included resources.

Please note `Application` is just a method to help users to register their resteful resources easier in Servlet container, both Jersey and RESTEasy core design don't merely rely on the `Application` to find and register resources, and other non-servet containers just don't need `Application` to register resources. You can refer to RESTEasy's Netty container document[^3] to see how it register resource classes via programmable interfaces.

### _References_

---

[^1]: [JerseyServletContainerInitializer.java](https://github.com/jersey/jersey/blob/master/containers/jersey-servlet/src/main/java/org/glassfish/jersey/servlet/init/JerseyServletContainerInitializer.java#L156)

[^2]: [ResourceConfig.java](https://github.com/jersey/jersey/blob/master/core-server/src/main/java/org/glassfish/jersey/server/ResourceConfig.java#L108)

[^3]: [RESTEasy_Embedded_Container.html.](http://docs.jboss.org/resteasy/docs/3.1.2.Final/userguide/html/RESTEasy_Embedded_Container.html#d4e1597)
