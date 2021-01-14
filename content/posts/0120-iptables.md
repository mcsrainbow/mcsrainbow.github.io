---
title: "共享一个iptables数据转发与端口映射的脚本"
date: "2007-07-17"
tags: ["Linux","iptables"]
categories: ["DevOps"]
---

将商用通设备的80端口转发到后端的Web服务器，并作为网关允许所有内网网段的服务器上网。

<!--more-->

```bash
lan_subnet=192.168.1.0/24
web_addr=192.168.1.20
wan_addr=$(ifconfig eth0 |grep "inet addr" |awk -F: '{print $2}' |awk '{print $1}')
lan_addr=$(ifconfig eth1 |grep "inet addr" |awk -F: '{print $2}' |awk '{print $1}')

iptables -F INPUT
iptables -F FORWARD
iptables -F POSTROUTING -t nat
iptables -A FORWARD -s ${lan_subnet} -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

iptables -t nat -A PREROUTING -d ${wan_addr} -p tcp --dport 80 -j DNAT --to ${web_addr}:80
iptables -t nat -A POSTROUTING -d ${web_addr} -p tcp --dport 80 -j SNAT --to ${lan_addr}
 
iptables -t nat -A POSTROUTING -o eth0 -s ${lan_subnet} -j MASQUERADE

iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT

sysctl -w net.ipv4.ip_forward=1
```

