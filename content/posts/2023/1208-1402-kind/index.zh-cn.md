---
title: "K8S系列之KinD实践"
date: 2023-12-08T14:02:36+08:00
author: "郭冬"
description: "KinD是一个工具，用于在Docker中运行本地Kubernetes集群。"
categories: ["技能矩阵"]
tags: ["Kubernetes"]
resources:
- name: "featured-image"
  src: "featured-image.jpeg"

lightgallery: true
---

KinD是一个工具，用于在Docker中运行本地Kubernetes集群。

<!--more-->

## 基础环境

```yaml
OS: macOS
Architecture: ARM64
Driver: Docker

Installer: Homebrew
```

## 安装使用KinD

```plain
➜ brew install kind
==> Installing kind 
==> Pouring kind--0.20.0.arm64_sonoma.bottle.tar.gz
==> kind
```

```plain
➜ kind version
kind v0.20.0 go1.21.1 darwin/arm64
```

创建一个名为mycluster的K8S集群，并将hostPort的30080端口暴露到localhost的30080端口。

```yaml
➜ vim config-with-port-mapping.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30080
    hostPort: 30080
```

```plain
➜ kind create cluster --name mycluster --config=config-with-port-mapping.yaml
Creating cluster "mycluster" ...
 ✓ Ensuring node image (kindest/node:v1.27.3)
 ✓ Preparing nodes
 ✓ Writing configuration
 ✓ Starting control-plane
 ✓ Installing CNI
 ✓ Installing StorageClass
Set kubectl context to "kind-mycluster"

You can now use your cluster with:
kubectl cluster-info --context kind-mycluster

Thanks for using kind!
```

```plain
➜ kubectl cluster-info --context kind-mycluster
Kubernetes control plane is running at https://127.0.0.1:64070
CoreDNS is running at https://127.0.0.1:64070/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

```plain
➜ kind get clusters
mycluster
```

```plain
➜ kubectl get nodes
NAME                      STATUS   ROLES           AGE   VERSION
mycluster-control-plane   Ready    control-plane   85s   v1.27.3

➜ kubectl get pods -n kube-system
NAME                                              READY   STATUS    RESTARTS   AGE
coredns-5d78c9869d-6zdpz                          1/1     Running   0          81s
coredns-5d78c9869d-twr96                          1/1     Running   0          81s
etcd-mycluster-control-plane                      1/1     Running   0          94s
kindnet-x9zrb                                     1/1     Running   0          81s
kube-apiserver-mycluster-control-plane            1/1     Running   0          96s
kube-controller-manager-mycluster-control-plane   1/1     Running   0          94s
kube-proxy-5zzch                                  1/1     Running   0          81s
kube-scheduler-mycluster-control-plane            1/1     Running   0          94s

➜ kubectl get namespaces
NAME                 STATUS   AGE
default              Active   108s
kube-node-lease      Active   108s
kube-public          Active   108s
kube-system          Active   108s
local-path-storage   Active   104s
```

## 部署测试Nginx Service

```plain
➜ kubectl get all
NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   119s
```

```yaml
➜ vim nginx-deploy-svc-portmapping.yaml 
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deploy
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-svc
spec:
  selector:
    app: nginx
  ports:
    - name: http
      port: 80
      nodePort: 30080
  type: NodePort
```

```plain
➜ kubectl apply -f nginx-deploy-svc-portmapping.yaml
deployment.apps/nginx-deploy created
service/nginx-svc created
```

```plain
➜ kubectl get all
NAME                               READY   STATUS    RESTARTS   AGE
pod/nginx-deploy-55f598f8d-f2c2q   1/1     Running   0          35s
pod/nginx-deploy-55f598f8d-ljxd8   1/1     Running   0          35s

NAME                 TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
service/kubernetes   ClusterIP   10.96.0.1      <none>        443/TCP        5m5s
service/nginx-svc    NodePort    10.96.221.64   <none>        80:30080/TCP   35s

NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx-deploy   2/2     2            2           35s

NAME                                     DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-deploy-55f598f8d   2         2         2       35s
```

访问Nginx: http://localhost:30080

{{< image src="kind_nginx_svc_web.jpg" alt="kind_nginx_svc_web" width=800 >}}

## 清理KinD

```plain
➜ kind delete cluster --name mycluster
Deleting cluster "mycluster" ...
Deleted nodes: ["mycluster-control-plane"]

➜ kind get clusters
No kind clusters found.
```
