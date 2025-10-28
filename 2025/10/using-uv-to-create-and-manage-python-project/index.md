# 使用 uv 创建和管理 Python 项目


uv 是一个 Python 包和项目管理器，由 Astral 开发，它使用 Rust 编写，旨在替代 pip 和 virtualenv 等工具。  
uv 提供了比现有工具快10到100倍的性能，同时保持了对 requirements.txt 和 pyproject.toml 文件的兼容性。

<!--more-->

---

## 初始化项目环境

安装 uv

```bash
❯ brew install uv
```

初始化项目 (指定 Python 版本，自动生成 .python-version 和 pyproject.toml 文件)

```bash
❯ uv init myapp --python 3.12
Initialized project `myapp` at `/Users/damonguo/Workspace/demo/myapp`
```

进入项目目录

```bash
❯ cd myapp
```

创建虚拟环境 (自动读取 .python-version)

```bash
❯ uv venv
Using CPython 3.12.12 interpreter at: /opt/homebrew/opt/python@3.12/bin/python3.12
Creating virtual environment at: .venv
Activate with: source .venv/bin/activate
```

指定阿里云 PyPI 镜像源，加速依赖包下载

```toml
❯ cat pyproject.toml
[project]
name = "myapp"
version = "0.1.0"
description = "Add your description here"
readme = "README.md"
requires-python = ">=3.12"
dependencies = []
```

```toml
❯ cat <<'EOT' >> pyproject.toml

[[tool.uv.index]]
name = "aliyun"
url = "https://mirrors.aliyun.com/pypi/simple/"
default = true
EOT
```

```toml
❯ cat pyproject.toml
[project]
name = "myapp"
version = "0.1.0"
description = "Add your description here"
readme = "README.md"
requires-python = ">=3.12"
dependencies = []

[[tool.uv.index]]
name = "aliyun"
url = "https://mirrors.aliyun.com/pypi/simple/"
default = true
```

安装依赖包

```bash
❯ uv add fastapi uvicorn
Resolved 16 packages in 5.06s
Prepared 13 packages in 2.37s
Installed 14 packages in 20ms
 + annotated-doc==0.0.3
 + annotated-types==0.7.0
 + anyio==4.11.0
 + click==8.3.0
 + fastapi==0.120.0
 + h11==0.16.0
 + idna==3.11
 + pydantic==2.12.3
 + pydantic-core==2.41.4
 + sniffio==1.3.1
 + starlette==0.48.0
 + typing-extensions==4.15.0
 + typing-inspection==0.4.2
 + uvicorn==0.38.0
```

编写一个 FastAPI 最小示例

```python
❯ mkdir -p src/myapp
❯ cat <<'EOT' > main.py
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent / "src"))

from myapp.app import app

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("myapp.app:app", host="0.0.0.0", port=8000, reload=True)
EOT
```

```python
❯ cat <<'EOT' > src/myapp/app.py
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def hi():
    return {"ok": True}
EOT
```

运行 FastAPI 最小示例

```bash
❯ uv run python main.py
INFO:     Will watch for changes in these directories: ['/Users/damonguo/Workspace/demo/myapp']
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
INFO:     Started reloader process [25820] using StatReload
INFO:     Started server process [25825]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

```bash
❯ curl http://127.0.0.1:8000
{"ok":true}
```

导出 requirements.txt (可选)  
对于 uv 项目，非必选项，uv 项目使用的是 pyproject.toml 和 uv.lock

```bash
❯ uv pip freeze > requirements.txt
```

项目文件列表 (.venv 已自动添加到 .gitignore 文件中)

```bash
❯ ls -a1
.
..
.git
.gitignore
.python-version
.venv
main.py
pyproject.toml
README.md
requirements.txt
src
uv.lock
```

更新 uv.lock (支持生产环境 `uv sync --locked` 的依赖锁定)

```bash
❯ uv lock
Resolved 16 packages in 1.05s
```

## 加载项目环境

删除 .venv 目录

```bash
rm -r .venv
```

创建虚拟环境 (自动读取 .python-version)  
带有 `--locked` 参数，安装完全一致的依赖版本 (自动读取 pyproject.toml 与 uv.lock，不检查最新版本，不更新 pyproject.toml 与 uv.lock)

```bash
❯ uv sync --locked
Using CPython 3.12.12 interpreter at: /opt/homebrew/opt/python@3.12/bin/python3.12
Creating virtual environment at: .venv
Resolved 16 packages in 10ms
Installed 14 packages in 18ms
 + annotated-doc==0.0.3
 + annotated-types==0.7.0
 + anyio==4.11.0
 + click==8.3.0
 + fastapi==0.120.0
 + h11==0.16.0
 + idna==3.11
 + pydantic==2.12.3
 + pydantic-core==2.41.4
 + sniffio==1.3.1
 + starlette==0.48.0
 + typing-extensions==4.15.0
 + typing-inspection==0.4.2
 + uvicorn==0.38.0
```

```bash
❯ uv tree
Resolved 16 packages in 13ms
myapp v0.1.0
├── annotated-doc v0.0.3
├── annotated-types v0.7.0
├── anyio v4.11.0
│   ├── idna v3.11
│   ├── sniffio v1.3.1
│   └── typing-extensions v4.15.0
├── click v8.3.0
├── fastapi v0.120.0
│   ├── annotated-doc v0.0.3
│   ├── pydantic v2.12.3
│   │   ├── annotated-types v0.7.0
│   │   ├── pydantic-core v2.41.4
│   │   │   └── typing-extensions v4.15.0
│   │   ├── typing-extensions v4.15.0
│   │   └── typing-inspection v0.4.2
│   │       └── typing-extensions v4.15.0
│   ├── starlette v0.48.0
│   │   ├── anyio v4.11.0 (*)
│   │   └── typing-extensions v4.15.0
│   └── typing-extensions v4.15.0
├── h11 v0.16.0
├── idna v3.11
├── pydantic v2.12.3 (*)
├── pydantic-core v2.41.4 (*)
├── sniffio v1.3.1
├── starlette v0.48.0 (*)
├── typing-extensions v4.15.0
├── typing-inspection v0.4.2 (*)
└── uvicorn v0.38.0
    ├── click v8.3.0
    └── h11 v0.16.0
(*) Package tree already displayed
```

## 从 pip 迁移到 uv 项目

删除 uv 相关的目录和文件

```bash
❯ rm -r .venv
❯ rm .python-version
❯ rm pyproject.toml
❯ rm uv.lock

❯ ls -a1
.
..
.git
.gitignore
main.py
README.md
requirements.txt
src
```

初始化项目 (指定 Python 版本，自动生成 .python-version 和 pyproject.toml 文件)

```bash
❯ uv init --python 3.12
Initialized project `myapp`
```

指定阿里云 PyPI 镜像源，加速依赖包下载

```toml
❯ cat <<'EOT' >> pyproject.toml

[[tool.uv.index]]
name = "aliyun"
url = "https://mirrors.aliyun.com/pypi/simple/"
default = true
EOT
```

解析已经存在的 requirements.txt
安装完全一致的依赖版本 (自动生成 uv.lock)

```bash
❯ uv add -r requirements.txt
Using CPython 3.12.12 interpreter at: /opt/homebrew/opt/python@3.12/bin/python3.12
Creating virtual environment at: .venv
Resolved 16 packages in 2.46s
Installed 14 packages in 29ms
 + annotated-doc==0.0.3
 + annotated-types==0.7.0
 + anyio==4.11.0
 + click==8.3.0
 + fastapi==0.120.0
 + h11==0.16.0
 + idna==3.11
 + pydantic==2.12.3
 + pydantic-core==2.41.4
 + sniffio==1.3.1
 + starlette==0.48.0
 + typing-extensions==4.15.0
 + typing-inspection==0.4.2
 + uvicorn==0.38.0
```

```bash
❯ ls -a1
.
..
.git
.gitignore
.python-version
.venv
main.py
pyproject.toml
README.md
requirements.txt
src
uv.lock
```

更新 uv.lock (支持生产环境 `uv sync --locked` 的依赖锁定)

```bash
❯ uv lock
Resolved 16 packages in 1.05s
```

## 适用于生产环境的 Dockerfile

创建 .dockerignore

```bash
❯ cat <<'EOT' > .dockerignore
# macOS
.DS_Store

# Git
.git/

# Python
__pycache__/
*.py[cod]
*$py.class
EOT
```

创建 Dockerfile

```dockerfile
❯ cat <<'EOT' > Dockerfile
# use uv to build dependencies
FROM ghcr.io/astral-sh/uv:python3.12-alpine AS builder

# set working directory
WORKDIR /app

# install dependencies using uv (only lockfile deps first)
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --locked --no-install-project --no-editable

# copy source code
ADD . /app

# install project itself into .venv
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-editable


# final runtime image
FROM python:3.12-alpine

# set working directory
WORKDIR /app

# create non-root user
RUN addgroup -S app && adduser -S app -G app

# copy project and virtual environment from builder
COPY --from=builder --chown=app:app /app /app

# add /app/src to Python module search path
ENV PYTHONPATH=/app/src

# exposed port
EXPOSE 8000

# run as non-root user
USER app

# start uvicorn app (expand WORKERS_NUM env)
CMD ["/bin/sh", "-c", "/app/.venv/bin/uvicorn myapp.app:app --host 0.0.0.0 --port 8000 --workers ${WORKERS_NUM:-1}"]
EOT
```

构建 Docker image

```bash
❯ docker build -f ./Dockerfile --platform linux/amd64 -t myapp:2015.10.28_1 .
[+] Building 5.3s (15/15) FINISHED                                       docker:orbstack
 => [internal] load build definition from Dockerfile                     0.0s
 => => transferring dockerfile: 1.15kB                                   0.0s
 => [internal] load metadata for docker.io/library/python:3.12-alpine    0.3s
 => [internal] load metadata for ghcr.io/astral-sh/uv:python3.12-alpine  1.6s
 => [internal] load .dockerignore                                        0.0s
 => => transferring context: 115B                                        0.0s
 => [builder 1/5] FROM ghcr.io/astral-sh/uv:python3.12-alpine            0.0s
 => [internal] load build context                                        0.1s
 => => transferring context: 94.47kB                                     0.1s
 => [stage-1 1/4] FROM docker.io/library/python:3.12-alpine              0.0s
 => CACHED [builder 2/5] WORKDIR /app                                    0.0s
 => CACHED [stage-1 2/4] WORKDIR /app                                    0.0s
 => CACHED [stage-1 3/4] RUN addgroup -S app && adduser -S app -G app    0.0s
 => [builder 3/5] RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --locked --no-install-project --no-editable                  2.3s
 => [builder 4/5] ADD . /app                                             0.2s
 => [builder 5/5] RUN --mount=type=cache,target=/root/.cache/uv \
     uv sync --locked --no-editable                                      0.8s
 => [stage-1 4/4] COPY --from=builder --chown=app:app /app /app          0.1s
 => exporting to image                                                   0.1s
 => => exporting layers                                                  0.0s
 => => writing image                                                     0.0s
 => => naming to docker.io/library/myapp:2015.10.28_1                    0.0s
```

通过 docker-compose 运行 Docker 容器

```bash
❯ cat <<'EOT' > docker-compose.yml
services:
  myapp:
    image: myapp:2015.10.28_1
    platform: linux/amd64
    ports:
      - "8000:8000"
    environment:
      - WORKERS_NUM=2
EOT

❯ docker-compose up -d
[+] Running 2/2
 ✔ Network myapp_default    Created  0.0s
 ✔ Container myapp-myapp-1  Started  0.3s

❯ docker-compose ps
NAME            IMAGE                COMMAND                  SERVICE   CREATED         STATUS         PORTS
myapp-myapp-1   myapp:2015.10.28_1   "/bin/sh -c '/app/.v…"   myapp     5 minutes ago   Up 5 minutes   0.0.0.0:8000->8000/tcp

❯ curl http://127.0.0.1:8000
{"ok":true}
```

## 参考

https://docs.astral.sh/uv/guides/projects/  
https://docs.astral.sh/uv/guides/migration/pip-to-project/  
https://docs.astral.sh/uv/guides/integration/docker/#non-editable-installs  

