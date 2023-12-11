---
title: Playing with the WildFly Quickstart `batch-processing` example
---

The sample project is here:

- [WildFly Quickstart / batch-processing](https://github.com/wildfly/quickstart/tree/main/batch-processing)

To run the example, first is to build the project with:

```bash
$ mvn install
```

Then start the integrated wildfly server with:

```bash
$ mvn wildfly:start
```

After the server is started, open another terminal and deploy the built project:  

```bash
$ mvn wildfly:deploy
```

Here is the server output if the project is deplyed:

```txt
00:04:22,051 INFO  [org.jboss.as.jpa] (ServerService Thread Pool -- 78) WFLYJPA0010: Starting Persistence Unit (phase 2 of 2) Service 'batch-processing.war#primary'
00:04:23,323 INFO  [jakarta.enterprise.resource.webcontainer.faces.config] (ServerService Thread Pool -- 81) 初始化上下文 '/batch-processing' 的 Mojarra 4.0.4
00:04:23,609 INFO  [org.wildfly.extension.undertow] (ServerService Thread Pool -- 81) WFLYUT0021: Registered web context: '/batch-processing' for server 'default-server'
00:04:23,682 INFO  [org.jboss.as.server] (management-handler-thread - 1) WFLYSRV0010: Deployed "batch-processing.war" (runtime-name : "batch-processing.war")
```

And then access the sample with the following URL:

- [http://127.0.0.1:8080/batch-processing/batch.jsf](http://127.0.0.1:8080/batch-processing/batch.jsf)

And then we can play with the sample like this:

![](https://raw.githubusercontent.com/liweinan/blogpics2023/main/1212/image 3.png)