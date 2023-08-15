---
title: An introduction to the SeBootstrap Spec and the RESTEasy Implementation
--- 

`SeBootstrap` is a feature defined by the Jakarta Spec:

- [GitHub - jakartaee/rest: Jakarta RESTful Web Services](https://github.com/jakartaee/rest)

Here is the `javadoc` of the `jakarta.ws.rs.SeBootstrap` interface:

![](https://raw.githubusercontent.com/liweinan/blogpics2022/master/oct26/9DBD8875-2B0E-4272-980D-904218367095.png)

The above `javadoc` explains the purpose of `SeBootstrap`. Now let’s see its design.

## The design of the `SeBootstrap`

Here is the class diagram of the `SeBootstrap` interfaces in the spec:

![](https://raw.githubusercontent.com/liweinan/blogpics2022/master/oct26/sebootstrap.jpg)

- `SeBootstrap` contains `start()` methods which accepts an instance of `Application`, and an optional `Configuration` typed instance, and it will return a type of `CompletionStage<Instance>` instance.
- `Instance` type contains a `stop()` method that returns a type of `StopResult` instance.
- `Instance` type also contains a `configuration()` method that returns a type of `Configuration` instance.
- The `Configuration` type can be used to define multiple parameters of a `Instance`.
- The `Configuration` type contains a `Builder` and can be used to create an instance of `Configuration`.
- The `Builder` has multiple configuration methods such as `protocol()`, `host()`, and `port()`, etc.
- The `Builder` has a `build()` method that finally creates a `Configuration` method.

Here is the `start()` method inside the `SeBootstrap` interface:

![](https://raw.githubusercontent.com/liweinan/blogpics2022/master/oct26/E6A4BEAE-6C75-46CB-B3CF-2340D3D7BC53.png)

We can see it will use a `RuntimeDelegate` instance to bootstrap the `Application` instance. The `RuntimeDelegate` should be implemented by the implementation frameworks. For example, RESTEasy is one of the implementation frameworks and it provides `org.jboss.resteasy.core.providerfactory.ResteasyProviderFactoryImpl` to implement the interface. To understand how does the framework implementation loading process work, you can check this article:

- [How does the Jakarta RESTful Web Services Specification load an implementation into runtime.](https://weinan.io/2022/10/25/jakarta-spec.html)

Next let’s see how RESTEasy implements the `SeBootstrap` feature.

## The RESTEasy SeBootstrap Implementation

Here is the class diagram related with the implementation of RESTEasy SeBootstrap feature:

![](https://raw.githubusercontent.com/liweinan/blogpics2022/master/oct26/resteasy_sebootstrap_impl.jpg)

Here are a few notes to the above classes:

- The `ResteasySeInstance` class implements the `jakarta::ws::rs::SeBootstrap` interface.
- The `ResteasySeConfiguration` class implements the `jakarta::ws::rs::SeBootstrap` interface.
- An inner `Builder` class inside the `ResteasySeConfiguration` class implements the `jakarta::ws::rs::SeBootstrap::Configuration` interface.

The core part of the implementation is the `ResteasySeInstance` class, which create a concrete SeBootstrap Instance for use. Here is the code of the `create()` method in the `ResteasySeInstance` class:

```java
/**
 * Creates a new {@link Instance} based on the {@linkplain Application application} and
 * {@linkplain Configuration configuration} passed in.
 * <p>
 * Note that if your {@link Application} does not override the {@link Application#getClasses()} or
 * {@link Application#getSingletons()} a {@linkplain Index Jandex index} is used to find resources and providers.
 * It's suggested that your application has a {@code META-INF/jandex.idx} or you provide an index with the
 * {@link ConfigurationOption#JANDEX_INDEX} configuration option. If neither of those exist, the class path itself
 * is indexed which could have significant performance impacts.
 * </p>
 *
 * @param application   the application to use for this instance
 * @param configuration the configuration used to configure the instance
 *
 * @return a {@link CompletionStage} which asynchronously produces and {@link Instance}
 */
public static CompletionStage<Instance> create(final Application application,
                                               final Configuration configuration) {
    final ExecutorService executor = ContextualExecutors.threadPool();
    return CompletableFuture.supplyAsync(() -> {
        try {
            final Configuration config = ResteasySeConfiguration.from(configuration);
            final EmbeddedServer server = EmbeddedServers.findServer(config);
            final ResteasyDeployment deployment = server.getDeployment();
            deployment.setRegisterBuiltin(ConfigurationOption.REGISTER_BUILT_INS.getValue(config));
            deployment.setApplication(application);
            try {
                scanForResources(deployment, application, config);
            } catch (IOException e) {
                throw Messages.MESSAGES.failedToScanResources(e);
            }
            deployment.start();
            if (LOGGER.isDebugEnabled()) {
                LOGGER.debugf("Application %s used for %s", deployment.getApplication(), server);
                deployment.getResourceClasses()
                        .forEach(name -> LOGGER.debugf("Resource %s found for %s", name, server));
                deployment.getProviderClasses()
                        .forEach(name -> LOGGER.debugf("Provider %s found for %s", name, server));
            }
            server.start(config);
            return new ResteasySeInstance(server, config, executor);
        } catch (Throwable t) {
            throw new CompletionException(t);
        }
    }, executor);
}
```

From the above code we can see the `create()` method of the `ResteasySeInstance` class takes the duty to setup the RESTEasy engine properly for use. And this line of the code takes the core role:

```java
final EmbeddedServer server = EmbeddedServers.findServer(config);
```

As the code shown above, RESTEasy defines a `EmbeddedServer` interface, and then try to find a server implementation from the runtime, and loads it. Finally it starts the server and wraps it into `ResteasySeInstance`:

```java
server.start(config);
return new ResteasySeInstance(server, config, executor);
```

Here is the class diagram of the `EmbeddedServer`:

![](https://raw.githubusercontent.com/liweinan/blogpics2022/master/oct26/Class Diagram23.png)

And RESTEasy already provides several implementations to the above interface:

![](https://raw.githubusercontent.com/liweinan/blogpics2022/master/oct26/E934BF73-24FF-4931-A4EF-0B742C23009B.png)

As the implementation list shown above, we can see RESTEasy provides several server backends for using. Until now, we have learned the design of the Bootstrap interfaces and its implementation in the RESTEasy framework. As this article is about the design of the RESTEasy SeBootstrap feature, not its usages, so I won’t explain its usages. I’ll put the introduction of the usages in a [separate article](https://resteasy.dev/2022/11/01/sebootstrap-usage/).

