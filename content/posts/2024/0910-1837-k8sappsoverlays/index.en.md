---
title: "Kubernetes Multi-environment and Multi-application Orchestration Practice"
date: 2024-09-10T18:37:39+08:00
author: "Dong Guo | Damon"
description: "By implementing a Kubernetes multi-environment and multi-application orchestration with the same configuration by YAML(Manifests), Kustomize and Helm, we can quickly get started with Kustomize and Helm and understand the differences between them."
categories: ["Skills"]
tags: ["Kubernetes","Kustomize","Helm"]
resources:
- name: "featured-image"
  src: "featured-image.jpeg"

toc: true
lightgallery: true
---

By implementing a Kubernetes multi-environment and multi-application orchestration with the same configuration by YAML(Manifests), Kustomize and Helm, we can quickly get started with Kustomize and Helm and understand the differences between them.

<!--more-->

---

{{< admonition type=tip open=true >}}
"Talk is cheap. Show me the code." - Linus Torvalds
{{< /admonition >}}

**Code Sharing:** https://github.com/mcsrainbow/k8s-apps

## Manifests

Native YAML (Manifests) is the most straightforward and simple method for configuring Kubernetes resources. For multi-environment and multi-application orchestration, the approach is direct: create directories for different environments and separate resources into different YAML files based on common and application-specific configurations.

```
manifests/apps-overlays
├── development
│   ├── bu-project-all.yaml
│   ├── bu-project-apiproxy.yaml
│   └── bu-project-webfront.yaml
├── production
│   ├── bu-project-all.yaml
│   ├── bu-project-apiproxy.yaml
│   └── bu-project-webfront.yaml
└── staging
    ├── bu-project-all.yaml
    ├── bu-project-apiproxy.yaml
    └── bu-project-webfront.yaml
```

Pros: Highly intuitive, with no coupling between configurations for different environments and applications, reducing the impact of configuration errors.  
Cons: Repeated configuration code and difficulty modifying parameters, as changes require text-based search and replace.

## Kustomize

Kustomize is a resource configuration method that sits between YAML and Helm, enhancing YAML by introducing built-in plugins for code reuse and parameter modification.

Kustomize reads from the kustomization.yaml file by default, and a layered design can be achieved by referencing kustomization.yaml files in different directories.

```
kustomize/apps-overlays
├── base
│   ├── apps
│   │   ├── apiproxy
│   │   │   ├── deployment.yaml
│   │   │   ├── ingress.yaml
│   │   │   ├── kustomization.yaml
│   │   │   └── service.yaml
│   │   └── webfront
│   │       ├── deployment.yaml
│   │       ├── ingress.yaml
│   │       ├── kustomization.yaml
│   │       └── service.yaml
│   ├── files
│   │   └── dockerconfigjson.encrypted
│   ├── kustomization.yaml
│   └── patches
│       └── imagePullSecrets.yaml
└── overlays
    ├── development
    │   ├── files
    │   │   └── nginx.conf
    │   └── kustomization.yaml
    ├── production
    │   ├── files
    │   │   └── nginx.conf
    │   └── kustomization.yaml
    └── staging
        ├── files
        │   └── nginx.conf
        └── kustomization.yaml
```

Rendering of native YAML can be previewed using the `kustomize build` command.

```bash
cd kustomize/apps-overlays
kustomize build overlays/development
kustomize build overlays/staging
kustomize build overlays/production
```

Pros: Compatible with native YAML, supports reusable configurations, and allows reading files to generate Secret and ConfigMap, as well as modifying parameters (e.g., adding labels, prefixes, adjusting CPU and memory).  
Cons: Code reuse introduces coupling, increasing the impact of configuration errors. The built-in plugins are limited, which restricts highly flexible reuse and parameter modifications.

Kustomize Built-in Plugins: https://kubectl.docs.kubernetes.io/references/kustomize/builtins/

## Helm

Helm is a Kubernetes package manager and deployment tool, similar to Ansible + Yum on Linux.

Helm reads variables defined in the values.yaml file along with templates from the templates directory. This allows for highly flexible code reuse, parameter modification, and file generation.

Multi-environment and multi-application orchestration can be achieved by placing default and common parameters in the values.yaml file, and supplementing or overriding them through environment-specific values files.

```
helm/apps-overlays
├── Chart.yaml
├── files
│   ├── dockerconfigjson.encrypted
│   └── nginx.conf
├── templates
│   ├── apiproxy
│   │   ├── _helpers.tpl
│   │   ├── configmap.yaml
│   │   ├── deployment.yaml
│   │   ├── ingress.yaml
│   │   └── service.yaml
│   ├── secret.yaml
│   └── webfront
│       ├── _helpers.tpl
│       ├── deployment.yaml
│       ├── ingress.yaml
│       └── service.yaml
├── values
│   ├── development.yaml
│   ├── production.yaml
│   └── staging.yaml
└── values.yaml
```

Rendering of native YAML can be previewed using the `helm template` command.

```bash
cd helm/apps-overlays
helm template . -f values/development.yaml
helm template . -f values/staging.yaml
helm template . -f values/production.yaml
```

Pros: Powerful templating, with highly flexible code reuse, parameter modification, and file generation. Configurations can be packaged and published to Helm Repos for package management.  
Cons: High flexibility leads to high coupling, and the templated code is less intuitive. Configuration errors can have a larger impact and be more difficult to debug.

Helm Template Functions and Pipelines: https://helm.sh/zh/docs/chart_template_guide/functions_and_pipelines/
