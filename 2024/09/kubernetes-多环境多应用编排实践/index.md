# Kubernetes 多环境多应用编排实践


通过 YAML(Manifests)、Kustomize 和 Helm 各自实现一套相同配置的 Kubernetes 多环境多应用编排，可以快速的上手 Kustomize 和 Helm，并了解到它们之间的差异。

<!--more-->

---

{{< admonition type=tip open=true >}}
"Talk is cheap. Show me the code." - Linus Torvalds
{{< /admonition >}}

**代码分享:** https://github.com/mcsrainbow/k8s-apps

## Manifests

原生 YAML(Manifests) 是最直观和最简单的 Kubernetes 资源配置方式，对于多环境多应用的编排方式也简单粗暴，直接创建不同环境名称的目录，将资源按照公共和应用维度分别写入不同的 YAML 文件即可。

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

优点: 最直观，不同环境和应用之间配置无耦合，配置失误时影响范围小；  
缺点: 重复的配置代码较多，修改配置参数时不方便，需要通过文本方式查找和替换。

## Kustomize

Kustomize 是介于 YAML 和 Helm 之间的资源配置方式，在兼容 YAML 的基础上通过内置的插件实现配置代码的复用和参数的修改。

Kustomize 默认读取 kustomization.yaml 文件中的配置，可通过引用不同目录下的 kustomization.yaml 文件实现分层设计。

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

通过 `kustomize build` 命令可以预览渲染出的原生 YAML。

```bash
cd kustomize/apps-overlays
kustomize build overlays/development
kustomize build overlays/staging
kustomize build overlays/production
```

优点: 兼容原生 YAML，可复用配置代码，可通过内置的插件读取文件生成 Secret 和 ConfigMap，以及修改参数（例如: 增加标签、增加资源名称前缀、修改 CPU 和内存等）；  
缺点: 复用配置代码后也导致了耦合，配置失误时影响范围增大，内置的插件功能有限，无法高度自由地复用配置代码和修改参数。

Kustomize 内置插件: https://kubectl.docs.kubernetes.io/zh/guides/plugins/builtins/

## Helm

Helm 是 Kubernetes 包管理器和部署工具，类似 Linux 上的 配置管理工具 Ansible + 包管理器 Yum。

Helm 默认读取 values.yaml 文件中定义的变量，和 templates 目录下的模板文件、函数和代码块，可以高度自由地复用代码、修改参数和读取文件生成配置。

Helm 可以创建不同环境的 values 文件，将默认参数和公共参数放到 values.yaml 文件中，通过不同环境的 values 文件中的参数补充和覆盖，实现多环境多应用编排。

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

通过 `helm template` 命令可以预览渲染出的原生 YAML。

```
cd helm/apps-overlays
helm template . -f values/development.yaml
helm template . -f values/staging.yaml
helm template . -f values/production.yaml
```

优点: 模板功能强大，可以高度自由地复用代码、修改参数和读取文件生成配置，可将配置按应用打包发布到 Helm Repo 中进行包管理；  
缺点: 高度自由的定制能力也导致了高耦合，模板化的配置代码不够直观，配置失误时影响范围增大且调试难度增加。

Helm 模板函数: https://helm.sh/zh/docs/chart_template_guide/function_list/

