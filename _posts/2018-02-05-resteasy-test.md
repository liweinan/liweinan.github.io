---
title: RESTEasy：只运行testsuite中的某一个测试
abstract: 本文简单说明在RESTEasy的日常开发工作当中，经常用到的测试手段。
---

## {{ page.title }}

首先把`legacy-integration-tests`这些无关的测试在`pom.xml`里面给去掉：

```bash
$ pwd
/Users/weli/projs/resteasy-upstream/testsuite
```

下面是`pom.xml`里面的modules设置：

```xml
<modules>
	<module>arquillian-utils</module>
	<!-- <module>unit-tests</module> -->
	<!-- <module>legacy-integration-tests</module> -->
	<module>integration-tests</module>
	<!-- <module>integration-tests-spring</module> -->
</modules>
```

可以看到，仅保留`integration-tests`。

接下来就是只运行我需要的测试，比如我想运行`ParamConverterTest`，就执行下面的指令：

```bash
$ pwd
/Users/weli/projs/resteasy-upstream/testsuite
```

```bash
$ mvn -q test -Dtest=ParamConverterTest*
```

以下是执行结果：

```bash
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running org.jboss.resteasy.test.resource.param.ParamConverterTest
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 1.032 s - in org.jboss.resteasy.test.resource.param.ParamConverterTest
[INFO]
[INFO] Results:
[INFO]
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0
```

以上是常用的测试手段。