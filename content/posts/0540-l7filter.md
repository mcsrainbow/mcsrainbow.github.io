---
title: "安装L7filter使iptables支持对七层应用进行过滤"
date: "2008-11-28"
tags: ["Linux","iptables","L7-filter","Network"]
categories: ["DevOps"]
---

重新编译内核，使iptables支持L7filter，对七层应用进行过滤。

<!--more-->

iptables对于七层上面的应用过滤本身不支持，需要安装第三方的模块方可支持。L7-filter是一个iptables的外挂模块，它可以过滤很多种的L7协议，这样能够封杀如P2P、IM等应用。

1. **适用编译环境**

操作系统：`RedHat Enterprise Linux AS4 U4`以上且带有GCC编译工具

2. **软件下载**

```text
kernel 2.6.25: http://www.kernel.org/pub/linux/kernel/v2.6/linux-2.6.25.tar.bz2
iptables: http://www.netfilter.org/projects/iptables/files/iptables-1.4.0.tar.bz2
l7-filter: http://sourceforge.net/projects/l7-filter
netfilter-layer7-v2.20.tar.gz
l7-protocols-2008-04-23.tar.gz
```

3. **给内核打L7-filter补丁**

将以上各软件包都解压到 /usr/src 目录

```bash
cd /usr/src
tar xzvf netfilter-layer7-v2.20.tar.gz
tar xjvf linux-2.6.25.tar.bz2
cd linux-2.6.25
patch -p1 < /usr/src/netfilter-layer7-v2.20/kernel-2.6.25-layer7-2.20.patch
```

4. **编译内核**

使用make oldconfig可以继承老的kernel的配置，为自己的配置省去很多麻烦

```
make oldconfig
```

`make menuconfig`是文字界面下推荐一种方式，在这里可以选择你需要编译到核心的模块

```
make menuconfig
```

因为前面make oldconfig已经很多都继承老的配置，所以一般配置不要动。

有两项需要注意：

第一项：在我的版本里面默认就是选上的

```text
General setup -> features ->
Prompt for development and/or incomplete code/drivers
```

第二项：选择iptables里面关于L7filter的

里面有很多的选项，推荐将其全部选择

```text
Networking -> Networking options ->
— Network packet filtering framework (Netfilter)
[ ] Network packet filtering debugging

Advanced netfilter configuration>

Bridged IP/ARP packets filtering->
Core Netfilter Configuration ->
IP: Netfilter Configuration ->
Bridge: Netfilter Configuration ->
```

```text
Core Netfilter Configuration ->
```

该项必须选择，其它项可根据需要选择，不过同样推荐将其全部选择

```text
IP: Netfilter Configuration ->
IP tables support (required for filtering/masq/NAT)
```

```bash
make
make modules
make modules_install
make install
```

修改默认以新的内核启动

```
vi /boot/grub/grub.conf
```

```
default=0
```

将新的内核配置文件复制到/boot目录

```
cp /usr/src/linux-2.6.25/.config /boot/config-2.6.25
```

重启服务器

```
reboot
```

重启完成后确认内核版本是否正确

```
uname –r
```

```
2.6.25
```

5. **给iptables打补丁并升级**

卸载系统中的旧版本iptables

```
rpm -qa |grep iptables
rpm -e –nodeps iptables1.x.x
```

打补丁并升级

```bash
cd /usr/src
tar xjvf iptables-1.4.0.tar.bz2

tar xzvf netfilter-layer7-v2.20.tar.gz
cd iptables-1.4.0
patch p1 < /usr/src/netfilter-layer7-v2.20/iptables-1.4-for-kernel-2.6.20forward-layer7-2.20.patch

chmod +x extensions/ .layer7-test
export KERNEL_DIR=/usr/src/linux-2.6.25
export IPTABLES_DIR=/usr/src/iptables-1.4.0
make BINDIR=/sbin LIBDIR=/lib MANDIR=/usr/share/man install
```

确认版本

```
iptables -V
```

```
iptables v1.4.0
```

6. **安装l7-protocol**

```bash
cd /usr/src/
tar xzvf l7-protocols-2008-11-23.tar.gz
cd l7-protocols-2008-11-23
make install
```

其实就是把相应的目录copy到 /etc/l7-protocols/

真正调用的是/etc/l7-protocols/protocols/下面的文件

可以打开下面具体的文件，里面是一些L7程序特征码的正则表达式形式

这样自己也可以按照这样的样子，写自己的特征码

该特征码软件包一直在不停的更新，其后面的日期就是更新的日期，推荐定期选择最新的包进行更新

7. **测试**

```bash
iptables -I FORWARD -p udp --dport 53 -m string --string "tencent" --algo bm -j DROP
iptables -I FORWARD -p tcp -m multiport --dport 80,443 -m layer7 --l7proto qq -j DROP
iptables -I FORWARD -p udp --dport 8000 -j DROP
iptables -I FORWARD -p tcp -m layer7 --l7proto socks -j DROP
iptables -I FORWARD -p udp --dport 53 -m string --string "messenger" --algo bm -j DROP
iptables -I FORWARD -p tcp -m multiport --dport 80,443 -m layer7 --l7proto msnmessenger -j DROP
iptables -I FORWARD -p udp --dport 1863 -j DROP
iptables -t mangle -A PREROUTING -m layer7 --l7proto qq -j DROP
iptables -t mangle -A PREROUTING -m layer7 --l7proto msnmessenger -j DROP
```

可通过上面的策略表达式测试是否成功禁止掉qq和msn

**附注：**

使用-j MARK 参数与TC搭配：http://cha.homeip.net/blog/archives/2005/07/cbqinit.html

`lsmod`可以查看当前加载的模块

`modprobe`可以加载模块

与iptables相关的模块在下面两个目录：`/lib/modules/2.6.25/kernel/net/netfilter/`和`/lib/modules/2.6.25/kernel/net/ipv4/netfilter/`

**相关网址：**

下载与说明：http://l7-filter.sourceforge.net/HOWTO#Get

支持协议：http://l7-filter.sourceforge.net/protocols

**其它：**

```text
Application Layer Packet Classifier for Linux

L7-filter Supported Protocols

Netfilter Packet Traversal
```

**流程图：**

![nfk-traversal](/attachments/0540/nfk-traversal.png)