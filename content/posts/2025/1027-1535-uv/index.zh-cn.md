---
title: "使用 uv 创建和管理 Python 项目"
slug: "using-uv-to-create-and-manage-python-project"
date: 2025-10-27T15:35:29+08:00
author: "郭冬"
description: "uv 是一个 Python 包和项目管理器，它使用 Rust 编写，旨在替代 pip 和 virtualenv 等工具。"
categories: ["技能矩阵"]
tags: ["Python"]
resources:
- name: "featured-image"
  src: "featured-image.jpg"

lightgallery: true
---

uv 是一个 Python 包和项目管理器，由 Astral 开发，它使用 Rust 编写，旨在替代 pip 和 virtualenv 等工具。  
uv 提供了比现有工具快10到100倍的性能，同时保持了对 requirements.txt 和 pyproject.toml 文件的兼容性。

<!--more-->

---

## 初始化项目环境

安装 uv

```bash
❯ brew install uv
```

初始化项目(指定 Python 版本)

```bash
❯ uv init myapp --python 3.12
Initialized project `myapp` at `/Users/damonguo/Workspace/demo/myapp`
```

进入项目目录

```bash
❯ cd myapp
```

创建虚拟环境(指定 Python 版本)

```bash
❯ uv venv --python 3.12
Using CPython 3.12.12 interpreter at: /opt/homebrew/opt/python@3.12/bin/python3.12
Creating virtual environment at: .venv
Activate with: source .venv/bin/activate
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

项目文件列表(.venv 已自动添加到 .gitignore 文件中)

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

## 加载项目环境

删除 .venv 目录

```bash
rm -r .venv
```

创建虚拟环境(自动读取 .python-version)

```bash
❯ uv venv
Using CPython 3.12.12 interpreter at: /opt/homebrew/opt/python@3.12/bin/python3.12
Creating virtual environment at: .venv
Activate with: source .venv/bin/activate
```

安装完全一致的依赖版本(自动读取 pyproject.toml 与 uv.lock)

```bash
❯ uv sync
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

## 参考

https://docs.astral.sh/uv/guides/projects/
