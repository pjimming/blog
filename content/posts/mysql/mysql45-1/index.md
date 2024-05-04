---
title: "《MySQL实战45讲》阅读笔记——基础篇"
subtitle: ""
date: 2024-05-04T14:35:16+08:00
lastmod: 2024-05-04T14:35:16+08:00
draft: false
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

### 连接器

主要工作负责与客户端连接。通过认证之后根据权限表得到拥有的权限，之后的操作权限判定都会依靠此时获取的权限信息。

对于长连接内存占用太大的问题，原因是 MySQL 在执行过程中临时使用的内存是管理在连接对象里的。这些资源会在连接断开的时候才释放。解决方案：

1. 定期断开长连接。使用一段时间，或者程序里面判断执行过一个占用内存的大查询后，断开连接，之后要查询再重连。
2. 如果使用 MySQL 5.7 或以上版本，可以在每次执行一个比较大的操作后，通过执行 `mysql_reset_connection` 来重新初始化连接资源。这个过程不需要重连和重新做权限验证，但是会将连接恢复到刚刚创建完时的状态。

### 分析器

工作是对 SQL 语句做一个“词法分析”，识别字符串。识别完成之后做“语法分析”，根据语法规则判断是否符合 MySQL 语法。

### 优化器

经过分析器的处理，已经知道了要做什么操作。在执行之前，需要对操作进行优化。优化器是在表里面有多个索引的时候，决定使用哪个索引；或者在一个语句有多表关联（join）的时候，决定各个表的连接顺序

### 执行器

MySQL 通过分析器知道了你要做什么，通过优化器知道了该怎么做，于是就进入了执行器阶段，开始执行语句。执行步骤如下：

1. 判断是否拥有权限，若没有，则返回权限错误。
2. 根据表的引擎去调用引擎提供的接口。

## 02 | 日志系统：一条 SQL 更新语句是如何执行的？

MySQL 重要的日志模块有 redo log 和 binlog。

redo log 用于保证 **crash-safe** 能力。`innodb_flush_log_at_trx_commit` 这个参数设置成 1 的时候，表示每次事务的 redo log 都直接持久化到磁盘。这个参数设置成 1，这样可以保证 MySQL 异常重启之后数据不丢失。

`sync_binlog` 这个参数设置成 1 的时候，表示每次事务的 binlog 都持久化到磁盘。这个参数设置成 1，这样可以保证 MySQL 异常重启之后 binlog 不丢失。

### redo log

该日志模块的关键点在于 WAL（Write Ahead Logging），即先写日志，再写磁盘。避免了更新时找到对应日志记录，修改相关数据，最后再写入磁盘所花费的 I/O 代价。InnoDB 会在**合适**的时候将 redo log 上的记录更新到磁盘中。

![redo log示意图](https://fastly.jsdelivr.net/gh/pjimming/picx-images-hosting@master/20240504/image-image.2krq4obq86.webp)
write pos 是当前记录的位置，一边写一边后移，写到第 3 号文件末尾后就回到 0 号文件开头。checkpoint 是当前要擦除的位置，也是往后推移并且循环的，擦除记录前要把记录更新到数据文件。

write pos 和 checkpoint 之间的是 redo log 上还空着的部分，可以用来记录新的操作。如果 write pos 追上 checkpoint，表示 redo log 满了，这时候不能再执行新的更新，得停下来先擦掉一些记录，把 checkpoint 推进一下。

有了 redo log，InnoDB 就可以保证即使数据库发生异常重启，之前提交的记录都不会丢失，这个能力称为 **crash-safe**。

### binlog

redo log 是 InnoDB 自带的日志系统，而 Server 层的日志模块是 binlog。

它们之间的区别如下：

1. redo log 是 InnoDB 引擎特有的；binlog 是 MySQL 的 Server 层实现的，所有引擎都可以使用。
2. redo log 是物理日志，记录的是“在某个数据页上做了什么修改”；binlog 是逻辑日志，记录的是这个语句的原始逻辑，比如“给 ID=2 这一行的 c 字段加 1 ”。
3. redo log 是循环写的，空间固定会用完；binlog 是可以追加写入的。“追加写”是指 binlog 文件写到一定大小后会切换到下一个，并不会覆盖以前的日志。

执行器和 InnoDB 引擎在执行`update T set c=c+1 where ID=2;`语句时的内部流程。

1. 执行器先找引擎取 ID=2 这一行。ID 是主键，引擎直接用树搜索找到这一行。如果 ID=2 这一行所在的数据页本来就在内存中，就直接返回给执行器；否则，需要先从磁盘读入内存，然后再返回。
2. 执行器拿到引擎给的行数据，把这个值加上 1，比如原来是 N，现在就是 N+1，得到新的一行数据，再调用引擎接口写入这行新数据。
3. 引擎将这行新数据更新到内存中，同时将这个更新操作记录到 redo log 里面，此时 redo log 处于 prepare 状态。然后告知执行器执行完成了，随时可以提交事务。
4. 执行器生成这个操作的 binlog，并把 binlog 写入磁盘。
5. 执行器调用引擎的提交事务接口，引擎把刚刚写入的 redo log 改成提交（commit）状态，更新完成。

update 语句的执行流程图，图中浅色框表示是在 InnoDB 内部执行的，深色框表示是在执行器中执行的。

![update语句执行流程](https://fastly.jsdelivr.net/gh/pjimming/picx-images-hosting@master/20240504/image-image.3d4lmfh9b7.webp)

### 两阶段提交

上图可以注意到，在 redo log 中，存在 prepare 和 commit 两个阶段。两阶段提交就是让 redo log 和 binlog 这两个状态保持逻辑上的一致。

## 03 | 事务隔离：为什么你改了我还看不见？
