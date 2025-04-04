---
title: "Kubernetes 容器健康检查和优雅终止"
slug: "kubernetes-container-healthcheck-and-graceful-termination"
date: 2024-07-03T17:27:44+08:00
author: "郭冬"
description: "在 Kubernetes 中启用容器健康检查和优雅终止，并结合应用自身特点进行配置，可以提升生产环境的应用稳定性，减少上线事故和误报。"
categories: ["技能矩阵"]
tags: ["Kubernetes"]
resources:
- name: "featured-image"
  src: "featured-image.jpeg"

toc: true
lightgallery: true
---

在 Kubernetes 中启用容器健康检查和优雅终止，并结合应用自身特点进行配置，可以提升生产环境的应用稳定性，减少上线事故和误报。

<!--more-->

---

## 参数

相关配置项解释如下:

1. **`terminationGracePeriodSeconds`:** 全局配置项，Pod 终止的宽限期，必须大于 lifecycle.preStop，如果 Pod 中的容器在达到宽限期时仍未关闭，Pod 将被强制终止
2. **`lifecycle.preStop`:** 在容器停止之前执行命令的钩子，可用于延迟容器停止时间，为仍未完成的请求提供更多的时间释放连接
3. **`startupProbe`:** 检查容器的启动状态，可用于为容器内的应用启动提供更多的准备时间
4. **`livenessProbe`:** 检查容器是否存活，如果检查失败，kubelet 会杀死容器，然后重启容器
5. **`readinessProbe`:** 检查容器是否已经准备好接受流量，只有通过检查，kubelet 才会将 Pod 加入 Service 的负载均衡池

{{< image src="k8s_pod_lifecycle.jpg" alt="k8s_pod_lifecycle" width=800 >}}

## 实践配置

启用 `容器健康检查` 和 `优雅终止` 的 Kubernetes Deployment 实践配置示例:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: default
  name: myapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      # 默认值: 30
      terminationGracePeriodSeconds: 120
      imagePullSecrets:
        - name: mysecret
      containers:
        - name: myapp
          image: registry.example.com/myapp:1.0
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 8080
          startupProbe:
            tcpSocket:
              port: 8080
            # 默认值: 0
            initialDelaySeconds: 30
            # 默认值: 10
            periodSeconds: 30
            # 默认值: 3
            failureThreshold: 10
            # 默认值: 1 且设计目的和工作原理决定了只能设置为: 1
            successThreshold: 1
            # 默认值: 1
            timeoutSeconds: 2
          livenessProbe:
            tcpSocket:
              port: 8080
            # 默认值: 0
            initialDelaySeconds: 30
            # 默认值: 10
            periodSeconds: 30
            # 默认值: 3
            failureThreshold: 3
            # 默认值: 1 且设计目的和工作原理决定了只能设置为: 1
            successThreshold: 1
            # 默认值: 1
            timeoutSeconds: 2
          readinessProbe:
            tcpSocket:
              port: 8080
            # 默认值: 0
            initialDelaySeconds: 30
            # 默认值: 10
            periodSeconds: 30
            # 默认值: 3
            failureThreshold: 3
            # 默认值: 1
            successThreshold: 2
            # 默认值: 1
            timeoutSeconds: 2
          lifecycle:
            preStop:
              exec:
                command: ["/bin/sh", "-c", "sleep 60"]
          env:
            - name: TZ
              value: Asia/Shanghai
          resources:
            requests:
              cpu: 500m
              memory: 1Gi
            limits:
              cpu: 500m
              memory: 1Gi
```

## 实践配置详解

Kubernetes 默认配置:

1. **启动检查:** `无`
2. **容器上线:** 最短 `0` 秒
3. **容器状态:**  
   异常判定 `23`-`33` 秒 `failureThreshold(3) * timeoutSeconds(1) + ( failureThreshold(3) - 1 ) * periodSeconds(10)`  
   恢复判定 `0`-`10` 秒 `periodSeconds(10)`
4. **容器关闭:** 最短 `0` 秒，最长 `30` 秒 `terminationGracePeriodSeconds(30)`

实践配置:

1. **启动检查:**  
   最短 `30` 秒 `initialDelaySeconds(30)`  
   最长 `320` 秒 `initialDelaySeconds(30) + failureThreshold(10) * timeoutSeconds(2) + ( failureThreshold(10) - 1 ) * periodSeconds(30)`  
   注意: 设计目的和工作原理决定了 `startupProbe.successThreshold` 只能设置为 `1`
2. **容器上线:**  
   最短 `90` 秒 `启动检查(最短30秒)` + `initialDelaySeconds(30) + periodSeconds(30) * ( readinessProbe.successThreshold(2) - 1 )`  
   注意: 设计目的和工作原理决定了 `livenessProbe.successThreshold` 只能设置为 `1`
3. **容器状态:**  
   异常判定 `66`-`96` 秒 `failureThreshold(3) * timeoutSeconds(2) + ( failureThreshold(3) - 1 ) * periodSeconds(30)`  
   恢复判定 `30`-`60` 秒 `periodSeconds(30) * ( successThreshold(2) - 1 )`
4. **容器关闭:**  
   最短 `60` 秒 `sleep 60`  
   最长 `120` 秒 `terminationGracePeriodSeconds(120)`

## 实践总结

与 Kubernetes 默认配置相比，以上实践配置进行了如下优化:

1. 增加启动检查，结合应用自身特点，为容器内的应用启动提供 30-320 秒的准备时间
2. 容器上线时间延长 90 秒，在生产上线过程中可作为适当的缓冲时间
3. 容器状态的异常判定延长 66-96 秒，恢复判定延长 30-60 秒，可确保判定结果更加准确，避免不稳定的新容器被误判为可以正常提供服务而替换了旧的正常容器
4. 容器关闭时间延长 60 秒，可确保仍未完成的请求有更多的时间释放连接，避免用户尚未完成的请求被异常中断

## 进一步优化

1. 对于 Web 类应用，通过应用代码判断自身业务状态，生成 `/healthz` 健康检查页面
2. 将基于 `tcpSocket` 的健康检查升级为基于 `httpGet`，通过获取健康检查页面的返回结果进行精准判断

## 优化后的配置

启用 `/healthz` 健康检查页面的 Kubernetes Deployment 实践配置示例:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      # 默认值: 30
      terminationGracePeriodSeconds: 120
      imagePullSecrets:
        - name: mysecret
      containers:
        - name: myapp
          image: myapp:1.0
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 8080
          startupProbe:
            tcpSocket:
              port: 8080
            # 默认值: 0
            initialDelaySeconds: 30
            # 默认值: 10
            periodSeconds: 30
            # 默认值: 3
            failureThreshold: 10
            # 默认值: 1 且设计目的和工作原理决定了只能设置为: 1
            successThreshold: 1
            # 默认值: 1
            timeoutSeconds: 2
          livenessProbe:
            httpGet:
              path: /healthz
              port: 8080
            # 默认值: 0
            initialDelaySeconds: 30
            # 默认值: 10
            periodSeconds: 30
            # 默认值: 3
            failureThreshold: 3
            # 默认值: 1 且设计目的和工作原理决定了只能设置为: 1
            successThreshold: 1
            # 默认值: 1
            timeoutSeconds: 2
          readinessProbe:
            httpGet:
              path: /healthz
              port: 8080
            # 默认值: 0
            initialDelaySeconds: 30
            # 默认值: 10
            periodSeconds: 30
            # 默认值: 3
            failureThreshold: 3
            # 默认值: 1
            successThreshold: 2
            # 默认值: 1
            timeoutSeconds: 2
          lifecycle:
            preStop:
              exec:
                command: ["/bin/sh", "-c", "sleep 60"]
          env:
            - name: TZ
              value: Asia/Shanghai
          resources:
            requests:
              cpu: 500m
              memory: 1Gi
            limits:
              cpu: 500m
              memory: 1Gi
```

## 参考

https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
