---
title: "What are Private IP Addresses"
slug: "what-are-private-ip-addresses"
date: 2023-03-29T20:41:35+08:00
author: "Damon"
description: "In the Internet addressing architecture, the Internet Engineering Task Force (IETF) and the Internet Assigned Numbers Authority (IANA) have reserved various IP addresses for special purposes."
categories: ["Skills"]
tags: ["Network"]
resources:
- name: "featured-image"
  src: "featured-image.jpeg"

toc: false
lightgallery: true
---

In the Internet addressing architecture, the Internet Engineering Task Force (IETF) and the Internet Assigned Numbers Authority (IANA) have reserved various IP addresses for special purposes.

<!--more-->

---

## Misunderstandings about Private IP Addresses

The concepts of internal and external IP addresses are not fixed, but relative. It's easier to understand them as private and public IP addresses or local area network and internet IP addresses.

Almost all textbooks tell us that there are three types of private IP addresses:

+  Class A: 10.0.0.0 - 10.255.255.255
+  Class B: 172.16.0.0 - 172.31.255.255
+  Class C: 192.168.0.0 - 192.168.255.255

But in fact, private IP addresses are more than these. From the Wikipedia page [Reserved IP addresses](https://en.wikipedia.org/wiki/Reserved_IP_addresses), in the Internet addressing architecture, the Internet Engineering Task Force (IETF) and the Internet Assigned Numbers Authority (IANA) have reserved various IP addresses for special purposes.

## List of Reserved IPv4 Addresses

The IPv4 addresses are shown below:


| Address block CIDR | Address range                 | Number of addresses | Scope           | Description             |
| ------------------ | ----------------------------- | ------------------- | --------------- | ----------------------- |
| 0.0.0.0/8          | 0.0.0.0 – 0.255.255.255       | 16,777,216          | Software        | Current network |
| 10.0.0.0/8         | 10.0.0.0 – 10.255.255.255     | 16,777,216          | Private network | Used for local communications within a private network |
| 100.64.0.0/10      | 100.64.0.0 – 100.127.255.255  | 4,194,304           | Private network | Shared address space for communications between a service provider and its subscribers when using a carrier-grade NAT |
| 127.0.0.0/8        | 127.0.0.0 – 127.255.255.255   | 16,777,216          | Host            | Used for loopback addresses to the local host |
| 169.254.0.0/16     | 169.254.0.0 – 169.254.255.255 | 65,536              | Subnet          | Used for link-local addresses[5] between two hosts on a single link when no IP address is otherwise specified, such as would have normally been retrieved from a DHCP server |
| 172.16.0.0/12      | 172.16.0.0 – 172.31.255.255   | 1,048,576           | Private network | Used for local communications within a private network |
| 192.0.0.0/24       | 192.0.0.0 – 192.0.0.255       | 256                 | Private network | IETF Protocol Assignments |
| 192.0.2.0/24       | 192.0.2.0 – 192.0.2.255       | 256                 | Documentation   | Assigned as TEST-NET-1, documentation and examples |
| 192.31.196.0/24    | 192.31.196.0 - 192.31.196.255 | 256                 | Private network | AS112-v4 |
| 192.52.193.0/24    | 192.52.193.0 - 192.52.193.255 | 256                 | Private network | AMT |
| 192.88.99.0/24     | 192.88.99.0 – 192.88.99.255   | 256                 | Internet        | Deprecated (6to4 Relay Anycast) |
| 192.168.0.0/16     | 192.168.0.0 – 192.168.255.255 | 65,536              | Private network | Used for local communications within a private network |
| 192.175.48.0/24    | 192.175.48.0 - 192.175.48.255 | 256                 | Private network | Direct Delegation AS112 Service |
| 198.18.0.0/15      | 198.18.0.0 – 198.19.255.255   | 131,072             | Private network | Used for benchmark testing of inter-network communications between two separate subnets |
| 198.51.100.0/24    | 198.51.100.0 – 198.51.100.255 | 256                 | Documentation   | Assigned as TEST-NET-2, documentation and examples |
| 203.0.113.0/24     | 203.0.113.0 – 203.0.113.255   | 256                 | Documentation   | Assigned as TEST-NET-3, documentation and examples |
| 240.0.0.0/4        | 240.0.0.0 – 255.255.255.254   | 268,435,455         | Internet        | Reserved for future use |
| 255.255.255.255/32 | 255.255.255.255               | 1                   | Subnet          | Reserved for the "limited broadcast" destination address |

## References

https://en.wikipedia.org/wiki/Reserved_IP_addresses  
https://www.iana.org/assignments/iana-ipv4-special-registry/iana-ipv4-special-registry.xhtml  
