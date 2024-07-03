# K8S Port-based Container Healthcheck and Graceful Shutdown


Implementing container health checks and graceful shutdown in Kubernetes (K8S) with application-specific configurations enhances production stability, reduces deployment incidents and false alarms.

<!--more-->

---

**Configuration Item Descriptions:**

1. **`terminationGracePeriodSeconds`:** Global setting for Pod termination grace period; must greater than lifecycle.preStop. If containers aren't terminated within this period, the Pod will be forcibly terminated.  
2. **`lifecycle.preStop`:** Hook to execute commands before container stops, delaying termination to release connections for pending requests.  
3. **`startupProbe`:** Checks container startup status, providing additional preparation time.  
4. **`livenessProbe`:** Checks if the container is alive; kubelet kills and restarts the container if the check fails.  
5. **`readinessProbe`:** Checks if the container is ready to accept traffic; kubelet adds the Pod to the Service's load balancer pool only if this check passes.  

**Best Practice K8S Deployment Configuration with Health Checks and Graceful Shutdown:**

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
      terminationGracePeriodSeconds: 120 # default: 30
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
            initialDelaySeconds: 30      # default: 0
            periodSeconds: 30            # default: 10
            failureThreshold: 10         # default: 3
            successThreshold: 2          # default: 1
            timeoutSeconds: 2            # default: 1
          livenessProbe:
            tcpSocket:
              port: 8080
            initialDelaySeconds: 30      # default: 0
            periodSeconds: 30            # default: 10
            failureThreshold: 3          # default: 3
            successThreshold: 2          # default: 1
            timeoutSeconds: 2            # default: 1
          readinessProbe:
            tcpSocket:
              port: 8080
            initialDelaySeconds: 30      # default: 0
            periodSeconds: 30            # default: 10
            failureThreshold: 3          # default: 3
            successThreshold: 2          # default: 1
            timeoutSeconds: 2            # default: 1
          lifecycle:
            preStop:
              exec:
                command: ["/bin/sh", "-c", "sleep 60"]
          env:
            - name: TZ
              value: Asia/Shanghai
          resources:
            requests:
              cpu: "0.5"
              memory: 1Gi
```

**Default K8S Settings:**

1. **Startup Check:** `None`
2. **Container Readiness:** Minimum `0` seconds
3. **Container State:**  
   Failure determination `23`-`33` seconds `failureThreshold(3) * timeoutSeconds(1) + ( failureThreshold(3) -1 ) * periodSeconds(10)`  
   Recovery determination `0` - `10` seconds `periodSeconds(10)`
4. **Container Shutdown:** Minimum `0` seconds, Maximum `30` seconds `terminationGracePeriodSeconds(30)`

**Best Practice Configuration:**

1. **Startup Check:**  
   Minimum `60` seconds `initialDelaySeconds(30) + periodSeconds(30) * ( successThreshold(2) - 1 )`  
   Maximum `350` seconds `initialDelaySeconds(30) + failureThreshold(10) * ( timeoutSeconds(2) + periodSeconds(30) )`
2. **Container Readiness:**  
   Minimum `120` seconds `Startup Check(60)` + `initialDelaySeconds(30) + periodSeconds(30) * ( successThreshold(2) - 1 )`
3. **Container State:**  
   Failure determination `66`-`96` seconds `failureThreshold(3) * timeoutSeconds(2) + ( failureThreshold(3) -1 ) * periodSeconds(30)`  
   Recovery determination `30`-`60` seconds `periodSeconds(30) * ( successThreshold(2) - 1 )`
4. **Container Shutdown:**   
   Minimum `60` seconds `sleep 60`  
   Maximum `120` seconds `terminationGracePeriodSeconds(120)`

**Optimizations Compared to Default K8S Settings:**

1. **Startup Check:** Add 60-350 seconds for application startup.
2. **Container Readiness:** Add a 120 seconds buffer during deployment.
3. **Container State:** Add 33 seconds for failure determination and 30 seconds for recovery, improve accuracy.
4. **Container Shutdown:** Add 60 seconds to ensure connections are properly released.

**Further Enhancements:**

1. Create a `/healthz` endpoint for accurate health checks.
2. Upgrade from `port` to `httpGet` health checks for precise assessments.
