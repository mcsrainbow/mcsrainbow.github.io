---
title: "Kubernetes Series: Using K3D"
date: 2023-12-08T19:07:42+08:00
author: "Dong Guo | Damon"
description: "K3D is a lightweight wrapper to run K3S in docker."
categories: ["Skills"]
tags: ["Kubernetes"]
resources:
- name: "featured-image"
  src: "featured-image.jpeg"

lightgallery: true
---

K3D is a lightweight wrapper to run K3S in docker.

<!--more-->

## Basic

```yaml
OS: macOS
Architecture: ARM64
Driver: Docker

Installer: Homebrew
```

## Setup K3D

```plain
➜ brew reinstall k3d
==> Installing k3d 
==> Pouring k3d--5.6.0.arm64_sonoma.bottle.tar.gz
==> k3d
```

```plain
➜ k3d version
k3d version v5.6.0
k3s version v1.27.5-k3s1 (default)
```

Create a cluster 'mycluster', mapping the ingress port 80 to localhost:8081.

```plain
➜ k3d cluster create mycluster -p "8081:80@loadbalancer" --agents 1
INFO[0000] portmapping '8081:80' targets the loadbalancer: defaulting to [servers:*:proxy agents:*:proxy] 
INFO[0000] Prep: Network                                
INFO[0000] Created network 'k3d-mycluster'              
INFO[0000] Created image volume k3d-mycluster-images    
INFO[0000] Starting new tools node...                   
INFO[0000] Starting Node 'k3d-mycluster-tools'          
INFO[0001] Creating node 'k3d-mycluster-server-0'       
INFO[0001] Creating node 'k3d-mycluster-agent-0'        
INFO[0001] Creating LoadBalancer 'k3d-mycluster-serverlb' 
INFO[0001] Using the k3d-tools node to gather environment information 
INFO[0001] HostIP: using network gateway 192.168.167.1 address 
INFO[0001] Starting cluster 'mycluster'                 
INFO[0001] Starting servers...                          
INFO[0001] Starting Node 'k3d-mycluster-server-0'       
INFO[0004] Starting agents...                           
INFO[0004] Starting Node 'k3d-mycluster-agent-0'        
INFO[0007] Starting helpers...                          
INFO[0007] Starting Node 'k3d-mycluster-serverlb'       
INFO[0013] Injecting records for hostAliases (incl. host.k3d.internal) and for 3 network members into CoreDNS configmap... 
INFO[0015] Cluster 'mycluster' created successfully!    
INFO[0015] You can now use it like this:                
kubectl cluster-info
```

```plain
➜ kubectl cluster-info
Kubernetes control plane is running at https://0.0.0.0:56685
CoreDNS is running at https://0.0.0.0:56685/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://0.0.0.0:56685/api/v1/namespaces/kube-system/services/https:metrics-server:https/proxy
```

## Deploy Nginx Service

```plain
➜ kubectl get all
NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.43.0.1    <none>        443/TCP   48s
```

```yaml
➜ vim nginx-deploy-svc-ingress.yaml 
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
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
  annotations:
    ingress.kubernetes.io/ssl-redirect: "false"
spec:
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: nginx-svc
                port:
                  number: 80
```

```plain
➜ kubectl apply -f nginx-deploy-svc-ingress.yaml 
deployment.apps/nginx-deploy created
service/nginx-svc created
ingress.networking.k8s.io/nginx-ingress created
```

```plain
➜ kubectl get all
NAME                               READY   STATUS    RESTARTS   AGE
pod/nginx-deploy-55f598f8d-z9n5v   1/1     Running   0          2m
pod/nginx-deploy-55f598f8d-h5zkb   1/1     Running   0          2m

NAME                 TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
service/kubernetes   ClusterIP   10.43.0.1      <none>        443/TCP        3m12s
service/nginx-svc    NodePort    10.43.58.173   <none>        80:32459/TCP   2m

NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx-deploy   2/2     2            2           2m

NAME                                     DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-deploy-55f598f8d   2         2         2       2m
```

```plain
➜ kubectl get ingress
NAME            CLASS    HOSTS   ADDRESS                       PORTS   AGE
nginx-ingress   <none>   *       192.168.167.2,192.168.167.3   80      2m56s
```

Access Nginx via Ingress: http://localhost:8081

{{< image src="k3d_nginx_ingress_web.jpg" alt="k3d_nginx_ingress_web" width=800 >}}

## Cleanup K3D

```plain
➜ k3d cluster list
NAME        SERVERS   AGENTS   LOADBALANCER
mycluster   1/1       1/1      true

➜ k3d cluster delete mycluster
INFO[0000] Deleting cluster 'mycluster'                 
INFO[0000] Deleting cluster network 'k3d-mycluster'     
INFO[0000] Deleting 1 attached volumes...               
INFO[0000] Removing cluster details from default kubeconfig... 
INFO[0000] Removing standalone kubeconfig file (if there is one)... 
INFO[0000] Successfully deleted cluster mycluster!      

➜ k3d cluster list
NAME   SERVERS   AGENTS   LOADBALANCER
```
