---
title: "2008-8-7工作笔记–LVM磁盘管理"
date: "2008-08-07"
tags: ["Linux"]
categories: ["DevOps"]
---

如何挂载一块从别的机器上取下的做了LVM的硬盘

<!--more-->

```bash
fdisk -l #查看新增的硬盘是否已经被识别
vgscan #扫描LVM卷
vgchange -ay
lvscan #如果正常则会显示出硬盘的LV状态都是 active
mount -t ext3 /dev/VGname/LVname /mnt/lvmdisk/
```

如何将一块新硬盘添加到现有的LVM中，以达到扩容目的

```bash
fdisk -l #查看新增的硬盘是否已经被识别

fdisk /dev/sdb #创建一个新的分区sdb1，并使用t参数标记为8e(即Linux LVM)
n
t
8e

pvcreate #建立物理卷

vgextend VolGroup00 /dev/sdb1 #将新增的屋里卷加入到卷组中去

lvextend -L +800G /dev/VolGroup00/LogVol00 #将新增的80G硬盘的所有空间都加到逻辑卷中去

ext2online /dev/VolGroup00/LogVol00   #激活新增的空间，RHEL4
resize2fs -p /dev/VolGroup00/LogVol00 #激活新增的空间，RHEL5

df -h #此时便可以看到新增的空间了
```

如何删除一个现有的LVM

```bash
umount #所有vg0下的lv
lvremove /dev/vg0/lv0
vgchange -an /dev/vg0 #休眠vg0,-ay是激活
vgremove vg0 #移除vg0
```

如何删除一个现有LVM中的物理卷，以取出新增的硬盘

```
pvmove /dev/sdb1 [sdc1] #转移数据，如果想指定转移的物理卷则在后面输入
pvreduce vg0 /dev/sdb1 #把sdb1从卷组中删除
```

一些常用的LVM管理命令

```
#扩展VG
vgextend vg0 /dev/sdb1

#扩展LV
lvextend -L +10G/dev/vg0/lv0

#查看信息
vgdisplay /dev/vg0
lvdisplay /dev/vg0/lv0

#数据迁移 
pvmove /dev/sdb1 /dev/sdc1
```

**所有命令列表**

```bash
extendfs #扩展一个离线文件系统
lvchange #改变一个逻辑卷的的属性
lvcreate #在卷组中创建一个逻辑卷
lvdisplay #显示逻辑卷的信息
lvextend #增加分配给逻辑卷的物理区域数
lvlnboot #将逻辑卷设为启动，交换或内存映像卷
lvmerge #将以前镜像的卷合并成一个逻辑镜像卷
lvreduce #减少分配给逻辑卷的物理区域数
lvremove #从卷组中删除一个或多个逻辑卷
lvrmboot #删除联接到启动，交换或内存映像卷的逻辑卷
lvsplit #将镜像的逻辑卷分成两个逻辑卷
lvsync #同步在一个或多少失效逻辑卷上的逻辑卷镜像
pvchange #改变卷组中的物理卷的属性
pvcreate #创建一个可以被卷组使用的物理卷
pvdisplay #显示卷组中一个或多个物理卷的信息
pvmove #将分配的物理区域从一个物理卷转移鲐其他物理卷
vgcfgbackup #保存卷组LVM配置
vgcfgrestore #将LVM配置恢复　到卷组
vgchange #开关卷组的一些状态
vgcreate #创建一个卷组
vgdisplay #显示卷组信息
vgextend #通过添加物理卷扩展一个卷组
vgexport #从系统输出一个卷组
vgimport #向系统输入一个卷组
vgscan #扫描卷组的系统物理卷
vgreduce #通过删除一个或多个物理卷减小卷组
vgremove #从系统上删除一个或多个卷组的定义
vgsync #同步在一个或多个失效卷组上的逻辑镜像
```

