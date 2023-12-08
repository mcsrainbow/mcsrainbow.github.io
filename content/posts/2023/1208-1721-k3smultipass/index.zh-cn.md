---
title: "K8S系列之K3S结合Multipass实践"
date: 2023-12-08T17:21:19+08:00
author: "郭冬"
description: "K3S是一个轻量级、易于安装的Kubernetes发行版。Multipass是一个用于快速创建、管理和操作Ubuntu虚拟机的工具。"
categories: ["技能矩阵"]
tags: ["Kubernetes","Multipass"]
resources:
- name: "featured-image"
  src: "featured-image.jpeg"

lightgallery: true
---

K3S是一个轻量级、易于安装的Kubernetes发行版。  
Multipass是一个用于快速创建、管理和操作Ubuntu虚拟机的工具。

<!--more-->

## 基础环境

```yaml
OS: macOS
Architecture: ARM64
Virtualization: Multipass

CPUs: 1
Memory: 1Gi
Disk: 10GiB

Installer: Homebrew
```

## 安装使用Multipass

```plain
➜ brew install --cask multipass
==> Downloading https://github.com/canonical/multipass/releases/download/v1.12.2/multipass-1.12.2+mac-Darwin.pkg
==> Installing Cask multipass
installer: Package name is multipass
installer: Installing at base path /
installer: The install was successful.
multipass was successfully installed!
```

```plain
➜ multipass launch --name k3s --cpus 1 --memory 1G --disk 10G
Launched: k3s
```

```plain
➜ multipass info k3s
Name:           k3s
State:          Running
IPv4:           192.168.64.2
Release:        Ubuntu 22.04.3 LTS
Image hash:     9256911742f0 (Ubuntu 22.04 LTS)
CPU(s):         1
Load:           0.56 0.15 0.05
Disk usage:     1.4GiB out of 9.6GiB
Memory usage:   140.0MiB out of 962.3MiB
Mounts:         --
```

## 安装使用K3S

```plain
➜ multipass shell k3s
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-89-generic aarch64)
ubuntu@k3s:~$ curl -sfL https://get.k3s.io | sh -
[INFO]  Finding release for channel stable
[INFO]  Using v1.27.7+k3s2 as release
[INFO]  Downloading hash https://github.com/k3s-io/k3s/releases/download/v1.27.7+k3s2/sha256sum-arm64.txt
[INFO]  Downloading binary https://github.com/k3s-io/k3s/releases/download/v1.27.7+k3s2/k3s-arm64
[INFO]  Verifying binary download
[INFO]  Installing k3s to /usr/local/bin/k3s
[INFO]  Skipping installation of SELinux RPM
[INFO]  Creating /usr/local/bin/kubectl symlink to k3s
[INFO]  Creating /usr/local/bin/crictl symlink to k3s
[INFO]  Creating /usr/local/bin/ctr symlink to k3s
[INFO]  Creating killall script /usr/local/bin/k3s-killall.sh
[INFO]  Creating uninstall script /usr/local/bin/k3s-uninstall.sh
[INFO]  env: Creating environment file /etc/systemd/system/k3s.service.env
[INFO]  systemd: Creating service file /etc/systemd/system/k3s.service
[INFO]  systemd: Enabling k3s unit
Created symlink /etc/systemd/system/multi-user.target.wants/k3s.service → /etc/systemd/system/k3s.service.
[INFO]  systemd: Starting k3s

ubuntu@k3s:~$ sudo k3s kubectl get nodes
NAME   STATUS   ROLES                  AGE   VERSION
k3s    Ready    control-plane,master   19s   v1.27.7+k3s2

ubuntu@k3s:~$ sudo ss -lntpu | grep k3s-server
tcp   LISTEN 0      4096                          127.0.0.1:10248      0.0.0.0:*    users:(("k3s-server",pid=2786,fd=172))   
tcp   LISTEN 0      4096                          127.0.0.1:10249      0.0.0.0:*    users:(("k3s-server",pid=2786,fd=208))   
tcp   LISTEN 0      4096                          127.0.0.1:6444       0.0.0.0:*    users:(("k3s-server",pid=2786,fd=15))    
tcp   LISTEN 0      4096                          127.0.0.1:10256      0.0.0.0:*    users:(("k3s-server",pid=2786,fd=206))   
tcp   LISTEN 0      4096                          127.0.0.1:10257      0.0.0.0:*    users:(("k3s-server",pid=2786,fd=86))    
tcp   LISTEN 0      4096                          127.0.0.1:10258      0.0.0.0:*    users:(("k3s-server",pid=2786,fd=202))   
tcp   LISTEN 0      4096                          127.0.0.1:10259      0.0.0.0:*    users:(("k3s-server",pid=2786,fd=209))   
tcp   LISTEN 0      4096                                  *:10250            *:*    users:(("k3s-server",pid=2786,fd=168))   
tcp   LISTEN 0      4096                                  *:6443             *:*    users:(("k3s-server",pid=2786,fd=13)) 

ubuntu@k3s:~$ sudo cat /var/lib/rancher/k3s/server/node-token
K10fa8d62310e361852c7607ba12b9667cd05f52122df80ca928448200295bb0969::server:c421b343a4f042a2a3511156664a76b1

ubuntu@k3s:~$ exit
logout
```

```plain
➜ multipass launch --name k3s-worker --cpus 1 --memory 1G --disk 10G
Launched: k3s-worker
```

```plain
➜ multipass list
Name                    State             IPv4             Image
k3s                     Running           192.168.64.2     Ubuntu 22.04 LTS
                                          10.42.0.0
                                          10.42.0.1
k3s-worker              Running           192.168.64.3     Ubuntu 22.04 LTS
```

```plain
➜ multipass shell k3s-worker
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-89-generic aarch64)
ubuntu@k3s-worker:~$ curl -sfL https://get.k3s.io | K3S_URL=https://192.168.64.2:6443 K3S_TOKEN="K10fa8d62310e361852c7607ba12b9667cd05f52122df80ca928448200295bb0969::server:c421b343a4f042a2a3511156664a76b1" sh -
[INFO]  Finding release for channel stable
[INFO]  Using v1.27.7+k3s2 as release
[INFO]  Downloading hash https://github.com/k3s-io/k3s/releases/download/v1.27.7+k3s2/sha256sum-arm64.txt
[INFO]  Downloading binary https://github.com/k3s-io/k3s/releases/download/v1.27.7+k3s2/k3s-arm64
[INFO]  Verifying binary download
[INFO]  Installing k3s to /usr/local/bin/k3s
[INFO]  Skipping installation of SELinux RPM
[INFO]  Creating /usr/local/bin/kubectl symlink to k3s
[INFO]  Creating /usr/local/bin/crictl symlink to k3s
[INFO]  Creating /usr/local/bin/ctr symlink to k3s
[INFO]  Creating killall script /usr/local/bin/k3s-killall.sh
[INFO]  Creating uninstall script /usr/local/bin/k3s-agent-uninstall.sh
[INFO]  env: Creating environment file /etc/systemd/system/k3s-agent.service.env
[INFO]  systemd: Creating service file /etc/systemd/system/k3s-agent.service
[INFO]  systemd: Enabling k3s-agent unit
Created symlink /etc/systemd/system/multi-user.target.wants/k3s-agent.service → /etc/systemd/system/k3s-agent.service.
[INFO]  systemd: Starting k3s-agent

ubuntu@k3s-worker:~$ exit
logout
```

## 部署测试Nginx Service

```plain
➜ multipass shell k3s
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-89-generic aarch64)
ubuntu@k3s:~$ sudo k3s kubectl get nodes
NAME         STATUS   ROLES                  AGE     VERSION
k3s          Ready    control-plane,master   9m26s   v1.27.7+k3s2
k3s-worker   Ready    <none>                 71s     v1.27.7+k3s2
```

```yaml
ubuntu@k3s:~$ vim nginx-deploy-svc.yaml 
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
ubuntu@k3s:~$ sudo k3s kubectl apply -f nginx-deploy-svc.yaml 
deployment.apps/nginx-deploy created
service/nginx-svc created
```

```plain
ubuntu@k3s:~$ sudo k3s kubectl get all
NAME                               READY   STATUS    RESTARTS   AGE
pod/nginx-deploy-55f598f8d-pzr6n   1/1     Running   0          20m
pod/nginx-deploy-55f598f8d-z55ng   1/1     Running   0          20m

NAME                 TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)        AGE
service/kubernetes   ClusterIP   10.43.0.1     <none>        443/TCP        68m
service/nginx-svc    NodePort    10.43.202.7   <none>        80:32711/TCP   20m

NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx-deploy   2/2     2            2           20m

NAME                                     DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-deploy-55f598f8d   2         2         2       20m

ubuntu@k3s:~$ exit
logout 
```

```plain
➜ multipass list
Name                    State             IPv4             Image
k3s                     Running           192.168.64.2     Ubuntu 22.04 LTS
                                          10.42.0.0
                                          10.42.0.1
k3s-worker              Running           192.168.64.3     Ubuntu 22.04 LTS
                                          10.42.1.0
                                          10.42.1.1
```

{{< image src="k3s_nginx_svc_web.jpg" alt="k3s_nginx_svc_web" width=800 >}}

## 清理Multipass和K3S

```plain
➜ multipass delete k3s k3s-worker

➜ multipass list
Name                    State             IPv4             Image
k3s                     Deleted           --               Not Available
k3s-worker              Deleted           --               Not Available

➜ multipass purge

➜ multipass list
No instances found.
```

```plain
➜ brew uninstall --cask multipass
==> Uninstalling Cask multipass
==> Removing launchctl service com.canonical.multipassd
==> Uninstalling packages:
com.canonical.multipass.multipassd
com.canonical.multipass.multipass
com.canonical.multipass.multipass_gui
==> Removing files:
/opt/homebrew/etc/bash_completion.d/multipass
/Applications/Multipass.app
/Library/Application Support/com.canonical.multipass
/Library/Logs/Multipass
/usr/local/bin/multipass
/usr/local/etc/bash_completion.d/multipass
==> Purging files for version 1.12.2 of Cask multipass
```
