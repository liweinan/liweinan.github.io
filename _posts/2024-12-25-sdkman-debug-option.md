---
title: The SDKMAN debug option affetcs the SSH connection.
---

If I set the `debug` option of `sdkman` to `true` in its config file `~/.sdkman/etc/config`:

```txt
sdkman_debug_mode=true
```

Then during the login of the terminal, it will output information like this:

```
Last login: Thu Dec 26 01:13:53 on ttys007
Setting candidates csv: activemq,ant,asciidoctorj,ballerina,bld,bpipe,btrace,concurnas,connor,coursier,cuba,cxf,detekt,doctoolchain,flink,gaiden,gcn,grace,gradle,gradleprofiler,grails,groovy,groovyserv,hadoop,helidon,http4k,infrastructor,jarviz,java,jbake,jbang,jetty,jextract,jikkou,jmc,jmeter,joern,jreleaser,karaf,kcctl,ki,kobweb,kotlin,kscript,ktx,layrry,leiningen,liquibase,maven,mcs,micronaut,mulefd,mvnd,mybatis,neo4jmigrations,pierrot,pomchecker,quarkus,sbt,scala,scalacli,schemacrawler,skeletal,spark,springboot,sshoogr,taxi,test,tomcat,toolkit,vertx,visualvm,webtau,znai
```

The above output may affect SSH login or `scp` command somtimes, so better to turn it off.