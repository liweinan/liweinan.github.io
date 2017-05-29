---
title: "Analyzing the JBoss Remoting Protocol - Continued"
abstract: "This article will introduce the "
---

# {{ page.title }}


```java
public void testManyChannelsLotsOfData() throws Exception {
    final XnioWorker clientWorker = clientEndpoint.getXnioWorker();
    final XnioWorker serverWorker = serverEndpoint.getXnioWorker();
    final Queue<Throwable> problems = new ConcurrentLinkedQueue<Throwable>();
    final CountDownLatch serverChannelCount = new CountDownLatch(CHANNEL_COUNT * CONNECTION_COUNT);
    final CountDownLatch clientChannelCount = new CountDownLatch(CHANNEL_COUNT * CONNECTION_COUNT);
    serverEndpoint.registerService("test", new OpenListener() {
        public void channelOpened(final Channel channel) {
            channel.receiveMessage(new Channel.Receiver() {
                public void handleError(final Channel channel, final IOException error) {
                    problems.add(error);
                    error.printStackTrace();
                    serverChannelCount.countDown();
                }

                public void handleEnd(final Channel channel) {
                    serverChannelCount.countDown();
                }

                public void handleMessage(final Channel channel, final MessageInputStream message) {
                    try {
                        channel.receiveMessage(this);
                        while (message.read(junkBuffer) > -1);
                    } catch (Exception e) {
                        e.printStackTrace();
                        problems.add(e);
                    } finally {
                        IoUtils.safeClose(message);
                    }
                }
            });
        }

        public void registrationTerminated() {
        }
    }, OptionMap.EMPTY);
    final AtomicReferenceArray<Connection> connections = new AtomicReferenceArray<Connection>(CONNECTION_COUNT);
    for (int h = 0; h < CONNECTION_COUNT; h ++) {
        IoFuture<Connection> futureConnection = AuthenticationContext.empty().with(MatchRule.ALL, AuthenticationConfiguration.EMPTY.useName("bob").usePassword("pass").allowSaslMechanisms("SCRAM-SHA-256")).run(new PrivilegedAction<IoFuture<Connection>>() {
            public IoFuture<Connection> run() {
                try {
                    return clientEndpoint.connect(new URI("remote://localhost:30123"), OptionMap.EMPTY);
                } catch (URISyntaxException e) {
                    throw new RuntimeException(e);
                }
            }
        });
        final Connection connection = futureConnection.get();
        connections.set(h, connection);
        for (int i = 0; i < CHANNEL_COUNT; i ++) {
            clientWorker.execute(new Runnable() {
                public void run() {
                    final Random random = new Random();
                    final IoFuture<Channel> future = connection.openChannel("test", OptionMap.EMPTY);
                    try {
                        final Channel channel = future.get();
                        try {
                            final byte[] bytes = new byte[BUFFER_SIZE];
                            for (int j = 0; j < MESSAGE_COUNT; j++) {
                                final MessageOutputStream stream = channel.writeMessage();
                                try {
                                    for (int k = 0; k < 100; k++) {
                                        random.nextBytes(bytes);
                                        stream.write(bytes, 0, random.nextInt(BUFFER_SIZE - 1) + 1);
                                    }
                                    stream.close();
                                } finally {
                                    IoUtils.safeClose(stream);
                                }
                                stream.close();
                            }
                        } finally {
                            IoUtils.safeClose(channel);
                        }
                    } catch (IOException e) {
                        e.printStackTrace();
                        problems.add(e);
                    } finally {
                        clientChannelCount.countDown();
                    }
                }
            });
        }
    }
    Thread.sleep(500);
    serverChannelCount.await();
    clientChannelCount.await();
    for (int h = 0; h < CONNECTION_COUNT; h ++) {
        connections.get(h).close();
    }
    assertArrayEquals(new Object[0], problems.toArray());
}
```