---
title: "健康检查端点 /healthz 设计实践"
slug: "health-check-endpoint-healthz-design-practice"
date: 2025-07-18T11:02:05+08:00
author: "Damon"
description: "设计一个具有关键检查和独立外部监控的健康检查端点。"
categories: ["技能矩阵"]
tags: ["Kubernetes"]
resources:
- name: "featured-image"
  src: "featured-image.jpeg"

toc: true
lightgallery: true
---

设计一个具有关键检查和独立外部监控的健康检查端点。

<!--more-->

---

{{< admonition type=tip open=true >}}
"Talk is cheap. Show me the code." - Linus Torvalds
{{< /admonition >}}

**代码分享:** https://github.com/mcsrainbow/mock-healthz-metrics

## ✨ 特性

- `/healthz`:
  - 返回码: 健康 `200`, 异常 `500`
  - 输出: `纯文本`, `JSON`
- `/metrics`: Prometheus 指标
- **两级健康检查**:
  - 🔴 **关键检查** 影响整体健康状态:
    - 🔌 数据库连接: 核心依赖，必须健康
    - ⚙️ 配置服务: 核心依赖，必须健康  
    - 🔁 内部 API `billing`, `usage`: 依赖上游服务`DB + Config`，上游失败时跳过
  - 🟡 **外部检查** 独立:
    - 🌍 外部 API `alipay`, `sms`: 独立运行，不影响整体健康状态
- 依赖项具有内置错误概率和超时模拟
- 完全兼容 Kubernetes 探针和 Prometheus 抓取
- **依赖链**:
  - 数据库 + 配置服务 → 内部 API → 整体健康状态
  - 外部 API → 仅独立监控

---

## 🚀 开始使用

### 1. 安装依赖

```plain
pip install bottle
```

### 2. 运行脚本

```plain
python mock-healthz-metrics.py
```

```plain
Service endpoints available:
  Healthcheck (Text):  http://0.0.0.0:8080/healthz
  Healthcheck (JSON):  http://0.0.0.0:8080/healthz?format=json
  Prometheus metrics:  http://0.0.0.0:8080/metrics
```

## ✅ 健康检查

### 纯文本

http://127.0.0.1:8080/healthz  
http://127.0.0.1:8080/healthz?format=text  

**健康状态**

```plain
CHECK                   STATUS  MESSAGE
----- Critical -----
db_connection           PASS    Database is connected
config_service          PASS    Config service is reachable
internal_api/billing    PASS    internal_api/billing OK (392ms)
internal_api/usage      PASS    internal_api/usage OK (348ms)
----- External -----
external_api/alipay     PASS    external_api/alipay OK (308ms)
external_api/sms        FAIL    external_api/sms timed out
```

**异常状态**

```plain
CHECK                   STATUS  MESSAGE
----- Critical -----
db_connection           PASS    Database is connected
config_service          PASS    Config service is reachable
internal_api/billing    PASS    internal_api/billing OK (253ms)
internal_api/usage      FAIL    internal_api/usage returned error
----- External -----
external_api/alipay     PASS    external_api/alipay OK (101ms)
external_api/sms        PASS    external_api/sms OK (183ms)
```

### JSON 格式

http://127.0.0.1:8080/healthz?format=json

**健康状态**

```json
{
  "status": "ok",
  "data": {
    "message": "All critical checks passed",
    "checks": {
      "critical": [
        {
          "name": "db_connection",
          "status": "ok",
          "message": "Database is connected"
        },
        {
          "name": "config_service",
          "status": "ok",
          "message": "Config service is reachable"
        },
        {
          "name": "internal_api/billing",
          "status": "ok",
          "message": "internal_api/billing OK (392ms)"
        },
        {
          "name": "internal_api/usage",
          "status": "ok",
          "message": "internal_api/usage OK (348ms)"
        }
      ],
      "external": [
        {
          "name": "external_api/alipay",
          "status": "ok",
          "message": "external_api/alipay OK (308ms)"
        },
        {
          "name": "external_api/sms",
          "status": "error",
          "message": "external_api/sms timed out"
        }
      ]
    }
  }
}
```

**异常状态**

```json
{
  "status": "error",
  "data": {
    "message": "Critical checks failed",
    "checks": {
      "critical": [
        {
          "name": "db_connection",
          "status": "ok",
          "message": "Database is connected"
        },
        {
          "name": "config_service",
          "status": "ok",
          "message": "Config service is reachable"
        },
        {
          "name": "internal_api/billing",
          "status": "ok",
          "message": "internal_api/billing OK (253ms)"
        },
        {
          "name": "internal_api/usage",
          "status": "error",
          "message": "internal_api/usage returned error"
        }
      ],
      "external": [
        {
          "name": "external_api/alipay",
          "status": "ok",
          "message": "external_api/alipay OK (101ms)"
        },
        {
          "name": "external_api/sms",
          "status": "ok",
          "message": "external_api/sms OK (183ms)"
        }
      ]
    }
  }
}
```

## 📈 Prometheus

http://127.0.0.1:8080/metrics

### 配置

```yaml
scrape_configs:
  - job_name: 'mock-healthz-metrics'
    static_configs:
      - targets: ['127.0.0.1:8080']
```

默认抓取 `http://127.0.0.1:8080/metrics` 链接。

### 指标

**健康状态**

```plain
# HELP healthcheck_status Health check status (1=ok,0=error)
# TYPE healthcheck_status gauge
healthcheck_status{check="db_connection",type="critical"} 1
healthcheck_status{check="config_service",type="critical"} 1
healthcheck_status{check="internal_api/billing",type="critical"} 1
healthcheck_status{check="internal_api/usage",type="critical"} 1
healthcheck_status{check="external_api/alipay",type="external"} 1
healthcheck_status{check="external_api/sms",type="external"} 0
```

**异常状态**

```plain
# HELP healthcheck_status Health check status (1=ok,0=error)
# TYPE healthcheck_status gauge
healthcheck_status{check="db_connection",type="critical"} 1
healthcheck_status{check="config_service",type="critical"} 1
healthcheck_status{check="internal_api/billing",type="critical"} 0
healthcheck_status{check="internal_api/usage",type="critical"} 1
healthcheck_status{check="external_api/alipay",type="external"} 1
healthcheck_status{check="external_api/sms",type="external"} 1
```

## 🐳 Kubernetes

对于 Kubernetes livenessProbe 和 readinessProbe:

```plain
❯ curl -I http://127.0.0.1:8080/healthz
HTTP/1.0 200 OK
Date: Fri, 18 Jul 2025 03:43:31 GMT
Server: WSGIServer/0.2 CPython/3.11.11
Content-Type: text/plain
Content-Length: 444

❯ curl -I http://127.0.0.1:8080/healthz
HTTP/1.0 500 Internal Server Error
Date: Fri, 18 Jul 2025 03:43:36 GMT
Server: WSGIServer/0.2 CPython/3.11.11
Content-Type: text/plain
Content-Length: 438
```

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 30
  failureThreshold: 5
  timeoutSeconds: 5

readinessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 20
  failureThreshold: 3
  successThreshold: 2
  timeoutSeconds: 2
```

关于更详细的探针设计，请参考文章: [Kubernetes 容器健康检查和优雅终止](https://blog.heylinux.com/2024/07/kubernetes-container-healthcheck-and-graceful-termination/)。

## 📌 注意事项

- 此脚本使用随机化逻辑来模拟服务不稳定性
- 对于生产环境使用，请用真实的健康检查实现替换模拟逻辑（例如，数据库 ping、HTTP 客户端调用等）
