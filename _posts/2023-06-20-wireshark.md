---
title: Using Wireshark To Analyze The GRPC/ProtoBuf Messages
---

First run a gRPC server:

- [gRPC-Java-Master-Class-Build-Modern-API-Micro-services/1.grpc-unary/grpc-java-course at main · liweinan/gRPC-Java-Master-Class-Build-Modern-API-Micro-services · GitHub](https://github.com/liweinan/gRPC-Java-Master-Class-Build-Modern-API-Micro-services/tree/main/1.grpc-unary/grpc-java-course)

Build the project firstly:

```bash
$ mvn install
```

Then run the gRPC server:

```bash
$ mvn exec:java -Dexec.mainClass="greeting.server.GreetingServer"
```

If everything goes fine the server is started:

![](https://raw.githubusercontent.com/liweinan/blogpics2023/main/0620/3C6E4786-8E13-4DB6-8205-C68877D06900.png)

The above example project opens a gRPC service at port `50051`, then we can open Wireshark and start to capture packets at `lo0`:

![](https://raw.githubusercontent.com/liweinan/blogpics2023/main/0620/549184EC-E7A8-4AA6-AD96-266B514F0F50.png)

There are heavy traffics at `lo0`, and we just need to check the packets at port `50051`, so we can user the filter to display the packets at port `50051` only:

![](https://raw.githubusercontent.com/liweinan/blogpics2023/main/0620/339DBFD4-8BA0-41E8-8DA0-0015371E5194.png)

And then we can use the tool `grpcurl` to do the request to the service:

```bash
➤ grpcurl --plaintext -d '{"first_name": "foo"}' localhost:50051 greeting.GreetingService/greet
{
  "result": "Hello : foo"
}
```

And now we can see Wireshark has captured the packets between the communication:

![](https://raw.githubusercontent.com/liweinan/blogpics2023/main/0620/BF90931B-DFC0-4083-B023-F8B7C8616C2D.png)

From the above screenshot we can see the packets are captured and they are interpreted as TCP packets. We can right click one of the packets and select `Decode As...`:

![](https://raw.githubusercontent.com/liweinan/blogpics2023/main/0620/37492F8D-1313-4600-ABC5-7A0A0A2CD5F5.png)

And then ask the Wireshark to decode the packets at port `50051` as `HTTP2` and click `OK`:

![](https://raw.githubusercontent.com/liweinan/blogpics2023/main/0620/A4E0F5BA-A692-45EB-945E-2B66370C9989.png)

Now the `HTTP2` packets can be interpreted, and the `GRPC` communication can also be recognized:

![](https://raw.githubusercontent.com/liweinan/blogpics2023/main/0620/9C1DD4DC-F788-43D8-A642-5EAFBDF40445.png)

To let the Wireshark understanding the detail message format in the `GRPC` communication, we can select one of the `GRPC` messages and right click it and select `Open Protocol Buffes preferences...` as shown in below:

![](https://raw.githubusercontent.com/liweinan/blogpics2023/main/0620/9E600302-837A-4F88-80DD-D820A39E7369.png)

And then select the `ProtoBuf` config tab and edit the `Protobuf search paths` to select the `.proto` file used in the communication:

![](https://raw.githubusercontent.com/liweinan/blogpics2023/main/0620/5E0E2426-A7E9-46AD-BCCD-53AB1783490E.png)

As the screenshot above, we have selected the `.proto` file path used in the example project. The `.proto` file is defined like this:

```proto
syntax = "proto3";

package greeting;

option java_package = "com.proto.greeting";
option java_multiple_files = true;

message GreetingRequest {
  string first_name = 1;
}

message GreetingResponse {
  string result = 1;
}

service GreetingService {
  rpc greet(GreetingRequest) returns (GreetingResponse);
}
```

In addition, I have enabled these two options in the config:

![](https://raw.githubusercontent.com/liweinan/blogpics2023/main/0620/6AAA4F98-52BC-4E10-9338-A27BDACC6CCD.png)

After clicking `OK` to finish the setting, the packets capture window are refreshed, and the data structure can now be recognized by Wireshark. We can double click one of the `GRPC` packet:

![](https://raw.githubusercontent.com/liweinan/blogpics2023/main/0620/3680A98C-5D38-4212-A6BE-7C09FCF696D2.png)

As the screenshot shown above, we can see the message structure can be interpreted.

## References

- [How to decode protobuf by wireshark - Ask Wireshark](https://ask.wireshark.org/question/15787/how-to-decode-protobuf-by-wireshark/)
- [Analyzing gRPC messages using Wireshark / gRPC](https://grpc.io/blog/wireshark/)


