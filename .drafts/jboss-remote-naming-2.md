


Now let's see the dependencies of the `naming` module. We can extract the relative information from the `pom.xml` file of the `naming` module. Here is the dependencies extracted from the `naming` module:

```xml
<artifactId>wildfly-naming</artifactId>

 <name>WildFly: Naming Subsystem</name>

 <dependencies>
    <dependency>
        <groupId>org.jboss</groupId>
        <artifactId>jboss-remote-naming</artifactId>
    </dependency>
    <dependency>
        <groupId>org.jboss.msc</groupId>
        <artifactId>jboss-msc</artifactId>
    </dependency>
    <dependency>
        <groupId>org.wildfly.core</groupId>
        <artifactId>wildfly-server</artifactId>
    </dependency>
    ...
</dependencies>
```

I have removed logging, testing and security related dependencies from the above list, and the above are the core dependencies of the `naming` subsystem. We know `jboss-msc` is the Wildfly micro-container(see [An introduction to the JBoss Modular Service Container: Part 1 - Basic architecture of the container.](http://weinan.io/2017/05/10/jboss-msc.html)). 

`wildfly-server` is from `wildfly-core`, this project can be found on Github(See [wildfly-core](https://github.com/wildfly/wildfly-core)). The `wildfly-core` is the basic Wildfly server, I will write a series of articles to introduce this project in detail in the future.

The last dependency is `jboss-remote-naming`(See [jboss-remote-naming](https://github.com/jbossas/jboss-remote-naming)), and this is a standalone project that helps Wildfly to support remote JNDI service. Here is the screenshot of the project:

![/assets/naming/remote-naming-struct.png](/assets/naming/remote-naming-struct.png)

From the above screenshot, we can see the basic structure of the `jboss-remote-naming` project. We will 




---

`RemoteNamingServerService` will inject `NamingStore` into `RemoteNamingService`.
 
 `RemoteNamingService` is provided by the `jboss-remote-naming` project.