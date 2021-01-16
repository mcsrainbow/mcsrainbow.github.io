---
title: "Subversion在Linux上的安装与配置"
date: "2010-08-11"
tags: ["Linux","Subversion"]
categories: ["DevOps"]
---

Subversion作为目前最优秀的开源版本控制系统，已经替代CVS成为了使用范围最广的软件。

<!--more-->

关于Subversion的安装与配置也有很多方式，结合Apache、LDAP、MySQL等软件，可以实现更强大的功能。但本文的目的是对Subversion本身独立的安装与配置进行讲解，使大家能够快速的上手，分分钟搞定，真不是什么难事。

1. 安装Subversion

目前各大发行版本都有了Subversion的二进制版本，因此推荐采用该方式进行安装。

RHEL/SELS:

```
rpm -ivh subversion-*
```

CentOS:

```
yum install mod_dav_svn subversion
```

Ubuntu:

```
apt-get install subversion
```

2. 创建Subversion代码库的根目录

```
mkdir -p /data/svn_repo
```

3. 启动Subversion服务

```
svnserve -d -T -r /data/svn_repo
```

将Subversion服务设置为开机自启动

```
echo “svnserve -d -T -r /data/svn_repo” >> /etc/rc.local
```

4. 创建project1代码库

```
svnadmin create /data/svn_repo/project1
```

5.配置project1代码库基础配置文件

注意：每一行的配置前后都不要留空格。

```
cd /data/svn_repo/project1/conf
vim svnserve.conf
```

```ini
[general]
anon-access = none
auth-access = write
password-db = passwd
authz-db = authz
```

6. 配置project1代码库的用户账号

```
vim passwd
```

```ini
[users]
jack = imjack
tom = tomhere
mary = marygirl
mick = micklee
```

7. 配置project1代码库的用户组以及目录访问权限

```
vim authz
```

```ini
[groups]
g_manager = jack
g_coder = tom
g_hr = mary
g_vip = jack,tom,mary

[project1:/]
@g_manager = rw
* = r

[project1:/code]
@g_manager = rw
@g_coder = rw
@g_vip = rw
* =

[project1:/code/source]
@g_manager = rw
@g_coder = rw
* =

[project1:/hr]
@g_manager = rw
@g_hr = rw
* =

[project1:/temp]
* = rw
```

相关注解如下：

以上配置文件中的权限设置如下，具体内容请根据实际情况进行设置

```text
project1 /管理层（可读写）其他（可读）
|— /code 管理层、程序员、特殊权限组（可读写）其他（无权限）
| |— /code/source 管理层、程序员（可读写）其他（无权限）
|— /hr 管理层、人力资源组（可读写）其他（无权限）
|— /temp 所有人（可读写）
```

8. 使project1代码库的authz文件支持中文

将配置文件authz转换成`不包含BOM的UTF-8格式`之后，Subversion就能够正确识别文件中的中文字符了，可以转换的工具软件有Notepad++与UltraEdit。

9. Subversion客户端的使用

在Windows平台上推荐使用TortoiseSVN作为客户端。

在安装好该客户端软件以后，执行`SVN检出`project1代码库（假设服务器IP为192.168.10.4）：`svn://192.168.10.4/project1`

在提示框中输入用户名与密码，即可上传与下载代码及文件了。
