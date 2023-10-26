---
title: JBeret TCK Testing Process
---

I have recorded the process to do the TCK test for JBeret here:

- [https://github.com/jberet/jsr352/pull/381#issuecomment-1764776583](https://github.com/jberet/jsr352/pull/381#issuecomment-1764776583)

Currently, it's a manual process. In the future I plan to automate the testing process. 

Here is some additional info:

To download the TCK zip, here is the command:

```bash
➤ wget https://download.eclipse.org/jakartaee/batch/2.1/jakarta.batch.official.tck-2.1.1.zip                                                                 02:18:59
--2023-10-16 02:19:00--  https://download.eclipse.org/jakartaee/batch/2.1/jakarta.batch.official.tck-2.1.1.zip
正在解析主机 download.eclipse.org (download.eclipse.org)... 198.41.30.199
正在连接 download.eclipse.org (download.eclipse.org)|198.41.30.199|:443... 已连接。
已发出 HTTP 请求，正在等待回应... 200 OK
长度：2668103 (2.5M) [application/zip]
正在保存至: “jakarta.batch.official.tck-2.1.1.zip”

jakarta.batch.official.tck-2.1.1.zip      100%[===================================================================================>]   2.54M  59.2KB/s  用时 2m 17s

2023-10-16 02:21:19 (19.0 KB/s) - 已保存 “jakarta.batch.official.tck-2.1.1.zip” [2668103/2668103])
```

Prepare the projects for testing:

```bash
➤ cd jberet_tck                                                                                                                                               02:37:50
weli@192:~/w/jberet_tck
➤ ls                                                                                                                                                          02:37:53
jakarta.batch.official.tck-2.1.1	jakarta.batch.official.tck-2.1.1.zip	jberet-tck-porting			wildfly
weli@192:~/w/jberet_tck
➤
```

To do EE testing, it needs WildFly.

The `jberet-tck-porting`[^porting] project contains POMs that use JBeret as dependency that can be copied to `jakarta.batch.official.tck-2.1.1`[^tck] project for testings.

In addition, it contains the JAR file that needs to be copied into WildFly for EE testings.

The detail of test process it recorded in the comment of the above PR link. 

## References

[^porting]: [https://github.com/jberet/jberet-tck-porting](https://github.com/jberet/jberet-tck-porting)
[^tck]: [https://github.com/eclipse-ee4j/batch-tck](https://github.com/eclipse-ee4j/batch-tck)