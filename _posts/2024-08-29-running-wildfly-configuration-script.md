---
title: Using the CLI script to configure the WildFly during provision phase.
---

Here is an example showing how to use the `.cli` script to run WildFly CLI commands to configure the WildFly server during the provision phase:

- [jberet-tck-runner / add CLI script to configure batch subsystem to use JDBC job repo automatically](https://github.com/jberet/jberet-tck-runner/commit/c9ac7899fd244bacd1dd51089105daf83fcd8663)

It uses the `embed-server` command to run the commands. Here is the blog post introducing the `embed-server` mode:

- [Running an Embedded WildFly Host Controller in the CLI](https://www.wildfly.org/news/2017/10/10/Embedded-Host-Controller/)
