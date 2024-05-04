---
title: "Golang性能分析工具之pprof采样过程与原理"
subtitle: ""
date: 2024-03-24T15:41:04+08:00
lastmod: 2024-03-24T15:41:04+08:00
draft: false
author: "PanJM"
authorLink: "https://github.com/pjimming/"
description: ""
license: ""
images: []

tags: [golang, pprof, 性能优化]
categories: [golang]

featuredImage: "https://www.jsdelivr.ren/gh/pjimming/picx-images-hosting@master/20240324/image-image.1set04apdx.webp"
featuredImagePreview: "https://www.jsdelivr.ren/gh/pjimming/picx-images-hosting@master/20240324/image-image.1set04apdx.webp"

outdatedInfoWarning: true
---

简单介绍一下 pprof 工具的采样过程以及原理

<!--more-->

---

## CPU

- 采样对象：函数调用和它们的占用时间
- 采样率：100 次/秒，固定值
- 采样时间：从手动开始到手动结束

采样时，进程每秒会暂停 100 次，每次暂停会记录当前的调用栈信息，汇总之后根据调用栈在采样中出现的次数来推断程序的运行时间。

![CPU采样步骤](https://www.jsdelivr.ren/gh/pjimming/picx-images-hosting@master/20240324/image-image.3uulo6g7nl.webp)

1. 操作系统：由进程注册的定时器，每 10ms 向进程发送一次 SIGPROF 信号
2. 进程：每次收到 SIGPROF 信号会记录调用堆栈
3. 写缓冲：启动一个 goroutine，每 100ms 读取已经记录的调用栈并写入输入流
4. 采样停止时，进程向 OS 取消定时器，不再接受信号，写缓冲读取不到新的堆栈信息时，结束输出

![CPU采样流程](https://www.jsdelivr.ren/gh/pjimming/picx-images-hosting@master/20240324/image-image.39ky1vr3hn.webp)

## Heap - 堆内存

提到的内存的概念说的都是**堆内存**，而非内存，因为 pprof 的采样有局限性。

在实现上依赖于内存分配器的记录，所有它只记录在堆上的分配，并且会参与 GC 的内存，一些预分配的内存，例如调用结束就会回收的栈内存、一些更底层使用 cgo 分配的内存等，是不会被内存采样记录的

采样过程如下：

- 采样程序通过内存分配器在堆上分配和释放的内存，记录分配/释放内存的大小和数量
- 采样率：每分配 512KB 记录一次，可在运行的开头进行修改，设为 1 则每次分配都记录
- 采样时间：从程序运行开始到采样时，内存采样是一个持续的过程，会记录从运行开始所有分配或释放的内存大小和对象数量，并在采样时遍历这些结果进行汇总
- 采样指标：`alloc_space`,`alloc_objects`,`inuse_space`,`inuse_objects`
- 计算方式：$inuse = alloc - free$

## Goroutine 协程 & ThreadCreate 线程

- Goroutine：记录所有用户发起且运行中的 goroutine（即入口非 runtime 开头的），以及 main 函数所在的 goroutine 信息和创建这些 goroutine 的调用栈
- ThreadCreate：记录程序创建的所有系统线程的信息

![协程和线程创建的采样流程](https://www.jsdelivr.ren/gh/pjimming/picx-images-hosting@master/20240324/image-image.9gwc22cn2h.webp)

可以发现都是在 STW 之后，遍历所有 goroutine/线程的列表（M 对应 GMP 中的 M，在 Golang 中和线程一一对应）并输出堆栈，最后 Start The World 继续运行。这个采样是立刻触发的全量记录，可以比较两个时间点的差值来得到某一时间段的指标

## Block 阻塞 & Mutex 锁

- 阻塞操作：
  - 采样阻塞操作的次数和耗时
  - 采样率：阻塞耗时超过阈值才会被记录，设置为 1 时表示每次阻塞都会被记录
- 锁竞争：
  - 采样争抢锁的次数和耗时
  - 采样率：只记录固定比例的锁操作，设置为 1 时表示每次加锁均被记录

![阻塞和锁竞争的采样流程](https://www.jsdelivr.ren/gh/pjimming/picx-images-hosting@master/20240324/image-image.sypmzjq7s.webp)

阻塞操作的采样率是一个**阈值**，消耗超过阈值时间的阻塞操作才会被记录。而锁竞争的采样率是一个**比例**，运行时会通过随机数来记录固定比例的锁操作。

实现上都是一个主动上报的过程，在阻塞操作和锁竞争发生时，会计算出消耗时间，连同调用栈一起上报给采样器，采样器会根据采样率丢弃一些数据。采样时，采样器会遍历已经记录的信息，统计出具体操作的次数，调用栈和总耗时。并且可以对比两个时间点的差异值。

## Reference

- [性能优化分析工具](https://juejin.cn/course/bytetech/7140987981803814919/section/7142747721789603848)
