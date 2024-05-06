---
title: "《MySQL实战45讲》阅读笔记——实践篇（一）"
subtitle: ""
date: 2024-05-06T13:18:31+08:00
lastmod: 2024-05-06T13:18:31+08:00
draft: false
author: "PanJM"
authorLink: "https://github.com/pjimming/"
description: ""
license: ""
images: []

tags: []
categories: []

featuredImage: "https://www.jsdelivr.ren/gh/pjimming/picx-images-hosting@master/20240504/image-image.8s347bmo8x.webp"
featuredImagePreview: "https://www.jsdelivr.ren/gh/pjimming/picx-images-hosting@master/20240504/image-image.8s347bmo8x.webp"

outdatedInfoWarning: true
---

《MySQL 实战 45 讲》第 9 章至第 17 章的笔记

<!--more-->

---

## 09 | 普通索引和唯一索引，应该怎么选择？

### Change Buffer

当需要更新一个数据页时，如果数据页在内存中就直接更新，而如果这个数据页还没有在内存中的话，在不影响数据一致性的前提下，InnoDB 会将这些更新操作缓存在 change buffer 中，这样就不需要从磁盘中读入这个数据页了。在下次查询需要访问这个数据页的时候，将数据页读入内存，然后执行 change buffer 中与这个页有关的操作。通过这种方式就能保证这个数据逻辑的正确性。

将 change buffer 中的操作应用到原数据页，得到最新结果的过程称为 merge。除了访问这个数据页会触发 merge 外，系统有后台线程会定期 merge。在数据库正常关闭（shutdown）的过程中，也会执行 merge 操作。

如果能够将更新操作先记录在 change buffer，减少读磁盘，语句的执行速度会得到明显的提升。而且，数据读入内存是需要占用 buffer pool 的，所以这种方式还能够避免占用内存，提高内存利用率。

同时 change buffer 用的是 buffer pool 里的内容，因此不能无限增大。可以通过参数 `innodb_change_buffer_max_size` 来动态设置。这个参数设置为 50 的时候，表示 change buffer 的大小最多只能占用 buffer pool 的 50%。

### 唯一索引不需要使用 Change Buffer

对于唯一索引，每次更新需要判断是否违反唯一性约束。因此需要将磁盘的内容读入到内存中，直接在内存中更新显然效率更高，就不需要使用 change buffer 了。

因此只有普通索引才可以使用 change buffer。

### 数据不在内存中时，两个索引的新增操作表现

- 对于唯一索引来说，需要将数据页读入到内存中，判断是否违反了唯一性约束，插入值，语句结束。
- 对于普通索引来说，在 change buffer 中记录一条数据，语句结束。

将数据从磁盘读入内存涉及随机 IO 的访问，是数据库里面成本最高的操作之一。change buffer 因为减少了随机磁盘访问，所以对更新性能的提升是会很明显的。

### change buffer 的使用场景

change buffer 的作用就是将记录的变更操作缓存起来，因此缓存的记录越多，收益越大。

- 对于写多读少的业务，比如账单类、日志类的系统，change buffer 可以提供非常好的效果。
- 对于写入之后需要马上查询的业务，写入 change buffer 后会立即触发 merge 操作，随机访问的 IO 操作不会减少，还会增加 change buffer 的维护代价，因此会起到反作用。

### redo log 和 change buffer

redo log 主要节省随机写磁盘的 IO 消耗（转为顺序写）；change buffer 主要节省随机读磁盘的 IO 消耗。

![带change buffer的更新过程](https://www.jsdelivr.ren/gh/pjimming/picx-images-hosting@master/20240506/image-image.73tra6jw4l.webp)

## 10 | MySQL 为什么有时候会选错索引？

### 优化器的逻辑
