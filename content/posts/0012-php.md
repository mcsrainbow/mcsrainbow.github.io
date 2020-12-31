---
title: "Linux服务器优化策略之PHP的加密与加速"
date: "2007-06-30"
tags: ["Linux","eAccelerator","Zend","PHP"]
categories: ["DevOps"]
---

Zend Optimizer是由Zend技术公司所开发的免费PHP优化软件。

<!--more-->

### 1. 安装Zend Optimizer优化PHP程序

据Zend公司透露使用这个软件某些情况下至少可以提高性能30%以上！现在我们来看看如何安装配置这套软件。打开http://www.zend.com/downloads官方网站下载最新的Zend Optimizer。

1.1 执行tar命令解压该刚刚下载的Zend Optimizer

1.2 进入解压后的程序目录，运行安装文件install.sh

1.3 接下来很轻松的按照向导一步步执行

* 阅读许可协议并同意

* 安装向导会要求你确认当前使用的APACHE服务器

* 安装向导会提示您确认php.ini的位置，并提示备份php.ini

* 安装向导会提示你重新启动WEB服务

* 安装完毕后程序会自动根据你的选择来修改php.ini并帮助你启动这个引擎

* 这个时候，你的php执行效率已经得到了优化，且经过zend加密的php程序也可以执行了

### 2. 安装eAccelerator再度优化PHP程序并对其加密
2.1 eAccelerator介绍

2.1.1 背景

eAccelerator 是一个免费开源的PHP加速、优化、编译和动态缓存的项目，它可以通过缓存PHP代码编译后的结果来提高PHP脚本的性能，使得一向很复杂和离我们很远的PHP脚本编译问题完全得到解决。
通过使用eAccelerator，可以优化PHP代码执行速度，降低服务器负载，可以提高PHP应用执行速度最高达10倍。

eAccelerator 项目诞生于2004年，当时它是作为Turck MMCache项目的一个分支提出并投入开发的。Turck MMCache由Dmitry Stogov开发，是个非常优秀的PHP内存缓存加速系统，如今仍然有很大部分 eAccelerator 的代码应用到该项目中，目前该项目有很长时间没有更新了，对于最新的PHP5.x的支持还未推出。

2.1.2 原理

eAccelerator 通过把经过编译后的PHP代码缓存到共享内存中，并在用户访问的时候直接调用从而起到高效的加速作用。它的效率非常高，从创建共享内存到查找编译后的代码都在非常短的时间内完成，对于不能缓存到共享内存中的文件和代码，eAccelerator还可以把他们缓存到系统磁盘上。

eAccelerator 同样还支持PHP代码的编译和解释执行，可以通过encoder.php脚本来对php代码进行编译达到保护代码的目的，经过编译后的代码必须运行在安装了eAccelerator的环境下。eAccelerator编译后的代码不能被反编译，它不象其他一些编译工具那样可以进行反编译，这将使得代码更加安全和高效。

2.2 eAccelerator安装配置

2.2.1 系统要求

```text
php4
php5
autoconf
automake
libtool
m4
```

eAccelerator只支持使用mod_php或者fastcgi mode安装的PHP

2.2.2 安装eAccelerator

先去eAccelerator官方下载最新版的源码包如：eaccelerator-0.9.5-beta.tar.bz2

```bash
tar -zxvf ./eaccelerator-0.9.5-beta2.tar.bz2
cd eaccelerator-0.9.5-beta2
export PHP_PREFIX="/usr/local/php/" #把PHP安装目录导入到环境变量，如产用的/usr/local/php
$PHP_PREFIX/bin/phpize
./configure –enable-eaccelerator=shared –with-php-config=$PHP_PREFIX/bin/php-config
make
make install
```

2.2.3 php.ini文件配置

安装完成，下面开始配置php.ini文件

注：将以下代码加入到[Zend]标签之前，否则不能启动APACHE服务器。

```ini
[eAccelerator]
extension="eaccelerator.so"
eaccelerator.shm_size="16"
eaccelerator.cache_dir="/tmp/eaccelerator"
eaccelerator.enable="1"
eaccelerator.optimizer="1"
eaccelerator.check_mtime="1"
eaccelerator.debug="0"
eaccelerator.log_file="/var/log/httpd/eaccelerator_log"
eaccelerator.filter=""
eaccelerator.shm_max="0"
eaccelerator.shm_ttl="0"
eaccelerator.shm_prune_period="0"
eaccelerator.shm_only="0"
eaccelerator.compress="1"
eaccelerator.compress_level="9"
```

设置中需要注意的是：

* `extension="eaccelerator.so"`这一项中的`eaccelerator.so`应该修改为实际的该文件的绝对路径；
* 接着在`php.ini`中搜寻`extension_dir`，并将`extension_dir = "./"`修改为`extension_dir = "/"`，即修改其为根目录；

2.2.4 完成安装配置后，我们最后要创建缓存目录：

```bash
mkdir /tmp/eaccelerator
chmod 777 /tmp/eaccelerator
```

2.2.5 重启apache使eaccelerator引擎生效

2.2.6 验证安装结果

通过浏览器访问您的`phpinfo()`页面或者运行`php -i`得到php配置信息，里面如果看到类似下面的信息就表示安装成功了。

```text
This program makes use of the Zend Scripting Language Engine:
Zend Engine, Copyright (c) 1998-2006 Zend Technologies with eAccelerator v0.9.5-beta2, Copyright (c) 2004-2006 eAccelerator, by eAccelerator.
```

2.2.7 使用引擎对PHP进行加密

将eaccelerator安装目录下的encoder.php文件提取出来，首先备份准备加密的网站程序怒路，然后用该文件进行加密（如我对/var/www/admincp/这个目录下的所有PHP程序进行加密）；

```bash
$PHP_PREFIX/bin/php encoder.php -rf -sphp /var/www/admincp/  -o /var/www/admincp/
```

好了，一套完整的PHP优化与加密策略完成了！打开你的浏览器，体验其带来的暂新速度体验吧！