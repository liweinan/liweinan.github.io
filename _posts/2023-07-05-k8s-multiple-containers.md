---
title: Creating a Pod that has multiple containers
---

In this article I will create a Kubernetes pod that contains two containers. First writing a manifest file like this[^pod]:

```yaml
kind: Pod
apiVersion: v1
metadata:
  name: mc
spec:
  containers:
    - name: c0
      image: alpine/socat
      command: [ "/bin/sh", "-c", "/usr/bin/socat tcp-l:1234,fork exec:'echo c0'" ]
    - name: c1
      image: alpine/socat
      command: [ "/bin/sh", "-c", "/usr/bin/socat tcp-l:1235,fork exec:'echo c1'" ]
```

The above manifest file describes a pod named `mc`, and it contains two containers called `c0` and `c1`. The container uses the image `alpine/socat`, which is convenient to start a TCP server. In the above pod, there are two containers, and each container will run a tcp server that output `c0` and `c1` specifically, and one service listens to the port `1234` and the other listens to `1235`. To create the above pod, run the following command:

```bash
➤ kubectl apply -f mc.yml
pod/mc created
```

If everything goes fine, after a while the pod should be created and run. Using the following command to check the status of the pod:

```bash
➤ kubectl get po | grep mc
mc                                  2/2     Running   0          4m9s
```

From the above output, we can see the `mc` pod is running and there are `2/2` containers running. And we can see the details of the containers with the following command:

```bash
➤ kubectl describe po mc | grep -A34 'Containers:'                                                                                     23:23:42
Containers:
  c0:
    Container ID:  docker://8e754fd7ab1807881d314af6cb186d16c210bb7900e99405ecc7a1bc6f322be1
    Image:         alpine/socat
    Image ID:      docker-pullable://alpine/socat@sha256:0f359f1a2fabf445765eb5762ff565d1c1f7c360a5fa5e788848e68eb193c349
    Port:          <none>
    Host Port:     <none>
    Command:
      /bin/sh
      -c
      /usr/bin/socat tcp-l:1234,fork exec:'echo c0'
    State:          Running
      Started:      Wed, 05 Jul 2023 23:08:03 +0800
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-kthb6 (ro)
  c1:
    Container ID:  docker://bf65ca4ef733b07781114e1556f942969308a946bc73ab5bce8e9fa55e2958bd
    Image:         alpine/socat
    Image ID:      docker-pullable://alpine/socat@sha256:0f359f1a2fabf445765eb5762ff565d1c1f7c360a5fa5e788848e68eb193c349
    Port:          <none>
    Host Port:     <none>
    Command:
      /bin/sh
      -c
      /usr/bin/socat tcp-l:1235,fork exec:'echo c1'
    State:          Running
      Started:      Wed, 05 Jul 2023 23:08:09 +0800
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-kthb6 (ro)
```

From the above output, we can see there are two containers `c0` and `c1`. We can login to `c0` with the following command[^cmd]:

```bash
➤ kubectl exec -i -t mc --container c0 -- /bin/sh
/ #
```

Now we are entering the terminal of `c0`, then we need to add the `telnet` command to access the services provide by the containers. We can use the `apk` tool provided by the container(which is Alpine Linux based) to install the `telnet` command. First update the Alpine Linux repo with the following command:

```bash
/ # apk update
fetch https://dl-cdn.alpinelinux.org/alpine/v3.18/main/x86_64/APKINDEX.tar.gz
481BDE4E0F7F0000:error:0A000126:SSL routines:ssl3_read_n:unexpected eof while reading:ssl/record/rec_layer_s3.c:303:
WARNING: updating https://dl-cdn.alpinelinux.org/alpine/v3.18/main: Permission denied
fetch https://dl-cdn.alpinelinux.org/alpine/v3.18/community/x86_64/APKINDEX.tar.gz
v3.18.2-273-g8291981acc0 [https://dl-cdn.alpinelinux.org/alpine/v3.18/main]
v3.18.2-274-ga199b869491 [https://dl-cdn.alpinelinux.org/alpine/v3.18/community]
0 unavailable, 1 stale; 20062 distinct packages available
/ #
```

And then install the `busybox-extras` which contains the `telnet` command:

```bash
/ # apk add busybox-extras
(1/1) Installing busybox-extras (1.36.1-r0)
Executing busybox-extras-1.36.1-r0.post-install
Executing busybox-1.36.1-r0.trigger
OK: 9 MiB in 20 packages
/ #
```

Until now we have installed the `telnet` command in container `c0`, and we can access the service provided by the `c0` container like this:

```bash
/ # telnet localhost 1234
Connected to localhost
c0
Connection closed by foreign host
```

From the above output we can see the `c0` string is output by the service created by the `socat` command defined in the pod manifest. In addition, because the two containers share the same network[^network], so we can directly access the service provided by `c1` in `c0` like this:

```bash
/ # telnet localhost 1235
Connected to localhost
c1
Connection closed by foreign host
/ #
```

Until now, we have seen how to create and access the containers inside a pod.

## References

[^pod]: [mc.yml](https://github.com/liweinan/play-k8s/blob/main/mc.yml)
[^cmd]: [Get a Shell to a Running Container](https://kubernetes.io/docs/tasks/debug/debug-application/get-shell-running-container/)
[^network]: [Understanding kubernetes networking: pods](https://medium.com/google-cloud/understanding-kubernetes-networking-pods-7117dd28727)

