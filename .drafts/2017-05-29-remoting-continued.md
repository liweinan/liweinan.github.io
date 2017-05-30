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

There are multiple fields in `Capability Parameters`. They are: `Protocol Version`, `Endpoint Name`, `Supports Msg Close Protocol`, `Impl Version`, `Inbound Channel`, `Outbound Channel`. 




![/assets/remoting/lo_003.png](/assets/remoting/lo_003.png)

![/assets/remoting/lo_004.png](/assets/remoting/lo_004.png)

![/assets/remoting/lo_005.png](/assets/remoting/lo_005.png)

![/assets/remoting/lo_006.png](/assets/remoting/lo_006.png)

![/assets/remoting/lo_007.png](/assets/remoting/lo_007.png)

![/assets/remoting/lo_008.png](/assets/remoting/lo_008.png)

![/assets/remoting/lo_009.png](/assets/remoting/lo_009.png)

![/assets/remoting/lo_010.png](/assets/remoting/lo_010.png)

![/assets/remoting/lo_011.png](/assets/remoting/lo_011.png)

![/assets/remoting/lo_012.png](/assets/remoting/lo_012.png)

![/assets/remoting/lo_013.png](/assets/remoting/lo_013.png)

![/assets/remoting/lo_014.png](/assets/remoting/lo_014.png)


