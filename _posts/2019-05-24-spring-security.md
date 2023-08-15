---
title: spring-security的authentication模型
abstract: 粗略过一遍spring-security的认证鉴权模型
---



`spring-security`的核心是`AuthenticationProvider`：

* [spring-security/AuthenticationProvider.java at master · spring-projects/spring-security · GitHub](https://github.com/spring-projects/spring-security/blob/master/core/src/main/java/org/springframework/security/authentication/AuthenticationProvider.java)

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/may24/Class Diagram2.png)

这个接口的核心就是`authenticate()`方法，它接受一个`Authentication`类型的参数：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/may24/Class Diagram3.png)

这个`Authentication`类型的两个核心参数就是`Principal`和`Credentials`。此外，`Authentication`还接受更细致的权限划分，提供一个`getAuthorities()`方法，去接受一系列的`GrantedAuthority`类型的参数：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/may24/Class Diagram31.png)

上面是`spring-security`的一个基础的架子。后续核心要看的重点是`DaoAuthenticationProvider`：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/may24/Class Diagram34.png)	

上面这个`DaoAuthenticationProvider`是基于数据库的。

spring-security的认证核心是`userDetailService`（[Spring Security: Database-backed UserDetailsService](https://www.baeldung.com/spring-security-authentication-with-a-database)）。认证用的用户表很基础：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/may24/2D16EA20-873C-4715-8270-3ECC611F1E88.png)

就是「用户名」和「密码」。`JdbcDaoImpl`是跟数据库打交道的class：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/may24/Class Diagram3 2.png)

`spring-security`里面定义了用户表，和围绕着用户表的方法，不需要自己实现了。并且这个用户模型可以容纳所有的「认证」与「鉴权」的需求。从最简单的「用户名」+「密码」，到最复杂的「ACL」列表，全部都定义好了，根据自己的需求来使用就可以了。

多说一句spring的「鉴权」（Authorization）模型：`Authorization`和`Authentication`是分开的，`Authentication`只管「认证」。下面是一个`spring-security`实现的`vote based`鉴权模型（[11. Authorization](https://docs.spring.io/spring-security/site/docs/current/reference/html/authorization.html)）：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/may24/access-decision-voting.png)

基于acl的鉴权模型（[An Introduction to Spring Security ACL](https://www.baeldung.com/spring-security-acl)）位于`spring-security-acl`子项目里：

```bash
$ pwd
/Users/weli/works/spring-security/acl
```

它的项目里包含了数据库的建库`sql`脚本：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/may24/FFC95E6D-6778-4AD8-9797-ECA0C4901C2A.png)

我们倒入`sql`，创建库表：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/may24/28742AEA-3733-475A-B07A-3863D8A9021D.png)

我们用`vp uml`反向工程这个数据库，得到er图：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/may24/Entity Relationship Diagram3.png)

上面这个模型可以实现最细颗粒度的鉴权。



