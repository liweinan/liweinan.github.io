---
title: Using RESTEasy Spring With WildFly
---

This pull request shows how to use `resteasy-spring` with the current most recent version of WildFly:

- [WFLY-17534 Re-enabled the spring-resteasy Quickstart #639](https://github.com/wildfly/quickstart/pull/639)

It has several things that should be noted. First is that the `Springframework 6` needs `JDK7` to build:

```xml
<profile>
    <id>jdk-17-required</id>
    <activation>
        <jdk>[17,)</jdk>
    </activation>
    <modules>
        <module>spring-resteasy</module>
    </modules>
</profile>
```

Next is that CDI related subsystems need to be removed from WildFly because Springframework conflicts with JBoss Weld(CDI Implementation):

- [spring-resteasy/src/test/resources/jboss-deployment-structure.xml](https://github.com/wildfly/quickstart/pull/639/files#diff-5043e2bab7593e2f87ddc81920ca3fc7eca2cd146f956be22727d198bff517c4R1)

```xml
<?xml version="1.0"?>
<jboss-deployment-structure xmlns="urn:jboss:deployment-structure:1.2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <deployment>
        <!-- Spring does not support CDI and therefore CDI required subsystem and dependencies must be excluded -->
        <exclude-subsystems>
            <subsystem name="jsf"/>
            <subsystem name="microprofile-opentracing-smallrye"/>
            <subsystem name="weld"/>
        </exclude-subsystems>
        <exclusions>
            <module name="org.jboss.resteasy.resteasy-cdi"/>
        </exclusions>
    </deployment>
</jboss-deployment-structure>
```

Next is that in Arquillian test code, it needs to load the Spring dependencies into the WAR file:

- [spring-resteasy/src/test/java/org/jboss/as/quickstarts/resteasyspring/test/ResteasySpringIT.java](https://github.com/wildfly/quickstart/pull/639/files#diff-bfb08e577e733ba7b2962f6ea0679dc67cef3884775f0ae4d4cee1820fbd1637R61)

```java
.addAsLibraries(Maven.configureResolver()
        .resolve("org.springframework:spring-web:4.3.9.RELEASE")
        .loadPomFromFile("pom.xml")
        .resolve(
                "org.springframework:spring-core",
                "org.springframework:spring-web",
                "org.springframework:spring-context",
                "org.springframework:spring-beans"
        )
        .withTransitivity().asFile());
```

Please note this PR is also related with this:

- [Add an Arquillian Processor which adds a jboss-deployment-struct… #71](https://github.com/resteasy/resteasy-spring/pull/71)

To run the QuickStart example, you can currently try with this branch:

- https://github.com/jamezp/wildfly-quickstarts/tree/WFLY-17534

To run the example first you need to build the project with:

```bash
$ mvn install
```

After the whole project is built, you need to download a WildFly distribution to run the QuickStart example. WildFly `27.0.1.Final` is suitable to run this branch of the example:

- [Release 27.0.1.Final · wildfly/wildfly · GitHub](https://github.com/wildfly/wildfly/releases/tag/27.0.1.Final)

For myself, I use my own built WildFly distribution from source code, so I setup the `JBOSS_HOME` like this:

```bash
➤ export JBOSS_HOME=/Users/weli/works/wildfly/dist/target/wildfly-28.0.0.Beta1-SNAPSHOT
```

And to run the `spring-resteasy` example, I entered the example directory and run the following commands:

```bash
➤ pwd
/Users/weli/works/wildfly-quickstart/spring-resteasy
```

```bash
➤ mvn verify -Parq-managed                  
```

And the above command will start the managed WildFly server, deploy the example project and run the test. Here is the log of the process:

```txt
23:19:29,448 INFO  [org.wildfly.extension.undertow] (ServerService Thread Pool -- 10) WFLYUT0021: Registered web context: '/spring-resteasy' for server 'default-server'
23:19:29,488 INFO  [org.jboss.as.server] (management-handler-thread - 1) WFLYSRV0010: Deployed "spring-resteasy.war" (runtime-name : "spring-resteasy.war")
SLF4J: Failed to load class "org.slf4j.impl.StaticLoggerBinder".
SLF4J: Defaulting to no-operation (NOP) logger implementation
SLF4J: See http://www.slf4j.org/codes.html#StaticLoggerBinder for further details.
23:19:29,827 INFO  [stdout] (default task-1) Locating Resource...
23:19:29,978 INFO  [stdout] (default task-1) Sending greeing: Welcome to RESTEasy + Spring, JBoss Developer.
23:19:30,000 INFO  [stdout] (default task-1) Locating Resource...
23:19:30,000 INFO  [stdout] (default task-1) getBasic()
23:19:30,005 INFO  [stdout] (default task-1) Locating Resource...
23:19:30,010 INFO  [stdout] (default task-1) basic
23:19:30,012 INFO  [stdout] (default task-1) Locating Resource...
23:19:30,015 INFO  [stdout] (default task-1) Locating Resource...
23:19:30,018 INFO  [stdout] (default task-1) Locating Resource...
23:19:30,030 INFO  [stdout] (default task-1) Sending greeing: Welcome to RESTEasy + Spring, JBoss Developer.
23:19:30,032 INFO  [stdout] (default task-1) getBasic()
23:19:30,035 INFO  [stdout] (default task-1) basic
23:19:30,052 INFO  [org.wildfly.extension.undertow] (ServerService Thread Pool -- 10) WFLYUT0022: Unregistered web context: '/spring-resteasy' from server 'default-server'
23:19:30,053 INFO  [io.undertow.servlet] (ServerService Thread Pool -- 10) Closing Spring root WebApplicationContext
23:19:30,083 INFO  [org.jboss.as.server.deployment] (MSC service thread 1-7) WFLYSRV0028: Stopped deployment spring-resteasy.war (runtime-name: spring-resteasy.war) in 33ms
23:19:30,115 INFO  [org.jboss.as.repository] (management-handler-thread - 1) WFLYDR0002: Content removed from location /Users/weli/works/wildfly/dist/target/wildfly-28.0.0.Beta1-SNAPSHOT/standalone/data/content/a3/9ccdb8261027139cc6e1a7ed038a6e6d4fec80/content
23:19:30,116 INFO  [org.jboss.as.server] (management-handler-thread - 1) WFLYSRV0009: Undeployed "spring-resteasy.war" (runtime-name: "spring-resteasy.war")
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 7.879 s - in org.jboss.as.quickstarts.resteasyspring.test.ResteasySpringIT
23:19:30,127 INFO  [org.jboss.as.server] (management-handler-thread - 1) WFLYSRV0272: Suspending server
23:19:30,131 INFO  [org.jboss.as.ejb3] (management-handler-thread - 1) WFLYEJB0493: Jakarta Enterprise Beans subsystem suspension complete
23:19:30,131 INFO  [org.jboss.as.server] (Management Triggered Shutdown) WFLYSRV0241: Shutting down in response to management operation 'shutdown'
23:19:30,142 INFO  [org.wildfly.extension.undertow] (MSC service thread 1-3) WFLYUT0019: Host default-host stopping
23:19:30,142 INFO  [org.jboss.as.connector.subsystems.datasources] (MSC service thread 1-6) WFLYJCA0010: Unbound data source [java:jboss/datasources/ExampleDS]
23:19:30,142 INFO  [org.jboss.as.mail.extension] (MSC service thread 1-5) WFLYMAIL0002: Unbound mail session [java:jboss/mail/Default]
23:19:30,143 INFO  [org.wildfly.extension.undertow] (MSC service thread 1-4) WFLYUT0008: Undertow HTTPS listener https suspending
23:19:30,144 INFO  [org.wildfly.extension.undertow] (MSC service thread 1-4) WFLYUT0007: Undertow HTTPS listener https stopped, was bound to 127.0.0.1:8443
23:19:30,145 INFO  [org.jboss.as.connector.deployers.jdbc] (MSC service thread 1-5) WFLYJCA0019: Stopped Driver service with driver-name = h2
23:19:30,145 INFO  [org.wildfly.extension.undertow] (MSC service thread 1-6) WFLYUT0008: Undertow HTTP listener default suspending
23:19:30,145 INFO  [org.wildfly.extension.undertow] (MSC service thread 1-6) WFLYUT0007: Undertow HTTP listener default stopped, was bound to 127.0.0.1:8080
23:19:30,147 INFO  [org.wildfly.extension.undertow] (MSC service thread 1-4) WFLYUT0004: Undertow 2.3.0.Final stopping
23:19:30,171 INFO  [org.jboss.as] (MSC service thread 1-3) WFLYSRV0050: WildFly Full 28.0.0.Beta1-SNAPSHOT (WildFly Core 20.0.0.Beta4) stopped in 35ms
[INFO] 
[INFO] Results:
[INFO] 
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0
[INFO] 
[INFO] 
[INFO] --- maven-failsafe-plugin:2.22.2:verify (default) @ spring-resteasy ---
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  12.091 s
[INFO] Finished at: 2023-01-22T23:19:30+08:00
[INFO] ------------------------------------------------------------------------
```

From the above log output we can see the example project is working.

## References

- [Testing Jakarta EE 9 Applications with Arquillian and WildFly](https://itnext.io/testing-jakarta-ee-9-applications-with-arquillian-and-wildfly-cd108eec57e2)
- [Arquillian WildFly Managed Container Adapter · Arquillian](https://arquillian.org/modules/wildfly-arquillian-wildfly-managed-container-adapter/)

