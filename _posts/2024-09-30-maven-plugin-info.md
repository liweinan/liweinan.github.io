---
title: Showing the information of Maven plugins
---

To display the plugin dependencies of a project, use this command to do so:

```bash
$ mvn dependency:resolve-plugins
```

Here is an example output:

```txt
[INFO] Scanning for projects...
[INFO] 
[INFO] -----------< org.jberet.examples:batch-deployment-examples >------------
[INFO] Building jberet-deployment-examples 1.0.0-SNAPSHOT
[INFO] --------------------------------[ war ]---------------------------------
[INFO] 
[INFO] --- maven-dependency-plugin:3.6.1:resolve-plugins (default-cli) @ batch-deployment-examples ---
[INFO] 
[INFO] The following plugins have been resolved:
[INFO]    org.apache.maven.plugins:maven-source-plugin:maven-plugin:3.2.1:runtime
[INFO]       org.apache.maven.plugins:maven-source-plugin:jar:3.2.1
[INFO]       org.apache.maven:maven-model:jar:3.0
[INFO]       org.apache.maven:maven-plugin-api:jar:3.0
[INFO]       org.apache.maven:maven-artifact:jar:3.0
[INFO]       org.sonatype.sisu:sisu-inject-plexus:jar:1.4.2
[INFO]       org.sonatype.sisu:sisu-inject-bean:jar:1.4.2
[INFO]       org.sonatype.sisu:sisu-guice:jar:noaop:2.1.7
[INFO]       org.apache.maven:maven-core:jar:3.0
[INFO]       org.apache.maven:maven-settings:jar:3.0
[INFO]       org.apache.maven:maven-settings-builder:jar:3.0
[INFO]       org.apache.maven:maven-repository-metadata:jar:3.0
[INFO]       org.apache.maven:maven-model-builder:jar:3.0
[INFO]       org.apache.maven:maven-aether-provider:jar:3.0
[INFO]       org.sonatype.aether:aether-impl:jar:1.7
[INFO]       org.sonatype.aether:aether-spi:jar:1.7
[INFO]       org.sonatype.aether:aether-api:jar:1.7
[INFO]       org.sonatype.aether:aether-util:jar:1.7
[INFO]       org.codehaus.plexus:plexus-interpolation:jar:1.14
[INFO]       org.codehaus.plexus:plexus-classworlds:jar:2.2.3
[INFO]       org.codehaus.plexus:plexus-component-annotations:jar:1.7.1
[INFO]       org.sonatype.plexus:plexus-sec-dispatcher:jar:1.3
[INFO]       org.sonatype.plexus:plexus-cipher:jar:1.4
[INFO]       org.apache.maven:maven-archiver:jar:3.5.0
[INFO]       org.apache.maven.shared:maven-shared-utils:jar:3.2.1
[INFO]       commons-io:commons-io:jar:2.5
[INFO]       org.codehaus.plexus:plexus-archiver:jar:4.2.1
[INFO]       org.codehaus.plexus:plexus-io:jar:3.2.0
[INFO]       org.apache.commons:commons-compress:jar:1.19
[INFO]       org.iq80.snappy:snappy:jar:0.4
[INFO]       org.tukaani:xz:jar:1.8
[INFO]       org.codehaus.plexus:plexus-utils:jar:3.3.0
[INFO]    org.apache.maven.plugins:maven-release-plugin:maven-plugin:3.0.1:runtime
[INFO]       org.apache.maven.plugins:maven-release-plugin:jar:3.0.1
[INFO]       org.apache.maven.release:maven-release-api:jar:3.0.1
[INFO]       org.eclipse.aether:aether-api:jar:1.0.0.v20140518
...
```


To display the goals of a plugin, use this command for example[^list_goals]:

```bash
➤ mvn help:describe -Dplugin=org.wildfly.plugins:wildfly-maven-plugin
```

Here is the example output of the above command:

```txt
[INFO] Scanning for projects...
[INFO] 
[INFO] -----------< org.jberet.examples:batch-deployment-examples >------------
[INFO] Building jberet-deployment-examples 1.0.0-SNAPSHOT
[INFO] --------------------------------[ war ]---------------------------------
[INFO] 
[INFO] --- maven-help-plugin:3.4.0:describe (default-cli) @ batch-deployment-examples ---
[INFO] org.wildfly.plugins:wildfly-maven-plugin:5.0.1.Final

Name: WildFly Maven Plugin
Description: A maven plugin that allows various management operations to be
  executed on WildFly Application Server.
Group Id: org.wildfly.plugins
Artifact Id: wildfly-maven-plugin
Version: 5.0.1.Final
Goal Prefix: wildfly

This plugin has 18 goals:

wildfly:add-resource
  Description: Adds a resource If force is set to false and the resource has
    already been added to the server, an error will occur and the operation
    will fail.

wildfly:deploy
  Description: Deploys the application to the WildFly Application Server. If
    force is set to true, the server is queried to see if the application
    already exists. If the application already exists, the application is
    redeployed instead of deployed. If the application does not exist the
    application is deployed as normal. If force is set to false and the
    application has already been deployed to the server, an error will occur
    and the deployment will fail.

wildfly:deploy-artifact
  Description: Deploys an arbitrary artifact to the WildFly application
    server

wildfly:deploy-only
  Description: Deploys only the application to the WildFly Application Server
    without first invoking the the execution of the lifecycle phase 'package'
    prior to executing itself. If force is set to true, the server is queried
    to see if the application already exists. If the application already
    exists, the application is redeployed instead of deployed. If the
    application does not exist the application is deployed as normal. If force
    is set to false and the application has already been deployed to the
    server, an error will occur and the deployment will fail.

wildfly:dev
  Description: Starts a standalone instance of WildFly and deploys the
    application to the server. The deployment type must be a WAR. Once the
    server is running, the source directories are monitored for changes. If
    required the sources will be compiled and the deployment may be redeployed.
    Note that changes to the POM file are not monitored. If changes are made
    the POM file, the process will need to be terminated and restarted. Note
    that if a WildFly Bootable JAR is packaged, it is ignored by this goal.

wildfly:execute-commands
  Description: Execute commands to the running WildFly Application Server.
    Commands should be formatted in the same manner CLI commands are formatted.
    Executing commands in a batch will rollback all changes if one command
    fails. true false
    /subsystem=logging/console=CONSOLE:write-attribute(name=level,value=DEBUG)

wildfly:help
  Description: Display help information on wildfly-maven-plugin. Call mvn
    wildfly:help -Ddetail=true -Dgoal= to display parameter details.

wildfly:image
  Description: Build (and push) an application image containing the
    provisioned server and the deployment. The image goal extends the package
    goal, building and pushing the image occurs after the server is provisioned
    and the deployment deployed in it. The image goal relies on a Docker binary
    to execute all image commands (build, login, push). Note that if a WildFly
    Bootable JAR is packaged, it is ignored when building the image.

wildfly:package
  Description: Provision a server, copy extra content and deploy primary
    artifact if it exists

wildfly:provision
  Description: Provision a server.

wildfly:redeploy
  Description: Redeploys the application to the WildFly Application Server.

wildfly:redeploy-only
  Description: Redeploys only the application to the WildFly Application
    Server without first invoking the the execution of the lifecycle phase
    'package' prior to executing itself.

wildfly:run
  Description: Starts a standalone instance of WildFly and deploys the
    application to the server. This goal will block until cancelled or a
    shutdown is invoked from a management client. Note that if a WildFly
    Bootable JAR is packaged, it is ignored by this goal.

wildfly:shutdown
  Description: Shuts down a running WildFly Application Server. Can also be
    used to issue a reload instead of a full shutdown. If a reload is executed
    the process will wait for the serer to be available before returning.

wildfly:start
  Description: Starts a standalone instance of WildFly Application Server.
    The purpose of this goal is to start a WildFly Application Server for
    testing during the maven lifecycle. Note that if a WildFly Bootable JAR is
    packaged, it is ignored by this goal.

wildfly:start-jar
  Description: Starts a WildFly Application Server packaged as Bootable JAR.
    The purpose of this goal is to start a WildFly Application Server packaged
    as a Bootable JAR for testing during the maven lifecycle.

wildfly:undeploy
  Description: Undeploys the application to the WildFly Application Server.

wildfly:undeploy-artifact
  Description: Undeploys (removes) an arbitrary artifact to the WildFly
    application server

For more information, run 'mvn help:describe [...] -Ddetail'

[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  1.748 s
[INFO] Finished at: 2024-09-30T00:52:29+08:00
[INFO] ------------------------------------------------------------------------
```

The above output contains the goals of the plugins. To display the goals in more detail, just add the `-Ddetail=true` to the options:

```bash
➤ mvn help:describe -Dplugin=org.wildfly.plugins:wildfly-maven-plugin -Ddetail=true
```

To list the phases and goals of Maven plugins, use the following command:

```bash
> mvn buildplan:list
```

Here’s the output of the above command:

```
➤ mvn buildplan:list
...
[INFO]
[INFO] --- buildplan-maven-plugin:2.2.2:list (default-cli) @ batch-deployment-examples ---
[INFO] Build Plan for jberet-deployment-examples:
-----------------------------------------------------------------------------------------------------------
PHASE                  | PLUGIN                    | VERSION     | GOAL             | EXECUTION ID
-----------------------------------------------------------------------------------------------------------
validate               | maven-enforcer-plugin     | 3.5.0       | enforce          | enforce-java-version
validate               | maven-enforcer-plugin     | 3.5.0       | enforce          | enforce-maven-version
validate               | build-helper-maven-plugin | 3.6.0       | regex-properties | add-regex-properties
initialize             | buildnumber-maven-plugin  | 3.2.0       | create           | get-scm-revision
process-resources      | maven-resources-plugin    | 3.3.1       | resources        | default-resources
compile                | maven-compiler-plugin     | 3.13.0      | compile          | default-compile
package                | wildfly-maven-plugin      | 5.0.1.Final | provision        | server-provisioning
process-test-resources | maven-resources-plugin    | 3.3.1       | testResources    | default-testResources
test-compile           | maven-compiler-plugin     | 3.13.0      | testCompile      | default-testCompile
test                   | maven-surefire-plugin     | 3.2.5       | test             | default-test
package                | maven-war-plugin          | 3.4.0       | war              | default-war
package                | maven-source-plugin       | 3.2.1       | jar-no-fork      | attach-sources
pre-integration-test   | wildfly-maven-plugin      | 5.0.1.Final | start            | wildfly-start
pre-integration-test   | wildfly-maven-plugin      | 5.0.1.Final | deploy           | wildfly-start
integration-test       | maven-failsafe-plugin     | 3.2.5       | integration-test | default
post-integration-test  | wildfly-maven-plugin      | 5.0.1.Final | shutdown         | wildfly-stop
verify                 | maven-failsafe-plugin     | 3.2.5       | verify           | default
install                | maven-install-plugin      | 3.1.2       | install          | default-install
deploy                 | maven-deploy-plugin       | 3.1.2       | deploy           | default-deploy
...
```

To show the phases and goals grouped by plugin, use the following command[^buildplan1]:

```bash
> mvn buildplan:list-plugin
```

The output of the above command is:

```
...
[INFO] --- buildplan-maven-plugin:2.2.2:list-plugin (default-cli) @ batch-deployment-examples ---
[INFO] Build Plan for jberet-deployment-examples:
maven-enforcer-plugin --------------------------------------------------
    + validate               | enforce          | enforce-java-version
    + validate               | enforce          | enforce-maven-version
build-helper-maven-plugin ----------------------------------------------
    + validate               | regex-properties | add-regex-properties
buildnumber-maven-plugin -----------------------------------------------
    + initialize             | create           | get-scm-revision
maven-resources-plugin -------------------------------------------------
    + process-resources      | resources        | default-resources
    + process-test-resources | testResources    | default-testResources
maven-compiler-plugin --------------------------------------------------
    + compile                | compile          | default-compile
    + test-compile           | testCompile      | default-testCompile
wildfly-maven-plugin ---------------------------------------------------
    + package                | provision        | server-provisioning
    + pre-integration-test   | start            | wildfly-start
    + pre-integration-test   | deploy           | wildfly-start
    + post-integration-test  | shutdown         | wildfly-stop
maven-surefire-plugin --------------------------------------------------
    + test                   | test             | default-test
maven-war-plugin -------------------------------------------------------
    + package                | war              | default-war
maven-source-plugin ----------------------------------------------------
    + package                | jar-no-fork      | attach-sources
maven-failsafe-plugin --------------------------------------------------
    + integration-test       | integration-test | default
    + verify                 | verify           | default
maven-install-plugin ---------------------------------------------------
    + install                | install          | default-install
maven-deploy-plugin ----------------------------------------------------
    + deploy                 | deploy           | default-deploy
[INFO] ------------------------------------------------------------------------
...
```

As the table shown above, the `wildfly-maven-plugin` phases and goals are[^buildplan2]:

```
wildfly-maven-plugin ---------------------------------------------------
    + package                | provision        | server-provisioning
    + pre-integration-test   | start            | wildfly-start
    + pre-integration-test   | deploy           | wildfly-start
    + post-integration-test  | shutdown         | wildfly-stop
```

Here is the relative configuration of the `wildfly-maven-plugin` in the `pom.xml`:

```xml
<plugin>
    <groupId>org.wildfly.plugins</groupId>
    <artifactId>wildfly-maven-plugin</artifactId>
    <version>${version.maven.wildfly.plugin}</version>
    <configuration>
        <galleon-options>
            <!--                        <galleon.offline>false</galleon.offline>-->
            <jboss-fork-embedded>true</jboss-fork-embedded>
        </galleon-options>
    </configuration>
    <executions>
        <execution>
            <id>server-provisioning</id>
            <phase>generate-test-resources</phase>
            <goals>
                <goal>provision</goal>
            </goals>
            <configuration>
                <provisioning-dir>${jboss.home}</provisioning-dir>
                <galleon-options>
                    <jboss-fork-embedded>${galleon.fork.embedded}</jboss-fork-embedded>
                </galleon-options>
                <feature-packs>
                    <feature-pack>
                        <groupId>${server.test.feature.pack.groupId}</groupId>
                        <artifactId>${server.test.feature.pack.artifactId}</artifactId>
                        <version>${wildfly.version}</version>
                        <inherit-configs>false</inherit-configs>
                        <included-configs>
                            <config>
                                <model>standalone</model>
                                <name>standalone-full.xml</name>
                            </config>
                            <config>
                                <model>standalone</model>
                                <name>standalone.xml</name>
                            </config>
                        </included-configs>
                        <excluded-packages>
                            <name>docs.schema</name>
                            <name>appclient</name>
                            <name>domain</name>
                        </excluded-packages>
                    </feature-pack>
                </feature-packs>
                <channels>
                    <channel>
                        <manifest>
                            <groupId>org.jberet</groupId>
                            <artifactId>jberet-channel-manifest</artifactId>
                            <version>${version.jberet}</version>
                        </manifest>
                    </channel>
                </channels>
            </configuration>
        </execution>
        <execution>
            <id>wildfly-start</id>
            <phase>pre-integration-test</phase>
            <goals>
                <goal>start</goal>
                <goal>deploy</goal>
            </goals>
            <configuration>
                <filename>batch-deployment.war</filename>
            </configuration>
        </execution>
        <execution>
            <phase>post-integration-test</phase>
            <id>wildfly-stop</id>
            <goals>
                <goal>shutdown</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

The output of the buildplan is corresponding with the above configuration.

In addition, the plugin itself is having a default phase like[^devmojo]:

```java
@Mojo(name = "dev", requiresDependencyResolution = ResolutionScope.COMPILE_PLUS_RUNTIME, defaultPhase = LifecyclePhase.PACKAGE)
public class DevMojo extends AbstractServerStartMojo {
...
```

The above mojo has goal defined:

```java
@Override
public String goal() {
    return "dev";
}
```

Above is an introduction to the methods to show the information of Maven plugins.

## References

[^list_goals]: [How to display a list of available goals?](https://stackoverflow.com/questions/1674524/how-to-display-a-list-of-available-goals)
[^buildplan1]: [Buildplan Maven Plugin – Usage](https://www.mojohaus.org/buildplan-maven-plugin/usage.html)
[^buildplan2]: [Show Maven build plan](https://jeanchristophegay.com/en/posts/maven-build-plan/)
[^devmojo]: [DevMojo.java](https://github.com/wildfly/wildfly-maven-plugin/blob/main/plugin/src/main/java/org/wildfly/plugin/dev/DevMojo.java)





