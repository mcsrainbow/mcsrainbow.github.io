---
title: "Kubernetes Container Healthcheck and Graceful Termination"
slug: "kubernetes-container-healthcheck-and-graceful-termination"
date: 2024-07-03T17:27:44+08:00
author: "Damon"
description: "Implementing container health checks and graceful termination in Kubernetes with application-specific configurations enhances production stability, reduces deployment incidents and false alarms."
categories: ["Skills"]
tags: ["Kubernetes"]
resources:
- name: "featured-image"
  src: "featured-image.jpeg"

toc: true
lightgallery: true
---

Implementing container health checks and graceful termination in Kubernetes with application-specific configurations enhances production stability, reduces deployment incidents and false alarms.

<!--more-->

---

## Parameters

1. **`terminationGracePeriodSeconds`:** Global setting for Pod termination grace period; must greater than lifecycle.preStop. If containers aren't terminated within this period, the Pod will be forcibly terminated.  
2. **`lifecycle.preStop`:** Hook to execute commands before container stops, delaying termination to release connections for pending requests.  
3. **`startupProbe`:** Checks container startup status, providing additional preparation time.  
4. **`livenessProbe`:** Checks if the container is alive; kubelet kills and restarts the container if the check fails.  
5. **`readinessProbe`:** Checks if the container is ready to accept traffic; kubelet adds the Pod to the Service's load balancer pool only if this check passes.  

{{< image src="k8s_pod_lifecycle.jpg" alt="k8s_pod_lifecycle" width=800 >}}


## Practice

Kubernetes deployment configurations with health checks and graceful termination:

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
      # default: 30
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
            # default: 0
            initialDelaySeconds: 30
            # default: 10
            periodSeconds: 30
            # default: 3
            failureThreshold: 10
            # default: 1 and must be 1 by design
            successThreshold: 1
            # default: 1
            timeoutSeconds: 2
          livenessProbe:
            tcpSocket:
              port: 8080
            # default: 0
            initialDelaySeconds: 30
            # default: 10
            periodSeconds: 30
            # default: 3
            failureThreshold: 3
            # default: 1 and must be 1 by design
            successThreshold: 1
            # default: 1
            timeoutSeconds: 2
          readinessProbe:
            tcpSocket:
              port: 8080
            # default: 0
            initialDelaySeconds: 30
            # default: 10
            periodSeconds: 30
            # default: 3
            failureThreshold: 3
            # default: 1
            successThreshold: 2
            # default: 1
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

## Explanation

Default Kubernetes configurations:

1. **Startup Check:** `None`
2. **Container Readiness:** Minimum `0` seconds
3. **Container State:**  
   Failure determination `23`-`33` seconds `failureThreshold(3) * timeoutSeconds(1) + ( failureThreshold(3) - 1 ) * periodSeconds(10)`  
   Recovery determination `0` - `10` seconds `periodSeconds(10)`
4. **Container Termination:** Minimum `0` seconds, Maximum `30` seconds `terminationGracePeriodSeconds(30)`

Practice configurations:

1. **Startup Check:**  
   Minimum `30` seconds `initialDelaySeconds(30)`  
   Maximum `320` seconds `initialDelaySeconds(30) + failureThreshold(10) * timeoutSeconds(2) + ( failureThreshold(10) - 1 ) * periodSeconds(30)`  
   Note: The design purpose and working principle determine that `startupProbe.successThreshold` can only be set to `1`
2. **Container Readiness:**  
   Minimum `90` seconds `Startup Check(30)` + `initialDelaySeconds(30) + periodSeconds(30) * ( readinessProbe.successThreshold(2) - 1 )`  
   Note: The design purpose and working principle determine that `livenessProbe.successThreshold` can only be set to `1`
3. **Container State:**  
   Failure determination `66`-`96` seconds `failureThreshold(3) * timeoutSeconds(2) + ( failureThreshold(3) - 1 ) * periodSeconds(30)`  
   Recovery determination `30`-`60` seconds `periodSeconds(30) * ( successThreshold(2) - 1 )`
4. **Container Termination:**   
   Minimum `60` seconds `sleep 60`  
   Maximum `120` seconds `terminationGracePeriodSeconds(120)`

## Summary

Optimizations compared to default Kubernetes configurations:

1. **Startup Check:** Add 30-320 seconds for application startup.
2. **Container Readiness:** Add a 90 seconds buffer during deployment.
3. **Container State:** Add 66-96 seconds for failure determination and 30-60 seconds for recovery, improve accuracy.
4. **Container Termination:** Add 60 seconds to ensure connections are properly released.

## Optimization

Further optimization:

1. Create a `/healthz` endpoint for accurate health checks.
2. Upgrade from `tcpSocket` to `httpGet` health checks for precise assessments.

## Optimized Practice

Kubernetes deployment configurations enables the `/healthz` endpoint:

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
      # default: 30
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
            # default: 0
            initialDelaySeconds: 30
            # default: 10
            periodSeconds: 30
            # default: 3
            failureThreshold: 10
            # default: 1 and must be 1 by design
            successThreshold: 1
            # default: 1
            timeoutSeconds: 2
          livenessProbe:
            httpGet:
              path: /healthz
              port: 8080
            # default: 0
            initialDelaySeconds: 30
            # default: 10
            periodSeconds: 30
            # default: 3
            failureThreshold: 3
            # default: 1 and must be 1 by design
            successThreshold: 1
            # default: 1
            timeoutSeconds: 2
          readinessProbe:
            httpGet:
              path: /healthz
              port: 8080
            # default: 0
            initialDelaySeconds: 30
            # default: 10
            periodSeconds: 30
            # default: 3
            failureThreshold: 3
            # default: 1
            successThreshold: 2
            # default: 1
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

## Reference

https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
