---
title: "JNDI in Wildfly: Part 3 - The network layer of JBoss Remote Naming"
abstract: "The `jboss-remote-naming` project uses `jboss-remoting` as its network layer implementation. In this article, let's check the underlying network communication in the project.
---

# {{ page.title }}

{{ page.abstract }}

We can see the dependencies of `jboss-remote-naming` in its `pom.xml`. Here is the detail:

```xml
<dependency>
    <groupId>org.jboss.marshalling</groupId>
    <artifactId>jboss-marshalling</artifactId>
    <version>${version.org.jboss.marshalling}</version>
</dependency>

<dependency>
    <groupId>org.jboss.marshalling</groupId>
    <artifactId>jboss-marshalling-river</artifactId>
    <version>${version.org.jboss.marshalling}</version>
</dependency>

<dependency>
    <groupId>org.jboss.xnio</groupId>
    <artifactId>xnio-api</artifactId>
    <version>${version.org.jboss.xnio}</version>
</dependency>

<dependency>
    <groupId>org.jboss.xnio</groupId>
    <artifactId>xnio-nio</artifactId>
    <version>${version.org.jboss.xnio}</version>
    <scope>test</scope>
</dependency>

<dependency>
    <groupId>org.jboss.remoting</groupId>
    <artifactId>jboss-remoting</artifactId>
    <version>${version.org.jboss.remoting}</version>
</dependency>
```

The above are the related network components of the project. We can see `jboss-remoting` is the networking layer of the remoting service. To verify this, I run the `EJBInvocationTestCase` provided in the `jboss-remote-naming` project:

![/assets/naming/EJBInvocationTestCase.png](/assets/naming/EJBInvocationTestCase.png)

The above screenshot shows the test case is run and passed. Here is the network data packets captured from the Wireshark:

![/assets/naming/datapackets.png](/assets/naming/datapackets.png)

The above screenshot shows the data packets using the `Remoting` protocol. So we know `jboss-remote-naming` uses the `jboss-remoting` for network layer. This design is integrated into Wildfly application server.

In the previous article, we know the `ProtocolCommand` interface is used to define the methods to deal with remote naming requests from both server side and client side, and now let's review the code of the interface:

```java
package org.jboss.naming.remote.protocol;

public interface ProtocolCommand<T> {
    byte getCommandId();

    T execute(Channel channel, Object... args) throws IOException, NamingException;

    void handleServerMessage(Channel channel, DataInput input, int correlationId, RemoteNamingService remoteNamingService) throws IOException;

    void handleClientMessage(DataInput input, int correlationId, RemoteNamingStore namingStore) throws IOException;
}
```

From the above code, we can see there are two methods to deal with server request and client request. The `handleServerMessage(...)` method accept the instance of `RemoteNamingService` class as parameter, which means the server side is mainly to with `RemoteNamingService`. On the other hand, the `handleClientMessage(...)` method accepts a `RemoteNamingStore` instance, so we can know the naming store is used to serve the client request.

Here is the diagram that shows the classes related with `RemoteNamingStore` and `RemoteNamingService`:

![/assets/naming/server_and_store.png](/assets/naming/server_and_store.png)

From the above diagram, we can see the classes to deal with server side and client side are independent from each other.

Now we need to check the `Protocol` class. This class is the biggest one in the whole `jboss-remote-naming` project. We can see this from the code line counting result:

![/assets/naming/Protocol_count.png](/assets/naming/Protocol_count.png)

The above screenshot shows there are around 5k lines of code(excluding the test code) in the project, and we can see the `Protocol.java` contains 1k+ lines of code by itself!

This class is used to implement the different JNDI operations by implementing the `ProtocolCommand` interface. We can see the code in `Protocol` is like this:

```java
class Protocol {
    static ProtocolCommand<Object> LOOKUP = new BaseProtocolCommand<Object, ClassLoadingNamedIoFuture<Object>>((byte) 0x01) {
        ...
    };

    static ProtocolCommand<Void> BIND = new BaseProtocolCommand<Void, ProtocolIoFuture<Void>>((byte) 0x02) {
        ...
    };

    static ProtocolCommand<Void> REBIND = new BaseProtocolCommand<Void, ProtocolIoFuture<Void>>((byte) 0x03) {
        ...
    };
    
    ...
}
```

From the above excerpt of the code, we can see each JNDI operation is implemented as a `ProtocolCommand`. This means each operation needs to consider to accept the request from server side and client side. This is the reason that this is the biggest class in the project. Next we should check the implementation of each operation.








