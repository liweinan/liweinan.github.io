
---

TODO:

`main/java/org/jboss/naming/remote/client/ejb/RemoteNamingStoreEJBClientHandler.java`


---




Now let's go back to `wildfly` source base and see the dependencies of the `naming` module. We can extract the relative information from the `pom.xml` file of the `naming` module. Here is the dependencies extracted from the file:

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

I have removed trivial dependencies such as logging, testing and security related modules from from the above list, and left the core dependencies.

In above list, `jboss-msc` is the Wildfly micro-container(see [An introduction to the JBoss Modular Service Container: Part 1 - Basic architecture of the container.](http://weinan.io/2017/05/10/jboss-msc.html))

`wildfly-server` is from `wildfly-core`, this project can be found on Github(See [wildfly-core](https://github.com/wildfly/wildfly-core)). The `wildfly-core` is the basic Wildfly server, I will write a series of articles to introduce this project in detail in the future.

The last dependency is `jboss-remote-naming`, and I have provided the source repository of the project to you in above. Now let's check this project in detail.

---

