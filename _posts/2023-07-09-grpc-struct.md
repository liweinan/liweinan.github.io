---
title: The structure of the generated Java gRPC classes
---

This project contains a basic gRPC service:

- [https://github.com/liweinan/gRPC-Java-Master-Class-Build-Modern-API-Micro-services/tree/main/1.grpc-unary/grpc-java-course](https://github.com/liweinan/gRPC-Java-Master-Class-Build-Modern-API-Micro-services/tree/main/1.grpc-unary/grpc-java-course)

The project can generate the Java classes according to the `.proto` files defined in the project, and here is the class diagram of the `greeting` related classes together with generated classes:

![](https://raw.githubusercontent.com/liweinan/blogpics2023/main/0710/Class Diagram2.jpg)

From the above class diagram, there are several notes:

- The `GreetingClient`, `GreetingServer` and `GreetingServerImpl` classes are project original classes.
- The other classes are the generated `gRPC` classes.
- There are three core parts of the generated classes together with their related classes: `GreetingRequest`, `GreetingResponse` and `GreetingServiceGrpc`.
- The `GreetingServiceGrpc` contains some inner classes, and one of its inner class is `GreetingServiceImplBase`.
- The `GreetingServiceImplBase` implements the `io.grpc.BindableService` interface[^grpc].

In addition, the handwritten `GreetingServerImpl` class extends the `GreetingServiceGrpc.GreetingServiceImplBase` inner class:

```java
package greeting.server;

import com.proto.greeting.GreetingRequest;
import com.proto.greeting.GreetingResponse;
import com.proto.greeting.GreetingServiceGrpc;
import io.grpc.stub.StreamObserver;

public class GreetingServerImpl extends GreetingServiceGrpc.GreetingServiceImplBase {

    @Override
    public void greet(GreetingRequest request, StreamObserver<GreetingResponse> responseObserver) {
        responseObserver.onNext(GreetingResponse.newBuilder()
                .setResult("Hello : "+request.getFirstName()).build());
        responseObserver.onCompleted();
    }
}
```

And the `GreetingServer`  uses the `GreetingServerImpl`:

```java
package greeting.server;

import io.grpc.Server;
import io.grpc.ServerBuilder;
import io.grpc.protobuf.services.ProtoReflectionService;

import java.io.IOException;

public class GreetingServer {
    public static void main(String[] args) throws IOException, InterruptedException {
        int port = 50052;

        Server server = ServerBuilder.forPort(port)
                .addService(new GreetingServerImpl())
                .addService(ProtoReflectionService.newInstance())
                .build();

        server.start();
        System.out.println("Server started");
        System.out.println("Listing on port : "+ port);

        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            System.out.println("Received Shutdown Request");
            server.shutdown();
            System.out.println("Server Stopped");
        }));

        server.awaitTermination();
    }
}
```

Above is the structure of the generated Java gRPC classes.


## References

[^grpc]: [https://github.com/grpc/grpc-java/blob/master/api/src/main/java/io/grpc/BindableService.java](https://github.com/grpc/grpc-java/blob/master/api/src/main/java/io/grpc/BindableService.java)

