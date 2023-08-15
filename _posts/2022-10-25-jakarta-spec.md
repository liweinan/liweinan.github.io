---
title: How does the Jakarta RESTful Web Services Specification load an implementation into runtime.
--- 

The Jakarta RESTful Web Services Specification actually implements the service loading process, and it allows different implementation frameworks to be loaded in a standard way. Here is the code repository of the spec:

- [Jakarta RESTful Web Services](https://github.com/jakartaee/rest)

The above repository contains the Java code that defines the interfaces and part of the implementation code that should be shared around all the implementation frameworks.

> *Note* Currently the javadoc inside the code is still using the term `JAX-RS`, which should be replaced to `Jakarta RESTful Web Services`  or the acronym in the future. There were discussion to the acronym to be used and it is not determined yet: [Renamed project to ‘Jakarta RESTful Web Services’ by mkarg · Pull Request #763 · jakartaee/rest · GitHub](https://github.com/jakartaee/rest/pull/763#issuecomment-491907309)

In this article I want to analyze the way the spec loads an implementation framework into runtime. The loading process involves several classes, and here is their class diagram:

![](https://raw.githubusercontent.com/liweinan/blogpics2022/master/oct25/Class Diagram20.png)

The above two abstract classes(`HeaderDelegate` is an inner class of the `RuntimeDelegate` class) are implemented inside the spec code:

- `RuntimeDelegate`
- `FactoryFinder`

And inside `RuntimeDelegate` it defines the way to load the implementation into runtime. Here is the `javadoc` inside the `RuntimeDelegate` class:

![](https://raw.githubusercontent.com/liweinan/blogpics2022/master/oct25/D7143E22-8FC9-4159-AECD-B3367052BADD.png)

From the `javadoc` we can see this abstract class should be extended by every implementation framework. Besides, it already defines several methods related with the framework loading process. The entry method is the `getInstance()` method as shown in above class diagram, and here is the source code of the method:

![](https://raw.githubusercontent.com/liweinan/blogpics2022/master/oct25/6BEE2DBF-18A4-4EB2-A43C-A8193E89B378.png)

From the above code we can see it calls the `findDelegate()` method to do the implementation class loading. Here is the sequence diagram of the `findDelegate()` method:

![](https://raw.githubusercontent.com/liweinan/blogpics2022/master/oct25/jakarta.ws.rs.ext.RuntimeDelegate.findDelegate().png)

From above, we can see it called the `find()` method from the `FactoryFinder` class. Here is the source code of the `findDelegate()` method:

![](https://raw.githubusercontent.com/liweinan/blogpics2022/master/oct25/8F0F2FAE-A594-4E7A-927B-07E664A7FA64.png)

From the above code, we can see it passes the `JAXRS_RUNTIME_DELEGATE_PROPERTY` and `RuntimeDelegate.class` into the `Factory,find()` method. The value of `JAXRS_RUNTIME_DELEGATE_PROPERTY` is defined in the `RuntimeDelegate` class itself:

```java
public static final String JAXRS_RUNTIME_DELEGATE_PROPERTY = "jakarta.ws.rs.ext.RuntimeDelegate";
```

We’ll see how this value and the `RuntimeDelegate` class is used in the `find()` method of the `FactoryFinder` class:

![](https://raw.githubusercontent.com/liweinan/blogpics2022/master/oct25/F1ECA3FB-BA87-4C6A-AB2B-4391213EACAD.png)

From the above source code of the `FactoryFinder` class, we can see it passes the parameters into the `findFirstService()` method:

![](https://raw.githubusercontent.com/liweinan/blogpics2022/master/oct25/B74F5738-1AB8-43B1-A6B7-DB36062F7F4B.png)

From the above code we can see the parameters are actually passed into the `ServiceLoader.load()` method. Until now, we can see the whole process relies on the `ServiceLoader`, which is a feature provided by Java:

- [ServiceLoader (Java Platform SE 8 )](https://docs.oracle.com/javase/8/docs/api/java/util/ServiceLoader.html)

Generally speaking, one can write a pure text file with the interface or the abstract class name, and put the implementation class name inside the file, then `ServiceLoader` will help to load it into Java runtime.

So the loading process becomes clear: The implementation framework should provide a text file named `jakarta.ws.rs.ext.RuntimeDelegate` and put the implementation class into the file. Taking RESTEasy as one of the implementation frameworks for example, we can check whether it has this file or not. Doing a file search inside the RESTEasy source code directory will find the result:

```bash
➤ find . | grep jakarta.ws.rs.ext.RuntimeDelegate
./resteasy-core/src/main/resources/META-INF/services/jakarta.ws.rs.ext.RuntimeDelegate
```

As the result shown above, we can see it does have this file, and let’s see the content of the file:

```bash
➤ cat ./resteasy-core/src/main/resources/META-INF/services/jakarta.ws.rs.ext.RuntimeDelegate                                                                                                                                                                                                       
org.jboss.resteasy.core.providerfactory.ResteasyProviderFactoryImpl
```

From the above result, we can see RESTEasy provides an implementation class to the `jakarta.ws.rs.ext.RuntimeDelegate`, which is `ResteasyProviderFactoryImpl`. Here is the class diagram of the RESTEasy classes:

![](https://raw.githubusercontent.com/liweinan/blogpics2022/master/oct25/Class Diagram21.png)

As the class diagram shown above, we can see `ResteasyProviderFactoryImpl` extends the `ResteasyProviderFactory` class, and the `ResteasyProviderFactory` class extends the `RuntimeDelegate` class.

We can see this is the way defined by the spec how an implementation is loaded into runtime.
