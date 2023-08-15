---
title: An Introduction to the RESTEasy Builtin Provider
---

The [Jakarta RESTful Web Services](https://jakarta.ee/specifications/restful-ws/3.1/jakarta-restful-ws-spec-3.1.html#providercontext) has defined a `Providers` interface like this:

> The Providers interface allows for lookup of provider instances based on a set of search criteria. An instance of Providers can be injected into a class field or method parameter using the @Context annotation.

And in the spec codebase, it has a `jakarta.ws.rs.ext.Providers` interface:

- [rest/Providers.java at master · jakartaee/rest · GitHub](https://github.com/jakartaee/rest/blob/master/jaxrs-api/src/main/java/jakarta/ws/rs/ext/Providers.java)

Here is the class diagram of the `Providers` interface:

![](https://raw.githubusercontent.com/liweinan/blogpics2023/master/resteasy_builtins/Providers.jpg)

RESTEasy has implemented this interfaces in several classes. For example, the `ResteasyProviderFactoryImpl` class implements this interface. Here is one of the interface methods implemented by the class:

```java
/**
 * Always returns server MBRs.
 *
 * @param type        the class of the object that is to be read.
 * @param genericType the type of object to be produced. E.g. if the
 *                    message body is to be converted into a method parameter, this will be
 *                    the formal type of the method parameter as returned by
 *                    {@code Class.getGenericParameterTypes}.
 * @param annotations an array of the annotations on the declaration of the
 *                    artifact that will be initialized with the produced instance. E.g. if
 *                    the message body is to be converted into a method parameter, this will
 *                    be the annotations on that parameter returned by
 *                    {@code Class.getParameterAnnotations}.
 * @param mediaType   the media type of the data that will be read.
 * @param <T>         type
 * @return message reader
 */
public <T> MessageBodyReader<T> getMessageBodyReader(Class<T> type, Type genericType, Annotation[] annotations,
        MediaType mediaType) {
    MediaTypeMap<SortedKey<MessageBodyReader>> availableReaders = getServerMessageBodyReaders();
    MessageBodyReader<T> reader = resolveMessageBodyReader(type, genericType, annotations, mediaType,
            availableReaders);
    if (reader != null)
        LogMessages.LOGGER.debugf("MessageBodyReader: %s", reader.getClass().getName());
    return reader;
}
```

The above code shows the standard usage of the `jakarta.ws.rs.ext.Providers` interface in RESTEasy. Besides RESTEasy has an additional usage of the interface: It uses the interface canonical name as the [provider-configuration file](https://docs.oracle.com/javase/8/docs/api/java/util/ServiceLoader.html) to include the builtin providers. In this article, I’ll explain how does this feature work in RESTEasy.

## The Register Builtin Providers

When a RESTEasy based service is started, the RESTEasy framework will load some builtin providers by default. This is defined in a file inside the `resteasy-core`:

- https://github.com/resteasy/resteasy/blob/main/resteasy-core/src/main/resources/META-INF/services/jakarta.ws.rs.ext.Providers

The above file is located in the `resteasy-core/src/main/resources/META-INF/services/` directory, and the filename is `jakarta.ws.rs.ext.Providers`. This follows the rule defined in the [Java Service Provider Interface](https://www.baeldung.com/java-spi) specification. RESTEasy just follow the specification to place the file in this location, and it will process the file by itself. Here is the content of the above file currently:

```
org.jboss.resteasy.plugins.providers.AsyncStreamingOutputProvider
org.jboss.resteasy.plugins.providers.DataSourceProvider
org.jboss.resteasy.plugins.providers.DocumentProvider
org.jboss.resteasy.plugins.providers.DefaultTextPlain
org.jboss.resteasy.plugins.providers.DefaultNumberWriter
org.jboss.resteasy.plugins.providers.DefaultBooleanWriter
org.jboss.resteasy.plugins.providers.StringTextStar
org.jboss.resteasy.plugins.providers.SourceProvider
org.jboss.resteasy.plugins.providers.InputStreamProvider
org.jboss.resteasy.plugins.providers.ReaderProvider
org.jboss.resteasy.plugins.providers.ByteArrayProvider
org.jboss.resteasy.plugins.providers.FormUrlEncodedProvider
org.jboss.resteasy.plugins.providers.JaxrsFormProvider
org.jboss.resteasy.plugins.providers.CompletionStageProvider
org.jboss.resteasy.plugins.providers.ReactiveStreamProvider
org.jboss.resteasy.plugins.providers.FileProvider
org.jboss.resteasy.plugins.providers.FileRangeWriter
org.jboss.resteasy.plugins.providers.StreamingOutputProvider
org.jboss.resteasy.plugins.providers.IIOImageProvider
org.jboss.resteasy.plugins.providers.MultiValuedParamConverterProvider
org.jboss.resteasy.plugins.interceptors.CacheControlFeature
org.jboss.resteasy.plugins.interceptors.ClientContentEncodingAnnotationFeature
org.jboss.resteasy.plugins.interceptors.ServerContentEncodingAnnotationFeature
org.jboss.resteasy.plugins.interceptors.MessageSanitizerContainerResponseFilter
org.jboss.resteasy.plugins.providers.sse.SseEventProvider
org.jboss.resteasy.plugins.providers.sse.SseEventSinkInterceptor
```

It’s a pure-text file and contains a list of providers (also including some interceptors, filters, etc) that will be loaded by default. The class used to processing the above file is `RegisterBuiltin`:

- [resteasy/RegisterBuiltin.java at main · resteasy/resteasy · GitHub](https://github.com/resteasy/resteasy/blob/main/resteasy-core/src/main/java/org/jboss/resteasy/plugins/providers/RegisterBuiltin.java)

Here is the class diagram of the above class:

![](https://raw.githubusercontent.com/liweinan/blogpics2023/master/resteasy_builtins/RegisterBuiltin.jpg)

As the diagram shows, it contains a method called `scanBuiltins`. Here is the code of the method:

```java
public static Map<String, URL> scanBuiltins() throws IOException, PrivilegedActionException {
    Enumeration<URL> en;
    if (System.getSecurityManager() == null) {
        en = Thread.currentThread().getContextClassLoader().getResources("META-INF/services/" + Providers.class.getName());
    } else {
        en = AccessController.doPrivileged(new PrivilegedExceptionAction<Enumeration<URL>>() {
            @Override
            public Enumeration<URL> run() throws IOException {
                return Thread.currentThread().getContextClassLoader()
                        .getResources("META-INF/services/" + Providers.class.getName());
            }
        });
    }

    Map<String, URL> origins = new HashMap<String, URL>();
    while (en.hasMoreElements()) {
        final URL url = en.nextElement();
        InputStream is;
        if (System.getSecurityManager() == null) {
            is = url.openStream();
        } else {
            is = AccessController.doPrivileged(new PrivilegedExceptionAction<InputStream>() {
                @Override
                public InputStream run() throws IOException {
                    return url.openStream();
                }
            });
        }

        try {
            BufferedReader reader = new BufferedReader(new InputStreamReader(is, StandardCharsets.UTF_8));
            String line;
            while ((line = reader.readLine()) != null) {
                int commentIdx = line.indexOf('#');
                if (commentIdx >= 0) {
                    line = line.substring(0, commentIdx);
                }
                line = line.trim();
                if (line.equals(""))
                    continue;
                origins.put(line, url);
            }
        } finally {
            is.close();
        }
    }
    return origins;
}
```

And this is the core part of the above method:

```java
Enumeration<URL> en;
en = Thread.currentThread().getContextClassLoader().getResources("META-INF/services/" + Providers.class.getName());
```

As the code shown above, it loads the `jakarta.ws.rs.ext.Providers` file content located in the `META-INF/services/` directory, and then read the file content line by line and put it into a set called `en`. Then the `registerProviders` method will use the set to load these providers by default. Here is the code of the `registerProviders` method:

```java
public static void registerProviders(ResteasyProviderFactory factory) throws Exception {
    Map<String, URL> origins = scanBuiltins();
    for (final Entry<String, URL> entry : origins.entrySet()) {
        final String line = entry.getKey();
        try {
            Class<?> clazz;
            if (System.getSecurityManager() == null) {
                clazz = Thread.currentThread().getContextClassLoader().loadClass(line);
            } else {
                clazz = AccessController.doPrivileged(new PrivilegedExceptionAction<Class<?>>() {
                    @Override
                    public Class<?> run() throws ClassNotFoundException {
                        return Thread.currentThread().getContextClassLoader().loadClass(line);
                    }
                });
            }

            factory.registerProvider(clazz, true);
        } catch (NoClassDefFoundError e) {
            LogMessages.LOGGER.noClassDefFoundErrorError(line, entry.getValue(), e);
        } catch (ClassNotFoundException | PrivilegedActionException ex) {
            LogMessages.LOGGER.classNotFoundException(line, entry.getValue(), ex);
        }
    }
    if (isGZipEnabled()) {
        factory.registerProvider(GZIPDecodingInterceptor.class, true);
        factory.registerProvider(GZIPEncodingInterceptor.class, true);
    }
}
```

As the code shown above, it will scan the builtins firstly:

```java
Map<String, URL> origins = scanBuiltins();
```

And then it will process the defined provider classes line by line:

```java
for (final Entry<String, URL> entry : origins.entrySet()) {
...
```

And finally it will register the class into `ResteasyProviderFactory`:

```java
factory.registerProvider(clazz, true);
```

So this is the implementation of the RESTEasy builtin providers feature. Besides the `jakarta.ws.rs.ext.Providers` file defined in the `resteasy-core/src/main/resources/META-INF/services/` directory by default, you can also use this feature to define your providers that you want your service to load by default during the startup process. For example, there are several sample usages in the RESTEasy providers submodule and also in the test codebase:

```txt
./resteasy-client/src/main/resources/META-INF/services/jakarta.ws.rs.ext.Providers
./resteasy-rxjava2/src/main/resources/META-INF/services/jakarta.ws.rs.ext.Providers
./security/resteasy-crypto/src/main/resources/META-INF/services/jakarta.ws.rs.ext.Providers
./testsuite/integration-tests/src/test/resources/org/jboss/resteasy/test/providers/jackson2/jakarta.ws.rs.ext.Providers
./testsuite/integration-tests/src/test/resources/org/jboss/resteasy/test/resource/param/jakarta.ws.rs.ext.Providers
./testsuite/integration-tests/src/test/resources/org/jboss/resteasy/test/resource/param/jakarta.ws.rs.ext.Providers_HeaderDelegateAsProvider
./testsuite/integration-tests/src/test/resources/org/jboss/resteasy/test/client/jakarta.ws.rs.ext.Providers
./testsuite/integration-tests/src/test/resources/org/jboss/resteasy/test/interceptor/gzip/GzipAbstractTest-jakarta.ws.rs.ext.Providers
./providers/jackson2/src/main/resources/META-INF/services/jakarta.ws.rs.ext.Providers
./providers/resteasy-validator-provider/src/main/resources/META-INF/services/jakarta.ws.rs.ext.Providers
./providers/fastinfoset/src/main/resources/META-INF/services/jakarta.ws.rs.ext.Providers
./providers/jaxb/src/main/resources/META-INF/services/jakarta.ws.rs.ext.Providers
./providers/multipart/src/main/resources/META-INF/services/jakarta.ws.rs.ext.Providers
./providers/resteasy-html/src/main/resources/META-INF/services/jakarta.ws.rs.ext.Providers
```

So the providers defined in the above files will be loaded when above modules are in the class path. In addition, there is a test related with this feature for reference:

- [resteasy/WriterNotBuiltinTest.java at main · resteasy/resteasy · GitHub](https://github.com/resteasy/resteasy/blob/main/testsuite/integration-tests/src/test/java/org/jboss/resteasy/test/providers/custom/WriterNotBuiltinTest.java)

This feature is also used in WildFly integration environment. Here is the relative document shows its usage:

- [RESTEasy modules in WildFly](https://docs.jboss.org/resteasy/docs/6.2.2.Final/userguide/html/ch03.html#resteasy_modules_in_wildfly)

This is the basic usage of the RESTEasy builtin providers feature. 

Please note that this feature will be deprecated in the future. See:

- [https://issues.redhat.com/browse/RESTEASY-2437](https://issues.redhat.com/browse/RESTEASY-2437)
- [https://issues.redhat.com/browse/RESTEASY-3108](https://issues.redhat.com/browse/RESTEASY-3108) 

In addition, the `ResteasyProviderFactory` is likely to be deprecated as well as loading the providers through a pseudo service file. 




