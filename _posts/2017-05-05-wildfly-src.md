---
title: "Fetching and compiling the Wildfly upstream source"
author: Weinan
---

In this article I want to teach you how to fetch the Wildfly code from Github and compile it for playing. First we need to clone the Wildfly source repository from Github, and here is the address of the repository:

- [https://github.com/wildfly/wildfly.git](https://github.com/wildfly/wildfly.git)

The command to clone the repository is here:

```
git clone https://github.com/wildfly/wildfly.git
```

The above command will clone the `wildfly` project into our local machine. 


```
$ ls
appclient        clustering    integration-tests.bat  legacy              picketlink  servlet-build         tools         zanata.xml
batch            connector     integration-tests.sh   mail                pojo        servlet-dist          transactions
bean-validation  dist          jaxrs                  messaging-activemq  pom.xml     servlet-feature-pack  undertow
build            ee            jdr                    mod_cluster         README.md   spec-api              web-common
build.bat        ejb3          jpa                    mvnw                rts         system-jmx            webservices
build.sh         feature-pack  jsf                    mvnw.cmd            sar         target                weld
client           iiop-openjdk  jsr77                  naming              security    testsuite             xts
```

The above output shows the directory structure of the `wildfly` project. We can see the project is organized in subsystems. For example, the `undertow` subsystem is the WebServer module of the Wildfly, and `jaxrs` is the RESTFul WebService module. We will check these subsystems in future. The whole project is Maven based, and there is a build script named `build.sh` in the root directory. We can run the build script locally to build the whole project. Here is the command and part of the output:

```
$ ./build.sh
/home/weli/projs/wildfly/mvnw -Dmaven.user.home=/home/weli/projs/wildfly/tools  install
```

From the above command and its output we can see the `build.sh` will start to build the project using the `mvnw` command. The `mvnw` command will install Maven into local folder firstly, and then use it to build the project. The time to build the whole project depends on the speed of your network and the configuration of your hardware. During the build process, it will download many components from online Maven repositories, and it will run many tests in project. During the first time of build, it will use most time to download the dependencies, and the future builds will use less time. Here is the output of my build in my local machine:

```
[INFO] ------------------------------------------------------------------------
[INFO] Reactor Summary:
[INFO]
[INFO] WildFly: Parent Aggregator ......................... SUCCESS [  1.314 s]
[INFO] WildFly: Clustering Subsystems ..................... SUCCESS [  0.102 s]
[INFO] WildFly: JGroups modules ........................... SUCCESS [  0.036 s]
[INFO] WildFly: JGroups API ............................... SUCCESS [  1.827 s]
[INFO] WildFly: Clustering services ....................... SUCCESS [  1.092 s]
[INFO] WildFly: Naming Subsystem .......................... SUCCESS [  3.691 s]
[INFO] WildFly: Common code for clustering subsystems ..... SUCCESS [  0.934 s]
[INFO] WildFly: JGroups SPI ............................... SUCCESS [  0.457 s]
[INFO] WildFly: EE ........................................ SUCCESS [  6.884 s]
[INFO] WildFly: IIOP Openjdk Subsystem .................... SUCCESS [  3.283 s]
[INFO] WildFly: Transaction Subsystem ..................... SUCCESS [  6.460 s]
[INFO] WildFly: Clustering marshalling modules ............ SUCCESS [  0.028 s]
[INFO] WildFly: Clustering marshalling API ................ SUCCESS [  0.234 s]
[INFO] WildFly: Infinispan modules ........................ SUCCESS [  0.025 s]
[INFO] WildFly: Infinispan SPI ............................ SUCCESS [  1.150 s]
[INFO] WildFly: Security Subsystem parent ................. SUCCESS [  0.029 s]
[INFO] WildFly: Security Subsystem ........................ SUCCESS [  6.331 s]
[INFO] WildFly: Connector Subsystem ....................... SUCCESS [ 17.181 s]
[INFO] WildFly: Clustering public API ..................... SUCCESS [  0.314 s]
[INFO] WildFly: EE clustering ............................. SUCCESS [  0.026 s]
[INFO] WildFly: EE clustering SPI ......................... SUCCESS [  0.635 s]
[INFO] WildFly: SFSB clustering ........................... SUCCESS [  0.024 s]
[INFO] WildFly: SFSB clustering - SPI ..................... SUCCESS [  0.539 s]
[INFO] WildFly: Clustering marshalling SPI ................ SUCCESS [  1.475 s]
[INFO] WildFly: Clustering integration with JBoss Marshalling SUCCESS [  0.830 s]
[INFO] WildFly: Singleton modules ......................... SUCCESS [  0.025 s]
[INFO] WildFly: Singleton API ............................. SUCCESS [  0.756 s]
[INFO] WildFly: Clustering SPI ............................ SUCCESS [  0.348 s]
[INFO] WildFly: EJB Subsystem ............................. SUCCESS [ 13.298 s]
[INFO] WildFly: Web Common Classes ........................ SUCCESS [  0.717 s]
[INFO] WildFly: Undertow .................................. SUCCESS [  7.959 s]
[INFO] WildFly: Web Services Subsystem .................... SUCCESS [  0.015 s]
[INFO] WildFly: Web Services Server Integration Subsystem . SUCCESS [  6.692 s]
[INFO] WildFly: Application Client Bootstrap .............. SUCCESS [  0.432 s]
[INFO] WildFly: Batch Integration ......................... SUCCESS [  0.072 s]
[INFO] WildFly: Batch Integration Subsystem (JBeret implementation) SUCCESS [  4.082 s]
[INFO] WildFly: Batch Integration Subsystem ............... SUCCESS [  2.366 s]
[INFO] WildFly: Bean Validation ........................... SUCCESS [  2.139 s]
[INFO] WildFly: Servlet Feature Pack ...................... SUCCESS [  3.400 s]
[INFO] WildFly: JPA ....................................... SUCCESS [  0.018 s]
[INFO] jipijapa SPI ....................................... SUCCESS [  0.157 s]
[INFO] WildFly: Weld ...................................... SUCCESS [  0.016 s]
[INFO] WildFly: Weld Subsystem SPI ........................ SUCCESS [  0.227 s]
[INFO] WildFly: Weld Common Tools ......................... SUCCESS [  0.316 s]
[INFO] WildFly: JPA Subsystem ............................. SUCCESS [  2.246 s]
[INFO] WildFly: Weld Subsystem ............................ SUCCESS [  5.174 s]
[INFO] WildFly: PicketLink Subsystem ...................... SUCCESS [  6.638 s]
[INFO] WildFly: Security Subsystem API .................... SUCCESS [  0.226 s]
[INFO] WildFly: System JMX Module ......................... SUCCESS [  0.139 s]
[INFO] WildFly: JAX-RS Integration ........................ SUCCESS [  2.241 s]
[INFO] WildFly: RTS Subsystem ............................. SUCCESS [  2.326 s]
[INFO] jipijapa Hibernate 5.x (JPA 2.1) integration ....... SUCCESS [  0.323 s]
[INFO] jipijapa Hibernate 4.3.x (JPA 2.1) integration ..... SUCCESS [  1.719 s]
[INFO] jipijapa Hibernate 4.1.x + 4.2.x (JPA 2.0) integration SUCCESS [  0.265 s]
[INFO] jipijapa EclipseLink integration ................... SUCCESS [  0.161 s]
[INFO] jipijapa OpenJPA integration ....................... SUCCESS [  0.300 s]
[INFO] WildFly: EJB Client BOM ............................ SUCCESS [  0.071 s]
[INFO] WildFly: JMS Client BOM ............................ SUCCESS [  0.196 s]
[INFO] WildFly: EJB and JMS client combined jar ........... SUCCESS [  4.137 s]
[INFO] WildFly: EE clustering - Infinispan service provider SUCCESS [  0.927 s]
[INFO] WildFly: SFSB clustering - Infinispan integration .. SUCCESS [  4.098 s]
[INFO] WildFly: JGroups Subsystem ......................... SUCCESS [ 12.050 s]
[INFO] WildFly: Clustering marshalling Infinispan adapters  SUCCESS [  0.184 s]
[INFO] WildFly: Infinispan subsystem ...................... SUCCESS [ 50.308 s]
[INFO] WildFly: Clustering API implementation ............. SUCCESS [  0.910 s]
[INFO] WildFly: Singleton extension ....................... SUCCESS [  3.309 s]
[INFO] WildFly: Web session clustering .................... SUCCESS [  0.021 s]
[INFO] WildFly: Web session clustering API ................ SUCCESS [  0.139 s]
[INFO] WildFly: Web session clustering SPI ................ SUCCESS [  1.097 s]
[INFO] WildFly: Web session clustering - Infinispan service provider SUCCESS [  2.273 s]
[INFO] WildFly: Web session clustering - Undertow integration SUCCESS [  1.141 s]
[INFO] WildFly: EJB Container Managed Persistence Subsystem SUCCESS [  1.841 s]
[INFO] Wildfly: Config Admin .............................. SUCCESS [  1.631 s]
[INFO] WildFly: JAXR Client ............................... SUCCESS [  1.676 s]
[INFO] WildFly: JBoss Diagnostic Reporter ................. SUCCESS [  0.017 s]
[INFO] WildFly: JDR ....................................... SUCCESS [  1.843 s]
[INFO] WildFly: JSF ....................................... SUCCESS [  0.017 s]
[INFO] WildFly: JSF Subsystem ............................. SUCCESS [  1.710 s]
[INFO] WildFly: JSF Injection Handlers .................... SUCCESS [  0.309 s]
[INFO] WildFly: JSR-77 Subsystem .......................... SUCCESS [  2.216 s]
[INFO] WildFly: JacORB Subsystem .......................... SUCCESS [  7.434 s]
[INFO] WildFly: Mail subsystem ............................ SUCCESS [  5.446 s]
[INFO] WildFly: Messaging Subsystem With ActiveMQ Artemis . SUCCESS [  9.612 s]
[INFO] WildFly: (Legacy) Messaging Subsystem .............. SUCCESS [ 16.285 s]
[INFO] WildFly: mod_cluster Subsystem ..................... SUCCESS [  0.016 s]
[INFO] WildFly: mod_cluster Extension ..................... SUCCESS [  7.047 s]
[INFO] WildFly: mod_cluster Undertow Integration .......... SUCCESS [  1.190 s]
[INFO] WildFly: POJO Subsystem ............................ SUCCESS [  1.450 s]
[INFO] WildFly: Service Archive Subsystem ................. SUCCESS [  1.601 s]
[INFO] WildFly: Web Subsystem ............................. SUCCESS [  5.175 s]
[INFO] WildFly: Weld EJB .................................. SUCCESS [  0.249 s]
[INFO] WildFly: Weld JPA .................................. SUCCESS [  0.234 s]
[INFO] WildFly: Weld Bean Validation ...................... SUCCESS [  0.179 s]
[INFO] WildFly: Weld Webservices .......................... SUCCESS [  1.597 s]
[INFO] WildFly: Weld Transactions ......................... SUCCESS [  0.191 s]
[INFO] WildFly: XTS Subsystem ............................. SUCCESS [  3.584 s]
[INFO] WildFly: Full Feature Pack ......................... SUCCESS [ 17.819 s]
[INFO] WildFly: Build ..................................... SUCCESS [ 19.608 s]
[INFO] WildFly: Distribution .............................. SUCCESS [ 20.630 s]
[INFO] WildFly: JSF Multi-JSF installer ................... SUCCESS [  1.542 s]
[INFO] WildFly: Exported Java EE Specification APIs ....... SUCCESS [  0.037 s]
[INFO] WildFly: Validation Tests for Exported Java EE Specification APIs SUCCESS [  0.039 s]
[INFO] WildFly: Servlet Build ............................. SUCCESS [  0.462 s]
[INFO] WildFly: Servlet Distribution ...................... SUCCESS [  1.401 s]
[INFO] WildFly: Web Services Tests Integration Subsystem .. SUCCESS [  1.573 s]
[INFO] WildFly Test Suite: Shared ......................... SUCCESS [  0.578 s]
[INFO] WildFly Test Suite: Aggregator ..................... SUCCESS [  0.016 s]
[INFO] WildFly Test Suite: Integration (parent) ........... SUCCESS [  0.311 s]
[INFO] WildFly Test Suite: Integration - Web .............. SUCCESS [ 44.440 s]
[INFO] WildFly Test Suite: Integration - Smoke ............ SUCCESS [ 53.678 s]
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time: 07:23 min
[INFO] Finished at: 2017-05-05T02:47:04+00:00
[INFO] Final Memory: 322M/795M
[INFO] ------------------------------------------------------------------------
```

Above is a summary of the built components in `wildfly`. After all the components are built, it will be assembled into a runnable application server. You can find it in the `build/target` directory of the project. Here are the contents of the directory:

```
$ ls build/target
archive-tmp  wildfly-11.0.0.Beta1-SNAPSHOT  wildfly-11.0.0.Beta1-SNAPSHOT.zip
```

From above, we can see the application server is in `wildfly-11.0.0.Beta1-SNAPSHOT`, and there is also a zipped pacakge for distribution. We can enter the `wildfly-11.0.0.Beta1-SNAPSHOT` directory and check its contents:
 
```
[weli@io wildfly]$ cd build/target/wildfly-11.0.0.Beta1-SNAPSHOT/
[weli@io wildfly-11.0.0.Beta1-SNAPSHOT]$ ls
appclient  bin  copyright.txt  docs  domain  jboss-modules.jar  LICENSE.txt  modules  README.txt  standalone  welcome-content
```
 
From the above output, we can see the application server is in the directory. Now we can start the server with the following command:

```
$ bin/standalone.sh
```

The above command will run the Wildfly in standalone mode, and here is the output of the server:

```
===

  JBoss Bootstrap Environment

  JBOSS_HOME: /home/weli/projs/wildfly/build/target/wildfly-11.0.0.Beta1-SNAPSHOT

  JAVA: java

  JAVA_OPTS:  -server -Xms64m -Xmx512m -XX:MetaspaceSize=96M -XX:MaxMetaspaceSize=256m -Djava.net.preferIPv4Stack=true -Djboss.modules.system.pkgs=org.jboss.byteman -Djava.awt.headless=true

=========================================================================

03:20:01,271 INFO  [org.jboss.modules] (main) JBoss Modules version 1.6.0.Beta6
03:20:01,581 INFO  [org.jboss.msc] (main) JBoss MSC version 1.2.7.SP1
03:20:01,746 INFO  [org.jboss.as] (MSC service thread 1-8) WFLYSRV0049: WildFly Core 3.0.0.Beta17 "Kenny" starting
03:20:03,284 INFO  [org.jboss.as.controller.management-deprecated] (Controller Boot Thread) WFLYCTL0028: Attribute 'security-realm' in the resource at address '/core-service=management/management-interface=http-interface' is deprecated, and may be removed in future version. See the attribute description in the output of the read-resource-description operation to learn more about the deprecation.
03:20:03,305 INFO  [org.wildfly.security] (ServerService Thread Pool -- 5) ELY00001: WildFly Elytron version 1.1.0.Beta38
03:20:03,319 INFO  [org.jboss.as.controller.management-deprecated] (ServerService Thread Pool -- 29) WFLYCTL0028: Attribute 'security-realm' in the resource at address '/subsystem=undertow/server=default-server/https-listener=https' is deprecated, and may be removed in future version. See the attribute description in the output of the read-resource-description operation to learn more about the deprecation.
03:20:03,395 INFO  [org.jboss.as.server] (Controller Boot Thread) WFLYSRV0039: Creating http management service using socket-binding (management-http)
03:20:03,414 INFO  [org.xnio] (MSC service thread 1-5) XNIO version 3.5.0.Beta5
03:20:03,423 INFO  [org.xnio.nio] (MSC service thread 1-5) XNIO NIO Implementation Version 3.5.0.Beta5
03:20:03,464 INFO  [org.jboss.remoting] (MSC service thread 1-5) JBoss Remoting version 5.0.0.Beta20
03:20:03,486 INFO  [org.jboss.as.jaxrs] (ServerService Thread Pool -- 42) WFLYRS0016: RESTEasy version 3.0.22.Final
03:20:03,488 INFO  [org.jboss.as.naming] (ServerService Thread Pool -- 49) WFLYNAM0001: Activating Naming Subsystem
03:20:03,490 INFO  [org.jboss.as.clustering.infinispan] (ServerService Thread Pool -- 41) WFLYCLINF0001: Activating Infinispan subsystem.
03:20:03,499 INFO  [org.jboss.as.jsf] (ServerService Thread Pool -- 47) WFLYJSF0007: Activated the following JSF Implementations: [main]
03:20:03,509 WARN  [org.jboss.as.txn] (ServerService Thread Pool -- 58) WFLYTX0013: Node identifier property is set to the default value. Please make sure it is unique.
03:20:03,526 INFO  [org.wildfly.extension.io] (ServerService Thread Pool -- 40) WFLYIO001: Worker 'default' has auto-configured to 8 core threads with 64 task threads based on your 4 available processors
03:20:03,559 INFO  [org.jboss.as.security] (ServerService Thread Pool -- 57) WFLYSEC0002: Activating Security Subsystem
03:20:03,568 INFO  [org.jboss.as.connector.subsystems.datasources] (ServerService Thread Pool -- 36) WFLYJCA0004: Deploying JDBC-compliant driver class org.h2.Driver (version 1.4)
03:20:03,577 INFO  [org.jboss.as.webservices] (ServerService Thread Pool -- 60) WFLYWS0002: Activating WebServices Extension
03:20:03,583 INFO  [org.jboss.as.connector] (MSC service thread 1-4) WFLYJCA0009: Starting JCA Subsystem (WildFly/IronJacamar 1.4.4.Final)
03:20:03,613 INFO  [org.jboss.as.connector.deployers.jdbc] (MSC service thread 1-5) WFLYJCA0018: Started Driver service with driver-name = h2
03:20:03,597 INFO  [org.jboss.as.security] (MSC service thread 1-7) WFLYSEC0001: Current PicketBox version=5.0.1.Final
03:20:03,665 INFO  [org.wildfly.extension.undertow] (MSC service thread 1-6) WFLYUT0003: Undertow 1.4.13.Final starting
03:20:03,666 INFO  [org.jboss.as.naming] (MSC service thread 1-6) WFLYNAM0003: Starting Naming Service
03:20:03,667 INFO  [org.jboss.as.mail.extension] (MSC service thread 1-6) WFLYMAIL0001: Bound mail session [java:jboss/mail/Default]
03:20:04,080 INFO  [org.wildfly.extension.undertow] (ServerService Thread Pool -- 59) WFLYUT0014: Creating file handler for path '/home/weli/projs/wildfly/build/target/wildfly-11.0.0.Beta1-SNAPSHOT/welcome-content' with options [directory-listing: 'false', follow-symlink: 'false', case-sensitive: 'true', safe-symlink-paths: '[]']
03:20:04,096 INFO  [org.jboss.as.ejb3] (MSC service thread 1-8) WFLYEJB0481: Strict pool slsb-strict-max-pool is using a max instance size of 64 (per class), which is derived from thread worker pool sizing.
03:20:04,098 INFO  [org.wildfly.extension.undertow] (MSC service thread 1-5) WFLYUT0012: Started server default-server.
03:20:04,099 INFO  [org.jboss.as.ejb3] (MSC service thread 1-7) WFLYEJB0482: Strict pool mdb-strict-max-pool is using a max instance size of 16 (per class), which is derived from the number of CPUs on this host.
03:20:04,105 INFO  [org.wildfly.extension.undertow] (MSC service thread 1-8) WFLYUT0018: Host default-host starting
03:20:04,205 INFO  [org.wildfly.extension.undertow] (MSC service thread 1-5) WFLYUT0006: Undertow HTTP listener default listening on 127.0.0.1:8080
03:20:04,420 INFO  [org.jboss.as.patching] (MSC service thread 1-8) WFLYPAT0050: WildFly cumulative patch ID is: base, one-off patches include: none
03:20:04,465 INFO  [org.jboss.as.ejb3] (MSC service thread 1-2) WFLYEJB0493: EJB subsystem suspension complete
03:20:04,507 WARN  [org.jboss.as.domain.management.security] (MSC service thread 1-8) WFLYDM0111: Keystore /home/weli/projs/wildfly/build/target/wildfly-11.0.0.Beta1-SNAPSHOT/standalone/configuration/application.keystore not found, it will be auto generated on first use with a self signed certificate for host localhost
03:20:04,554 INFO  [org.jboss.as.server.deployment.scanner] (MSC service thread 1-5) WFLYDS0013: Started FileSystemDeploymentService for directory /home/weli/projs/wildfly/build/target/wildfly-11.0.0.Beta1-SNAPSHOT/standalone/deployments
03:20:04,724 INFO  [org.wildfly.extension.undertow] (MSC service thread 1-2) WFLYUT0006: Undertow HTTPS listener https listening on 127.0.0.1:8443
03:20:04,730 INFO  [org.infinispan.factories.GlobalComponentRegistry] (MSC service thread 1-5) ISPN000128: Infinispan version: Infinispan 'Chakra' 8.2.6.Final
03:20:04,732 INFO  [org.jboss.as.connector.subsystems.datasources] (MSC service thread 1-1) WFLYJCA0001: Bound data source [java:jboss/datasources/ExampleDS]
03:20:04,840 INFO  [org.jboss.ws.common.management] (MSC service thread 1-8) JBWS022052: Starting JBossWS 5.1.8.Final (Apache CXF 3.1.11)
03:20:04,994 INFO  [org.jboss.as.server] (Controller Boot Thread) WFLYSRV0212: Resuming server
03:20:04,996 INFO  [org.jboss.as] (Controller Boot Thread) WFLYSRV0060: Http management interface listening on http://127.0.0.1:9990/management
03:20:04,997 INFO  [org.jboss.as] (Controller Boot Thread) WFLYSRV0051: Admin console listening on http://127.0.0.1:9990
03:20:04,997 INFO  [org.jboss.as] (Controller Boot Thread) WFLYSRV0025: WildFly Core 3.0.0.Beta17 "Kenny" started in 4127ms - Started 397 of 615 services (401 services are lazy, passive or on-demand)
```


The above output shows the server has been started. Until now, we have fetched the Wildfly source from Github repository, and we have built it locally in our machine, and then we run the application server locally. This is the basis to play with Wildfly source code. In future, we just need to keep pulling the newest code of Wildfly from the Github and compile it, then we can keep running a newest Wildfly server for study. 


