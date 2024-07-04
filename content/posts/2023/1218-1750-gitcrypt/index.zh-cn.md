---
title: "使用 git-crypt 加解密 Git 中的文件"
date: 2023-12-18T17:50:15+08:00
author: "郭冬"
description: "git-crypt 是一个用于加密和解密文件的工具，可以与 Git 仓库无缝集成，允许用户安全地存储和共享敏感数据。"
categories: ["技能矩阵"]
tags: ["Git","Cybersecurity"]
resources:
- name: "featured-image"
  src: "featured-image.jpeg"

lightgallery: true
---

git-crypt 是一个用于加密和解密文件的工具，可以与 Git 仓库无缝集成，允许用户安全地存储和共享敏感数据。

<!--more-->

---

## 安装 git-crypt

```plain
❯ brew install git-crypt
```

## 初始化 git-crypt 并备份加密 key

```plain
❯ git-crypt init
Generating key...
❯ git-crypt export-key /Users/damonguo/Workspace/keys/git-crypt-v1.key
❯ diff .git/git-crypt/keys/default /Users/damonguo/Workspace/keys/git-crypt-v1.key

❯ echo "git-crypt/api.key filter=git-crypt diff=git-crypt" > .gitattributes
❯ git add .gitattributes
❯ git commit -m "feat: tell git-crypt to encrypt git-crypt/api.key"
❯ git push
```

## 创建测试文件
```plain
❯ mkdir git-crypt
❯ echo "This is some text" > git-crypt/file.txt
❯ echo "dummy value" > git-crypt/api.key
❯ git add git-crypt
❯ git commit -m "feat: add git-crypt demo files"
❯ git push
```

## 校验文件加解密状态

使用 `git-crypt status` 命令查看文件的服务端加解密状态
```plain
❯ git-crypt status git-crypt
    encrypted: git-crypt/api.key
not encrypted: git-crypt/file.txt
```

通过 `GitLab 网页端` 查看文件的服务端加解密状态

{{< image src="git_crypt_encrypted_file.jpg" alt="git_crypt_encrypted_file" width=800 >}}

通过 `git-crypt lock/unlock` 命令对文件 `git-crypt/api.key` 进行本地加解密

```plain
❯ git-crypt lock
❯ file git-crypt/api.key
git-crypt/api.key: data

❯ git-crypt unlock /Users/damonguo/Workspace/keys/git-crypt-v1.key
❯ file git-crypt/api.key
git-crypt/api.key: ASCII text
❯ cat git-crypt/api.key
dummy value
```

## 在团队中使用 git-crypt

以安全的方式与团队成员共享导出的加密 Key `/Users/damonguo/Workspace/keys/git-crypt-v1.key`。

通知他们导入加密 Key 对 Git 仓库中的加密文件进行解密: `git-crypt unlock /path/to/git-crypt-v1.key`。

## 更新 git-crypt 加密 key

创建一个新的 git-crypt 加密 Key

```plain
❯ git-crypt unlock /Users/damonguo/Workspace/keys/git-crypt-v1.key
❯ rm -rf .git/git-crypt/keys
❯ git-crypt init
Generating key...
❯ git-crypt export-key /Users/damonguo/Workspace/keys/git-crypt-v2.key
❯ diff .git/git-crypt/keys/default /Users/damonguo/Workspace/keys/git-crypt-v2.key
```

触发更新并应用新的 git-crypt 加密 key。

```plain
❯ echo "new dummy value" > git-crypt/api.key
❯ git add git-crypt/api.key
❯ git commit -m "feat: update api.key with new git-crypt encryption key"
❯ git push
```

以安全的方式与团队成员共享新的加密 Key `/Users/damonguo/Workspace/keys/git-crypt-v2.key`。

通知他们暂停 git push 和 pull 等操作，先导入新的加密 Key: `git-crypt unlock /path/to/git-crypt-v2.key`，然后再继续。

## 参考

https://buddy.works/guides/git-crypt
