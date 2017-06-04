---
title: "JNDI in Wildfly: Part 2 - The remote naming service"
abstract: "In this article, let's check the Wildfly Remote Naming Service."
---

# {{ page.title }}

{{ page.abstract }}

In the previous article, we have checked `NamingStore` and `NamingsService`. We understand that the purpose of the `NamingService` is to enable `NamingStore` during Wildfly startup process. In addition to this process, Wildfly also need to enable remote naming service, so the users can access the service from other machines via network.

Here is the relative configuration in `standalone.xml`:

```xml
$ grep -C 2 'remote-naming' standalone.xml
        </subsystem>
        <subsystem xmlns="urn:jboss:domain:naming:2.0">
            <remote-naming/>
        </subsystem>
        <subsystem xmlns="urn:jboss:domain:pojo:1.0"/>
```

From the above configuration, we can see in basic standalone mode, the Wildfly naming subsystem will enable the '<remote-naming/>' by default. In source code, the `RemoteNamingServerService` will enable the remote naming service. Here is the class diagram of the `RemoteNamingServerService`:

![/assets/naming/RemoteNamingServerService.png](/assets/naming/RemoteNamingServerService.png)

From the above diagram, we can see the the `RemoteNamingServerService` contains the `remoteNamingService` and `namingStore`. We have learned the `namingStore` is the backend repository of the registered naming resources. On the other hand, the `remoteNamingService` is the class that provides naming service remote access ability.

In addition, `RemoteNamingServerService` will inject `NamingStore` into `RemoteNamingService`. Here is the relative code in 
the`RemoteNamingServerService` class:

```java
public synchronized void start(StartContext context) throws StartException {
    try {
        final Context namingContext = new NamingContext(namingStore.getValue(), new Hashtable<String, Object>());
        remoteNamingService = new RemoteNamingService(namingContext, executorService.getValue(), RemoteNamingLogger.INSTANCE);
        remoteNamingService.start(endpoint.getValue());
    } catch (Exception e) {
        throw new StartException("Failed to start remote naming service", e);
    }
}
```

The above code shows the logic of the `start(...)` method: It will create a `namingContext` with `namingStore` included, and then register the `namingContentxt` into `remoteNamingServer`. Finally it starts the `remoteNamingService` by calling its `start(...)` method.

So we should focus on checking the `RemoteNamingService` class provided by the `jboss-remote-naming` project to see how it's implemented. Before that, we need to fetch the source code of the `jboss-remote-naming` project. You can find the source code of this project on Github. Here is the URL of the project:

[https://github.com/jbossas/jboss-remote-naming](https://github.com/jbossas/jboss-remote-naming)

You need to clone the above repository to your local machine to check the source code. Here is the screenshot of the project in my IDE:

![/assets/naming/remote-naming.png](/assets/naming/remote-naming.png)

From the above screenshot, you can see the project structure of the `jboss-remote-naming` project.

Now let's see the class diagram of the `RemoteNamingService` class:

![/assets/naming/RemoteNamingService.png](/assets/naming/RemoteNamingService.png)

From the above diagram, we can see the `RemoteNamingService` and its inner classes. We know the service loading process in Wildfly is asynchronous, so from above diagram, we can see `RemoteNamingService` will use `ChannelOpenListener` and `ChannelCloseHandler` to manage the service lifecycle. There is an additional `ClientVersionReceiver` inner class in the diagram, and we will check its usage later.

The next step we can check the `start(...)` method of the `RemoteNamingService`. Here is the sequence diagram of the method:

![/assets/naming/org.jboss.naming.remote.server.RemoteNamingService.start(Endpoint).png](/assets/naming/org.jboss.naming.remote.server.RemoteNamingService.start(Endpoint).png)

From the above sequence diagram, we can see the `start(...)` method of `RemoteNamingService` is just to register the `ChannelOpenListener`. Now let's see the code of `ChannelOpenListener`:

```java
private class ChannelOpenListener implements OpenListener {
    public void channelOpened(Channel channel) {
        log.debugf("Channel Opened - %s", channel);
        channel.addCloseHandler(new ChannelCloseHandler());
        try {
            writeHeader(channel);
            channel.receiveMessage(new ClientVersionReceiver());
        } catch (IOException e) {
            logger.failedToSendHeader(e);
            IoUtils.safeClose(channel);
        }
    }

    public void registrationTerminated() {
    }
}
```

From the above code, we can see the `ChannelOpenListener` uses `ClientVersionReceiver` to handle the received message. From the above diagram, we can see the `ClientVersionReceiver` has a `handleMessage(...)` method. This method is used to handle the received message. Let's see the code of `handleMessage(...)` message:

```java
public void handleMessage(Channel channel, MessageInputStream messageInputStream) {
    DataInputStream dis = new DataInputStream(messageInputStream);
    try {
        byte[] namingHeader = new byte[6];
        dis.read(namingHeader);
        if (!Arrays.equals(namingHeader, NAMING)) {
            throw new IOException("Invalid leading bytes in header.");
        }
        byte version = dis.readByte();
        log.debugf("Chosen version 0x0%d", version);

        Versions.getRemoteNamingServer(version, channel, RemoteNamingService.this);
    } catch (IOException e) {
        logger.failedToDetermineClientVersion(e);
    } finally {
        IoUtils.safeClose(dis);
    }
}
```

The above code shows that it will read the `namingHeader` from the received message via network, and determines the correct `RemoteNamingServer` to use. Actually there is only one version of `RemoteNamingServer` currently, and it's named `RemoteNamingServerV1`. Here is the class diagram of the `RemoteNamingServer` and its implementation:

![/assets/naming/RemoteNamingServer.png](/assets/naming/RemoteNamingServer.png)

From the above diagram, we can see `RemoteNamingServer` currently has one version of implementation, which is `RemoteNamingServerV1`. In addition, we can see the `RemoteNamingServerV1` contains `MessageReceiver` to deal with the incoming request.

We can see the full package name of `RemoteNamingServerV1` is `org.jboss.naming.remote.protocol.v1`. In this package, it contains the current implementation of the remote naming server. In the package, it contains a `Protocol` class that implements the relative JNDI operations. Here is the screenshot of the class:

![/assets/naming/Protocol.png](/assets/naming/Protocol.png)

From the above screenshot, we can see the operations implemented by the class. Because the `Protocol` class is very big and it contains a thousand lines of code, so I won't explain its detail implementation here.

Now let's check the `RemoteNamingStore` interface and its implementation `RemoteNamingStoreV1`. Here is the class diagram of them:

![/assets/naming/RemoteNamingStore.png](/assets/naming/RemoteNamingStore.png)

From the above diagram, we can see the `RemoteNamingStore` is used to store the naming resources provide the resources via JNDI operations.

What's the relationship of the `RemoteNamingStore` interface and the `RemoteNamingServer` interface? To answer this question, we can check the `ProtocolCommand` interface. Here is the class diagram of the interface:

![/assets/naming/ProtocolCommand.png](/assets/naming/ProtocolCommand.png)

From the above diagram, we can see the `ProtocolCommand` defines two methods: one is `handleServerMessage(...)` and the other is `handleClientMessage(...)`.

In `handleServerMessage(...)` method, it uses the `remoteNamingService` (There is currently a type in the class, and I have submitted the PR to fix it. See: [fix a minor typo in ProtocolCommand #32](https://github.com/jbossas/jboss-remote-naming/pull/32/files)) to interact with the naming service provider(The Wildfly server in our case).

In `handleClientMessage(...)` method, it uses the `namingStore` to deal with the user requests. This is very similar to the situation we have see in the previous article, which Wildfly uses the local `NamingStore` to deal with the local JNDI requests.

The `ProcotolCommand` interface is implemented in each JNDI operation defined in the `Protocol` class. For example, here is the code in `Protocol` class that implements the JNDI `LOOKUP` operation:

```java
class Protocol {
    static ProtocolCommand<Object> LOOKUP = new BaseProtocolCommand<Object, ClassLoadingNamedIoFuture<Object>>((byte) 0x01) {

        public void handleServerMessage(Channel channel, final DataInput input, final int correlationId, final RemoteNamingService remoteNamingService) throws IOException {

            final Unmarshaller unmarshaller = prepareForUnMarshalling(input, this.getClass().getClassLoader());
            Name name;
            try {
                byte paramType = unmarshaller.readByte();
                if (paramType != NAME) {
                    remoteNamingService.getLogger().unexpectedParameterType(NAME, paramType);
                }
                name = unmarshaller.readObject(Name.class);
            } catch (ClassNotFoundException cnfe) {
                throw new IOException(cnfe);
            } finally {
                unmarshaller.close();
            }

            try {
                final Object result = remoteNamingService.getLocalContext().lookup(name);
                write(channel, new WriteUtil.Writer() {
                    public void write(DataOutput output) throws IOException {
                        output.writeByte(getCommandId());
                        output.writeInt(correlationId);
                        output.writeByte(SUCCESS);
                        if (result instanceof Context) {
                            output.writeByte(CONTEXT);
                        } else {
                            output.writeByte(OBJECT);
                            final Marshaller marshaller = prepareForMarshalling(output);
                            marshaller.writeObject(result);
                            marshaller.finish();
                        }
                    }
                });
            } catch (NamingException e) {
                writeExceptionResponse(channel, e, getCommandId(), correlationId);
            }
        }

        public void handleClientMessage(final DataInput input, final int correlationId, final RemoteNamingStore namingStore) throws IOException {
            readResult(correlationId, input, new ValueReader<ClassLoadingNamedIoFuture<Object>>() {
                public void read(final DataInput input, ClassLoadingNamedIoFuture<Object> future) throws IOException {
                    byte parameterType = input.readByte();
                    switch (parameterType) {
                        case OBJECT: {
                            try {
                                final Unmarshaller unmarshaller = prepareForUnMarshalling(input, future.getClassLoader());
                                future.setResult(unmarshaller.readObject());
                                unmarshaller.finish();
                            } catch (ClassNotFoundException e) {
                                throw new IOException(e);
                            } catch (ClassCastException e) {
                                throw new IOException(e);
                            }
                            break;
                        }
                        case CONTEXT: {
                            future.setResult(new RemoteContext(NamedIoFuture.class.cast(future).name, namingStore, new Hashtable<String, Object>()));
                            break;
                        }
                        default: {
                            throw new IOException("Unexpected response parameter received.");
                        }

                    }
                }
            });
        }
    };
}
```

I have removed unrelated code and in above you can see how does the `LOOKUP` operation implements the `ProtocolCommand` interface, and how the `namingStore` and `namingService` are used in the methods. We can see the `Protocol` class uses the `ProtocolCommand` to provide services to both server side (Wildfly) and user side. Compared with the local naming service in Wildfly source base as we see in last article, the remote design is more complex.

Above are all the topics I want to say in this article. In the next article, let's see the network communication layer of the `jboss-remote-naming` project.



