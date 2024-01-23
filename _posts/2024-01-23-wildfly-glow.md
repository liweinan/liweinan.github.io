---
title: Using WildFly Glow to provision the Wildfly server
---

Here is a sample project created by [Kabir](https://github.com/kabir) showing the usage of WildFly Glow:

- [https://github.com/kabir/vlog-glow](https://github.com/kabir/vlog-glow)

In its `pom.xml` it contains a `glow` profile that shows the Glow usage:

```xml
 <profile>
    <id>glow</id>
    <build>
        <plugins>
            <plugin>
                <groupId>org.wildfly.plugins</groupId>
                <artifactId>wildfly-maven-plugin</artifactId>
                <configuration>
                    <discover-provisioning-info>
                        <version>${version.server}</version>
                    </discover-provisioning-info>
                    <!-- deploys the quickstart on root web context -->
                    <name>ROOT.war</name>
                </configuration>
                <executions>
                    <execution>
                        <goals>
                            <goal>package</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>
</profile>
```

With the above configuration, you can see the layers configurations are not required. To build the project, Glow needs to download necessary components, and you may need to set HTTP proxy:

```bash
$ MAVEN_OPTS='-Dhttp.proxyHost=your_proxy_host -Dhttp.proxyPort=your_proxy_port -Dhttps.proxyHost=your_proxy_host -Dhttps.proxyPort=your_proxy_port' mvn install -Pglow
```

Here is the output of the build process:

```
[INFO] Glow scanning DONE.
[INFO] context: bare-metal
[INFO] enabled profile: none
[INFO] galleon discovery
[INFO] - feature-packs
   org.wildfly:wildfly-galleon-pack:30.0.1.Final
- layers
   ee-core-profile-server
   jaxrs
   microprofile-config

[INFO] Some suggestions have been found. You could enable suggestions with --suggest option (if using the WildFly Glow CLI) or <suggest>true</suggest> (if using the WildFly Maven Plugin).
[INFO] Provisioning server in /Users/weli/works/vlog-glow/target/server
[INFO] Resolving feature-packs
[INFO] Installing packages
[INFO] Resolving artifacts
[INFO] Generating configurations
[INFO] Delayed generation, waiting...
[INFO] Copy deployment /Users/weli/works/vlog-glow/target/glow-example.war to /Users/weli/works/vlog-glow/target/server/standalone/deployments/ROOT.war
[INFO] 
```

From the above output you can see the needed layers are found and it will be put into the provisioned server:

```bash
weli@192:~/w/v/t/server|main✓
➤ find . | grep microprofile
./modules/system/layers/base/org/eclipse/microprofile
./modules/system/layers/base/org/eclipse/microprofile/config
./modules/system/layers/base/org/eclipse/microprofile/config/api
./modules/system/layers/base/org/eclipse/microprofile/config/api/main
./modules/system/layers/base/org/eclipse/microprofile/config/api/main/module.xml
./modules/system/layers/base/org/eclipse/microprofile/config/api/main/microprofile-config-api-3.0.2.jar
./modules/system/layers/base/org/wildfly/extension/microprofile
./modules/system/layers/base/org/wildfly/extension/microprofile/config-smallrye
./modules/system/layers/base/org/wildfly/extension/microprofile/config-smallrye/main
./modules/system/layers/base/org/wildfly/extension/microprofile/config-smallrye/main/wildfly-microprofile-config-smallrye-30.0.1.Final.jar
./modules/system/layers/base/org/wildfly/extension/microprofile/config-smallrye/main/module.xml
weli@192:~/w/v/t/server|main✓
➤ pwd
/Users/weli/works/vlog-glow/target/server
weli@192:~/w/v/t/server|main✓
➤
```

The above is the usage of the WildFly Glow. The tool depends on the layers that exists in WildFly codebase. For example, here is one layer definition:

- [https://github.com/wildfly/wildfly/blob/main/ee-feature-pack/galleon-shared/src/main/resources/layers/standalone/jaxrs-core/layer-spec.xm](https://github.com/wildfly/wildfly/blob/main/ee-feature-pack/galleon-shared/src/main/resources/layers/standalone/jaxrs-core/layer-spec.xml)

Please note that not all the feature packs has relative layer definitions.

Here are some references:

- [https://github.com/wildfly/quickstart/pull/767/files\#diff-657ad0397672f78ec644b19c7b955917d66e112e559181faa88d7a87c8ffc63cR15](https://github.com/wildfly/quickstart/pull/767/files%23diff-657ad0397672f78ec644b19c7b955917d66e112e559181faa88d7a87c8ffc63cR15)
- [resteasy-spring Galleon layer and integration in WildFly Glow #162](https://github.com/resteasy/resteasy-spring/pull/162#pullrequestreview-1706708490)
- [https://github.com/wildfly/wildfly-galleon-feature-packs/pull/13#issuecomment-1904168877](https://github.com/wildfly/wildfly-galleon-feature-packs/pull/13#issuecomment-1904168877)
- [Using the Wildfly Channel manifest file to override the module version in provisioned WildFly server.](https://weinan.io/2023/12/09/jberet-manifest.html)
- [resteasy-example / trying to use Glow to provision WildFly in tracing-example \#175](https://github.com/resteasy/resteasy-examples/pull/175)
- [https://github.com/wildfly/wildfly-glow/pull/21](https://github.com/wildfly/wildfly-glow/pull/21)