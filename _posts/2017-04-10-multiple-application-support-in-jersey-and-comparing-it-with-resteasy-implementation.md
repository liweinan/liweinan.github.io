---
title: Multiple Application Support In Jersey And Comparing It With RESTEasy Implementation
abstract: Jersey supports multiple Application classes to be registered, on the other side currently RESTEasy doesn't support multiple Application classes deployment yet. In this article I'd like to give a brief introduction on Jersey implementation and compare it with RESTEasy current design.
---

## _{{ page.title }}_

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

From the above code, we can see RESTEasy stores a single `Application` instance internally. The data structure needs to be modified to store multiple `Application` instances. In Jersey, the `JerseyServletContainerInitializer` class accepts multiple `Application` definitions. Here is the relative code in `JerseyServletContainerInitializer.onStartupImpl()` method:

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

The main logic of  `JerseyServletContainerInitializer.addServletWithExistingRegistration()` is shown above. It will create an instance of `ResourceConfig` class. This class contains `Application` and the resource classes registered under the `Application`. Here is the class diagram of the `ResourceConfig`:

![2017-04-10-ResourceConfig.png]({{ site.url }}/assets2017-04-10-ResourceConfig.png)
