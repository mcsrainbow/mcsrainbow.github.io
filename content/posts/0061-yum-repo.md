---
title: "利用DVD安装光盘构建属于自己的RHEL YUM安装源"
date: "2009-05-26"
tags: ["Linux","YUM"]
categories: ["DevOps"]
---

相信大家一定都非常喜欢CentOS上面的yum，安装软件不用考虑那些烦人的软件包依赖关系。

但是我相信大家一定有很多也和我一样仍然喜欢使用正统的RHEL吧，但是目前免费的 RHEL YUM源 真的是很难找，如果用CentOS的源的话，感觉又很别扭。

<!--more-->
那么我们为什么不对自己好点，建立一个自己的RHEL YUM源呢？而且我从一位前辈那里得知，淘宝网的运维就是搭建了一个自己的yum源，然后将所有需要部署的自研软件都花费精力做成了rpm包，这样，每次部署软件的时候，一条yum install 就可以搞定了，听起来很过瘾咯。

整个yum的搭建过程其实非常easy，按照以下步骤就可以很快的完成。

我的环境：

```
cat /etc/redhat-release
```

```
Red Hat Enterprise Linux Server release 5.6 (Tikanga)
```

```
uname -a
```

```
Linux localhost.localdomain 2.6.18-238.el5 #1 SMP Sun Dec 19 14:22:44 EST 2010 x86_64 x86_64 x86_64 GNU/Linux
```

首先，使用rpm安装好以下软件包

yum-3.2.22-33.el5

createrepo-0.4.11-3.el5

vsftpd-2.0.5-16.el5_5.1

一、配置yum源服务端

1. 从DVD光盘中复制软件包

```
mkdir /mnt/cdrom
mount /dev/cdrom /mnt/cdrom
cp -prfa /mnt/cdrom /var/ftp/rhel5.6-x86_64
```

如果是iso文件则执行`mount -o loop rhel-server-5.6-x86_64-dvd.iso /mnt/cdrom`

2. 创建repository信息库

```
cd /var/ftp/rhel5.6-x86_64/Server/
createrepo -g repodata/comps-rhel5-server-core.xml ./

cd ../Cluster/
createrepo -g repodata/comps-rhel5-cluster.xml ./

cd ../ClusterStorage
createrepo -g repodata/comps-rhel5-cluster-st.xml ./

cd ../VT
createrepo -g repodata/comps-rhel5-vt.xml ./
```

3. 配置vsFTPd服务

确认开启了匿名用户访问权限

```
grep anonymous_enable /etc/vsftpd/vsftpd.conf
```

```
anonymous_enable=YES
```

启动vsftp服务

```
/etc/init.d/vsftpd start
```

二、配置yum客户端

1. 创建.repo配置文件（具体IP请根据实际情况进行修改）

```
vim /etc/yum.repos.d/rhel5-rpms-from-dvd.repo
```

```ini
[Cluster]
name=Cluster Directory
baseurl=ftp://192.168.10.129/rhel5.6-x86_64/Cluster
enabled=1
gpgcheck=0

[ClusterStorage]
name=ClusterStorage Directory
baseurl=ftp://192.168.10.129/rhel5.6-x86_64/ClusterStorage
enabled=1
gpgcheck=0

[Server]
name=Server Directory
baseurl=ftp://192.168.10.129/rhel5.6-x86_64/Server
enabled=1
gpgcheck=0

[VT]
name=VT Directory
baseurl=ftp://192.168.10.129/rhel5.6-x86_64/VT
enabled=1
gpgcheck=0
```

2. 清除旧的缓存数据

```
yum clean all
```

3. 软件安装测试

```
yum install unzip
```

```text
Loaded plugins: rhnplugin, security
This system is not registered with RHN.
RHN support will be disabled.
Cluster | 1.1 kB 00:00
Cluster/primary | 5.9 kB 00:00
Cluster 32/32
ClusterStorage | 1.1 kB 00:00
ClusterStorage/primary | 8.4 kB 00:00
ClusterStorage 39/39
Server | 1.1 kB 00:00
Server/primary | 1.1 MB 00:00
Server 3229/3229
VT | 1.1 kB 00:00
VT/primary | 18 kB 00:00
VT 57/57
Setting up Install Process
Package unzip-5.52-3.el5.x86_64 already installed and latest version
Nothing to do
```

证明成功检查出unzip已经被安装，yum源搭建成功。