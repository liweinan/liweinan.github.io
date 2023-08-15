---
title: 试玩opentracing-examples
abstract: 试玩「opentracing-examples」里面提供的一些样例。
author: 阿男
---



「opentracing」默认提供了一些examples，放在了「opentracing-examples」子项目[^example]里面，这篇文章玩一下里面的「client_server」这个例子。

[^example]: https://github.com/opentracing/opentracing-java/tree/master/opentracing-examples

以下是这个例子的项目结构：

```bash
$ pwd
/Users/weli/projs/opentracing-java/opentracing-examples/src/test/java/io/opentracing/examples/client_server
$ tree
.
├── Client.java
├── Message.java
├── Server.java
└── TestClientServerTest.java

0 directories, 4 files
```

从代码结构可以看到，这个例子包含一个「Client」，一个「Server」。然后「Message」是「Client」和「Server」共用的一个数据格式接口。下面是「Client」和「Server」的Class Diagram：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/opentracing_client_server.png)

「TestClientServerTest」负责启动「Server」并调用「Client」发送信息给「Server」。下面是「TestClientServerTest」的代码：

```java
public class TestClientServerTest {

    private final MockTracer tracer = new MockTracer(new ThreadLocalActiveSpanSource(),
            Propagator.TEXT_MAP);
    private final ArrayBlockingQueue<Message> queue = new ArrayBlockingQueue<>(10);
    private Server server;

    @Before
    public void before() {
        server = new Server(queue, tracer);
        server.start();
    }

    @After
    public void after() throws InterruptedException {
        server.interrupt();
        server.join(5_000L);
    }

    @Test
    public void test() throws Exception {
        Client client = new Client(queue, tracer);
        client.send();

        await().atMost(15, TimeUnit.SECONDS).until(finishedSpansSize(tracer), equalTo(2));

        List<MockSpan> finished = tracer.finishedSpans();
        assertEquals(2, finished.size());
        assertEquals(finished.get(0).context().traceId(), finished.get(1).context().traceId());
        
        assertNotNull(getOneByTag(finished, Tags.SPAN_KIND, Tags.SPAN_KIND_CLIENT));
        assertNotNull(getOneByTag(finished, Tags.SPAN_KIND, Tags.SPAN_KIND_SERVER));
        assertNull(tracer.activeSpan());
    }
}
```

从上面的代码可以看到：Server端的启动；「test()」方法中，使用「client.send()」给服务端发消息。等流程结束后，查看「MockSpan」里面的内容是不是和预期一致。

其实「client.send()」方法并不是给Server发消息，而是往「queue」里面加数据。这个「queue」定义在上面给出的「TestClientServerTest」里面：

```java
public class Client {
    private final ArrayBlockingQueue<Message> queue = new ArrayBlockingQueue<>(10);
}
```

这个「queue」作为消息队列，由Client与Server共用。Client的send方法负责往里面加数据，下面是Client的代码：

```java
public class Client {

    private final ArrayBlockingQueue<Message> queue;
    private final Tracer tracer;

    public Client(ArrayBlockingQueue<Message> queue, Tracer tracer) {
        this.queue = queue;
        this.tracer = tracer;
    }

    public void send() throws InterruptedException {
        Message message = new Message();

        try (ActiveSpan activeSpan = tracer.buildSpan("send")
                .withTag(Tags.SPAN_KIND.getKey(), Tags.SPAN_KIND_CLIENT)
                .withTag(Tags.COMPONENT.getKey(), "example-client")
                .startActive()) {
            tracer.inject(activeSpan.context(), Builtin.TEXT_MAP, new TextMapInjectAdapter(message));
            queue.put(message);
        }
    }

}
```

从上面可以看到Client的send方法中，会把message加到和Server共用的queue里面去。而Server的工作是不断地从这个消息队列里面取数据。下面是「Server」的代码：

```java
public class Server extends Thread {

    private final ArrayBlockingQueue<Message> queue;
    private final Tracer tracer;

    public Server(ArrayBlockingQueue<Message> queue, Tracer tracer) {
        this.queue = queue;
        this.tracer = tracer;
    }

    private void process(Message message) {
        SpanContext context = tracer.extract(Builtin.TEXT_MAP, new TextMapExtractAdapter(message));

        System.out.println("context in Server.process(): " + context);

        try (ActiveSpan activeSpan = tracer.buildSpan("receive")
                .withTag(Tags.SPAN_KIND.getKey(), Tags.SPAN_KIND_SERVER)
                .withTag(Tags.COMPONENT.getKey(), "example-server")
                .asChildOf(context).startActive()) {
        }
    }

    @Override
    public void run() {
        while (!Thread.currentThread().isInterrupted()) {

            try {
                process(queue.take());
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                return;
            }
        }
    }
}
```

可以看到Server逻辑就是不断从queue里面取出message。

在上面的过程当中，是对Tracer的使用。其中，「ActiveSpan」会在tracing结束后，自动关闭自己，因为它扩展了Java 8的「Autoclosable」接口。下面是「ActiveSpan」的Class Diagram：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/active_span_autoclosable.png)

因此「ActiveSpan」接口对「close()」方法的实现，就决定了它的关闭逻辑。因为「ActiveSpan」本身是个接口，所以具体的逻辑由使用者自己决定。

「opentracing」默认提供了自己的实现，就是「opentracing-mock」这个项目[^mock]。这个项目给出了一些接口的实现样例，可以去给出的URL地址查看使用方法。

[^mock]: https://github.com/opentracing/opentracing-java/tree/master/opentracing-mock

