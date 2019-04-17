---
title: 使用kubernetes创建一个双containers的pod
abstract: 同一个pod里面的containers共享网络端口，ip地址等资源。
---

## {{ page.title }}

本文介绍如何使用kubernetes创建一个双containers的pod。首先确保docker的kubernetes已经加载：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/apr18/192C4A38-1826-4B99-98DE-BE97A20C8C24.png)

如上图所示，docker自带一个kubernetes的单节点群集，把它启动就好。启动后可以看到kubernetes开始工作：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/apr18/A01AEF98-0531-41FD-BB45-F88C8B7BD9DE.png)

创建一个文件`two.yaml`，内容如下：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: two-containers
spec:

  restartPolicy: Never

  volumes:
  - name: shared-data
    emptyDir: {}

  containers:

  - name: nginx-container
    image: nginx
    volumeMounts:
    - name: shared-data
      mountPath: /usr/share/nginx/html

  - name: debian-container
    image: debian
    volumeMounts:
    - name: shared-data
      mountPath: /pod-data
    command: ["/bin/sh"]
    args: ["-c", "echo Hello from the debian container > /pod-data/index.html"]
```

注意上面的pod里面有两个containers。第一个container叫做`nginx`，第二个叫做`debian`。并且两个containers共享一个存储位置，叫做`shared-data`，但是在各自container里面挂装到不同的位置。此外，在`debian`这个container里面，会往`shared-data`里面加入`index.html`，内容是`Hello from the debian container`。通过上面的yaml文件创建所需pod：

```bash
$ kubectl apply -f two.yaml
pod "two-containers" created
```

进入pod的其中一个container：

```bash
$ kubectl exec -it two-containers -c nginx-container -- /bin/bash
root@two-containers:/#
```

在这个`nginx`的container里面安装`curl`和`ps`命令：

```bash
$ apt-get update
$ apt-get install curl procps
```

安装完成如下：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/apr18/4368D9EE-5058-4D7C-B28E-6F7A7A0CF985.png)

使用`ps`命令查看`nginx`进程：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/apr18/BEE53876-08E4-4218-B488-05E258DCE028.png)

使用`curl`命令访问本地`nginx`服务：

```bash
$ curl localhost
```

可以看到相关输出：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/apr18/DB5D5AD9-1FA8-4E86-85D4-9511E3F2C235.png)

上面的`Hello from the debian container`来自`debian`这个container对`shared-data`里面`index.html`的数据操作。

参考文档：

- [Communicate Between Containers in the Same Pod Using a Shared Volume - Kubernetes](https://kubernetes.io/docs/tasks/access-application-cluster/communicate-containers-same-pod-shared-volume/)

∎
