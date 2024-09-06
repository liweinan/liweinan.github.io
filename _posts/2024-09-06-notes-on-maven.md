---
title: Some Notes about Maven Lifecycle, Phase and Goal
---

If you have read these articles you may have an understanding of the Maven Lifecycle:

- [Maven – Introduction to the Build Lifecycle](https://maven.apache.org/guides/introduction/introduction-to-the-lifecycle.html)
- [Maven Goals and Phases](https://www.baeldung.com/maven-goals-phases)

Generally speaking, each lifecycle consists of a sequence of phases, and each phase is a sequence of goals. The concept is not difficult, but there are confusions while using the Maven.

The first confusion is that the goal name and the phase name are sometimes same. For example, in the [Maven Failsafe Plugin](https://maven.apache.org/surefire/maven-failsafe-plugin/) it has these goals:

```bash
➤ mvn failsafe:help | grep -v INFO
  Maven Failsafe MOJO in maven-failsafe-plugin.

This plugin has 3 goals:

failsafe:help
  Display help information on maven-failsafe-plugin.
  Call mvn failsafe:help -Ddetail=true -Dgoal=<goal-name> to display parameter
  details.

failsafe:integration-test
  Run integration tests using Surefire.

failsafe:verify
  Verify integration tests ran using Surefire.
```

The above are the goals defined in the plugin. And `verify` and `integration-test` are also phase names of Maven.

I checked the source code of `maven-failsafe-plugin` and here is the source code related to the phase binding:

- [https://github.com/apache/maven-surefire/blob/master/maven-failsafe-plugin/src/main/java/org/apache/maven/plugin/failsafe/VerifyMojo.java#L52](https://github.com/apache/maven-surefire/blob/master/maven-failsafe-plugin/src/main/java/org/apache/maven/plugin/failsafe/VerifyMojo.java#L52)

```java
@Mojo(name = "verify", defaultPhase = LifecyclePhase.VERIFY, requiresProject = true, threadSafe = true)
public class VerifyMojo extends AbstractMojo implements SurefireReportParameters {
...
```

So the goal is bound to `LifecyclePhase.VERIFY`. Here is the class diagram of the `maven-failsafe-plugin`:

![](https://raw.githubusercontent.com/liweinan/blogpics2024/main/0907/failsafe-mojo.jpg)

So this configuration can be removed:

```xml
<executions>
    <execution>
        <goals>
            <goal>integration-test</goal>
            <goal>verify</goal>
        </goals>
    </execution>
</executions>
```

And the `mvn verify` still works with the failsafe plugin:

- [https://github.com/jberet/jberet-examples/pull/1](https://github.com/jberet/jberet-examples/pull/1)
- [https://github.com/jberet/jberet-examples/actions/runs/10742863181/job/29796369058?pr=1#step:4:51346](https://github.com/jberet/jberet-examples/actions/runs/10742863181/job/29796369058?pr=1#step:4:51346)

The other confusion is that from the failsafe plugin doc: 

- [https://maven.apache.org/surefire/maven-failsafe-plugin/](https://maven.apache.org/surefire/maven-failsafe-plugin/)

There is a note about the usage:

> NOTE: when running integration tests, you should invoke Maven with the (shorter to type too)
>
> mvn verify
> rather than trying to invoke the integration-test phase directly, as otherwise the post-integration-test phase will not be executed.

The above text doesn’t explain why the `verify` phase will execute the `post-integration-test`, I have checked the above source code of `VerifyMojo.java` and it doesn’t have anything related to running the `post-integration-test` test phase.

So I guess this execution is defined by Maven itself. I need to check Maven's source code to confirm this.

