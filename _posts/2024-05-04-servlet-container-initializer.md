---
title: A ServletContainerInitializer Example
---

I have created an example showing the usage of `ServletContainerInitializer`[^doc] here:

- [https://github.com/liweinan/servlet-example/pull/1/files](https://github.com/liweinan/servlet-example/pull/1/files)

Here is the real usage of the interface in RESTEasy:

- [https://github.com/resteasy/resteasy/blob/main/resteasy-servlet-initializer/src/main/java/org/jboss/resteasy/plugins/servlet/ResteasyServletInitializer.java](https://github.com/resteasy/resteasy/blob/main/resteasy-servlet-initializer/src/main/java/org/jboss/resteasy/plugins/servlet/ResteasyServletInitializer.java)

Here is the class diagram of the Servlet APIs:

![](https://raw.githubusercontent.com/liweinan/blogpics2024/main/0507/servlet-api.jpg)

The interfaces defined in the above Servlet APIs in implemented by the container such as Apache Tomcat. The [previous blog post](https://weinan.io/2024/04/15/servlet-example.html) has some notes showing the implementations in Apache Tomcat. 

[^doc]: [ServletContainerInitializer \(Java EE 6 \)](https://docs.oracle.com/javaee%2F6%2Fapi%2F%2F/javax/servlet/ServletContainerInitializer.html)

