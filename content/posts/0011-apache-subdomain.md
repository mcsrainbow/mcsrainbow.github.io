---
title: "最简单快速的Apache二级域名实现方法"
date: "2007-05-04"
tags: ["Linux","Apache"]
categories: ["DevOps"]
---

首先，你要拥有一个有泛域名解析的顶级域名，例如：`domain.com`，并你的域名控制面板中添加一个范解析`*.domain.com`到你的服务器IP。

<!--more-->

然后，在httpd.conf中打开mod_rewrite模块支持：打开Apache的配置文件httpd.conf，去掉`LoadModule rewrite_module modules/mod_rewrite.so`前面的`#`号；

其次，在 httpd.conf 的最后，添加以下内容：

```bash
RewriteEngine on
RewriteMap lowercase int:tolower
RewriteMap vhost txt:/usr/local/etc/apache/vhost.map #定义映像文件
RewriteCond ${lowercase:%{SERVER_NAME}} ^(.+)$
RewriteCond ${vhost:%1} ^(/.*)$
RewriteRule ^/(.*)$ %1/$1
```

其中的`/usr/local/etc/apache`是你的Apache服务器配置文件所在路径，请根据实际情况更改。

然后，在这个所在路径的目录下创建一个文件：vhost.map，内容为：

```
bbs.domain.com /usr/local/www/data-dist/bbs
anyname.domain.com /usr/local/www/data-dist/anyname
```

以上部分都是：“域名+空格+绝对路径” 的形式。

最后，在你的网站根目录`/usr/local/www/data-dist`下，创建对应目录：bbs，anyname 等等，理论上可以无限。

这样通过访问`bbs.domain.com`实际上访问的就是`/usr/local/www/data-dist/bbs`目录下的文件。

而且，你可以随时更改vhost.map来增加、删除、修改你的二级域名和所指向的实际路径，且不用重启Apache。
