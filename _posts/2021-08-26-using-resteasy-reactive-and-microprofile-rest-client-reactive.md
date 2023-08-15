---
title: Learning About Quarkus RESTEasy Reactive and Microprofile Rest Client Reactive
--- 

I have played with `quarkus-resteasy-reactive` and `quarkus-rest-client-reactive` for a while and would like to share some learning experiences with you in this blog. 

Firstly, the best articles I’ve found to learn to use the components is Quarkus own documents:

- [Quarkus - Using the REST Client Reactive](https://quarkus.io/guides/rest-client-reactive)
- [Quarkus - Writing REST Services with RESTEasy Reactive](https://quarkus.io/guides/resteasy-reactive)

They are well written and should definitely be read first, which covers a lot of details on how to using them.

As Mutiny provides a unique way to wrap the reactive APIs, and because these reactive components use its `Uni` and `Multi` as standard way to wrap the asynchronous objects, so it’s better to learn how to use Mutiny firstly. And here is the article I start with:

- [Quarkus - Getting Started With Reactive](https://quarkus.io/guides/getting-started-reactive)

Quarkus now supports both `Jsonb` and `Jackson` as JSON provider:

```xml
<dependency>
    <groupId>io.quarkus</groupId>
    <artifactId>quarkus-resteasy-reactive-jackson</artifactId>
</dependency>
```

```xml
<dependency>
    <groupId>io.quarkus</groupId>
    <artifactId>quarkus-resteasy-reactive-jsonb</artifactId>
</dependency>
```

You should from one of the above projects as your JSON provider. For me I used the `jackson` one. And please note that you can’t use the reactive library and non-reactive library at same time, or Quarkus will throw error to you.

But you can use reactive library for RESTEasy part, but using the non-reactive libraries for other parts, such as `rest-client` or `hibernate-panache`, which will not have conflicts, because they are independent from each other. But for me I’d like to stick all by libraries to the reactive ones.

Now come to `rest-client` part. Here is the dependency of the `rest-client-reactive`:

```xml
<dependency>
    <groupId>io.quarkus</groupId>
    <artifactId>quarkus-rest-client-reactive</artifactId>
</dependency>
<dependency>
    <groupId>io.quarkus</groupId>
    <artifactId>quarkus-rest-client-reactive-jackson</artifactId>
</dependency>
```

One thing to note that currently RESTEasy has not supported `HTTP/2` yet, and above Quarkus components are all relying on RESTEasy mainstream, which means if you are using  you can not do `HTTP/2` communication yet with above components. 

Here are relative issues which are work in progress if you are interested in:

- [Http Client should support Http/2 · Issue #13969 · quarkusio/quarkus · GitHub](https://github.com/quarkusio/quarkus/issues/13969)
- [RESTEASY-2802 RESTEasy client should support HTTP/2 - Red Hat Issue Tracker](https://issues.redhat.com/browse/RESTEASY-2802)

The other thing I’d like to talk is that how to register the `ClientResponseFilter` and `ClientRequestFilter` into your REST client. For example here is a `ProxyFilter` that implements the filter interfaces:

```java
@Provider
public class ProxyFilter implements ClientResponseFilter, ClientRequestFilter {
...
}
```

And you have a REST client like this:

```java
@RegisterRestClient
@Produces(MediaType.APPLICATION_JSON)
@Path("/foo") // todo : use real URL
public interface FooClient {
   @GET
   Uni<String> get();
}
```

And then you use it in your service:

```java
@RestClient
FooClient client;
```

And if you find the filters are not working, you can try to manually build a client instead of using `@RestClient` to inject it:

```java
var client = RestClientBuilder.newBuilder()
        .baseUri(URI.create("https://example.com/"))
        .register(ProxyFilter.class)
        .build(FooClient.class);
```

Then the filter is working as expected. This behavior may change in the future, but currently it’s useful to me.

If you want to do a multipart form POST action, this article is useful to you:

- [Quarkus - Using the REST Client with Multipart](https://quarkus.io/guides/rest-client-multipart)

Nevertheless, sometimes some microservices provides an file upload API that doesn’t support multipart form and ask you to POST the file directly, I write the REST client like this and it works:

```java
@RegisterRestClient
public interface FooProxy {

    @PUT
    @Consumes(MediaType.WILDCARD)
    @Path("/{bucket}/{directory}/{filename}")
    Uni<Response> upload(@HeaderParam("Authorization") String Authorization,
                         @HeaderParam("Date") String Date,
                         @PathParam("bucket") String bucket,
                         @PathParam("directory") String directory,
                         @PathParam("filename") String filename,
                         File file);
}
```

This code is extracted from real scenario and as you can see the last parameter type is `File`, which is not a class annotated with `@MultipartForm`. Doing a Wireshark packet analyze, and I can see the HTTP request is correctly generated:

```txt
PUT *** HTTP/1.1
Authorization: ***
Content-Length: 102117
Content-Type: */*
Date: Wed, 25 Aug 2021 12:46:56 GMT
host: ***

......JFIF.....H.H.....XICC_PROFILE......HLino....mntrRGB XYZ .....	...1..acspMSFT....IEC sRGB.......................-HP  ................................................cprt...P...3desc.......lwtpt........bkpt........rXYZ........gXYZ...,....bXYZ...@....dmnd...T...pdmdd........vued...L....view.......$lumi........meas.......$tech...0....rTRC...<....gTRC...<....bTRC...<....text....Copyright (c) 1998 Hewlett-Packard Company..desc........sRGB IEC61966-2.1............sRGB IEC61966-2.1..................................................XYZ .......Q........XYZ ................XYZ ......o...8.....XYZ ......b.........XYZ ......$.........desc........IEC http://www.iec.ch............IEC http://www.iec.ch..............................................desc........IEC 61966-2.1 Default RGB colour space - sRGB............IEC 61966-2.1 Default RGB colour space - sRGB......................desc.......,Reference Viewing Condition in IEC61966-2.1...........,Reference Viewing Condition in IEC61966-2.1..........................view.........._...............\.....XYZ .....L	V.P...W..meas................................sig ....CRT curv.............
.........#.(.-.2.7.;.@.E.J.O.T.Y.^.c.h.m.r.w.|.......................................................
.......%.+.2.8.>.E.L.R.Y.`.g.n.u.|.........................................&./.8.A.K.T.].g.q.z...............................!.-.8.C.O.Z.f.r.~......................... .-.;.H.U.c.q.~...................
...+.:.I.X.g.w.....................'.7.H.Y.j.{...................+.=.O.a.t...................2.F.Z.n..............	.	%	:	O	d	y	.	.	.	.	.	.
```

From above we can see a `JPEG` image file is uploaded to a microservice API directly, and the response is `HTTP.1.1 200 OK`.

Above are some of my learning experiences on using Quarkus RESTEasy Reactive and REST Client Reactive, hope it’s useful to you.

Have fun! :D

