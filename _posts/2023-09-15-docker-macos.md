---
title: Setup the Docker sock file on MacOS
---

With the recent release of Docker my local docker build process can't access to the sock file anymore:

```bash
[ERROR] Failed to execute goal org.eclipse.jkube:kubernetes-maven-plugin:1.14.0:build (default-cli) on project random-generator: Execution default-cli of goal org.eclipse.jkube:kubernetes-maven-plugin:1.14.0:build failed: No <dockerHost> given, no DOCKER_HOST environment variable, no read/writable '/var/run/docker.sock' or '//./pipe/docker_engine' and no external provider like Docker machine configured -> [Help 1]
```

It seems the `/var/run/docker.sock` is no longer available. After some searching I found this topic on StackOverflow describes the Docker sock file change: 

- [Docker socket is not found while using Intellij IDEA and Docker desktop on MacOS](https://stackoverflow.com/a/74175227/1212922)

According to the instruction in above link, this command shows the Docker sock file config:

```bash
➤ docker context ls
NAME                TYPE                DESCRIPTION                               DOCKER ENDPOINT                              KUBERNETES ENDPOINT   ORCHESTRATOR
default             moby                Current DOCKER_HOST based configuration   unix:///var/run/docker.sock
desktop-linux *     moby                Docker Desktop                            unix:///Users/weli/.docker/run/docker.sock
```

From the above we can see the actual docker sock file is in user's `.docker` directory. This command links the sock file to the default location:

```bash
➤ sudo ln -s /Users/weli/.docker/run/docker.sock /var/run/docker.sock
```

After the above setup, the docker service can be accessed.

Update 2023-09-17:

In addition, these settings can be set:

![](https://raw.githubusercontent.com/liweinan/blogpics2023/main/0917/image.png)


