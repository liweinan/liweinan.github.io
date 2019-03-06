---
title: "Analyzing the JBoss Remoting Protocol - Continued"
abstract: "This article will analyze the JBoss Remoting Protocol in detail."
---

# {{ page.title }}

This article is the continued part of this article: [Analyzing the JBoss Remoting Protocol](http://weinan.io/2017/05/23/remoting.html). In this part, let's see the detail of the JBoss Remoting Protocol.

I will use the `ConnectionTestCase.testManyChannelsLotsOfData()` method in this article. You can find the source code of the test case on Github: [ConnectionTestCase.java](https://github.com/jboss-remoting/jboss-remoting/blob/master/src/test/java/org/jboss/remoting3/test/ConnectionTestCase.java). Generally speaking, the `ConnectionTestCase` will startup a server endpoint, and create a client endpoint to connect to the server. The client will firstly send the username and password to the server for authentication. After the authentication is succeed, the client will send some data to the server. Finally the communication is over and server will be closed. This is a typical communication process, and we will use Wireshark to monitor the network traffic to see the network packets in detail.

In addition, in the `before()` method of the `ConnectionTestCase`, we can see some important information of the server endpoint. Here is the code of the `before()` method:

```java
@Before
public void before() throws Exception {
    System.gc();
    System.runFinalization();
    Logger.getLogger("TEST").infof("Running test %s", name.getMethodName());
    final NetworkServerProvider networkServerProvider = serverEndpoint.getConnectionProviderInterface("remote", NetworkServerProvider.class);
    final SecurityDomain.Builder domainBuilder = SecurityDomain.builder();
    final SimpleMapBackedSecurityRealm mainRealm = new SimpleMapBackedSecurityRealm();
    domainBuilder.addRealm("mainRealm", mainRealm).build();
    domainBuilder.setDefaultRealmName("mainRealm");
    final PasswordFactory passwordFactory = PasswordFactory.getInstance("clear");
    mainRealm.setPasswordMap("bob", passwordFactory.generatePassword(new ClearPasswordSpec("pass".toCharArray())));
    final SaslServerFactory saslServerFactory = new ServiceLoaderSaslServerFactory(getClass().getClassLoader());
    final SaslAuthenticationFactory.Builder builder = SaslAuthenticationFactory.builder();
    domainBuilder.setPermissionMapper((permissionMappable, roles) -> PermissionVerifier.ALL);
    builder.setSecurityDomain(domainBuilder.build());
    builder.setFactory(saslServerFactory);
    builder.setMechanismConfigurationSelector(mechanismInformation -> SaslMechanismInformation.Names.SCRAM_SHA_256.equals(mechanismInformation.getMechanismName()) ? MechanismConfiguration.EMPTY : null);
    final SaslAuthenticationFactory saslAuthenticationFactory = builder.build();
    server = networkServerProvider.createServer(new InetSocketAddress("localhost", 30123), OptionMap.create(Options.SSL_ENABLED, Boolean.FALSE), saslAuthenticationFactory, SSLContext.getDefault());
}
```

From the above code, we can see the server will accept the username `bob`, and its password is `pass`. This information is stored in server side for authentication, and client will need to use `bob/pass` to pass the authentication of server later.

In addition, the server will accept the `SCRAM_SHA_256` encryption method for data communication. JBoss Remoting supports many different encryption algorithms, and the service and client need to negotiate what method to use. We will see the negotiation process between server and client later. Finally, we can see the server will serve at TCP port `30123`. We will capture the data to and from this port in Wireshark later.
 
Now let's check the JBoss Remoting Protocol class. The JBoss Remoting Protocol is defined in the `org.jboss.remoting3.remote.Protocol` class, and it's well documented. You can check the class on Github: [Protocol.java](https://github.com/jboss-remoting/jboss-remoting/blob/master/src/main/java/org/jboss/remoting3/remote/Protocol.java). Here is the class diagram of the `Protocol` class:

![/assets/remoting/Protocol.png](/assets/remoting/Protocol.png)

From the above diagram, we can see the packet type and attributes defined by JBoss Remoting Protocol. We will check the detail later.

After the above investigation, I started the test and capture the data packets transmitted between server and client. Because the communication between server and client happened on local machine, so I just need to capture the `lo` interface and filter out the data packets that are using the `Remoting` protocol. I have captured the whole process with Wireshark screenshots, and let's see them one by one. Here is the first screenshot:

![/assets/remoting/lo_001.png](/assets/remoting/lo_001.png)

From the above screenshot, we can see the first data packet is sent from server to the client, because the `Src Port` is `30123`, and the `Dst Port` is `36797`. We know that the server is set to listen on port `30123`, so we can understand this packet is sent from server to client.

In addition, we can see the `Remoting Type` of this packet is `Greeting`. From `Protocol.java`, we can get the document of the `Greeting` message. Here is the code:

```java
/**
 * Sent by server only.
 * byte 0: GREETING
 * byte 1..n: greeting message body
 */
static final byte GREETING = 0;
```

From the above code, we can understand that the greeting message is sent from server to client as the beginning of the communication process. In addition, from the above screenshot, we can see the `Greeting` message contains the `Greeting Parametmers`. Under `Greeting Parametmers`, it contains one item, which is `Server Name`, and its value is `localhost`. This information will be passed to client side for processing. 

Now let's see what the client responded to the server:

![/assets/remoting/lo_002.png](/assets/remoting/lo_002.png)

From the above screenshot, we can see the client responded to server with a `Capabilities` typed message. Here is the document in `Protocol` class for the type:

```java
/**
 * Sent by client then server.
 * byte 0: CAPABILITIES
 * byte 1..n: capabilities summary
 */
static final byte CAPABILITIES = 1;
```

From the above code and the above screenshot, we can understand the `capabilities` message contains the information of the communication. From the above screenshot we can see the relative information of this communication is contained in the `Capability Parameters`.

There are multiple fields in `Capability Parameters`. They are: `Protocol Version`, `Endpoint Name`, `Supports Msg Close Protocol`, `Impl Version`, `Inbound Channel`, `Outbound Channel`. The information will be used for negotiation between server and client to determine the communication details.

Now let's see how does the server responded to the `capabilities` request from the client. Here is the screenshot: 

![/assets/remoting/lo_003.png](/assets/remoting/lo_003.png)

From the above screenshot, we can see the server returns many information back to the client, which includes the `Protocol Version` to be used, the `Endpoint Name` it provides, and the encryption algorithms it supports. If client accepts the server, it can start the authentication process by sending the username and password with the proper encryption algorithm. Here is the screenshot that client sent the authentication request to the server:  

![/assets/remoting/lo_004.png](/assets/remoting/lo_004.png)

From the above screenshot, we can see that the client sent `Auth Request` message to the server, and the encryption method it used is `SCRAM-SHA-256`. We can't see the username and password in the data packet because it's already encrypted. Let's see how does server responded to `Auth Request`: 

![/assets/remoting/lo_005.png](/assets/remoting/lo_005.png)

From the above screenshot we can see the server sent back an `Auth Challenge` message to client. We don't have to understand the detail of `Auth Challenge` message for now, and we can think it is an additional step adopted by the server to verify the client. Let's see how does client respond to it: 

![/assets/remoting/lo_006.png](/assets/remoting/lo_006.png)

We can see the client replied an `Auth Response` message to the server. And server will verify this message. If everything goes fine, it will reply an `Auth Complete` message to client: 

![/assets/remoting/lo_007.png](/assets/remoting/lo_007.png)

The above screenshot shows the authentication process is passed, and then client will start the real work with server. Here is the screenshot:

![/assets/remoting/lo_008.png](/assets/remoting/lo_008.png)

From the above screenshot, we can see the client sent an `Channel Open Request` to the server. Here is the document for the `Channel Open Request` in `Protocol` class:

```java
// Messages for opening channels

// Channel are bidirectional thus each side's ID namespace is intermingled
// if local in origin, read 0 MSb, write 1 MSb
// if remote in origin, read 1 MSb, write 0 MSb

/**
 * byte 0: CHANNEL_OPEN_REQUEST
 * byte 1..4: new channel ID (MSb = 1)
 * byte n+1..m: requested parameters (see Channel Open Parameters below)
 *    {@link #O_SERVICE_NAME} is required
 *    inbound = responder->requester
 *    outbound = requester->responder
 */
static final byte CHANNEL_OPEN_REQUEST = 0x10;
```

From the above code, we can understand that the important information encapsulated in `Channel Open Request` is the `Remoting Channel ID`, and we can find this information in above screenshot. In addition, the message contains the `Service Name` the client needs, and together with some other parameters.

Let's see how does the server responded to the client of the request: 

![/assets/remoting/lo_009.png](/assets/remoting/lo_009.png)

From the above screenshot, we can see the server responded an `Channel Open Ack` message to the client. Here is the document of the `Channel Open Ack` in the `Protocol` class:

```java
/**
 * byte 0: CHANNEL_OPEN_ACK
 * byte 1..4: channel ID (MSb = 0)
 * byte 5..n: agreed parameters (see Channel Open Parameters below)
 *    inbound = responder->requester
 *    outbound = requester->responder
 */
static final byte CHANNEL_OPEN_ACK = 0x11;
```

The `Channel Open Ack` message is similar to the `Channel Open Request`, and contains the channel ID used by server to the client.

After the previous step has been done, the client can send the data to server. Here is the screenshot to show the action:

![/assets/remoting/lo_010.png](/assets/remoting/lo_010.png)

From the above screenshot, we can see the client sends a `Message Data` packet to the server. This is the real data sent by the client. Here is the document of `Message Data` in the `Protocol` class:

```java
// Messages for handling channel messages
 // Messages are unidirectional thus each side's ID namespace is distinct

/**
 * byte 0: MESSAGE_DATA
 * byte 1..4: channel ID
 * byte 5..6: message ID
 * byte 7: flags: - - - - - C N E  C = Cancelled N = New E = EOF
 * byte 8..n: message content
 *
 * Always flows from message sender to message recipient.
 */
static final byte MESSAGE_DATA = 0x30;
```

From the above code, we can understand the JBoss Remoting uses `channel ID` to identify the endpoints, and it uses the `message ID` to identify the messages. After the data is sent to the server side, let's see how does the server responded to the client:

![/assets/remoting/lo_011.png](/assets/remoting/lo_011.png)

From the above screenshot, we can see the server sent an `Message Async Close` packet back to the client. Here is the document of the `Message Async Close` data:

```java
* byte 0: MESSAGE_CLOSE
* byte 1..4: channel ID
* byte 5..6: message ID
*
* Always flows from message recipient to message sender.
*/
static final byte MESSAGE_CLOSE = 0x32;
```

It means the server has received the data sent by the client, and the client side can close its request. Now client can go on sending other requests to the server, or close the connection to the server. In our test case, the client then requested to close the connection with the server. Here is the screenshot of the request:  

![/assets/remoting/lo_012.png](/assets/remoting/lo_012.png)

From the above screenshot, we can see the client sent a `Channel Shutdown Write` message to the server.

```java
/**
 * byte 0: CHANNEL_CLOSE_WRITE
 * byte 1..4: channel ID
 *
 * Sent when channel writes are shut down.
 */
static final byte CHANNEL_SHUTDOWN_WRITE = 0x20;
```

From the above code we can see the client will use the `CHANNEL_SHUTDOWN_WRITE` to tell server that the client request is done and the channel can be closed. Here is the reply from the server:

![/assets/remoting/lo_013.png](/assets/remoting/lo_013.png)

We can see the server sent a `Channel Shutdown Write` to the client too, but the `channel id` is different. This means both client and server will tell each other that their channel can be closed. Here is the last message sent from the client to the server:

![/assets/remoting/lo_014.png](/assets/remoting/lo_014.png)

The above screenshot shows the client sent a `Connection Close` message to the server, and the whole communication is over.

In conclusion, we have checked the JBoss Remoting communication process between server and client in this article, and we have checked the detail of the Remoting protocol. We didn't cover all the details of the protocol, but this article is a good beginning for you to dig into the JBoss Remoting code by yourself. 

