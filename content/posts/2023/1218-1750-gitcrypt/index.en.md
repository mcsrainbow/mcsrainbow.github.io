---
title: "Use git-crypt to encrypt files in Git"
date: 2023-12-18T17:50:15+08:00
author: "Dong Guo | Damon"
description: "git-crypt is a tool for encrypting and decrypting files that integrates seamlessly with Git repositories, allowing users to securely store and share sensitive data."
categories: ["Skills"]
tags: ["Git","Cybersecurity"]
resources:
- name: "featured-image"
  src: "featured-image.jpeg"

lightgallery: true
---

git-crypt is a tool for encrypting and decrypting files that integrates seamlessly with Git repositories, allowing users to securely store and share sensitive data.

<!--more-->


## Install git-crypt

```plain
❯ brew install git-crypt
```

## Initialize git-crypt and back up the encryption key

```plain
❯ git-crypt init
Generating key...
❯ git-crypt export-key /Users/damonguo/Workspace/sshkeys/git-crypt.key
❯ diff .git/git-crypt/keys/default /Users/damonguo/Workspace/sshkeys/git-crypt.key

❯ echo "git-crypt/api.key filter=git-crypt diff=git-crypt" > .gitattributes
❯ git add .gitattributes
❯ git commit -m "feat: tell git-crypt to encrypt git-crypt/api.key"
❯ git push
```

## Create git-crypt demo files

```plain
❯ mkdir git-crypt
❯ echo "This is some text" > git-crypt/file.txt
❯ echo "dummy value" > git-crypt/api.key
❯ git add git-crypt
❯ git commit -m "feat: add git-crypt demo files"
❯ git push
```

## Verify encryption and decryption status

Use the `git-crypt status` command to view the server side encryption and decryption status

```plain
❯ git-crypt status git-crypt
    encrypted: git-crypt/api.key
not encrypted: git-crypt/file.txt
```

View the server side encryption and decryption status on the `GitLab Web`

{{< image src="git_crypt_encrypted_file.jpg" alt="git_crypt_encrypted_file" width=800 >}}

Encrypt and decrypt the file locally with `git-crypt lock/unlock` commands

```plain
❯ git-crypt lock
❯ file git-crypt/api.key
git-crypt/api.key: data
❯ cat git-crypt/file.txt
This is some text

❯ git-crypt unlock /Users/damonguo/Workspace/sshkeys/git-crypt.key
❯ file git-crypt/api.key
git-crypt/api.key: ASCII text
❯ cat git-crypt/api.key
dummy value
```

## References

https://buddy.works/guides/git-crypt
