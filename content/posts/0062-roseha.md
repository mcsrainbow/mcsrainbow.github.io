---
title: "RoseHA for Linux安装与配置"
date: "2009-08-17"
tags: ["Linux","RoseHA"]
categories: ["DevOps"]
---

**一、安装RoseHA**

1. 将光驱挂载到mnt文件夹

<!--more-->

```
su - root
mount /dev/cdrom /mnt
cd /mnt
```

2. 安装ROSEHA

```
sh install.sh
```

3. 检查 /opt/roseha/bin 目录中是否有文件存在

```
cd /opt/roseha/bin
ls
```

4. 执行 NewPass 修改密码（第一次运行需要修改密码）

```
./NewPass
```

按照提示操作

```
User: ha ( 管理员的用户名 )
New password: 密码
Re-enter new password: 重新输入密码
```

**二、配置RoseHA**

1. 配置hosts文件

修改文件/etc/hosts（设置内容请依照实际情况）两边的服务器都需要做相同的设置。

```text
127.0.0.1      localhost
192.168.0.11   serverA
192.168.0.12   serverB
```

设置完毕后重启系统

```
sync
reboot
```

2. 运行 RoseHA 的UI管理界面

```
cd /opt/roseha/bin
./hacon
```

进入控制界面，选择`Connect`，输入刚刚设置的用户名和密码，进入系统

![roseha_011](/attachments/0062/roseha_011.jpg)

出现如下界面则说明连接正常

![roseha_021](/attachments/0062/roseha_021.jpg)

3. 配置licence授权

移动 Tab 键在`HostName`处将本机的主机名和对端主机名填写正确就可以了`OK`。

并且注意，两边机器都需要进行设置。

![roseha_04](/attachments/0062/roseha_04.jpg)

4. 创建socket 私网

进入`PrivateNet` - `Create Socket`, 选择主机用于私网的地址，用来作为两台机器通讯用的IP地址（心跳IP）。

注：该操作在两台主机上都要做。

![roseha_06](/attachments/0062/roseha_06.jpg)

5. 获取对方主机信息

进入 `Tools` - `Network`，直接选中`AutoGet` - `OK`，这样就会得到对方主机信息。

6. 创建Oracle服务

进入`Services` - `Create`，

配置说明：

```text
Service Name: Oracle
Type: ORACLE
SID: 输入Oracle服务的SID
Active Server: 指定哪一台Server为该服务的主机
Standby Server: 指定哪一台Server为该服务的备机
IP Holding NIC: 分别选择两台主机所提供外界服务的网卡设备名，注意不能与心跳网卡在同一个设备上。
Active IP Address: Oracle服务的IP（虚拟IP）地址，必须与上面所选择的网卡的IP在同一网段上。
Active SubnetMask: 虚拟IP的子网掩码。
Agent Script: 相应的监控脚本，ha_ag_oracle.x （保持默认）
Start Script: 相应的启动脚本，ora_start.sh（保持默认）
Stop Script: 相应的停止脚本，ora_stop.sh（保持默认）
Active Volume: 磁盘阵列两台主机共用的文件系统的设备名，这里我们设置为/dev/sda1。
Backup Volume: 通常Active Volume应与Backup Volume的值相同。
Mount Point: 与Active Volume,Backup Volume值所对应的mount 点，这里我们设置为/data。
SwitchBack: NO
```

7. 创建Tomcat服务

进入`Services` - `Create`，

```text
Service Name: Tomcat
Type: USERDEF
Active Server: 指定哪一台Server为该服务的主机
Standby Server: 指定哪一台Server为该服务的备机
IP Holding NIC: 分别选择两台主机所提供外界服务的网卡设备名，不能与心跳网卡在同一个设备上。
Active IP Address: Tomcat服务的IP（虚拟IP）地址，必须与上面所选择的网卡的IP在同一网段上。
Active SubnetMask: 虚拟IP的子网掩码。
Agent Script: 相应的监控脚本，如：ha_ag_tomcat.sh （自定义脚本）
Start Script: 相应的启动脚本，如：tomcat_start.sh（自定义脚本）
Stop Script: 相应的停止脚本，如：tomcat_stop.sh（自定义脚本）
Active Volume: 磁盘阵列两台主机共用的文件系统的设备名，这里我们设置为/dev/sda2
Backup Volume: 通常Active Volume应与Backup Volume的值相同。
Mount Point: 与Active Volume,Backup Volume 值所对应的mount 点，这里我们设置为/tomcat
SwitchBack: NO
```

创建文件tomcat所需的三个脚本，放置在两台Server的/opt/roseha/bin 目录下，并给予执行权限：

监控脚本ha_ag_tomcat.sh：

```bash
#!/bin/sh
# This file: ha_ag_tomcat.sh
# Version: 4.0.2
# Return		0       ok
#           1       error
#
# IMPORTANT NOTE:
# IN COMMENT MEANS THERE ARE SOME VALUES (MUST) NEED TO BE CHANGED
# IN FOLLOWING LINES BEFORE YOU RUN THIS AGENT PROGRAM

if test ! "$1" -o ! "$2"
then
  echo Usage: $0 SERVICENAME CHECKTIME
  exit
fi

HAHOME=`cat /etc/init.d/HAHOME`
export HAHOME
SERVICENAME=$1
CHECKTIME=$2

while test "1"
do
  RETURN=0

  echo "Message: [`date`] ha_ag_tomcat.sh Check <$SERVICENAME>." >> $HAHOME/etc/tomcat_agent.log

  # Check the Tomcat process status

  # Check java Process
  JDK=`ps ax |grep java |grep tomcat|grep -v grep |wc -l`
  if [ $JDK -ne 0 ];
  then
    echo "Message: Tomcat is OK">> $HAOME/etc/tomcat_agent.log
  else
    $HAHOME/bin/apierror.x $SERVICENAME tomcatError
    echo "Error: [`date`] Tomcat is MISS."
    echo "Error: [`date`] Tomcat is MISS." >>$HAHOME/etc/tomcat_agent.log
    RETURN=1
  fi

  # End of Check the Tomcat process

  # Report the result to HA daemon

  if test $CHECKTIME -eq 0
    then
    if test $RETURN -eq 0
      then
      exit 0
    else
      exit 1
    fi
  fi

  if test $RETURN -eq 0
  then
    $HAHOME/bin/APIOK.x $SERVICENAME

    # Clear the tomcat_agent.log
    > $HAHOME/etc/tomcat_agent.log
  fi

  sleep $CHECKTIME
  continue
done
echo $0 exit
```

启动脚本tomcat_start.sh

```bash
#!/bin/sh
# This file: tomcat_start.sh
# Version: 4.0.1

HAHOME=`cat /etc/init.d/HAHOME`
export HAHOME
out=$HAHOME/bin/APIOUT.x
JOBNAME=$2

# When Another Server are Down, You MUST sleep awhile.
# You can change this value to meet your requirement if need.
if [ "$1" = "anotherdown" ]
then
  /bin/sleep 30
fi

#DISKDEV=/dev/sda5
#MOUNTPOINT=/var/lib/mysql
#$HAHOME/bin/dflush $DISKDEV
#fsck -a $DISKDEV
#if test $? -ne 0
#then
#	${out} "[INFO] fsck ${DISKDEV}......"
#	fsck -yf $DISKDEV
#fi
#mount $DISKDEV $MOUNTPOINT
#mount | grep "${DISKDEV} on ${MOUNTPOINT} " >/dev/null 2>&1
#if test $? -ne 0
#then
#      	${out} "[INFO] Cannot mount ${DISKDEV}."
#	exit
#fi

${out} "[INFO] Start Tomcat server...."
export JAVA_HOME=/usr/java/jdk1.5.0_20
export CLASSPATH=.:$CLASSPATH:$JAVA_HOME/lib/:$JAVA_HOME/jre/lib/
export PATH=$PATH:$JAVA_HOME/bin
export JRE_HOME=$JAVA_HOME/jre
/tomcat/bin/catalina.sh start

${out} "[INFO] Start shell <$0> finished."
```

停止脚本tomcat_stop.sh

```bash
#!/bin/sh
# This file: tomcat_stop.sh
# Version: 4.0.1

HAHOME=`cat /etc/init.d/HAHOME`
export HAHOME
out=$HAHOME/bin/APIOUT.x
JOBNAME=$2

#DISKDEV=/dev/sda5
#MOUNTPOINT=/var/lib/mysql

ERRORNUMBER=$3
${out} "[INFO] The service <${JOBNAME}> stop because of {$ERRORNUMBER}."

${out} "[INFO] Stop Tomcat server...."
/tomcat/bin/catalina.sh stop
sync

#$HAHOME/bin/UMOUNT $DISKDEV $MOUNTPOINT
#mount | grep "${DISKDEV} on ${MOUNTPOINT} " >/dev/null 2>&1
#if test $? -eq 0
#then
#	${out} "[WARNING] Cannot umount ${DISKDEV}."
#	/sbin/reboot
#fi

${out} "[INFO] Stop shell <$0> finished."
```

为脚本加上执行权限

```
chmod +x *.sh
```

8. 载入Oracle与Tomcat服务

在Oracle主机上的RoseHA 图形管理工具中

`Services` - `Bring in`  - `Oracle`

在Tomcat主机上的RoseHA图形管理工具中

`Services` - `Bring in` - `Tomcat`

此时，即实现了Oracle与Tomcat的双机双活应用。

**三、维护RoseHA**

1. RoseHA常用命令

查询Roseha进程的命令

```
ps –ef | grep ha
```

可以看到四个进程`hamond`、`hasysd`、`hachkd`、`hasvrd`

停止Roseha：`/opt/roseha/bin/ha_kill ha`

手工启动Roseha进程：`/opt/roseha/bin/hamond`

进入Roseha图形管理工具：`/opt/roseha/bin/hacon`

重启RoseHA服务：

```
/opt/roseha/bin/roseha stop
/opt/roseha/bin/roseha start
```

2. 双机软件的开关机顺序

开机：先后依次开磁盘阵列，主机，备机

关机：先后依次关备机，主机，磁盘阵列

3. 双机软件中的术语

Bring in：把服务带入双机，受双机软件管理

Bring out：把服务带出双机，不受双机软件管理

Take over：手工切换服务。在备机动作，来接管主机服务

Fail over：手工切换服务。在主机动作，来提交主机服务给备机