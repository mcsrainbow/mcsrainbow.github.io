---
title: "CISCO3560 VLAN配置实例"
date: "2009-11-25"
tags: ["Network","Cisco"]
categories: ["DevOps"]
ShowToc: true
TocOpen: true
---

### 1. 注意事项

* 交换机启动需要大约4-5分钟；

* 网线插入交换机接口从黄变为绿需要大约1-2分钟，即进入正常工作模式；

* 建议使用XP系统进行操作，2003默认没有安装超级终端，需要使用安装光盘添加该工具才有；
* 请严格按照以下步骤进行，背景灰色字体为交换机显示信息，蓝色字体为配置命令。

<!--more-->

### 2. 准备工作

先保持交换机断电状态；

使用调试串口线连接笔记本电脑的串口与交换机背面的CONSOLE接口；

打开超级终端：`开始`-`所有程序`-`附件`-`超级终端`

配置超级终端：

`名称`-`cisco`-选择`com1`或`com2`（请依照实际情况进行选择）-修改每秒位数为`9600`-`应用`-`确定`-`回车`

### 3. 初始配置

给交换机通电，片刻后会看到交换机的启动信息，直到出现以下配置选项：

```text
Would you like to terminate autoinstall? [yes]: no
Would you like to enter the initial configuration dialog? [yes/no]:no
Would you like to terminate autoinstall? [yes]: no
```

### 4. 出现命令窗口

```text
Switch>
```

### 5. 备份出厂配置

```text
Switch> en 进入特权模式
Switch# copy running-config sfbak-config
Destination filename [sfbak-config]? 回车
```

```text
1204 bytes copied in 0.529 secs (2276 bytes/sec)
```


表示文件备份成功。

### 6. 配置账号密码

```text
Switch# configure terminal 进入配置子模式
Switch(config)# enable password cisco 设置password密码为cisco
Switch(config)# enable secret cisco 设置secret密码为cisco
Switch(config)# exit
```

```text
00:11:26: %SYS-5-CONFIG_I: Configured from console by console
```


表示将配置保存到了内存中，在后面的配置过程中会出现类似的信息，属于正常现象。

### 7. 创建VLAN

```text
Switch# show vlan 查看VLAN信息，默认有一个VLAN 1，并且所有端口都属于它
Switch# vlan database 进入VLAN子模式
```

```text
% Warning: It is recommended to configure VLAN from config mode,
as VLAN database mode is being deprecated. Please consult user
documentation for configuring VTP/VLAN in config mode.
```

属于正常的警告信息。

```text
Switch(vlan)# vlan 2 创建VLAN2
```

```text
VLAN 2 added:
Name: VLAN0002
```


表示VLAN创建成功。

```text
Switch(vlan)# vlan 3 创建VLAN3
Switch(vlan)# exit
```

### 8. 为VLAN设置IP地址

为VLAN2设置IP地址

```text
Switch# configure terminal 进入配置子模式
Switch(config)# interface vlan 2 配置IP,VLAN2
Switch(config-if)# ip address 133.37.125.5 255.255.255.0 设置交换机IP（具体IP请依照实际情况设置）
Switch(config-if)# exit
```

为VLAN3设置IP地址

```text
Switch(config)# interface vlan 3 配置IP,VLAN3
Switch(config-if)# ip address 192.168.1.5 255.255.255.0 设置交换机IP（具体IP请依照实际情况设置）
Switch(config-if)# exit
```

### 9. 为VLAN划分交换机接口

配置1-12号电口为VLAN2

```text
Switch(config)# interface range fastEthernet 0/1 – 12 进入F0/1 到 F0/12
Switch(config-if)# switchport mode access 设成静态VLAN访问模式
Switch(config-if)# switchport access vlan 2 将此口分给VLAN2
Switch(config-if)# exit
```

配置13-24号电口为VLAN3

```text
Switch(config)# interface range fastEthernet 0/13 – 24 进入F0/13 到 F0/24
Switch(config-if)# switchport mode access 设成静态VLAN访问模式
Switch(config-if)# switchport access vlan 3 将此口分给VLAN3
Switch(config-if)# exit
```

配置1号光口为VLAN-2

```text
Switch(config)# interface GigabitEthernet 0/1 进入G0/1
Switch(config-if)# switchport mode access 设成静态VLAN访问模式
Switch(config-if)# switchport access vlan 2 将此口分给VLAN2
Switch(config-if)# exit
```

配置2号光口为VLAN-3

```text
Switch(config)# interface GigabitEthernet 0/2 进入G0/2
Switch(config-if)# switchport mode access 设成静态VLAN访问模式
Switch(config-if)# switchport access vlan 3 将此口分给VLAN3
Switch(config-if)# exit
Switch(config)# exit
```

### 10. 关闭VLAN1

```text
Switch# configure terminal 进入配置子模式
Switch(config)# interface vlan 1 配置VLAN1
Switch(config-if)# shutdown 关闭VLAN1
Switch(config-if)# exit
Switch(config)# exit
```

```text
Switch# show interface fastethernet0/1 status 查看F0/1网口状态
Switch# show interface fastethernet0/1 查看F0/1网口详细配置
Switch# show running-config 查看全局配置
```

### 11. 配置默认网关

```text
Switch# configure terminal 进入配置子模式
Switch(config)# ip default-gateway 133.37.125.4
Switch(config)# exit
```

### 12. 设置使可以远程telnet登陆

```text
Switch# configure terminal 进入配置子模式
Switch(config)# line vty 0 4
Switch(config-line)# password cisco
Switch(config-line)# login
Switch(config-line)# exit
Switch(config)# exit
```

### 13.保存当前配置

```text
Switch# copy running-config startup-config
Destination filename [startup-config]? 回车
```

```text
Building configuration…
[OK]
```

表示当前配置保存成功。

### 14.交换机配置情况图示

配置完成，目前整个交换机配置情况如下：

![ciscovlan](/attachments/0911/ciscovlan.jpg)

### 15.其它相关知识

交换机与交换机/路由器间级联通信：

当级联的设备端口设置了trunk或划分了VLAN等情况，可能需要修改级联端口的工作模式为trunk模式才能实现相互之间的通信。

如果是与电口级联，可以修改1号网口为trunk工作模式，使用该接口进行级联：

```text
Switch# configure terminal 进入配置子模式
Switch(config)# interface fastethernet0/1 进入F0/1口
Switch(config-if)# switchport trunk encapsulation dot1q
Switch(config-if)# switchport mode trunk 设成TRUNK口
Switch(config-if)# switchport trunk allowed vlan all 允许所有VLAN从此口通过
Switch(config-if)# exit
Switch(config)# exit
```

如果是与光纤接口级联，可以修改1号光纤接口为trunk工作模式，使用该接口进行级联：

```text
Switch# configure terminal 进入配置子模式
Switch(config)# interface GigabitEthernet 0/1 进入G0/1
Switch(config-if)# switchport trunk encapsulation dot1q
Switch(config-if)# switchport mode trunk 设成TRUNK口
Switch(config-if)# switchport trunk allowed vlan all 允许所有VLAN从此口通过
Switch(config-if)# exit
Switch(config)# exit
```

执行后请按照第13步中的描述保存当前配置。

WEB方式检查交换机状态：

如果需要对交换机的状态进行实施查看，可以通过 URL：http://192.168.1.5 或 http://133.8.5.7

账号：`admin` 密码：`cisco`，登陆后进行查看。

恢复交换机出厂设置：

```text
Switch> en 进入特权模式
Switch# write erase
Erasing the nvram filesystem will remove all configuration files! Continue? [confirm] 回车
```

```text
[OK]
Erase of nvram: complete
00:36:19: %SYS-7-NV_BLOCK_INIT: Initialized the geometry of nvram
```

```text
Switch# reload
Proceed with reload? [confirm] 回车
```

```
00:36:59: %SYS-5-RELOAD: Reload requested by console. Reload Reason: Reload Command.
```

片刻之后，交换机会进行重启，并在重启后恢复为出厂设置。

远程通过telnet登陆交换机终端：

1. 将本机IP设置为与交换机VLAN2或VLAN3同一个网段；

2. `开始`-`运行`-`cmd`

3. 执行`telnet 133.37.125.5`或`telnet 192.168.1.5`即可
