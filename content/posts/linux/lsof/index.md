---
title: "Linux中lsof的使用介绍"
subtitle: ""
date: 2024-07-23T10:52:20+08:00
lastmod: 2024-07-23T10:52:20+08:00
draft: false
author: "PanJM"
authorLink: "https://github.com/pjimming/"
description: ""
license: ""
images: []

tags: [linux, lsof, 操作系统]
categories: [linux]

featuredImage: "https://cdn.jsdelivr.net/gh/pjimming/picx-images-hosting@master/20240723/image-image.2yy91c2jla.webp"
featuredImagePreview: "https://cdn.jsdelivr.net/gh/pjimming/picx-images-hosting@master/20240723/image-image.2yy91c2jla.webp"

outdatedInfoWarning: true
---

lsof(list open files)是一个查看进程打开的文件的工具。

<!--more-->

---

在 linux 系统中，一切皆文件。通过文件不仅仅可以访问常规数据，还可以访问网络连接和硬件。所以 lsof 命令不仅可以查看进程打开的文件、目录，还可以查看进程监听的端口等 socket 相关的信息。
