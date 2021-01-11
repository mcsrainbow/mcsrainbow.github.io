---
title: "工作笔记—基于本地用户方式的vsFTPd高级设置"
date: "2008-11-06"
tags: ["vsFTPd"]
categories: ["DevOps"]
---

创建一个专用的FTP数据存储目录

<!--more-->

```bash
mkdir /ftpserver
vi /etc/vsftpd/vsftpd.conf
```

设置vsFTPd为standalone工作模式

```bash
listen=YES
tcp_wrappers=YES
```

启用本地用户

```bash
local_enable=YES
```

禁用匿名用户

```bash
anonymous_enable=NO
#anon_upload_enable=YES
#anon_mkdir_write_enable=YES
```

更改FTP默认监听端口21

```bash
Listen_port=5200
```

设置FTP的PASV模式传输端口，以配合防火墙通过PASV模式传输数据

```bash
port_enable=NO
pasv_enable=YES
pasv_min_port=10021
pasv_max_port=10025
```

设置FTP服务器最大的并发连接数,默认值为0，表示不限最大连接数

```bash
max_clients=1000
```

设置每个IP地址最大的并发连接数目，默认值为0，表示不限制

```bash
max_per_ip=10
```

启用锁定主目录用户名单功能

```bash
chroot_list_enable=YES
chroot_list_file=/etc/vsftpd.chroot_list
```

```bash
touch /etc/vsftpd.chroot_list
```

启用特定用户独立配置文件功能

```bash
user_config_dir=/etc/vsftpd/user_config/
```

```bash
mkdir /etc/vsftpd/user_config
```

创建一个FTP用户，将该用户的主目录指向到/ftpserver，并使其不能登陆shell

```bash
useradd jacky -d /ftpserver/jacky -s /sbin/nologin
passwd jacky
```

锁定jacky用户的主目录

```
vi /etc/vsftpd.chroot_list
```

```
jacky
```

创建jacky用户的独立配置文件

```bash
cd /etc/vsftpd/user_config/
vi jacky
```

```bash
##Allow this user download?
#download_enable=YES
##Uncomment this to enable any form of FTP write command,such as "STOR,DELE,RNFR,RNTO,MKD,RMD,APPE,SITE …"
#write_enable=YES
##If you set the "write_enable=YES",but don’t want to allow "rename or delete …"
##You can open "cmds_allowed",and remove the command which you don't allow.
##"delete" = "DELE,RMD"; "rename" = "RNFR,RNTO"; "mkdir" = "MKD"
#cmds_allowed=ABOR,ACCT,ALLO,APPE,CDUP,CWD,DELE,EPRT,EPSV,FEAT,HELP,LIST,MDTM,MKD,MODE,NLST,NOOP,OPTS,PASS,PASV,PORT,PWD,QUIT,REIN,REST,RETR,RMD,RNFR,RNTO,SITE,SIZE,SMNT,STAT,STOR,STOU,STRU,SYST,TYPE,USER,XCUP,XCWD,XMKD,XPWD,XRMD,BYE
##Set the max rate for this user,"Bytes/s".
#local_max_rate=204800
##Set the root directory for this user.
#local_root=
```

使jacky用户仅具有下载、上传和创建目录的权限，而没有删除和重命名的权限

```bash
download_enable=YES
write_enable=YES
cmds_allowed=ABOR,ACCT,ALLO,APPE,CDUP,CWD,EPRT,EPSV,FEAT,HELP,LIST,MDTM,MKD,MODE,NLST,NOOP,OPTS,PASS,PASV,PORT,PWD,QUIT,REIN,REST,RETR,SITE,SIZE,SMNT,STAT,STOR,STOU,STRU,SYST,TYPE,USER,XCUP,XCWD,XMKD,XPWD,XRMD,BYE
```

限制jacky用户的最大下载速度为200KB左右

```
local_max_rate=204800
```

重启vsftpd以使配置生效

```bash
/etc/init.d/vsftpd restart
```

修改防火墙以使FTP通过

```bash
vi /etc/sysconfig/iptables
```

```bash
-A RH-Firewall-1-INPUT -m state --state NEW -m tcp -p tcp --dport 5200 -j ACCEPT
-A RH-Firewall-1-INPUT -m state --state NEW -m tcp -p tcp --dport 10021:10025 -j ACCEPT
```

重启防火墙以使策略生效

```
/etc/init.d/iptables restart
```

OK! The end.

PS（根据实际需要）:

开放root用户的FTP权限

```bash
vi /etc/vsftpd.ftpusers
```

```bash
#root
```

```bash
vi /etc/vsftpd.user_list
```

```bash
#root
```

禁止jacky用户的FTP权限

```bash
vi /etc/vsftpd.ftpusers
```

```bash
jacky
```

```bash
vi /etc/vsftpd.user_list
```

```bash
jacky
```