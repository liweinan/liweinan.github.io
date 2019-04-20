---
title: kubernetes的service操作实验
abstract: 使用kubernetes的在线交互教程做创建services的实验。
---

## {{ page.title }}

Kubernetes官方提供一个交互式的实验环境：

* [Interactive Tutorial - Exposing Your App - Kubernetes](https://kubernetes.io/docs/tutorials/kubernetes-basics/expose/expose-interactive/)

打开上面的网站，进入到在线的实验平台：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/apr20/6172A874-B0C2-4925-91FD-BFCD373B8488.png)

如上所示，实际操作`kubectl`，创建service，并查看ip地址：

```bash
$ kubectl get services/kubernetes-bootcamp
NAME                  TYPE       CLUSTER-IP    EXTERNAL-IP   PORT(S)          AGE
kubernetes-bootcamp   NodePort   10.97.9.161   <none>        8080:32580/TCP   10m
```

从上面可以看到`cluster-ip`，和`8080 <-> 32580`的端口映射。下面查看service获得的endpoints：

```bash
$ kubectl describe services/kubernetes-bootcamp
...
Endpoints:                172.18.0.2:8080
```

endpoints就是kubernetes管理的ip地址和端口资源。下面查看node的ip地址：

```bash
$ minikube ip
172.17.0.6
```

pod的ip地址：

```bash
$ kubectl get pods
NAME                                   READY   STATUS    RESTARTS   AGE
kubernetes-bootcamp-6bf84cb898-vpn6f   1/1     Running   0          3m53s
```

查看pod的label：

```bash
$ kubectl describe pods/kubernetes-bootcamp-6bf84cb898-vpn6f
...
Node:               minikube/172.17.0.6
...
Labels:             pod-template-hash=6bf84cb898
                    run=kubernetes-bootcamp
...
IP:                 172.18.0.2
```

service会利用pod的label进行请求的分发和负载平衡，把请求分发到对应label的pods去(具体的网络转发是由`kube-proxy`控制的)。综上所述，架构图如下：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/apr20/Deployment Diagram1.png)

`kube-proxy`，`service`，`pod`的架构关系如下：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/apr20/EA9BE39A-64B5-4BC7-BE05-CFF32AE21176.png)

上面的图片来自于`Kubernetes Cookbook`这本书。下面是书中对`kube-proxy`的说明：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/apr20/5207E2A6-EA5E-4FEF-BA5B-E7DD4DAC6570.png)

以上是对services的进一步学习的记录。

∎

