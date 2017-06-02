---
title: "JNDI in Wildfly: Part 1 - The Wildfly `naming` module"
abstract: "This series will be focused on the `Java Naming and Directory Interface` implementation in Wildfly. This first article will make a brief introduction on the overall design of Wildfly in this part."
---

# {{ page.title }}

{{ page.abstract }}

From the definition on Wikipedia, the `Java Naming and Directory Interface(JNDI)` is "a Java API for a directory service that allows Java software clients to discover and look up data and objects via a name"(See: [Java_Naming_and_Directory_Interface](https://en.wikipedia.org/wiki/Java_Naming_and_Directory_Interface)). The `JNDI` specification is defined by the interfaces in `javax.naming` package provided by JDK. Here is the screenshot of my `openjdk` source directory:

![/assets/naming/javax.naming.png](/assets/naming/javax.naming.png)

From the above screenshot, we can see the relative interfaces in `javax.naming` package. In Wildfly, the `naming` module implements the `JNDI` specification. Here is the screenshot of the Wildfly `nameing` module:

![/assets/naming/naming_subsystem.png](/assets/naming/naming_subsystem.png)

You can see the `naming` module and its structure in above screenshot, and Wildfly will use the module to provide its `JNDI` service during runtime. The `naming` module contains two kinds of the naming services, they are `RemoteNamingServerService` and `NamingService`. In this article, let's check the `NamingService` firstly. Here is the class diagram of the `NamingService` class:

![/assets/naming/NamingService.png](/assets/naming/NamingService.png)

From the above diagram, we can see the `SERVICE_NAME` of the `NamingService` is registered as `naming`, and in the class it contains a `namingStore`. The `namingStore` will be used to store the registered naming entries. Here is the class declaration of the `NamingService` class:

```java
public class NamingService implements Service<NamingStore> {
    public static final ServiceName SERVICE_NAME = ServiceName.JBOSS.append("naming");
```

From the above declaration, we can see `NamingService` implements the `Service<NamingStore>`, which means the service is to enable the `NamingStore` during Wildfly startup process. Now let's see the class diagram of `NamingStore`:

![/assets/naming/NamingStore.png](/assets/naming/NamingStore.png)


From the above diagram, we can see the `NamingStore` interface contains the operations defined by the JNDI spec. For example, there are operations like `lookup`, `list`, `listBindings`, etc.

`NamingStore` is an interface that can be implemented as a standalone container, or provided by the underlying application server. Here is the class diagram of the interface and its implementations:

![/assets/naming/naming-stores.png](/assets/naming/naming-stores.png)

We can see there are multiple implementations of `NamingStore` in above. The `InMemoryNamingStore` is not used in Wildfly production environment, but you can check its code see how to implement a naming store. The `ServiceBasedNamingStore` and its subclass are used by Wildfly runtime. We can see its usages in these classes:

```bash
$ pwd
/Users/weli/projs/jboss/wildfly/naming
$ grep -rl 'ServiceBasedNamingStore' *
src/main/java/org/jboss/as/naming/ContextListManagedReferenceFactory.java
src/main/java/org/jboss/as/naming/service/BinderService.java
src/main/java/org/jboss/as/naming/service/NamingStoreService.java
src/main/java/org/jboss/as/naming/ServiceBasedNamingStore.java
src/main/java/org/jboss/as/naming/subsystem/NamingBindingAdd.java
src/main/java/org/jboss/as/naming/WritableServiceBasedNamingStore.java
src/test/java/org/jboss/as/naming/ServiceBasedNamingStoreTestCase.java
src/test/java/org/jboss/as/naming/WritableServiceBasedNamingStoreTestCase.java
```

There are several test cases for both `ServiceBasedNamingStore` and `InMemoryNamingStore` you may want to check for their usages. In this article I won't dive into much detail on the usage part.

In this article, we have checked the `NamingService`, and knows that it will enable `NamingStore` during Wildfly startup process. In next article, let's check the `RemoteNamingServerService`.