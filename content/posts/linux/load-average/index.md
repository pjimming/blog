---
title: "Linux系统中Load Average的二三事"
subtitle: ""
date: 2024-03-03T20:04:20+08:00
lastmod: 2024-03-03T20:04:20+08:00
draft: false
author: "PanJM"
authorLink: "https://github.com/pjimming/"
description: ""
license: ""
images: []

tags: [linux,运维]
categories: [linux]

featuredImage: "featured-image.png"
featuredImagePreview: "featured-image.png"

---
介绍Linux中平均负载的相关概念

<!--more-->

---

## 什么是Load Average
系统负载（System Load）是系统CPU繁忙程度的度量，即有多少进程在等待被CPU调度（进程等待队列的长度）。

平均负载（Load Average）是一段时间内系统的平均负载，这个一段时间一般取1分钟、5分钟、15分钟。

即，Linux系统对当前CPU工作量的度量。

## 如何查看Load Average

`uptime`、`top`、`w`皆可查看系统负载。

```bash
➜  ~ w
 20:11:32 up 14:11,  0 users,  load average: 0.00, 0.01, 0.00
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
➜  ~ uptime
 20:11:36 up 14:11,  0 users,  load average: 0.00, 0.01, 0.00
➜  ~ top
top - 20:11:41 up 14:11,  0 users,  load average: 0.00, 0.01, 0.00
Tasks:  27 total,   1 running,  26 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.0 us,  0.0 sy,  0.0 ni,100.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
MiB Mem :   7626.3 total,   5361.5 free,    781.8 used,   1483.0 buff/cache
MiB Swap:   2048.0 total,   2048.0 free,      0.0 used.   6549.0 avail Mem

  PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
    1 root      20   0    2456   1612   1500 S   0.0   0.0   0:00.52 init(Ubuntu-20.
    4 root      20   0    2556    288    196 S   0.0   0.0   0:43.55 init
 9164 root      20   0    2464    112      0 S   0.0   0.0   0:00.00 SessionLeader
 9165 root      20   0    2480    120      0 S   0.0   0.0   0:00.06 Relay(9166)
 9166 pjm       20   0    2616    596    528 S   0.0   0.0   0:00.01 sh
 9167 pjm       20   0    2616    600    528 S   0.0   0.0   0:00.00 sh
 9192 pjm       20   0    2616    596    528 S   0.0   0.0   0:00.00 sh
 9254 pjm       20   0  962848 103232  42044 S   0.0   1.3   0:37.84 node
 9274 pjm       20   0  739296  74784  38820 S   0.0   1.0   0:59.74 node
 9310 pjm       20   0  851080  58720  38612 S   0.0   0.8   0:07.65 node
 9343 pjm       20   0 1012872 154420  43844 S   0.0   2.0   7:31.38 node
 9367 pjm       20   0  625704  72716  38576 S   0.0   0.9   0:10.73 node
 9524 pjm       20   0   12692   6724   4524 S   0.0   0.1   0:00.28 zsh
 9657 pjm       20   0   15628   7524   5148 S   0.0   0.1   0:00.63 zsh
16458 root      20   0    2464    112      0 S   0.0   0.0   0:00.00 SessionLeader
16459 root      20   0    2480    120      0 S   0.0   0.0   0:00.07 Relay(16460)
16460 pjm       20   0   16348   8152   5364 S   0.0   0.1   0:00.60 zsh
19286 root      20   0    2484    112      0 S   0.0   0.0   0:00.00 SessionLeader
19287 root      20   0    2500    124      0 S   0.0   0.0   0:01.37 Relay(19288)
19288 pjm       20   0  602504  56584  37424 S   0.0   0.7   0:05.53 node
19298 root      20   0    2484    112      0 S   0.0   0.0   0:00.00 SessionLeader
19299 root      20   0    2500    124      0 S   0.0   0.0   0:00.54 Relay(19300)
19300 pjm       20   0  601480  52768  37308 S   0.0   0.7   0:02.34 node
➜  ~  
```

## Load Average 值的含义
### 1. 单核处理器

假设我们的系统是单CPU单内核的，把它比喻成是一条单向马路，把CPU任务比作汽车。

- 当车不多的时候，load < 1；
- 当车占满整个马路的时候 load = 1；
- 当马路都站满了，而且马路外还堆满了汽车的时候，load > 1。

### 2. 多核处理器

我们经常会发现服务器Load > 1但是运行仍然不错，那是因为服务器是多核处理器(Multi-core)。

假设我们服务器CPU是2核，那么将意味我们拥有2条马路，我们的Load = 2时，所有马路都跑满车辆。

注：查看cpu 核数命令： 
```bash
➜  ~ grep 'model name' /proc/cpuinfo | wc -l
16
```

## 对于不同 Load Average 值，哪些值得警惕？(单核)
- **Load < 0.7**：系统很闲，马路上没什么车，要考虑多部署一些服务
- **0.7 < Load < 1**：系统状态不错，马路可以轻松应对
- **Load == 1**：系统马上要处理不多来了，赶紧找一下原因
- **Load > 1**：马路已经非常繁忙了，进入马路的每辆汽车都要无法很快的运行

## 三种 Load Average 情况分析（单核）
##### 1分钟Load>1，5分钟Load<1，15分钟Load<1
短期内繁忙，中长期空闲，初步判断是一个“抖动”，或者是“拥塞前兆”
##### 1分钟Load>1，5分钟Load>1，15分钟Load<1
短期内繁忙，中期内紧张，很可能是一个“拥塞的开始”
##### 1分钟Load>1，5分钟Load>1，15分钟Load>1
短、中、长期都繁忙，系统“正在拥塞”
##### 1分钟Load<1，5分钟Load>1，15分钟Load>1
短期内空闲，中、长期繁忙，不用紧张，系统“拥塞正在好转”