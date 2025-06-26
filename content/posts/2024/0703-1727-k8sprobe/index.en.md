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

1. **`terminationGracePeriodSeconds`:** Global setting for Pod termination grace period, must greater than `lifecycle.preStop`. If containers aren't stopped within this period, the Pod will be forcibly terminated.  
2. **`lifecycle.preStop`:** Hook to execute commands before container stops, delaying termination to release connections for in-flight requests.  
3. **`startupProbe`:** Checks the container startup status, providing additional preparation time. kubelet kills and restarts the container if the check fails.  
4. **`livenessProbe`:** Checks if the container is alive. kubelet kills and restarts the container if the check fails.  
5. **`readinessProbe`:** Checks if the container is ready to accept traffic. kubelet adds the Pod to the Service's load balancer pool only if this check passes.  

{{< image src="k8s_pod_lifecycle.jpg" alt="k8s_pod_lifecycle" width=800 >}}


## Practice

### Manifests

Kubernetes deployment configurations with health checks and graceful termination:

```yaml
---
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
            initialDelaySeconds: 10
            # default: 10
            # fixed interval, does not wait for the previous probe to complete
            periodSeconds: 10
            # default: 3
            failureThreshold: 30
            # default: 1 
            # cannot be changed, must be 1 by design
            successThreshold: 1
            # default: 1
            timeoutSeconds: 2
          livenessProbe:
            tcpSocket:
              port: 8080
            # default: 0
            initialDelaySeconds: 10
            # default: 10
            # fixed interval, does not wait for the previous probe to complete
            periodSeconds: 30
            # default: 3
            failureThreshold: 5
            # default: 1
            # cannot be changed, must be 1 by design
            successThreshold: 1
            # default: 1
            timeoutSeconds: 5
          readinessProbe:
            tcpSocket:
              port: 8080
            # default: 0
            initialDelaySeconds: 5
            # default: 10
            # fixed interval, does not wait for the previous probe to complete
            periodSeconds: 20
            # default: 3
            failureThreshold: 3
            # default: 1
            # set to 2 to avoid mistaking unstable new containers as ready
            successThreshold: 2
            # default: 1
            timeoutSeconds: 2
          lifecycle:
            # delay container stop by 60 seconds
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

### Explanation

Default Kubernetes configurations:

1. **Startup Check:**  
   `None`  
2. **Liveness:**  
   Minimum: `0` seconds  
   Failure determination: `21` seconds `( failureThreshold(3) - 1 ) * periodSeconds(10) + timeoutSeconds(1)`  
3. **Readiness:**  
   Minimum: `0` seconds  
   Failure determination: `21` seconds `( failureThreshold(3) - 1 ) * periodSeconds(10) + timeoutSeconds(1)`  
   Recovery determination: `10` seconds `periodSeconds(10)`  
4. **Termination:**  
   Minimum: `0` seconds  
   Maximum: `30` seconds `terminationGracePeriodSeconds(30)`  

Practice configurations:

1. **Startup:**  
   Minimum: `10` seconds `initialDelaySeconds(10)`  
   Failure determination: `302` seconds `initialDelaySeconds(10) + ( failureThreshold(30) - 1 ) * periodSeconds(10) + timeoutSeconds(2)`  
   Note: The working principle determines that `startupProbe.successThreshold` can only be set to `1`  
2. **Liveness:**  
   Minimum: `20` seconds `Startup(10)` + `initialDelaySeconds(10)`  
   Failure determination (first): `135` seconds `initialDelaySeconds(10) + ( failureThreshold(5) - 1 ) * periodSeconds(30) + timeoutSeconds(5)`  
   Failure determination (running): `125` seconds `( failureThreshold(5) - 1 ) * periodSeconds(30) + timeoutSeconds(5)`  
   Note: The working principle determines that `livenessProbe.successThreshold` can only be set to `1`  
3. **Readiness:**  
   Minimum: `35` seconds `Startup(10)` + `initialDelaySeconds(5) + ( readinessProbe.successThreshold(2) - 1 ) * periodSeconds(20)`  
   Failure determination (first): `47` seconds `initialDelaySeconds(5) + ( failureThreshold(3) - 1 ) * periodSeconds(20) + timeoutSeconds(2)`  
   Failure determination (running): `42` seconds `( failureThreshold(3) - 1 ) * periodSeconds(20) + timeoutSeconds(2)`  
   Recovery determination: `40` seconds `successThreshold(2) * periodSeconds(20)`  
4. **Termination:**  
   Minimum `60` seconds `sleep 60`  
   Maximum `120` seconds `terminationGracePeriodSeconds(120)`  

### Summary

Optimizations compared to default Kubernetes configurations:

1. **Startup:** `10` seconds delay, failure threshold `302` seconds, failed checks trigger container restart.  
2. **Liveness:** `20` seconds delay, failure threshold `125` seconds, failed checks trigger container restart.  
3. **Readiness:** `35` seconds delay, `2` times health checks to avoid mistaking unstable new containers as ready, failure threshold `42` seconds blocks inbound traffic, `40` seconds recovery threshold allows inbound traffic again.  
4. **Termination:** Immediately block inbound traffic to old container, allow `60` seconds delay before termination to ensure in-flight user requests complete gracefully.  

## Optimization

### Solution

Further optimization:

1. Create a `/healthz` endpoint for accurate health checks.
2. Upgrade from `tcpSocket` to `httpGet` health checks for precise assessments.

### Manifests

Kubernetes deployment configurations enables the `/healthz` endpoint:

```yaml
---
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
          image: registry.example.com/myapp:1.0
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 8080
          startupProbe:
            tcpSocket:
              port: 8080
            # default: 0
            initialDelaySeconds: 10
            # default: 10
            # fixed interval, does not wait for the previous probe to complete
            periodSeconds: 10
            # default: 3
            failureThreshold: 30
            # default: 1
            # cannot be changed, must be 1 by design
            successThreshold: 1
            # default: 1
            timeoutSeconds: 2
          livenessProbe:
            httpGet:
              path: /healthz
              port: 8080
            # default: 0
            initialDelaySeconds: 10
            # default: 10
            # fixed interval, does not wait for the previous probe to complete
            periodSeconds: 30
            # default: 3
            failureThreshold: 5
            # default: 1
            # cannot be changed, must be 1 by design
            successThreshold: 1
            # default: 1
            timeoutSeconds: 5
          readinessProbe:
            httpGet:
              path: /healthz
              port: 8080
            # default: 0
            initialDelaySeconds: 5
            # default: 10
            # fixed interval, does not wait for the previous probe to complete
            periodSeconds: 20
            # default: 3
            failureThreshold: 3
            # default: 1
            # set to 2 to avoid mistaking unstable new containers as ready
            successThreshold: 2
            # default: 1
            timeoutSeconds: 2
          lifecycle:
            # delay container stop by 60 seconds
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


## Graceful Draining

Container health checks ensure that Pods are running properly, while graceful termination allows Pods to delay shutdown.

Typically, user requests are routed through an Ingress. However, some Ingress controllers such as Alibaba Cloud Kubernetes may remove Pods from backend pools before the Pod fully Terminated.

To avoid interrupting in-flight user requests, the Ingress should be configured with a graceful connection drain timeout that aligns with the container `lifecycle.preStop`. 

This ensures the Ingress keeps connections alive until the timeout expires.

Alibaba Cloud graceful draining configuration:

```yaml
---
apiVersion: v1
kind: Service
metadata:
  namespace: default
  name: myapp-svc
spec:
  selector:
    app: myapp
  clusterIP: None
  ports:
    - port: 80
      targetPort: 80
      protocol: TCP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  namespace: default
  name: myapp-ingress
  annotations:
    # enable graceful draining
    alb.ingress.kubernetes.io/connection-drain-enabled: "true"
    # match lifecycle.preStop
    alb.ingress.kubernetes.io/connection-drain-timeout: "60"
spec:
  ingressClassName: alb
  rules:
    - host: example.com
      http:
        paths:
          - path: /myapp
            pathType: Prefix
            backend:
              service:
                name: myapp-svc
                port:
                  number: 80
```

## Reference

https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/  
https://help.aliyun.com/zh/ack/serverless-kubernetes/user-guide/advanced-alb-ingress-settings#c5bf22507239t  