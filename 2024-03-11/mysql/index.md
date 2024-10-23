# 面试题精选--MySQL篇


总结一些常考的 MySQL 面试题，相关资料皆从网络上收集

<!--more-->

---

## 事物

### 事物的四大特性

事物的四大特性：原子性、一致性、隔离性、持久性，简称 ACID

- 原子性：事物是最小的执行单位，不允许分割。要么全都执行，要么全都不执行
- 一致性：执⾏事务前后，数据保持⼀致，多个事务对同⼀个数据读取的结果是相同的
- 隔离性：并发访问数据库时，一个用户的事物不被其他事物所干扰，各并发事物之间数据库是独立的
- 持久性：一个事物被提交后，对于数据库的改变是持久的，即使数据库发生故障也不应该对其有任何影响

实现保证：MySQL 的存储引擎 InnoDB 使用重做日志保证一致性与持久性，回滚日志保证原子性，使用各种锁来保证隔离性。

### 事物的隔离级别

- 读未提交：最低的隔离级别，允许读取尚未提交的数据变更，可能会导致脏读、幻读或不可重复读。
- 读已提交：允许读取并发事务已经提交的数据，可以阻⽌脏读，但是幻读或不可重复读仍有可能发⽣。
- 可重复读：同⼀字段的多次读取结果都是⼀致的，除⾮数据是被本身事务⾃⼰所修改，可以阻⽌脏读和不可重复读，会有幻读。
- 串行化：最⾼的隔离级别，完全服从 ACID 的隔离级别。所有的事务依次逐个执⾏，这样事务之间就完全不可能产⽣⼲扰。

| 隔离级别 |            并发问题            |
| :------: | :----------------------------: |
| 读未提交 | 可能导致脏读、幻读或不可重复读 |
| 读已提交 |    可能导致幻读或不可重复读    |
| 可重复读 |          可能导致幻读          |
|  串行化  |          不会产生干扰          |

### 什么是脏读、不可重复读和幻读

#### 脏读

脏读（Dirty Read）是指一个事务读取了另一个未提交的事务所写入的数据。

假设有两个事务 T1 和 T2，T1 在读取某个数据之后，T2 修改了该数据但尚未提交，如果 T1 再次读取该数据，就会读取到 T2 修改后的“脏数据”，因为 T2 的修改最终可能被回滚，导致读取到的数据不正确。

![](https://cdn.jsdelivr.net/gh/pjimming/picx-images-hosting@master/image.3nrda66ljv.webp)

#### 不可重复读

不可重复读（Non-repeatable Read）是指一个事务在相同的查询条件下多次读取同一行数据时，得到的结果不一致。

假设事务 T1 执行了一次查询并读取了某行数据，然后事务 T2 修改了该行数据并提交，如果 T1 再次执行相同的查询，得到的结果就可能与之前不同。

![](https://cdn.jsdelivr.net/gh/pjimming/picx-images-hosting@master/image.5c0q7d95ts.webp)

#### 幻读

幻读（Phantom Read）是指一个事务在相同的查询条件下多次执行查询，得到的结果集不一致。

假设事务 T1 执行了一次查询并返回了一些行数据，然后事务 T2 在这些行数据中插入了新的数据并提交，如果 T1 再次执行相同的查询，得到的结果集就可能与之前不同。

![](https://cdn.jsdelivr.net/gh/pjimming/picx-images-hosting@master/image.99t3o1koao.webp)

### 默认隔离级别-RR

MySQL 默认的隔离级别为可重复读，即：同⼀字段的多次读取结果都是⼀致的，除⾮数据是被本身事务⾃⼰所修改；

可重复读是有可能出现幻读的，如果要保证绝对的安全只能把隔离级别设置成 `SERIALIZABLE`；这样所有事务都只能顺序执行，自然不会因为并发有什么影响了，但是性能会下降许多。

第二种方式，针对快照读（普通 `select` 语句），是通过 MVCC 方式解决了幻读，因为可重复读隔离级别下，事务执行过程中看到的数据，一直跟这个事务启动时看到的数据是一致的，即使中途有其他事务插入了一条数据，是查询不出来这条数据的，所以就很好了避免幻读问题。

```sql
select id
from table_xx
where id = ?
  and version = Vupdate;
select id
from table_xx
where id = ?
  and version = V + 1;
```

第三种方式，针对当前读（`select ... for update` 等语句），是通过 `next-key lock`（记录锁+间隙锁）方式解决了幻读，因为当执行 `select ... for update` 语句的时候，会加上 `next-key lock`，如果有其他事务在 `next-key lock` 锁范围内插入了一条记录，那么这个插入语句就会被阻塞，无法成功插入，所以就很好了避免幻读问题。

```sql
select id
from table_xx
where id > 100 for
update;
select id
from table_xx
where id > 100 lock in share mode;
```

### RR 和 RC 使用场景

事务隔离级别 RC(read commit)和 RR（repeatable read）两种事务隔离级别基于多版本并发控制 MVCC(multi-version concurrency control）来实现。

「读提交」隔离级别是在每个 `select` 都会生成一个新的 Read View，也意味着，事务期间的多次读取同一条数据，前后两次读的数据可能会出现不一致，因为可能这期间另外一个事务修改了该记录，并提交了事务。

「可重复读」隔离级别是启动事务时生成一个 Read View，然后整个事务期间都在用这个 Read View，这样就保证了在事务期间读到的数据都是事务启动前的记录。

|        | RC                                       | RR                         |
| ------ | ---------------------------------------- | -------------------------- |
| 实现   | 多个 `select` 会创建多个不同的 Read View | 仅需要一个版本的 Read View |
| 粒度   | 语句级读一致性                           | 事物级读一致性             |
| 准确性 | 每次语句执行时间点的数据                 | 第一条语句执行时间点的数据 |

### 行锁，表锁，意向锁

InnoDB ⽀持⾏级锁(row-level locking)和表级锁，默认为⾏级锁

InnoDB 按照不同的分类的锁：

- 共享/排它锁(Shared and Exclusive Locks)：行级别锁，
- 意向锁(Intention Locks)，表级别锁
- 间隙锁(Gap Locks)，锁定一个区间
- 记录锁(Record Locks)，锁定一个行记录

#### 表级锁：（串行化）

Mysql 中锁定**粒度最大**的一种锁，对当前操作的整张表加锁，实现简单，资源消耗也比较少，加锁快，不会出现死锁。其锁定粒度最大，触发锁冲突的概率最高，并发度最低，MyISAM 和 InnoDB 引擎都支持表级锁。

#### 行级锁：（RR、RC）

Mysql 中锁定**粒度最小**的一种锁，只针对当前操作的行进行加锁。行级锁能大大减少数据库操作的冲突。其加锁粒度最小，并发度高，但加锁的开销也最大，加锁慢，会出现死锁。InnoDB 支持的行级锁，包括如下几种：

- 记录锁（Record Lock）: 对索引项加锁，锁定符合条件的行。其他事务不能修改和删除加锁项；
- 间隙锁（Gap Lock）: 对索引项之间的“间隙”加锁，锁定记录的范围，不包含索引项本身，其他事务不能在锁范围内插入数据。
- Next-key Lock： 锁定索引项本身和索引范围。即 Record Lock 和 Gap Lock 的结合。可解决幻读问题。

  InnoDB 支持多粒度锁（multiple granularity locking），它允许行级锁与表级锁共存，而意向锁就是其中的一种表锁。

- 共享锁（ shared lock, S ）锁允许持有锁读取行的事务。加锁时将自己和子节点全加 S 锁，父节点直到表头全加 IS 锁
- 排他锁（ exclusive lock， X ）锁允许持有锁修改行的事务。 加锁时将自己和子节点全加 X 锁，父节点直到表头全加 IX 锁
- 意向共享锁（intention shared lock, IS）：事务有意向对表中的某些行加共享锁（S 锁）
- 意向排他锁（intention exclusive lock, IX）：事务有意向对表中的某些行加排他锁（X 锁）

|   互斥性   | 共享锁（S） | 排他锁（X） | 意向共享锁（IS） | 意向排他锁（IX） |
| :--------: | :---------: | :---------: | :--------------: | :--------------: |
|   共享锁   |     ✅      |     ❌      |        ✅        |        ❌        |
|   排他锁   |     ❌      |     ❌      |        ❌        |        ❌        |
| 意向共享锁 |     ✅      |     ❌      |        ✅        |        ✅        |
| 意向排他锁 |     ❌      |     ❌      |        ✅        |        ✅        |

### MVCC 多版本并发控制

MVCC 是一种多版本并发控制机制，通过事务的可见性看到自己预期的数据，能降低其系统开销。（RC 和 RR 级别工作）

InnoDB 的 MVCC,是通过在每行记录后面保存系统版本号(可以理解为事务的 ID)，每开始一个新的事务，系统版本号就会自动递增，事务开始时刻的系统版本号会作为事务的 ID。这样可以确保事务读取的行，要么是在事务开始前已经存在的，要么是事务自身插入或者修改过的，防止幻读的产生。

1. MVCC 手段只适用于 Msyql 隔离级别中的读已提交（Read committed）和可重复读（Repeatable Read）.
2. Read uncimmitted 由于存在脏读，即能读到未提交事务的数据行，所以不适用 MVCC.
3. 简单的 select 快照度不会加锁，删改及 `select for update` 等需要当前读的场景会加锁

原因是 MVCC 的创建版本和删除版本只要在事务提交后才会产生。客观上，mysql 使用的是乐观锁的一整实现方式，就是每行都有版本号，保存时根据版本号决定是否成功。Innodb 的 MVCC 使用到的快照存储在 Undo 日志中，该日志通过回滚指针把一个数据行所有快照连接起来。

在 InnoDB 引擎表中，它的聚簇索引记录中有两个必要的隐藏列：

- trx_id：这个 id 用来存储的每次对某条聚簇索引记录进行修改的时候的事务 id。
- roll_pointer：每次对哪条聚簇索引记录有修改的时候，都会把老版本写入 undo 日志中。这个 roll_pointer 就是存了一个指针，它指向这条聚簇索引记录的上一个版本的位置，通过它来获得上一个版本的记录信息。(注意插入操作的 undo 日志没有这个属性，因为它没有老版本)

#### Read View：

![](https://cdn.jsdelivr.net/gh/pjimming/picx-images-hosting@master/image.5c0q7f8meb.webp)

Read View 有四个重要的字段：

- `m_ids` ：指的是在创建 Read View 时，当前数据库中「活跃事务」的事务 id 列表，注意是一个列表，“活跃事务”指的就是，启动了但还没提交的事务。
- `min_trx_id` ：指的是在创建 Read View 时，当前数据库中「活跃事务」中事务 id 最小的事务，也就是 m_ids 的最小值。
- `max_trx_id` ：这个并不是 m_ids 的最大值，而是创建 Read View 时当前数据库中应该给下一个事务的 id 值，也就是全局事务中最大的事务 id 值 + 1；
- `creator_trx_id` ：指的是创建该 Read View 的事务的事务 id。

每次修改都会在版本链中记录。SELECT 可以去版本链中拿记录，这就实现了读-写，写-读的并发执行，提升了系统的性能。

#### trx_id：

![](https://cdn.jsdelivr.net/gh/pjimming/picx-images-hosting@master/image.7p3commubs.webp)

一个事务去访问记录的时候，除了自己的更新记录总是可见之外，还有这几种情况：

- 如果记录的 trx_id 值小于 Read View 中的 min_trx_id 值，表示这个版本的记录是在创建 Read View 前已经提交的事务生成的，所以该版本的记录对当前事务可见。
- 如果记录的 trx_id 值大于等于 Read View 中的 max_trx_id 值，表示这个版本的记录是在创建 Read View 后才启动的事务生成的，所以该版本的记录对当前事务不可见。
- 如果记录的 trx_id 值在 Read View 的 min_trx_id 和 max_trx_id 之间，需要判断 trx_id 是否在 m_ids 列表中：
  - 如果记录的 trx_id 在 m_ids 列表中，表示生成该版本记录的活跃事务依然活跃着（还没提交事务），所以该版本的记录对当前事务不可见。
  - 如果记录的 trx_id 不在 m_ids 列表中，表示生成该版本记录的活跃事务已经被提交，所以该版本的记录对当前事务可见。

## 索引

### Innodb 和 Myisam 引擎

**Myisam**：支持表锁，适合读密集的场景，不支持外键，不支持事务，索引与数据在不同的文件

**Innodb**：支持行、表锁，默认为行锁，适合并发场景，支持外键，支持事务，索引与数据同一文件

### 哈希索引

哈希索引用索引列的值计算该值的 hashCode，然后在 hashCode 相应的位置存执该值所在行数据的物理位置，因为使用散列算法，因此访问速度非常快，但是一个值只能对应一个 hashCode，而且是散列的分布方式，因此哈希索引不支持范围查找和排序的功能。

### B+树索引

优点：

B+树的磁盘读写代价低，更少的查询次数，查询效率更加稳定，有利于对数据库的扫描

B+树是 B 树的升级版，B+树只有叶节点存放数据，其余节点用来索引。索引节点可以全部加入内存，增加查询效率，叶子节点可以做双向链表，从而提高范围查找的效率，增加的索引的范围。

在大规模数据存储的时候，红黑树往往出现由于树的深度过大而造成磁盘 I/O 读写过于频繁，进而导致效率低下的情况。所以，只要我们通过某种较好的树结构减少树的结构尽量减少树的高度，B 树与 B+树可以有多个子女，从几十到上千，可以降低树的高度。

磁盘预读原理：将一个节点的大小设为等于一个页，这样每个节点只需要一次 I/O 就可以完全载入。为了达到这个目的，在实际实现 B-Tree 还需要使用如下技巧：每次新建节点时，直接申请一个页的空间，这样就保证一个节点物理上也存储在一个页里，加之计算机存储分配都是按页对齐的，就实现了一个 node 只需一次 I/O。

### 创建索引

```sql
CREATE [UNIQUE | FULLTEXT] INDEX 索引名 ON 表名(字段名) [USING 索引方法];
```

说明：

- UNIQUE：可选。表示索引为唯一性索引。
- FULLTEXT：可选。表示索引为全文索引。
- INDEX 和 KEY：用于指定字段为索引，两者选择其中之一就可以了，作用是一样的。
- 索引名：可选。给创建的索引取一个新名称。
- 字段名：指定索引对应的字段的名称，该字段必须是前面定义好的字段。
- 索引方法：默认使用 B+TREE。

### 聚簇索引和非聚簇索引

聚簇索引：将数据存储与索引放到了一块，索引结构的叶子节点保存了行数据（主键索引）

非聚簇索引：将数据与索引分开存储，索引结构的叶子节点指向了数据对应的位置（辅助索引）

聚簇索引的叶子节点就是数据节点，而非聚簇索引的叶子节点仍然是索引节点，只不过有指向对应数据块的指针。

### 最左前缀问题

最左前缀原则主要使用在联合索引中，联合索引的 B+Tree 是按照第一个关键字进行索引排列的。

联合索引的底层是一颗 B+树，只不过联合索引的 B+树节点中存储的是键值。由于构建一棵 B+树只能根据一个值来确定索引关系，所以数据库依赖联合索引最左的字段来构建。

采用>、<等进行匹配都会导致后面的列无法走索引，因为通过以上方式匹配到的数据是不可知的。

## SQL 查询

### SQL 语句执行过程

查询语句：

```sql
select * from student  A where A.age='18' and A.name='张三';
```

![](https://cdn.jsdelivr.net/gh/pjimming/picx-images-hosting@master/image.2a4u67odm9.webp)

结合上面的说明，我们分析下这个语句的执行流程：

1. 通过客户端/服务器通信协议与 MySQL 建立连接。并查询是否有权限
1. Mysql8.0 之前开看是否开启缓存，开启了 Query Cache 且命中完全相同的 SQL 语句，则将查询结果直接返回给客户端；
1. 由解析器进行语法语义解析，并生成解析树。如查询是 select、表名 tb_student、条件是 id='1'
1. 查询优化器生成执行计划。根据索引看看是否可以优化
1. 查询执行引擎执行 SQL 语句，根据存储引擎类型，得到查询结果。若开启了 Query Cache，则缓存，否则直接返回。

### 回表查询和覆盖索引

普通索引（唯一索引+联合索引+全文索引）需要扫描两遍索引树

1. 先通过普通索引定位到主键值 `id=5`；
1. 在通过聚集索引定位到行记录；

这就是所谓的回表查询，先定位主键值，再定位行记录，它的性能较扫一遍索引树更低。

覆盖索引：主键索引==聚簇索引==覆盖索引

如果 where 条件的列和返回的数据在一个索引中，那么不需要回查表，那么就叫覆盖索引。

实现覆盖索引：常见的方法是，将被查询的字段，建立到联合索引里去。

### Explain 及优化

[Explain 结果每个字段的含义说明](https://www.jianshu.com/p/8fab76bbf448)

#### 索引优化：

1. 最左前缀索引：`like` 只用于`'string%'`，语句中的`=`和 `in` 会动态调整顺序
1. 唯一索引：唯一键区分度在 0.1 以上
1. 无法使用索引：`!=`、`is null`、 `or`、`><`、（5.7 以后根据数量自动判定）`in`、`not in`
1. 联合索引：避免 `select *` ，查询列使用覆盖索引

```sql
# 创建联合覆盖索引，避免回表查询
ALTER TABLE user
    add index idx_gid_ctime_uid (gid, ctime, uid);
SELECT uid
From user
Where gid = 2
order by ctime asc
limit 10;
```

#### 语句优化：

1. `char` 固定长度查询效率高，`varchar` 第一个字节记录数据长度
1. 应该针对 `Explain` 中 `Rows` 增加索引
1. `group/order by` 字段均会涉及索引
1. `Limit` 中分页查询会随着 `start` 值增大而变缓慢，通过**子查询+表连接**解决

   ```sql
   select *
   from mytbl
   order by id
   limit 100000,10;
   # 改进后的 SQL 语句如下：
   select *
   from mytbl
   where id >= (select id from mytbl order by id limit 100000,1)
   limit 10;
   select *
   from mytbl inner ori join (select id from mytbl order by id limit 100000,10) as tmp
   on tmp.id=ori.id;
   ```

1. `count` 会进行全表扫描，如果估算可以使用 `explain`
1. `delete` 删除表时会增加大量 `undo` 和 `redo` 日志， 确定删除可使用 `trancate`

#### 表结构优化：

1. 单库不超过 200 张表
1. 单表不超过 500w 数据
1. 单表不超过 40 列
1. 单表索引不超过 5 个

#### 数据库范式 ：

1. 第一范式（1NF）列不可分割
1. 第二范式（2NF）属性完全依赖于主键 [ 消除部分子函数依赖 ]
1. 第三范式（3NF）属性不依赖于其它非主属性 [ 消除传递依赖 ]

#### 配置优化：

配置连接数、禁用 Swap、增加内存、升级 SSD 硬盘

### JOIN 查询

![](https://cdn.jsdelivr.net/gh/pjimming/picx-images-hosting@master/image.3ye73f862e.webp)

`left join`(左联接) 返回包括左表中的所有记录和右表中关联字段相等的记录

`right join`(右联接) 返回包括右表中的所有记录和左表中关联字段相等的记录

`inner join`(等值连接) 只返回两个表中关联字段相等的行

## 集群

### 主从复制过程

#### MySQl 主从复制：

原理：将主服务器的 binlog 日志复制到从服务器上执行一遍，达到主从数据的一致状态。

过程：从库开启一个 I/O 线程，向主库请求 Binlog 日志。主节点开启一个 binlog dump 线程，检查自己的二进制日志，并发送给从节点；从库将接收到的数据保存到中继日志（Relay log）中，另外开启一个 SQL 线程，把 Relay 中的操作在自身机器上执行一遍

优点：

- 作为备用数据库，并且不影响业务
- 可做读写分离，一个写库，一个或多个读库，在不同的服务器上，充分发挥服务器和数据库的性能，但要保证数据的一致性

#### binlog 记录格式：statement、row、mixed

基于语句 statement 的复制、基于行 row 的复制、基于语句和行（mix）的复制。其中基于 row 的复制方式更能保证主从库数据的一致性，但日志量较大，在设置时考虑磁盘的空间问题。

### 数据一致性问题

"主从复制有延时"，这个延时期间读取从库，可能读到不一致的数据。

#### 缓存记录写 key 法：

在 cache 里记录哪些记录发生过的写请求，来路由读主库还是读从库

#### 异步复制：

在异步复制中，主库执行完操作后，写入 binlog 日志后，就返回客户端，这一动作就结束了，并不会验证从库有没有收到，完不完整，所以这样可能会造成数据的不一致。

#### 半同步复制：

当主库每提交一个事务后，不会立即返回，而是等待其中一个从库接收到 Binlog 并成功写入 Relay-log 中才返回客户端，通过一份在主库的 Binlog，另一份在其中一个从库的 Relay-log，可以保证了数据的安全性和一致性。

#### 全同步复制：

指当主库执行完一个事务，所有的从库都执行了该事务才返回给客户端。因为需要等待所有从库执行完该事务才能返回，所以全同步复制的性能必然会收到严重的影响。
