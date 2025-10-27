---
title: "Using uv to create and manage Python project"
slug: "using-uv-to-create-and-manage-python-project"
date: 2025-10-27T15:35:29+08:00
author: "Damon"
description: "uv is a Python package and project manager written in Rust and designed to replace tools such as pip and virtualenv."
categories: ["Skills"]
tags: ["Python"]
resources:
- name: "featured-image"
  src: "featured-image.jpg"

lightgallery: true
---

uv is a Python package and project manager developed by Astral, written in Rust and designed to replace tools such as pip and virtualenv.  
uv provides performance 10 to 100 times faster than existing tools while maintaining compatibility with requirements.txt and pyproject.toml files.

<!--more-->

---

## Initialize Project

Install uv

```bash
❯ brew install uv
```

Initialize project (specify Python version)

```bash
❯ uv init myapp --python 3.12
Initialized project `myapp` at `/Users/damonguo/Workspace/demo/myapp`
```

Enter project directory

```bash
❯ cd myapp
```

Create virtual environment (specify Python version)

```bash
❯ uv venv --python 3.12
Using CPython 3.12.12 interpreter at: /opt/homebrew/opt/python@3.12/bin/python3.12
Creating virtual environment at: .venv
Activate with: source .venv/bin/activate
```

Configure Aliyun PyPI mirror source to accelerate package downloads

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

Install dependencies

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

Write a minimal FastAPI example

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

Run the minimal FastAPI example

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

Export requirements.txt (optional)  
Not required for uv projects, as uv projects use pyproject.toml and uv.lock

```bash
❯ uv pip freeze > requirements.txt
```

Project file list (.venv is automatically added to .gitignore)

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

## Load Project

Remove .venv directory

```bash
rm -r .venv
```

Create virtual environment (automatically reads .python-version)

```bash
❯ uv venv
Using CPython 3.12.12 interpreter at: /opt/homebrew/opt/python@3.12/bin/python3.12
Creating virtual environment at: .venv
Activate with: source .venv/bin/activate
```

Install exact dependency versions (automatically reads pyproject.toml and uv.lock)

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

## References

https://docs.astral.sh/uv/guides/projects/
