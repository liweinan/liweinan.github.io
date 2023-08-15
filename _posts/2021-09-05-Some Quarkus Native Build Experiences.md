---
title: Some Quarkus Native Build Experiences
--- 

I played with the Quarkus native build recently and there are some things needs to be noted.

Firstly you need to have a `GraalVM`[^graalvm] release of Java to be installed. I use `SDKMAN`[^sdkman] to manage my Java releases, so I can get a list of Java releases with the `sdk` command:

```bash
$ sdk list java
```

Here is the output of the command:

![](https://raw.githubusercontent.com/liweinan/blogpic2021i/master/sep05/1963A290-7759-43D7-AFCA-844D4B704772.png)

From above output we can see there are several versions of `GraalVM`, and I installed the newest version with the command:

```bash
$ sdk install java 21.2.0.r16-grl
```

Because I have already installed the release, so it will output like this:

![](https://raw.githubusercontent.com/liweinan/blogpic2021i/master/sep05/07AC6D33-F4C8-451A-AF19-F413C60B8C1E.png)

If you haven’t installed the version in your environment, it will start the install process, and ask you if you want to switch to the installed Java release by default. Just selecting `y` and your environment will start to use this version of Java.

GraalVM provides the ability to compile Java code into the native binary code, which boosts the performance of the Java program. Before doing the native build, we need to use the `gu` command provided by the GraalVM release and install the `native-image` tool with the command:

```bash
$ gu install native-image
```

And here is the output on my computer:

![](https://raw.githubusercontent.com/liweinan/blogpic2021i/master/sep05/40B247E3-8454-45A5-B8A6-7C613F4535B1.png)

Because I have installed the `native-image` tool, so the output is like above. If you don’t have `native-image` tool installed, the above command will start the installation process.

After the environment is prepared, now we can compile our Quarkus project into native binary. Here is the command to do the native build:

```bash
$ mvn package -Pnative -DskipTests
```

The native build process is much slower than Java build process, and the build process is very CPU and memory intensive:

![](https://raw.githubusercontent.com/liweinan/blogpic2021i/master/sep05/9EE9E440-2DD4-479C-9C98-5485072A2DA8.png)

And here is the output of the build process:

![](https://raw.githubusercontent.com/liweinan/blogpic2021i/master/sep05/7904F823-D383-4F1C-A40E-D6A417A6AC49.png)

As you can see the native build process contains a lot of steps to transform the Java code into native binary executable. Finally we get a single executable file that contains the whole project:

![](https://raw.githubusercontent.com/liweinan/blogpic2021i/master/sep05/5ECDD546-0830-46BE-B521-B9DF870087FA.png)

We can run this executable file directly to start the project:

![](https://raw.githubusercontent.com/liweinan/blogpic2021i/master/sep05/276FDACF-2967-4E6A-8FA1-3B45F685C26A.png)

As the screenshot shown above, the whole project is a single executable file, and the project startup process is blazing fast. The memory footprint is also much smaller than the Java compiled byte code.

Nevertheless, there are some points that need to be noted to use the native build. The first thing need to be noted is that, for native build, it will automatically use your `prod` profile in your `application.properties`:

![](https://raw.githubusercontent.com/liweinan/blogpic2021i/master/sep05/6FB186B8-5C89-4DA6-B0AE-FB214D510A5F.png)

As the screenshot shown above, the `%prod` config properties will be picked during native build process. This can be seen during your binary executable file startup process:

![](https://raw.githubusercontent.com/liweinan/blogpic2021i/master/sep05/155B581C-1B08-438E-B9D8-B1FD4B5DD2E3.png)

In addition, the major difference between Java compilation and binary compilation is that, after compiling the Java code into binary code, we lose all the runtime information exists in bytecode format, which means, we can’t use the reflections during runtime in binary code, so all the code that rely on runtime reflection may not work properly after compiling into binary code.

For example, if you use Jackson[^jackson] to serialize a Java class into JSON like this:

![](https://raw.githubusercontent.com/liweinan/blogpic2021i/master/sep05/A2A9ED9C-1D40-4C2F-8699-A009786903B4.png)

![](https://raw.githubusercontent.com/liweinan/blogpic2021i/master/sep05/D66FBAF5-CC03-40B8-B442-4821E31CBE7B.png)

This will work for Java build, but after building it into native binary, and start the executable, you will get error like this:

![](https://raw.githubusercontent.com/liweinan/blogpic2021i/master/sep05/53610210-AF3C-40C2-92CB-DC19E26CADB0.png)

The error message tells us that Jackson can not serialize our class anymore, and we need to annotate our class with `@RegisterForReflection`. So we should follow the instruction and annotation our class:

![](https://raw.githubusercontent.com/liweinan/blogpic2021i/master/sep05/6B0C85D0-1DFC-415E-8B12-865BEB117A08.png)

And then Jackson can serialize our class properly after the code is compiled to binary. The other thing need to be noted is that, currently if you are using Hibernate in your project like this:

![](https://raw.githubusercontent.com/liweinan/blogpic2021i/master/sep05/3B92B7AC-B211-4B7E-BFCD-E100FB37C980.png)

And if you are willing to use the `schema-update` policy provided by Hibernate in your `application.properties`:

![](https://raw.githubusercontent.com/liweinan/blogpic2021i/master/sep05/6E0E75C2-615D-4C58-AB42-AB6D83D610B8.png)

You will find it doesn’t work during executable start process:

![](https://raw.githubusercontent.com/liweinan/blogpic2021i/master/sep05/89AE7B13-FF52-4C89-ACC2-4301F132DA91.png)

This is because currently the `update` policy has problem for `hibernate-panache-reactive`(And not only exists in binary build I guess), and here are some relative links to the issue:

* [Getting exception “Not using JDBC” while using quarkus-hibernate-reactive-panache with quarkus-reactive-mysql-client - (Quarkus 1.12.2.Final) - Stack Overflow](https://stackoverflow.com/questions/66897821/getting-exception-not-using-jdbc-while-using-quarkus-hibernate-reactive-panach)
* [Reactive Postgres Client and Flyway/Postgres does not work together · Issue #2751 · quarkusio/quarkus · GitHub](https://github.com/quarkusio/quarkus/issues/2751)

So we may need to wait Quarkus/Hibernate team to fix this soon.

完毕.

## References

[^graalvm]: [GraalVM](https://www.graalvm.org/)
[^sdkman]: [Home - SDKMAN! the Software Development Kit Manager](https://sdkman.io/)
[^jackson]: [GitHub - FasterXML/Jackson: Main Portal page for the Jackson project](https://github.com/FasterXML/jackson)
