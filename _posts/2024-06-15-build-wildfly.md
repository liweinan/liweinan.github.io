---
title: Customize the WildFly and build it for testing.
---

In this blog post I’d like to record the process to build WildFly from main branch and add some logs to find the used batch repository used in WildFly.

Firstly clone the WildFly repository into local environment:

```bash
$ git@github.com:wildfly/wildfly.git
```

Then build it without running tests:

```bash
➤ mvn install -DskipTests
```

If everything goes fine the build should be done:

```bash
[INFO] --- maven-install-plugin:2.5.2:install (default-install) @ wildfly-test-feature-pack-preview ---
[INFO] Installing /Users/weli/works/wildfly/testsuite/test-feature-pack-preview/pom.xml to /Users/weli/.m2/repository/org/wildfly/wildfly-test-feature-pack-preview/33.0.0.Beta1-SNAPSHOT/wildfly-test-feature-pack-preview-33.0.0.Beta1-SNAPSHOT.pom
[INFO] Installing /Users/weli/works/wildfly/testsuite/test-feature-pack-preview/target/wildfly-test-feature-pack-preview-33.0.0.Beta1-SNAPSHOT.zip to /Users/weli/.m2/repository/org/wildfly/wildfly-test-feature-pack-preview/33.0.0.Beta1-SNAPSHOT/wildfly-test-feature-pack-preview-33.0.0.Beta1-SNAPSHOT.zip
[INFO] Installing /Users/weli/works/wildfly/testsuite/test-feature-pack-preview/target/wildfly-test-feature-pack-preview-33.0.0.Beta1-SNAPSHOT-artifact-list.txt to /Users/weli/.m2/repository/org/wildfly/wildfly-test-feature-pack-preview/33.0.0.Beta1-SNAPSHOT/wildfly-test-feature-pack-preview-33.0.0.Beta1-SNAPSHOT-artifact-list.txt
[INFO] ------------------------------------------------------------------------
[INFO] Reactor Summary:
[INFO] 
[INFO] WildFly: Parent Aggregator 33.0.0.Beta1-SNAPSHOT ... SUCCESS [  1.620 s]
[INFO] WildFly: Naming Subsystem 33.0.0.Beta1-SNAPSHOT .... SUCCESS [  3.110 s]
[INFO] WildFly: EE 33.0.0.Beta1-SNAPSHOT .................. SUCCESS [  1.325 s]
[INFO] WildFly: Application Client Bootstrap 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.694 s]
[INFO] WildFly: Weld 33.0.0.Beta1-SNAPSHOT ................ SUCCESS [  0.026 s]
[INFO] WildFly: Weld Subsystem SPI 33.0.0.Beta1-SNAPSHOT .. SUCCESS [  0.917 s]
[INFO] WildFly: Weld Common Tools 33.0.0.Beta1-SNAPSHOT ... SUCCESS [  0.711 s]
[INFO] WildFly: IIOP Openjdk Subsystem 33.0.0.Beta1-SNAPSHOT SUCCESS [  1.081 s]
[INFO] WildFly: Transaction Subsystem 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.639 s]
[INFO] WildFly: Batch Integration Subsystem (JBeret implementation) 33.0.0.Beta1-SNAPSHOT SUCCESS [  4.897 s]
[INFO] WildFly: Bean Validation 33.0.0.Beta1-SNAPSHOT ..... SUCCESS [  0.948 s]
[INFO] WildFly: Common Dependency Management (Base Dependencies) 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.020 s]
[INFO] WildFly: Common Dependency Management (Expansion Dependencies) 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.021 s]
[INFO] WildFly: Legacy Dependency Management (Base Dependencies) 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.020 s]
[INFO] WildFly: Legacy Dependency Management (Expansion Dependencies) 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.018 s]
[INFO] WildFly: Legacy Testsuite Dependency Management 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.021 s]
[INFO] WildFly Preview: Dependency Management (Base Dependencies) 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.021 s]
[INFO] WildFly Preview: Dependency Management (Expansion Dependencies) 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.024 s]
[INFO] WildFly: Dependency Management (Base Dependencies) 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.024 s]
[INFO] WildFly: Dependency Management (Expansion Dependencies) 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.017 s]
[INFO] WildFly: BOM of Test Dependencies 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.017 s]
[INFO] WildFly: Dependency Management (Expansion Test Dependencies) 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.018 s]
[INFO] WildFly: JPA 33.0.0.Beta1-SNAPSHOT ................. SUCCESS [  0.018 s]
[INFO] WildFly: Jipijapa SPI 33.0.0.Beta1-SNAPSHOT ........ SUCCESS [  0.159 s]
[INFO] WildFly: Jipijapa EclipseLink integration 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.184 s]
[INFO] WildFly: Clustering subsystems and modules 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.084 s]
[INFO] WildFly: Clustering marshalling modules 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.033 s]
[INFO] WildFly: Clustering marshalling API 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.152 s]
[INFO] WildFly: Clustering marshalling SPI 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.302 s]
[INFO] WildFly: Marshalling for WildFly clustering: ProtoStream integration 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.373 s]
[INFO] WildFly: Jipijapa Hibernate 6 (JPA 3.1) integration 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.377 s]
[INFO] WildFly: Jipijapa Hibernate Search integration 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.131 s]
[INFO] WildFly: Jakarta Enterprise Beans and Jakarta Messaging client combined properties 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.095 s]
[INFO] WildFly: Jakarta Enterprise Beans and Jakarta Messaging client combined jar 33.0.0.Beta1-SNAPSHOT SUCCESS [ 15.133 s]
[INFO] WildFly: Contextual execution for clustering modules 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.159 s]
[INFO] WildFly: Clustering services 33.0.0.Beta1-SNAPSHOT . SUCCESS [  0.177 s]
[INFO] WildFly: Common code for clustering subsystems 33.0.0.Beta1-SNAPSHOT SUCCESS [  2.610 s]
[INFO] WildFly: EE clustering 33.0.0.Beta1-SNAPSHOT ....... SUCCESS [  0.029 s]
[INFO] WildFly: EE clustering SPI 33.0.0.Beta1-SNAPSHOT ... SUCCESS [  0.127 s]
[INFO] WildFly: Common EE implementations for caches 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.221 s]
[INFO] WildFly: EE clustering - HotRod service provider 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.133 s]
[INFO] WildFly: Infinispan modules 33.0.0.Beta1-SNAPSHOT .. SUCCESS [  0.031 s]
[INFO] WildFly: Infinispan embedded modules 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.029 s]
[INFO] WildFly: Infinispan embedded API extensions 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.119 s]
[INFO] WildFly: Marshalling for WildFly clustering: JBoss Marshalling integration 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.133 s]
[INFO] WildFly: Infinispan marshalling 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.129 s]
[INFO] WildFly: Infinispan embedded SPI 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.247 s]
[INFO] WildFly: Server clustering modules 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.031 s]
[INFO] WildFly: Public server clustering API 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.241 s]
[INFO] WildFly: Server clustering SPI 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.093 s]
[INFO] WildFly: EE clustering - Infinispan service provider 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.187 s]
[INFO] WildFly: SFSB clustering 33.0.0.Beta1-SNAPSHOT ..... SUCCESS [  0.029 s]
[INFO] WildFly: EJB client clustering module 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.123 s]
[INFO] WildFly: SFSB clustering - SPI 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.444 s]
[INFO] WildFly: Common abstractions for cache-based bean manager implementations 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.289 s]
[INFO] WildFly: Infinispan embedded services 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.569 s]
[INFO] WildFly: Server clustering requirements/services 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.435 s]
[INFO] WildFly: SFSB clustering - Infinispan integration 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.797 s]
[INFO] WildFly: Distributable EJB Subsystem 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.712 s]
[INFO] WildFly: Clustering Jakarta Expression Language API modules 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.063 s]
[INFO] WildFly: Clustering support for the Eclipse Expressly implementation of the Jakarta Expression Language API 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.214 s]
[INFO] WildFly: Clustering Jakarta Faces modules 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.028 s]
[INFO] WildFly: Clustering support for the Jakarta Faces API 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.151 s]
[INFO] WildFly: Clustering support for the Mojarra implementation of Jakarta Faces 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.528 s]
[INFO] WildFly: Infinispan client modules 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.037 s]
[INFO] WildFly: Infinispan Client API 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.115 s]
[INFO] WildFly: Infinispan Client requirements and services 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.352 s]
[INFO] WildFly: Infinispan Client SPI 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.088 s]
[INFO] WildFly: JGroups modules 33.0.0.Beta1-SNAPSHOT ..... SUCCESS [  0.017 s]
[INFO] WildFly: JGroups API 33.0.0.Beta1-SNAPSHOT ......... SUCCESS [  0.077 s]
[INFO] WildFly: JGroups SPI 33.0.0.Beta1-SNAPSHOT ......... SUCCESS [  0.425 s]
[INFO] WildFly: Singleton modules 33.0.0.Beta1-SNAPSHOT ... SUCCESS [  0.043 s]
[INFO] WildFly: Singleton API 33.0.0.Beta1-SNAPSHOT ....... SUCCESS [  0.186 s]
[INFO] WildFly: JGroups Subsystem 33.0.0.Beta1-SNAPSHOT ... SUCCESS [  0.850 s]
[INFO] WildFly: Connector Subsystem 33.0.0.Beta1-SNAPSHOT . SUCCESS [  1.364 s]
[INFO] WildFly: Infinispan subsystem 33.0.0.Beta1-SNAPSHOT  SUCCESS [  1.100 s]
[INFO] WildFly: Server clustering SPI implementation 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.230 s]
[INFO] WildFly: Server clustering extension 33.0.0.Beta1-SNAPSHOT SUCCESS [  2.197 s]
[INFO] WildFly: Requirements for WildFly clustering singleton service configurators 33.0.0.Beta1-SNAPSHOT SUCCESS [  1.234 s]
[INFO] WildFly: Singleton extension 33.0.0.Beta1-SNAPSHOT . SUCCESS [  1.480 s]
[INFO] WildFly: WildFly clustering singleton service implementation 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.376 s]
[INFO] WildFly: Web session clustering 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.026 s]
[INFO] WildFly: Web session clustering API 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.094 s]
[INFO] WildFly: Web session clustering SPI 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.136 s]
[INFO] WildFly: Common abstractions for cache-based session manager implementations. 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.230 s]
[INFO] WildFly: Web session clustering - Container SPI 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.472 s]
[INFO] WildFly: Web session clustering - HotRod service provider 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.147 s]
[INFO] WildFly: Web session clustering - Infinispan service provider 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.198 s]
[INFO] WildFly: Web session clustering requirements and service providers 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.480 s]
[INFO] WildFly: Web Common Classes 33.0.0.Beta1-SNAPSHOT .. SUCCESS [  0.590 s]
[INFO] WildFly: JSF 33.0.0.Beta1-SNAPSHOT ................. SUCCESS [  0.012 s]
[INFO] WildFly: JSF Subsystem 33.0.0.Beta1-SNAPSHOT ....... SUCCESS [  0.585 s]
[INFO] WildFly: Distributable Web Subsystem 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.641 s]
[INFO] WildFly: Undertow 33.0.0.Beta1-SNAPSHOT ............ SUCCESS [  0.764 s]
[INFO] WildFly: Web session clustering - Undertow integration 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.537 s]
[INFO] WildFly: Clustering Weld modules 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.022 s]
[INFO] WildFly: Clustering support for Weld 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.512 s]
[INFO] WildFly: EJB Subsystem 33.0.0.Beta1-SNAPSHOT ....... SUCCESS [  7.366 s]
[INFO] WildFly: Weld EJB 33.0.0.Beta1-SNAPSHOT ............ SUCCESS [  0.485 s]
[INFO] WildFly: Clustering support for Weld's ejb module 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.113 s]
[INFO] WildFly: Clustering support for Weld's web module 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.148 s]
[INFO] WildFly: Datasources with Agroal connection pool 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.654 s]
[INFO] WildFly: Jakarta EE Security 33.0.0.Beta1-SNAPSHOT . SUCCESS [  0.466 s]
[INFO] WildFly: Elytron OpenID Connect Client Extension 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.584 s]
[INFO] WildFly: Base Health Extension 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.442 s]
[INFO] WildFly: JAX-RS Integration 33.0.0.Beta1-SNAPSHOT .. SUCCESS [  0.702 s]
[INFO] WildFly: JDR 33.0.0.Beta1-SNAPSHOT ................. SUCCESS [  0.585 s]
[INFO] WildFly: JSF Injection Handlers 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.400 s]
[INFO] WildFly: JSR-77 Subsystem 33.0.0.Beta1-SNAPSHOT .... SUCCESS [  0.376 s]
[INFO] WildFly: JPA Subsystem 33.0.0.Beta1-SNAPSHOT ....... SUCCESS [  0.603 s]
[INFO] WildFly: Keycloak Subsystem 33.0.0.Beta1-SNAPSHOT .. SUCCESS [  0.656 s]
[INFO] WildFly: Mail subsystem 33.0.0.Beta1-SNAPSHOT ...... SUCCESS [  0.461 s]
[INFO] WildFly: Messaging Subsystem Parent With ActiveMQ Artemis 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.009 s]
[INFO] WildFly: Messaging Injection With ActiveMQ Artemis 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.396 s]
[INFO] WildFly: Messaging Subsystem With ActiveMQ Artemis 33.0.0.Beta1-SNAPSHOT SUCCESS [  4.111 s]
[INFO] WildFly: Base Metrics Extension 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.584 s]
[INFO] WildFly: mod_cluster Subsystem 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.012 s]
[INFO] WildFly: mod_cluster Extension 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.490 s]
[INFO] WildFly: mod_cluster Undertow Integration 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.459 s]
[INFO] WildFly: PicketLink Subsystem 33.0.0.Beta1-SNAPSHOT  SUCCESS [  0.622 s]
[INFO] WildFly: POJO Subsystem 33.0.0.Beta1-SNAPSHOT ...... SUCCESS [  0.593 s]
[INFO] WildFly: RTS Subsystem 33.0.0.Beta1-SNAPSHOT ....... SUCCESS [  0.528 s]
[INFO] WildFly: Service Archive Subsystem 33.0.0.Beta1-SNAPSHOT SUCCESS [  1.024 s]
[INFO] WildFly: Security Subsystem parent 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.012 s]
[INFO] WildFly: Security Subsystem 33.0.0.Beta1-SNAPSHOT .. SUCCESS [  0.406 s]
[INFO] WildFly: System JMX Module 33.0.0.Beta1-SNAPSHOT ... SUCCESS [  0.057 s]
[INFO] WildFly: Web Services Subsystem 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.012 s]
[INFO] WildFly: Web Services Server Integration Subsystem 33.0.0.Beta1-SNAPSHOT SUCCESS [  1.053 s]
[INFO] WildFly: XTS Subsystem 33.0.0.Beta1-SNAPSHOT ....... SUCCESS [  1.162 s]
[INFO] WildFly: Web Services OpenSAML ConfigurationPropertiesSource Impl 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.116 s]
[INFO] WildFly: Weld Bean Validation 33.0.0.Beta1-SNAPSHOT  SUCCESS [  0.456 s]
[INFO] WildFly: Weld Subsystem 33.0.0.Beta1-SNAPSHOT ...... SUCCESS [  0.570 s]
[INFO] WildFly: Weld JPA 33.0.0.Beta1-SNAPSHOT ............ SUCCESS [  0.407 s]
[INFO] WildFly: Weld Transactions 33.0.0.Beta1-SNAPSHOT ... SUCCESS [  0.535 s]
[INFO] WildFly: Weld Webservices 33.0.0.Beta1-SNAPSHOT .... SUCCESS [  0.405 s]
[INFO] WildFly: EE Feature Pack Parent 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.015 s]
[INFO] WildFly: EE Feature Pack Shared Galleon Content 33.0.0.Beta1-SNAPSHOT SUCCESS [  2.452 s]
[INFO] WildFly: EE Feature Pack Product Configuration 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.023 s]
[INFO] WildFly: EE Feature Pack Local Galleon Content 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.060 s]
[INFO] WildFly: EE Full Galleon Pack 33.0.0.Beta1-SNAPSHOT  SUCCESS [ 25.869 s]
[INFO] WildFly BOMs: Parent Aggregator 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.016 s]
[INFO] WildFly BOMs: Client Aggregator 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.013 s]
[INFO] WildFly BOMs: EJB Client Builder 33.0.0.Beta1-SNAPSHOT SUCCESS [ 19.221 s]
[INFO] WildFly BOMs: JAXWS Client Builder 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.834 s]
[INFO] WildFly BOMs: JMS Client Builder 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.742 s]
[INFO] WildFly BOMs: EE Builder 33.0.0.Beta1-SNAPSHOT ..... SUCCESS [  0.812 s]
[INFO] WildFly BOMs: EE with Tools Builder 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.033 s]
[INFO] WildFly: Feature Pack Parent 33.0.0.Beta1-SNAPSHOT . SUCCESS [  0.014 s]
[INFO] WildFly: Feature Pack Product Configuration 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.018 s]
[INFO] WildFly: Feature Pack Local Galleon Content 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.088 s]
[INFO] WildFly: MicroProfile modules 33.0.0.Beta1-SNAPSHOT  SUCCESS [  0.024 s]
[INFO] WildFly: MicroProfile Config Extension With SmallRye 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.759 s]
[INFO] WildFly: MicroProfile Metrics Extension With SmallRye 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.598 s]
[INFO] WildFly: Observability modules 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.026 s]
[INFO] WildFly: Micrometer API 33.0.0.Beta1-SNAPSHOT ...... SUCCESS [  0.132 s]
[INFO] WildFly: Base Micrometer Extension 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.651 s]
[INFO] WildFly: MicroProfile Fault Tolerance modules 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.021 s]
[INFO] WildFly: MicroProfile Fault Tolerance - Deployment 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.093 s]
[INFO] WildFly: MicroProfile Fault Tolerance - Extension 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.646 s]
[INFO] WildFly: MicroProfile Health Extension With SmallRye 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.480 s]
[INFO] WildFly: MicroProfile JWT Extension With SmallRye 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.553 s]
[INFO] WildFly: MicroProfile LRA Extensions 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.014 s]
[INFO] WildFly: MicroProfile LRA Coordinator extension 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.530 s]
[INFO] WildFly: MicroProfile LRA Participant extension 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.640 s]
[INFO] WildFly: MicroProfile OpenAPI Extension With SmallRye 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.512 s]
[INFO] WildFly: OpenTelemetry API 33.0.0.Beta1-SNAPSHOT ... SUCCESS [  0.091 s]
[INFO] WildFly: Base OpenTelemetry Extension 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.482 s]
[INFO] WildFly: MicroProfile OpenTracing Extension 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.310 s]
[INFO] WildFly: MicroProfile Reactive Messaging Parent 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.014 s]
[INFO] WildFly: MicroProfile Reactive Messaging Config 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.062 s]
[INFO] WildFly: MicroProfile Reactive Messaging Common 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.504 s]
[INFO] WildFly: MicroProfile Reactive Messaging Kafka 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.466 s]
[INFO] WildFly: MicroProfile Reactive Messaging Extension With SmallRye 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.550 s]
[INFO] WildFly: MicroProfile Reactive Messaging AMQP 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.455 s]
[INFO] WildFly: MicroProfile Reactive Streams Operators Parent 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.012 s]
[INFO] WildFly: MicroProfile Reactive Streams Operators Extension With SmallRye 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.486 s]
[INFO] WildFly: MicroProfile Reactive Streams Operators CDI Provider 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.063 s]
[INFO] WildFly: MicroProfile Telemetry Parent 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.011 s]
[INFO] WildFly: MicroProfile Telemetry CDI Provider 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.087 s]
[INFO] WildFly: MicroProfile Telemetry Extension 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.488 s]
[INFO] WildFly: Feature Pack Shared Galleon Content 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.514 s]
[INFO] WildFly: Galleon Pack 33.0.0.Beta1-SNAPSHOT ........ SUCCESS [  8.931 s]
[INFO] WildFly BOMs: MicroProfile Builder 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.976 s]
[INFO] WildFly: Feature Pack Channel 33.0.0.Beta1-SNAPSHOT  SUCCESS [  0.860 s]
[INFO] WildFly: Thin Server Build 33.0.0.Beta1-SNAPSHOT ... SUCCESS [ 32.034 s]
[INFO] WildFly Test Suite: Shared 33.0.0.Beta1-SNAPSHOT ... SUCCESS [  2.010 s]
[INFO] WildFly: Distribution 33.0.0.Beta1-SNAPSHOT ........ SUCCESS [ 31.761 s]
[INFO] WildFly: EE Feature Pack Channel 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.107 s]
[INFO] WildFly: EE Full Thin Server Build 33.0.0.Beta1-SNAPSHOT SUCCESS [ 28.854 s]
[INFO] WildFly: EE Full Distribution 33.0.0.Beta1-SNAPSHOT  SUCCESS [ 29.765 s]
[INFO] WildFly: EE Full Galleon Pack Layer Tests 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.097 s]
[INFO] WildFly: Galleon Pack Layer Tests 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.076 s]
[INFO] WildFly Preview: Parent 33.0.0.Beta1-SNAPSHOT ...... SUCCESS [  0.018 s]
[INFO] WildFly Preview: Feature Pack Product Configuration 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.020 s]
[INFO] WildFly Preview: Feature Pack Local Galleon Content 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.103 s]
[INFO] WildFly Preview: Galleon Feature Pack 33.0.0.Beta1-SNAPSHOT SUCCESS [ 37.754 s]
[INFO] WildFly: Preview Feature Pack Channel 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.089 s]
[INFO] WildFly Preview: Thin Server Build 33.0.0.Beta1-SNAPSHOT SUCCESS [ 30.774 s]
[INFO] WildFly Preview: Distribution 33.0.0.Beta1-SNAPSHOT  SUCCESS [ 27.775 s]
[INFO] WildFly: Release 33.0.0.Beta1-SNAPSHOT ............. SUCCESS [  0.026 s]
[INFO] WildFly: Exported Jakarta EE Specification APIs 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.068 s]
[INFO] WildFly: Validation Tests for Exported Jakarta EE Specification APIs 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.063 s]
[INFO] WildFly: Test Feature Pack 33.0.0.Beta1-SNAPSHOT ... SUCCESS [  0.132 s]
[INFO] WildFly Test Suite: Aggregator 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.022 s]
[INFO] WildFly Test Suite: Integration (parent) 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.788 s]
[INFO] WildFly Test Suite: Integration - Web 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.724 s]
[INFO] WildFly Test Suite: Integration - Smoke 33.0.0.Beta1-SNAPSHOT SUCCESS [  7.591 s]
[INFO] WildFly: Test Product Configuration 100000.0.1.Final-SNAPSHOT SUCCESS [  0.027 s]
[INFO] WildFly: Web Services Tests Integration Subsystem 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.670 s]
[INFO] WildFly Preview: Test Feature Pack 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.093 s]
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  06:30 min
[INFO] Finished at: 2024-06-14T23:37:03+08:00
[INFO] ------------------------------------------------------------------------
```

The built WildFly server should be in the `dist` dir:

```
➤ pwd
/Users/weli/works/wildfly/dist/target
weli@192:~/w/w/d/target|main✓
➤ ls
checkstyle-cachefile                    generated-test-sources                  verifier
checkstyle-checker.xml                  maven-archiver                          wildfly-33.0.0.Beta1-SNAPSHOT
checkstyle-header.txt                   maven-status                            wildfly-33.0.0.Beta1-SNAPSHOT.jar
checkstyle-result.xml                   site                                    xml-validation
checkstyle-suppressions.xml             test-classes
weli@192:~/w/w/d/target|main✓
➤                                                                
```

The `wildfly-33.0.0.Beta1-SNAPSHOT` is the server that can be run:

```bash
➤ cd wildfly-33.0.0.Beta1-SNAPSHOT/
weli@192:~/w/w/d/t/wildfly-33.0.0.Beta1-SNAPSHOT|main✓
➤ ls
LICENSE.txt             bin                     domain                  standalone
README.txt              copyright.txt           jboss-modules.jar       welcome-content
appclient               docs                    modules
```

Entering the `bin` directory, and we can use the `add-user.sh` to generate a management user firstly:

```bash
weli@192:~/w/w/d/t/w/bin|main✓
➤ ./add-user.sh

What type of user do you wish to add? 
 a) Management User (mgmt-users.properties) 
 b) Application User (application-users.properties)
(a): a

Enter the details of the new user to add.
Using realm 'ManagementRealm' as discovered from the existing property files.
Username : wildfly
Password recommendations are listed below. To modify these restrictions edit the add-user.properties configuration file.
 - The password should be different from the username
 - The password should not be one of the following restricted values {root, admin, administrator}
 - The password should contain at least 8 characters, 1 alphabetic character(s), 1 digit(s), 1 non-alphanumeric symbol(s)
Password : 
WFLYDM0098: The password should be different from the username
Are you sure you want to use the password entered yes/no? yes
Re-enter Password : 
What groups do you want this user to belong to? (Please enter a comma separated list, or leave blank for none)[  ]: 
About to add user 'wildfly' for realm 'ManagementRealm'
Is this correct yes/no? yes
Added user 'wildfly' to file '/Users/weli/works/wildfly/dist/target/wildfly-33.0.0.Beta1-SNAPSHOT/standalone/configuration/mgmt-users.properties'
Added user 'wildfly' to file '/Users/weli/works/wildfly/dist/target/wildfly-33.0.0.Beta1-SNAPSHOT/domain/configuration/mgmt-users.properties'
Added user 'wildfly' with groups  to file '/Users/weli/works/wildfly/dist/target/wildfly-33.0.0.Beta1-SNAPSHOT/standalone/configuration/mgmt-groups.properties'
Added user 'wildfly' with groups  to file '/Users/weli/works/wildfly/dist/target/wildfly-33.0.0.Beta1-SNAPSHOT/domain/configuration/mgmt-groups.properties'
```

As the process shown above, I added a `wildfly` management user and the password is `wildfly` too. Next run the server with `standalone.sh`:

```bash
➤ cd bin/
➤ ./standalone.sh
=========================================================================

  JBoss Bootstrap Environment

  JBOSS_HOME: /Users/weli/works/wildfly/dist/target/wildfly-33.0.0.Beta1-SNAPSHOT

  JAVA: /Users/weli/.sdkman/candidates/java/current/bin/java

  JAVA_OPTS:  -Djdk.serialFilter="maxbytes=10485760;maxdepth=128;maxarray=100000;maxrefs=300000" -Xms64m -Xmx512m -XX:MetaspaceSize=96M -XX:MaxMetaspaceSize=256m -Djava.net.preferIPv4Stack=true -Djboss.modules.system.pkgs=org.jboss.byteman -Djava.awt.headless=true  --add-exports=java.desktop/sun.awt=ALL-UNNAMED --add-exports=java.naming/com.sun.jndi.ldap=ALL-UNNAMED --add-exports=java.naming/com.sun.jndi.url.ldap=ALL-UNNAMED --add-exports=java.naming/com.sun.jndi.url.ldaps=ALL-UNNAMED --add-exports=jdk.naming.dns/com.sun.jndi.dns=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.lang.invoke=ALL-UNNAMED --add-opens=java.base/java.lang.reflect=ALL-UNNAMED --add-opens=java.base/java.io=ALL-UNNAMED --add-opens=java.base/java.net=ALL-UNNAMED --add-opens=java.base/java.security=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.util.concurrent=ALL-UNNAMED --add-opens=java.management/javax.management=ALL-UNNAMED --add-opens=java.naming/javax.naming=ALL-UNNAMED -Djava.security.manager=allow

=========================================================================

23:51:17,701 INFO  [org.jboss.modules] (main) JBoss Modules version 2.1.5.Final
23:51:18,110 INFO  [org.jboss.msc] (main) JBoss MSC version 1.5.5.Final
23:51:18,116 INFO  [org.jboss.threads] (main) JBoss Threads version 2.4.0.Final
23:51:18,205 INFO  [org.jboss.as] (MSC service thread 1-1) WFLYSRV0049: WildFly 33.0.0.Beta1-SNAPSHOT (WildFly Core 25.0.0.Beta3) starting
23:51:18,712 INFO  [org.wildfly.security] (Controller Boot Thread) ELY00001: WildFly Elytron version 2.4.2.Final
23:51:19,080 INFO  [org.jboss.as.server] (Controller Boot Thread) WFLYSRV0039: Creating http management service using socket-binding (management-http)
23:51:19,089 INFO  [org.xnio] (MSC service thread 1-2) XNIO version 3.8.15.Final
23:51:19,095 INFO  [org.xnio.nio] (MSC service thread 1-2) XNIO NIO Implementation Version 3.8.15.Final
23:51:19,125 INFO  [org.wildfly.extension.elytron.oidc._private] (ServerService Thread Pool -- 53) WFLYOIDC0001: Activating WildFly Elytron OIDC Subsystem
23:51:19,131 INFO  [org.jboss.as.clustering.infinispan] (ServerService Thread Pool -- 55) WFLYCLINF0001: Activating Infinispan subsystem.
23:51:19,131 INFO  [org.wildfly.extension.health] (ServerService Thread Pool -- 54) WFLYHEALTH0001: Activating Base Health Subsystem
23:51:19,143 INFO  [org.jboss.as.jaxrs] (ServerService Thread Pool -- 57) WFLYRS0016: RESTEasy version 6.2.9.Final
23:51:19,145 INFO  [org.jboss.as.connector] (MSC service thread 1-6) WFLYJCA0009: Starting Jakarta Connectors Subsystem (WildFly/IronJacamar 3.0.9.Final)
23:51:19,146 INFO  [org.wildfly.extension.io] (ServerService Thread Pool -- 56) WFLYIO001: Worker 'default' has auto-configured to 24 IO threads with 192 max task threads based on your 12 available processors
23:51:19,151 INFO  [org.jboss.as.connector.subsystems.datasources] (ServerService Thread Pool -- 44) WFLYJCA0004: Deploying JDBC-compliant driver class org.h2.Driver (version 2.2)
23:51:19,153 INFO  [org.jboss.as.connector.deployers.jdbc] (MSC service thread 1-5) WFLYJCA0018: Started Driver service with driver-name = h2
23:51:19,155 INFO  [org.jboss.remoting] (MSC service thread 1-8) JBoss Remoting version 5.0.28.Final
23:51:19,174 INFO  [org.wildfly.extension.microprofile.config.smallrye] (ServerService Thread Pool -- 65) WFLYCONF0001: Activating MicroProfile Config Subsystem
23:51:19,176 INFO  [org.jboss.as.jsf] (ServerService Thread Pool -- 62) WFLYJSF0007: Activated the following Jakarta Server Faces Implementations: [main]
23:51:19,183 INFO  [org.wildfly.extension.metrics] (ServerService Thread Pool -- 64) WFLYMETRICS0001: Activating Base Metrics Subsystem
23:51:19,187 WARN  [org.wildfly.extension.elytron] (MSC service thread 1-3) WFLYELY00023: KeyStore file '/Users/weli/works/wildfly/dist/target/wildfly-33.0.0.Beta1-SNAPSHOT/standalone/configuration/application.keystore' does not exist. Used blank.
23:51:19,190 INFO  [org.wildfly.extension.microprofile.jwt.smallrye] (ServerService Thread Pool -- 66) WFLYJWT0001: Activating MicroProfile JWT Subsystem
23:51:19,196 INFO  [org.jboss.as.naming] (ServerService Thread Pool -- 67) WFLYNAM0001: Activating Naming Subsystem
23:51:19,197 WARN  [org.wildfly.extension.elytron] (MSC service thread 1-1) WFLYELY01084: KeyStore /Users/weli/works/wildfly/dist/target/wildfly-33.0.0.Beta1-SNAPSHOT/standalone/configuration/application.keystore not found, it will be auto-generated on first use with a self-signed certificate for host localhost
23:51:19,209 INFO  [org.jboss.as.naming] (MSC service thread 1-6) WFLYNAM0003: Starting Naming Service
23:51:19,210 INFO  [org.jboss.as.mail.extension] (MSC service thread 1-2) WFLYMAIL0001: Bound mail session [java:jboss/mail/Default]
23:51:19,210 WARN  [org.jboss.as.txn] (ServerService Thread Pool -- 74) WFLYTX0013: The node-identifier attribute on the /subsystem=transactions is set to the default value. This is a danger for environments running multiple servers. Please make sure the attribute value is unique.
23:51:19,216 INFO  [org.jboss.as.webservices] (ServerService Thread Pool -- 76) WFLYWS0002: Activating WebServices Extension
23:51:19,229 INFO  [org.jboss.as.ejb3] (MSC service thread 1-2) WFLYEJB0482: Strict pool mdb-strict-max-pool is using a max instance size of 48 (per class), which is derived from the number of CPUs on this host.
23:51:19,229 INFO  [org.jboss.as.ejb3] (MSC service thread 1-5) WFLYEJB0481: Strict pool slsb-strict-max-pool is using a max instance size of 192 (per class), which is derived from thread worker pool sizing.
23:51:19,290 INFO  [org.wildfly.extension.undertow] (MSC service thread 1-3) WFLYUT0003: Undertow 2.3.13.Final starting
23:51:19,321 INFO  [org.wildfly.extension.undertow] (ServerService Thread Pool -- 75) WFLYUT0014: Creating file handler for path '/Users/weli/works/wildfly/dist/target/wildfly-33.0.0.Beta1-SNAPSHOT/welcome-content' with options [directory-listing: 'false', follow-symlink: 'false', case-sensitive: 'true', safe-symlink-paths: '[]']
23:51:19,324 INFO  [org.wildfly.extension.undertow] (MSC service thread 1-5) WFLYUT0012: Started server default-server.
23:51:19,325 INFO  [org.wildfly.extension.undertow] (MSC service thread 1-6) Queuing requests.
23:51:19,327 INFO  [org.wildfly.extension.undertow] (MSC service thread 1-6) WFLYUT0018: Host default-host starting
23:51:19,365 INFO  [org.wildfly.extension.undertow] (MSC service thread 1-5) WFLYUT0006: Undertow HTTP listener default listening on 127.0.0.1:8080
23:51:19,379 INFO  [org.wildfly.extension.undertow] (MSC service thread 1-1) WFLYUT0006: Undertow HTTPS listener https listening on 127.0.0.1:8443
23:51:19,407 INFO  [org.jboss.as.ejb3] (MSC service thread 1-5) WFLYEJB0493: Jakarta Enterprise Beans subsystem suspension complete
23:51:19,448 INFO  [org.jboss.as.connector.subsystems.datasources] (MSC service thread 1-4) WFLYJCA0001: Bound data source [java:jboss/datasources/ExampleDS]
23:51:19,521 INFO  [org.jboss.as.server.deployment.scanner] (MSC service thread 1-6) WFLYDS0013: Started FileSystemDeploymentService for directory /Users/weli/works/wildfly/dist/target/wildfly-33.0.0.Beta1-SNAPSHOT/standalone/deployments
23:51:19,571 INFO  [org.jboss.ws.common.management] (MSC service thread 1-5) JBWS022052: Starting JBossWS 7.1.0.Final (Apache CXF 4.0.4) 
23:51:19,658 INFO  [org.jboss.as.server] (Controller Boot Thread) WFLYSRV0212: Resuming server
23:51:19,662 INFO  [org.jboss.as] (Controller Boot Thread) WFLYSRV0060: Http management interface listening on http://127.0.0.1:9990/management
23:51:19,663 INFO  [org.jboss.as] (Controller Boot Thread) WFLYSRV0051: Admin console listening on http://127.0.0.1:9990
23:51:19,663 INFO  [org.jboss.as] (Controller Boot Thread) WFLYSRV0025: WildFly 33.0.0.Beta1-SNAPSHOT (WildFly Core 25.0.0.Beta3) started in 2184ms - Started 281 of 524 services (320 services are lazy, passive or on-demand) - Server configuration file in use: standalone.xml
```

Now we can access the admin GUI in browser:

```
http://127.0.0.1:9990
```

And then entering the `wildfly` account and password `wildfly` to login into the admin GUI:

![](https://raw.githubusercontent.com/liweinan/blogpics2024/main/0615/01.png)

If everything goes fine we can see the admin homepage:

![](https://raw.githubusercontent.com/liweinan/blogpics2024/main/0615/02.png)

Now we can try to deploy a batch example project into the WildFly server. We can use the `batch-processing` example from `wildfly-quickstart` as a sample project to deploy into built WildFly server. The following command will fork the `quickstart` repository:

```bash
$ git clone git@github.com:wildfly/quickstart.git wildfly-quickstart
```

After the repository is cloned into local environment, we can build the `batch-processing` sample project inside:

```bash
$ cd batch-processing
$ mvn install
```

If everything goes fine, we have the built WAR file:

```
➤ pwd
/Users/weli/works/wildfly-quickstart/batch-processing
weli@192:~/w/w/batch-processing|main⚡?
➤ ls target/*.war
target/batch-processing.war
```

Now we can deploy the built `batch-processing.war` into built WildFly. First click the `Start` of `Deployments`:

![](https://raw.githubusercontent.com/liweinan/blogpics2024/main/0615/03.png)

Then click `Upload Deployment`:

![](https://raw.githubusercontent.com/liweinan/blogpics2024/main/0615/04.png)

Then select the `batch-processing.war`:

![](https://raw.githubusercontent.com/liweinan/blogpics2024/main/0615/05.png)

Then click `next`:

![](https://raw.githubusercontent.com/liweinan/blogpics2024/main/0615/06.png)

Then click `Finish`:

![](https://raw.githubusercontent.com/liweinan/blogpics2024/main/0615/07.png)

And then wait for a moment for the deployment to be finished:

![](https://raw.githubusercontent.com/liweinan/blogpics2024/main/0615/08.png)

If everything goes fine we can see the deployed project:

![](https://raw.githubusercontent.com/liweinan/blogpics2024/main/0615/09.png)

Now we can check the `Runtime` section of the server:

![](https://raw.githubusercontent.com/liweinan/blogpics2024/main/0615/10.png)

From the above screenshot we can see the `Batch` subsystem has a `import-file` job there, which is from the deployed project, and the attributes of the `Batch` subsystem is shown at right.

Now we can try to modify the WildFly code to add some log info into the `batch-jberet` module. Here are my changes:

```diff
diff --git a/batch-jberet/src/main/java/org/wildfly/extension/batch/jberet/job/repository/JobRepositoryService.java b/batch-jberet/src/main/java/org/wildfly/extension/batch/jberet/job/repository/JobRepositoryService.java
index a4d1e60e5d..b4a825ce0f 100644
--- a/batch-jberet/src/main/java/org/wildfly/extension/batch/jberet/job/repository/JobRepositoryService.java
+++ b/batch-jberet/src/main/java/org/wildfly/extension/batch/jberet/job/repository/JobRepositoryService.java
@@ -47,6 +47,7 @@ abstract class JobRepositoryService implements JobRepository, Service<JobReposit
 
     @Override
     public final void start(final StartContext context) throws StartException {
+ BatchLogger.LOGGER.infof("Starting JobRepositoryService");
  startJobRepository(context);
  started = true;
  jobRepositoryConsumer.accept(this);
@@ -66,6 +67,7 @@ abstract class JobRepositoryService implements JobRepository, Service<JobReposit
 
     @Override
     public void addJob(final ApplicationAndJobName applicationAndJobName, final Job job) {
+ BatchLogger.LOGGER.infof("Adding Job: %s", job);
  getAndCheckDelegate().addJob(applicationAndJobName, job);
  }
 
@@ -224,6 +226,7 @@ abstract class JobRepositoryService implements JobRepository, Service<JobReposit
 
     private JobRepository getAndCheckDelegate() {
         final JobRepository delegate = getDelegate();
+ BatchLogger.LOGGER.infof("JobRepository delegate: " + (delegate == null ? "null" : delegate.getClass().getName()));
  if (started && delegate != null) {
  return delegate;
  }
```

As the patch shown above I added some log output to the `JobRepositoryService.java` in WildFly codebase, and then I did a rebuild of the WildFly:

```bash
$ mvn install -DskipTests
...
[INFO] WildFly Preview: Test Feature Pack 33.0.0.Beta1-SNAPSHOT SUCCESS [  0.084 s]
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  05:25 min
[INFO] Finished at: 2024-06-16T01:08:26+08:00
[INFO] ------------------------------------------------------------------------
```

After the server with changes is rebuilt, the content in `dist` directory is reset.  So we need to repeat the above steps to add `wildfly` and deploy the `batch-processing.war` into the server. And we can see the added log in the server output:

![](https://raw.githubusercontent.com/liweinan/blogpics2024/main/0615/11.png)

And here:

![](https://raw.githubusercontent.com/liweinan/blogpics2024/main/0615/12.png)

This way we can modify the WildFly and do the tests.

