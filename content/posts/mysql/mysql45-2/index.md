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

tags: [mysql, mysql实战45讲]
categories: [mysql]

featuredImage: "https://picx-img.pjmcode.top/20240517/image-image.4xud44n5ua.webp"
featuredImagePreview: "https://picx-img.pjmcode.top/20240517/image-image.4xud44n5ua.webp"

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

![带change buffer的更新过程](https://picx-img.pjmcode.top/20240506/image-image.73tra6jw4l.webp)

### 异常重启是否会丢失 change buffer 和数据

不会。事务在 commit 时，会把 change buffer 的操作记录到 redo log 中，因此在崩溃的时候，change buffer 也会找到原来的数据。

## 10 | MySQL 为什么有时候会选错索引？

### 优化器的逻辑

优化器选择索引的标准有：扫描行数、是否使用临时表、是否排序等。

如何判断扫描行数？根据索引的“区分度”去统计大概的扫描行数，区分度称为基数（cardinality），基数越大，区分度越好。

MySQL 提供采样统计来得到索引的基数。由于采样统计，可能就会出现基数不正确的情况。同样优化器也需要考虑回表的代价。

对于使用错误索引，可以参考以下方式：

1. 使用`force index`来强行指定索引。
2. 通过修改语句来引导优化器。
3. 通过增加或者删除索引来绕过问题。

## 11 | 怎么给字符串字段加索引？

1. 直接创建完整索引，但是比较占用空间。
2. 创建前缀索引，节省空间。但是会增加查询扫描次数，并不能使用覆盖索引。
3. 倒序存储，再创建前缀索引，绕过字符串本身前缀区分度不够的问题。
4. 创建 hash 字段索引，查询性能稳定，有额外的存储和计算消耗，不支持范围扫描。

## 12 | 为什么我的 MySQL 会“抖”一下？

1. 一个查询要淘汰的脏页个数太多，会导致查询的响应时间明显边长。
2. 日志写满，更新全部被堵住，写性能跌为 0。

## 13 | 为什么表数据删掉一半，表文件大小不变？

如果使用 delete 是无法收缩表占用空间的。删除的数据只会标注上可复用的标记。需要使用 alter table 命令重建表。同时 Online DDL 的方式可以考虑在业务低峰期使用。

![锁表DDL流程](https://picx-img.pjmcode.top/20240508/image-image.syrf4zgo5.webp)
![Online DDL流程](https://picx-img.pjmcode.top/20240508/image-image.101zakltfr.webp)

- `alter table t engine = InnoDB`（也就是 recreate）；
- `analyze table t` 其实不是重建表，只是对表的索引信息做重新统计，没有修改数据，这个过程中加了 MDL 读锁；
- `optimize table t` 等于 recreate+analyze。

## 14 | count(\*)这么慢，我该怎么办？

InnoDB 获取表记录数量时，会选择扫描行数少的索引，把所有匹配的记录扫描出来。

可以使用额外的存储记录总数，推荐用上 InnoDB 的事务进行计数。

效率排序：$count(字段)<count(pk)<count(1)\approx count(*)$

## 15 | 答疑文章（一）：日志和索引相关问题

### 如何判断 binlog 是否完整

- statement 格式的 binlog，最后会有 commit
- row 格式的 binlog，最后会有 XID event

同时引入 binlog-checksum 验证内容的正确性。

### redo log 和 binlog 如何关联

它们有一个共同的数据字段，叫 XID。崩溃恢复的时候，会按顺序扫描 redo log：

- 如果碰到既有 prepare、又有 commit 的 redo log，就直接提交；
- 如果碰到只有 prepare、而没有 commit 的 redo log，就拿着 XID 去 binlog 找对应的事务。

### 最终数据落盘，来自 redo log 还是 buffer pool

redo log 并没有记录数据页的完整数据，所以它并没有能力自己去更新磁盘数据页

1. 如果是正常运行的实例的话，数据页被修改以后，跟磁盘的数据页不一致，称为脏页。最终数据落盘，就是把内存中的数据页写盘。这个过程，甚至与 redo log 毫无关系。
2. 在崩溃恢复场景中，InnoDB 如果判断到一个数据页可能在崩溃恢复的时候丢失了更新，就会将它读到内存，然后让 redo log 更新内存内容。更新完成后，内存页变成脏页，就回到了第一种情况的状态。

## 16 | “order by”是怎么工作的？

1. 全字段排序：如果 `sort_buffer_size` 满足需要排序的内容大小，则进行全字段排序。
2. rowid 排序：如果不能满足内存排序大小，使用 rowid 排序，但是需要再回到原表去取数据。
3. 覆盖索引排序：根据查询选择特定的索引，由于索引具有有序性，所以不需要进行排序，直接取出数据即可。

## 17 | 如何正确地显示随机消息？

主要思想就是减少数据库的扫描行数。例如先随机出一个 id，找到第一个小于等于该 id 的数据，这样子通过索引只需要扫描一行。还有通过`limit Y,1`需要扫描 Y+1 行。
