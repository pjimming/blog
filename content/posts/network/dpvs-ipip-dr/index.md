---
title: "通过IPIP网络隧道实现DPVS的DR模式"
subtitle: ""
date: 2025-01-09T20:13:24+08:00
lastmod: 2025-01-09T20:13:24+08:00
draft: false
author: "PanJM"
authorLink: "https://github.com/pjimming/"
description: ""
license: ""
images: []

tags: [计算机网络, dpvs]
categories: [计算机网络]

featuredImage: "https://cdn.jsdelivr.net/gh/pjimming/picx-images-hosting@master/20250109/image-image.58hgci0kvs.webp"
featuredImagePreview: "https://cdn.jsdelivr.net/gh/pjimming/picx-images-hosting@master/20250109/image-image.58hgci0kvs.webp"

outdatedInfoWarning: true
---

简单介绍一下四层接入中的 DR 模式

<!--more-->

---

## 基础知识

### 1. IPIP 隧道简介

IPIP 隧道是一种简单的点对点隧道协议，通过在原始 IP 数据包上再封装一层 IP 头，将数据包通过隧道传递。它常用于跨地域传输数据，尤其是在负载均衡场景中。

### 2. DR 模式简介

Direct Routing 模式是负载均衡的一种方式，它允许请求流量通过负载均衡器到达后端服务器，但响应流量直接从后端服务器返回给客户端，而不经过负载均衡器。这种模式可以降低负载均衡器的流量压力。

### 3. DPVS 简介

DPVS 基于 DPDK（Data Plane Development Kit）的四层负载均衡器，特点是高性能、低延迟、丰富功能等优势。它特别适合高并发、高吞吐的场景，且对已有的 LVS 配置具有良好的兼容性，同时对于数据包在用户态进行处理，无需通过内核封装。

## 链路图解

![DR模式链路图解](https://cdn.jsdelivr.net/gh/pjimming/picx-images-hosting@master/20250124/image-image.4jo7dhx5bj.webp)

1. 客户端发送一个请求，目的 IP 是 DPVS 集群监听的 VIP
2. DPVS 集群收到了这个请求，将这个请求数据包封装成一个 ipip 数据包（源 IP: LB_IP, 目的 IP: RS_IP, 协议: 4；其中协议：4 表示一个 ipip 数据包），通过负载均衡算法，将这个 ipip 数据包发送给与 dpvs 打通 ipip 隧道的 rs 服务器
3. rs 服务器收到 dpvs 传来的 ipip 数据包，解封后得到原本的数据包，处理请求后，根据源 IP 地址，直接发送 response 到对于的 ip，不需要通过 dpvs 发送，减缓集群压力
