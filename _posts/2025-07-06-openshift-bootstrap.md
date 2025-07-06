---
title: OpenShift Disconnected Cluster安装步骤与实践
---

本文总结OpenShift断连集群（disconnected cluster，无法直接访问公网的集群）在AWS上的安装步骤，适合有OpenShift或Kubernetes基础的读者。

1. **配置VPC以支持断连集群**  
   public和private subnet通过NAT Gateway隔离，确保安全性。手工创建IAM用户以分配最小权限（学习总结：https://github.com/liweinan/deepseek-answers/blob/main/files/oc-disconnected-cluster.md#iam-configuration）。

2. **创建VPC endpoints以访问AWS服务**  
   VPC需创建endpoints（如S3、EC2 API）以确保bootstrap节点在private subnet中访问AWS服务，使用CloudFormation模板自动化配置（模板示例：https://github.com/liweinan/ocp-aws-vpc-ipi-examples/...）。

3. **配置bootstrap节点访问mirror registry**  
   bootstrap节点需通过VPC路由表访问bastion主机的mirror registry，添加指向registry的路由规则（样例：https://github.com/liweinan/ocp-aws-vpc-ipi-examples/pull/1/files#diff-24a44acdcecfb902f56d79c8bcf9580e288b96ee0c092d2508e114200d74c7d3R10）。

4. **生成安装配置文件与点火文件**  
   OpenShift安装从config文件生成manifests文件，再转换为Ignition点火文件，用于节点初始化。
    1. **`openshift-install`定制安装**  
       通过`MachineConfig`定义节点配置，生成`bootstrap.ign`等文件（`openshift-install create ignition-configs`，关键行167-170：https://github.com/liweinan/ocp-aws-vpc-ipi-examples/pull/1/files#diff-cfb8d6ddbeb137bdd82a3f15ec3b5d3e5470f6bfd7446d774aafb103c34c70efR167）。
    2. **点火文件与脚本**  
       点火文件包含节点初始化脚本，解码bootstrap脚本以便调试（核心功能：配置镜像仓库）：https://github.com/liweinan/ocp-aws-vpc-ipi-examples/pull/1/files#diff-eca50a42b09cea58a45168d832418b81d5365465ba99512bd82e927d6085f754。
    3. **学习`bootkube.sh`**  
       `bootkube.sh`启动Kubernetes控制平面，初始化etcd和API Server（关键步骤：https://github.com/liweinan/deepseek-answers/blob/main/files/oc-bootstrap.md#bootkube）。

![](https://raw.githubusercontent.com/liweinan/blogpics2025/main/0706/01.jpg)

![](https://raw.githubusercontent.com/liweinan/blogpics2025/main/0706/02.png)