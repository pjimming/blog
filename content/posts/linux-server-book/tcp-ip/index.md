---
title: "《Linux高性能服务器编程》阅读笔记--第一篇 TCP/IP协议详解"
subtitle: ""
date: 2024-10-23T23:52:37+08:00
lastmod: 2024-10-23T23:52:37+08:00
draft: true
author: "PanJM"
authorLink: "https://github.com/pjimming/"
description: ""
license: ""
images: []

tags: [linux, network, Linux高性能服务器编程]
categories: [Linux高性能服务器编程]

featuredImage: "https://cdn.jsdelivr.net/gh/pjimming/picx-images-hosting@master/20241023/image-image.9dcyl5v03f.webp"
featuredImagePreview: "https://cdn.jsdelivr.net/gh/pjimming/picx-images-hosting@master/20241023/image-image.9dcyl5v03f.webp"

outdatedInfoWarning: true
---

<!--more-->

---

## ARP 协议

实现任意网络层地址到任意物理地址的转换；工作原理是：主机向自己所在的网络广播一个 ARP 请求，该请求包含目标主机的网络地址，每个主机都会收到这个请求，但是只有被请求的目标机器会回应这个 ARP 应答，其中包含自己的物理地址。
