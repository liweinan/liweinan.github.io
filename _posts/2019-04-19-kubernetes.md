---
title: kubernetes的services
abstract: kubernetes的services是高于pods的一层抽象层面。
---

## {{ page.title }}

kubernetes的service是一个抽象层面，可以使用多个pods，形成一个负载平衡的cluster：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/apr19/05fig01_alt.jpg)

可以看到`service`是在`pod`之上的抽象层面。`service`会按照`label`来选择同一组label下的pods，达到负载平衡的效果：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/apr19/05fig02_alt.jpg)

## 常用的命令

查看services：

```bash
$ kubectl get svc
```

查看pods的labels：

```bash
$ kubectl get po --show-labels
```

## 实际操作

kubernetes提供了一个在线的交互式的学习环境：

* [Interactive Tutorial - Exposing Your App - Kubernetes](https://kubernetes.io/docs/tutorials/kubernetes-basics/expose/expose-interactive/)

点击`START SCENARIO`：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/apr19/F32FF1A0-F2BA-43BB-A85D-4EB5DED88CC8.png)

此时会进入到一个在线的，安装好了kubernetes的虚拟容器环境里：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/apr19/11985E58-E555-4BA5-9546-D1D8A20E11BA.png)

此时按照文档给出的命令，一步一步进行操作，就可以进行学习了。比如expose一个service的命令：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/apr19/4E404A50-4468-4EED-AD2F-7DA38B997091.png)

创建完成后，查看创建的service：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/apr19/007A25A2-899E-4EB0-9E5E-81C472C7576B.png)

以及查看service对应label的pods：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/apr19/BE000CB5-ADD8-4005-BF1A-16F83631FDA7.png)

按照这个交互教程操作一遍即可进行学习。

## 参考资料

* [https://medium.com/mayadata/kubernetes-label-selector-and-field-selector-81d6967bb2f](https://medium.com/mayadata/kubernetes-label-selector-and-field-selector-81d6967bb2f) 
* [https://kubernetes.io/docs/tutorials/kubernetes-basics/expose/expose-intro/](https://kubernetes.io/docs/tutorials/kubernetes-basics/expose/expose-intro/) 

∎

