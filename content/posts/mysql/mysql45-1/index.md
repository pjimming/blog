---
title: "《MySQL实战45讲》阅读笔记——基础篇"
subtitle: ""
date: 2024-05-04T14:35:16+08:00
lastmod: 2024-05-04T14:35:16+08:00
draft: true
author: "PanJM"
authorLink: "https://github.com/pjimming/"
description: ""
license: ""
images: []

tags: []
categories: []

featuredImage: "https://www.jsdelivr.ren/gh/pjimming/picx-images-hosting@master/20240504/image-image.4qr4q5cbtf.webp"
featuredImagePreview: "https://www.jsdelivr.ren/gh/pjimming/picx-images-hosting@master/20240504/image-image.4qr4q5cbtf.webp"

outdatedInfoWarning: true
---

关于 MySQL 基础架构、日志系统、事务、索引和锁的相关概念

<!--more-->

---

## 01 | 基础架构：一条 SQL 查询语句是如何执行的？

MySQL 的逻辑架构可分为 Server 层和存储引擎层。

Server 层包括了连接器、分析器、优化器、执行器等，涵盖 MySQL 的大多数核心服务功能，以及所有的内置函数（如日期、时间、数学和加密函数等），所有跨存储引擎的功能都在这一层实现，比如存储过程、触发器、视图等。

而存储引擎层负责数据的存储和提取。其架构模式为插件式，支持 InnoDB、MyISAM、Memory 等多个存储引擎。

![MySQL架构图](https://www.jsdelivr.ren/gh/pjimming/picx-images-hosting@master/20240504/image-image.2yy5v9tyli.webp)

###
