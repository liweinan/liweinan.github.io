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

In above list, I have extracted the dependencies that related with network communication.
