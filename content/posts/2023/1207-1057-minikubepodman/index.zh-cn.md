---
title: "K8S系列之Minikube结合Podman实践"
date: 2023-12-07T10:57:19+08:00
author: "郭冬"
description: "Minikube是一种轻量级的Kubernetes实现，可在本地计算机上创建虚拟机并部署仅包含一个节点的简单集群。Podman是一个开源的容器运行时工具，它提供与Docker相似的功能，但不需要守护进程，并且支持更多的安全特性和rootless模式运行。"
categories: ["技能矩阵"]
tags: ["Kubernetes","Podman"]
resources:
- name: "featured-image"
  src: "featured-image.jpeg"

toc: true
lightgallery: true
---

Minikube是一种轻量级的Kubernetes实现，可在本地计算机上创建虚拟机并部署仅包含一个节点的简单集群。  
Podman是一个开源的容器运行时工具，它提供与Docker相似的功能，但不需要守护进程，并且支持更多的安全特性和rootless模式运行。

<!--more-->

## 基础环境

```yaml
OS: macOS
Architecture: ARM64
Driver: Podman

CPUs: 2
Memory: 2Gi
Disk: 20GiB

Installer: Homebrew
```

## 安装使用Podman

```plain
➜ brew install podman
==> Installing dependencies for podman: capstone, dtc, pcre2, gettext, glib, gmp, libtasn1, nettle, p11-kit, openssl@3, libnghttp2, unbound, gnutls, jpeg-turbo, libpng, libslirp, libssh, libusb, lzo, pixman, snappy, vde and qemu
==> podman
```

```plain
➜ podman machine init --cpus 2 --memory 2048 --disk-size 20 --rootful
Downloading VM image: fedora-coreos-39.20231204.2.1-qemu.aarch64.qcow2.xz: done
Extracting compressed file: podman-machine-default_fedora-coreos-39.20231204.2.1-qemu.aarch64.qcow2: done
Image resized.
Machine init complete
```

```plain
➜ podman machine start
Starting machine "podman-machine-default"
Waiting for VM ...
Mounting volume... /Users:/Users
Mounting volume... /private:/private
Mounting volume... /var/folders:/var/folders
API forwarding listening on: /Users/damonguo/.local/share/containers/podman/machine/qemu/podman.sock

The system helper service is not installed; the default Docker API socket address can't be used by podman.
If you would like to install it, run the following commands:
  sudo /opt/homebrew/Cellar/podman/4.8.1/bin/podman-mac-helper install
  podman machine stop; podman machine start

  You can still connect Docker API clients by setting DOCKER_HOST using the following command in your terminal session:
  export DOCKER_HOST='unix:///Users/damonguo/.local/share/containers/podman/machine/qemu/podman.sock'

Machine "podman-machine-default" started successfully
```

```plain
➜ podman machine list
NAME                    VM TYPE     CREATED        LAST UP            CPUS        MEMORY      DISK SIZE
podman-machine-default  qemu        8 minutes ago  Currently running  2           2GiB        20GiB
```

## 安装使用Minikube

```plain
➜ brew install minikube
==> Installing dependencies for minikube: kubernetes-cli
==> minikube
```

```plain
➜ minikube config set driver podman
These changes will take effect upon a minikube delete and then a minikube start
```

```plain
➜ minikube start --driver=podman --kubernetes-version=v1.28.3
minikube v1.32.0 on Darwin 14.1.2 (arm64)
Using the podman (experimental) driver based on user configuration

Using Podman driver with root privileges
Starting control plane node minikube in cluster minikube
Pulling base image ...
Downloading Kubernetes v1.28.3 preload ...
preloaded-images-k8s-v18-v1...:  341.16 MiB / 341.16 MiB  100.00% 13.99 M
gcr.io/k8s-minikube/kicbase...:  410.58 MiB / 410.58 MiB  100.00% 13.22 M

Creating podman container (CPUs=2, Memory=1887MB) ...
Preparing Kubernetes v1.28.3 on Docker 24.0.7 ...
Generating certificates and keys ...
Booting up control plane ...
Configuring RBAC rules ...
Configuring bridge CNI (Container Networking Interface) ...

Verifying Kubernetes components...
Using image gcr.io/k8s-minikube/storage-provisioner:v5

Enabled addons: storage-provisioner, default-storageclass
Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
```

```plain
➜ minikube status
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

```plain
➜ kubectl get namespaces
NAME              STATUS   AGE
default           Active   4m40s
kube-node-lease   Active   4m40s
kube-public       Active   4m40s
kube-system       Active   4m40s

➜ kubectl get nodes
NAME       STATUS   ROLES           AGE     VERSION
minikube   Ready    control-plane   4m44s   v1.28.3

➜ kubectl get svc
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   16m
```
## 部署测试Nginx Service

```yaml
➜ vim nginx-deploy-svc.yaml 
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
  type: NodePort
```

```plain
➜ kubectl apply -f nginx-deploy-svc.yaml 
deployment.apps/nginx-deploy created
service/nginx-svc created
```

```plain
➜ kubectl get all
NAME                                READY   STATUS    RESTARTS   AGE
pod/nginx-deploy-7c5ddbdf54-4d8c2   1/1     Running   0          67s
pod/nginx-deploy-7c5ddbdf54-cmcg2   1/1     Running   0          67s

NAME                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
service/kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP        24m
service/nginx-svc    NodePort    10.103.72.229   <none>        80:31985/TCP   67s

NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx-deploy   2/2     2            2           67s

NAME                                      DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-deploy-7c5ddbdf54   2         2         2       67s
```

```plain
➜ minikube service nginx-svc --url
http://127.0.0.1:51726
Because you are using a Docker driver on darwin, the terminal needs to be open to run it.
```

{{< image src="minikube_nginx_svc_web.jpg" alt="minikube_nginx_svc_web" width=800 >}}

## 清理Minikube和Podman

```plain
➜ minikube stop
Stopping node "minikube"  ...
Powering off "minikube" via SSH ...
1 node stopped.
```

```plain
➜ minikube status
minikube
type: Control Plane
host: Stopped
kubelet: Stopped
apiserver: Stopped
kubeconfig: Stopped
```

```plain
➜ minikube delete
Deleting "minikube" in podman ...
Deleting container "minikube" ...
Removing /Users/damonguo/.minikube/machines/minikube ...
Removed all traces of the "minikube" cluster.
```

```plain
➜ podman machine list
NAME                    VM TYPE     CREATED         LAST UP            CPUS        MEMORY      DISK SIZE
podman-machine-default  qemu        54 minutes ago  Currently running  2           2GiB        20GiB
```

```plain
➜ podman machine stop podman-machine-default
Waiting for VM to exit...
Machine "podman-machine-default" stopped successfully
```

```plain
➜ podman machine rm podman-machine-default
The following files will be deleted:

/Users/damonguo/.ssh/podman-machine-default
/Users/damonguo/.ssh/podman-machine-default.pub
/Users/damonguo/.config/containers/podman/machine/qemu/podman-machine-default.ign
/Users/damonguo/.local/share/containers/podman/machine/qemu/podman-machine-default_fedora-coreos-39.20231204.2.1-qemu.aarch64.qcow2
/Users/damonguo/.local/share/containers/podman/machine/qemu/podman.sock
/Users/damonguo/.local/share/containers/podman/machine/qemu/podman-machine-default_ovmf_vars.fd
/Users/damonguo/.config/containers/podman/machine/qemu/podman-machine-default.json

Are you sure you want to continue? [y/N] y
```

```plain
➜ minikube delete --purge --all
Successfully deleted all profiles
Successfully purged minikube directory located at - [/Users/damonguo/.minikube]

➜ brew uninstall minikube
```
