# Using uv to create and manage Python project


uv is a Python package and project manager developed by Astral, written in Rust and designed to replace tools such as pip and virtualenv.  
uv provides performance 10 to 100 times faster than existing tools while maintaining compatibility with requirements.txt and pyproject.toml files.

<!--more-->

---

## Initialize Project

Install uv

```bash
❯ brew install uv
```

Initialize project (specify Python version, automatically generate .python-version and pyproject.toml)

```bash
❯ uv init myapp --python 3.12
Initialized project `myapp` at `/Users/damonguo/Workspace/demo/myapp`
```

Enter project directory

```bash
❯ cd myapp
```

Create virtual environment (automatically reads .python-version)

```bash
❯ uv venv
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
❯ export PYTHONPATH=src
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

Update uv.lock (supports dependency locking in production environment `uv sync --locked`)

```bash
❯ uv lock
Resolved 16 packages in 1.05s
```

## Load Project

Remove .venv directory

```bash
❯ rm -r .venv
```

Create virtual environment (automatically reads .python-version)  
With `--locked` parameter, install exact dependency versions (automatically reads pyproject.toml and uv.lock, does not check for the latest versions, and does not update pyproject.toml and uv.lock)

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
Resolved 16 packages in 18ms
myapp v0.1.0
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
│   │   ├── anyio v4.11.0
│   │   │   ├── idna v3.11
│   │   │   ├── sniffio v1.3.1
│   │   │   └── typing-extensions v4.15.0
│   │   └── typing-extensions v4.15.0
│   └── typing-extensions v4.15.0
└── uvicorn v0.38.0
    ├── click v8.3.0
    └── h11 v0.16.0
```

## Migrate from pip to a uv project

Remove uv related directories and files

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

Initialize a project (specify Python version, automatically generate .python-version and pyproject.toml)

```bash
❯ uv init --python 3.12
Initialized project `myapp`
```

Parse the existing requirements.txt  
Install exact dependency versions (automatically generate uv.lock)

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

Update uv.lock (supports dependency locking in production environment `uv sync --locked`)

```bash
❯ uv lock
Resolved 16 packages in 1.05s
```

## Dockerfile in production

Create .dockerignore

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

Create Dockerfile

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

Build Docker image

```bash
❯ docker build -f ./Dockerfile --platform linux/amd64 -t myapp:2015.10.27_1 .
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
 => => naming to docker.io/library/myapp:2015.10.27_1                    0.0s
```

Run Docker container via docker-compose

```bash
❯ cat <<'EOT' > docker-compose.yml
services:
  myapp:
    image: myapp:2015.10.27_1
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
myapp-myapp-1   myapp:2015.10.27_1   "/bin/sh -c '/app/.v…"   myapp     5 minutes ago   Up 5 minutes   0.0.0.0:8000->8000/tcp

❯ curl http://127.0.0.1:8000
{"ok":true}
```

## References

https://docs.astral.sh/uv/guides/projects/  
https://docs.astral.sh/uv/guides/migration/pip-to-project/  
https://docs.astral.sh/uv/guides/integration/docker/#non-editable-installs  

