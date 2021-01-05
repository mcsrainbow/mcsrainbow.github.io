---
title: "在Apache的日志中记录访问者的IP信息"
date: "2008-02-29"
tags: ["Apache"]
categories: ["DevOps"]
---

关于Apache 的 access.log 日志中记录访问的 client IP 解决方法入如下：

<!--more-->

Apache的httpd.conf中要修改LogFormt：

```bash
LogFormat "%{X-Forwarded-For}i %h %l %u %o %t \"%r\" %>s \"%{Referer}i\" \"%{User-Agent}i\"" combined
```


要把默认的`%h`改成`%{X-Forwarded-For}i`

得到的日志如下：

```bash
10.10.10.37 192.168.1.89 – – – [30/May/2006:21:41:27 +0800] "GET /index.htm HTTP/1.1" 304 "-" "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1)"
```

或这种格式：

```bash
10.10.10.37 – – [30/May/2006:21:31:07 +0800] "GET /index.htm HTTP/1.1" 200 107 "-" "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1)"
192.168.1.89 – – – [30/May/2006:21:31:07 +0800] "GET /index.htm HTTP/1.1" 200 "-" "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1)"
```



