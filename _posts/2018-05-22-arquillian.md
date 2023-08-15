---
title: 编译RESTEasy并在Wildfly的Arquillian容器里调试
abstract: 记录一下自己在RESTEasy开发过程中，使用Arquillian的心得。
---



目前Arquillian对Wildfy的支持还不是特别完善。Arquillian对每一种容器的每一个版本都要有特别的支持，所以维护起来比较困难。Arquillian的Wildfly容器在这里：

> https://github.com/wildfly/wildfly-arquillian

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/0c2165c7bc3ff64ffc1b6c3de10f5671.8a4219bbf7874d92985c53643b09a4fd.jpeg)

Arquillian对容器的支持有三种模式：

- embedded
- managed
- remote

IntelliJ支持这三种模式：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/4bd7d5dd9ef9d611a44cb014165d7260.9bac60fe53e7417a9ad5b5bd305f267b.jpeg)

但需要注意的是，并不是对所有容器的所有版本都支持，因为Arquillian自身目前也不是支持所有容器的所有版本。

Managed模式是比较常用的，并且需要你在`pom.xml`里面自己配置好。目前针对Wildfly的配置比较复杂，主要是各组件的版本依赖关系比较复杂。最好是使用Arquillian提供的样例项目，在此基础上面进行修改：

> https://github.com/arquillian/arquillian-examples

注意managed mode需要你自己的项目里有一个`Arquillian`配置文件：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/e5bc39df7b9367ff01d128dee20d1db2.6aa2d1991a544c1ea96669e345913d18.jpeg)

这个文件要放在`resources`目录里。

RESTEasy自己的`integreation-tests`使用了Arquillian，并做了大量配置。

如果要手动重新执行`integration-tests`，需要首先重新编译项目修改的部分，然后编译项目里的`jboss-modules`项目：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/7db840decef015df4f336506de5fae02.354df4ecf6d74c3b872128ba455dbf37.jpeg)

注意生成的打包zip文件，这个是Wildfly的modules。在`integration-tests`里面，会在managed的Wildfly服务器里自动展开这个module：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/978bbc8e27144c063b498eda64b9206a.810b4f6759f847ee9bc1fc8079a5a6c5.jpeg)

上面是`integration-test`的`pom.xml`文件。

这样，针对测试执行`mvn install`的时候，就会更新Wildfly里面的resteasy module了：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/91311a13008bc64e3762fe0f8772d060.336259280bfe493bba807c15fe175cd9.jpeg)

如果需要remote debug这个managed server，使用wildfly的`--debug`启动命令：

```bash
$ ./standalone.sh --debug -Dresteasy.server.tracing.type=ALL -Dresteasy.server.tracing.threshold=VERBOSE
```

此外Maven也支持远程调试：

```bash
$ mvn -q surefire:test -Dmaven.surefire.debug -Dtest=...
```

以上是对工作的简单记录。



