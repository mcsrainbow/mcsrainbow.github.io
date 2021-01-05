---
title: "Linux下自动启动和关闭Oracle数据库"
date: "2008-09-01"
tags: ["Oracle"]
categories: ["DevOps"]
---

自动启动oracle9i

<!--more-->

在/home/oracle下建立文件StartOra.sh

```bash
vi StartOra.sh
```

```bash
echo “Begin to start the oracle!”
lsnrctl start
sqlplus /nolog < connect /as sysdba
startup
exit
EOF
echo “Oracle just have been started!”
exit
```

给StartOra.sh执行权限

```bash
chmod a+x StartOra.sh
```

自动关闭oracle9i

在/oracle下建立文件StopOra.sh

```bash
vi StopOra.sh
```

```bash
echo “Begin to stop the oracle!”
sqlplus /nolog < connect /as sysdba
shutdown immediate
exit
EOF
lsnrctl stop
echo “Oracle just have been stopped!”
exit
```

给StopOra.sh执行权限

```bash
chmod a+x StopOra.sh
```

将启动和关闭oracle脚本加到系统的开机自启动

```bash
vi /etc/rc.local
su – oracle -c “/home/oracle/StartOra.sh” ＃启动oracle
```

后续：其实这个脚本并不是最好的，最好的解决方案是通过调用Oracle自带的dbstart和dbshut来实现。