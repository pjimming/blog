---
title: "《MySQL实战45讲》阅读笔记——实践篇（二）"
subtitle: ""
date: 2024-05-17T14:07:36+08:00
lastmod: 2024-05-17T14:07:36+08:00
draft: false
author: "PanJM"
authorLink: "https://github.com/pjimming/"
description: ""
license: ""
images: []

tags: [mysql, mysql实战45讲]
categories: [mysql]

featuredImage: "https://cdn.jsdelivr.net/gh/pjimming/picx-images-hosting@master/20240517/image-image.54xkzk6rwi.webp"
featuredImagePreview: "https://cdn.jsdelivr.net/gh/pjimming/picx-images-hosting@master/20240517/image-image.54xkzk6rwi.webp"

outdatedInfoWarning: true
---

《MySQL 实战 45 讲》第 18 章至第 26 章的笔记

<!--more-->

---

## 18 ｜ 为什么这些 SQL 语句逻辑相同，性能却差异巨大

- 条件字段函数操作：在语句中使用了函数，不走索引。
- 隐式数据转换：类型不一致，索引失效。
- 隐式字符集转换：编码格式不同，会导致索引失效。

## 19 ｜ 为什么我只差一行的语句，也执行这么慢

1. 长时间不返回
   - 等 MDL 锁
   - 等 flush
   - 等行锁
2. 查询慢
   - 其他事务阻塞查询
