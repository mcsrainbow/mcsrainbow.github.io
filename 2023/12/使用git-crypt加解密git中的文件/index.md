# 使用git-crypt加解密Git中的文件


git-crypt是一个用于加密和解密文件的工具,可以与Git仓库无缝集成,允许用户安全地存储和共享敏感数据。

<!--more-->

## 安装git-crypt

```plain
❯ brew install git-crypt
```

## 初始化git-crypt并备份加密key

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

使用`git-crypt status`命令查看文件的服务端加解密状态
```plain
❯ git-crypt status git-crypt
    encrypted: git-crypt/api.key
not encrypted: git-crypt/file.txt
```

通过`GitLab网页端`查看文件的服务端加解密状态

{{< image src="git_crypt_encrypted_file.jpg" alt="git_crypt_encrypted_file" width=800 >}}

通过`git-crypt lock/unlock`命令对文件`git-crypt/api.key`进行本地加解密

```plain
❯ git-crypt lock
❯ file git-crypt/api.key
git-crypt/api.key: data

❯ git-crypt unlock /Users/damonguo/Workspace/sshkeys/git-crypt.key
❯ file git-crypt/api.key
git-crypt/api.key: ASCII text
❯ cat git-crypt/api.key
dummy value
```

## 参考

https://buddy.works/guides/git-crypt

