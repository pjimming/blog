---
title: "【毕业季】本科毕设《Magic Camera》需求清单"
subtitle: ""
date: 2024-04-05T11:04:16+08:00
lastmod: 2024-04-05T11:04:16+08:00
draft: false
author: "PanJM"
authorLink: "https://github.com/pjimming/"
description: ""
license: ""
images: []

tags: [blog, 毕业设计]
categories: [blog]

featuredImage: "https://cdn.jsdelivr.net/gh/pjimming/picx-images-hosting@master/20240405/image-image.1lbllk4u06.webp"
featuredImagePreview: "https://cdn.jsdelivr.net/gh/pjimming/picx-images-hosting@master/20240405/image-image.1lbllk4u06.webp"

outdatedInfoWarning: false
---

记录本科毕设的需求、进度

<!--more-->

---

{{<admonition info "目前进度">}}

数据库

- [x] 设计数据库

后端服务

- [x] 登录/注册
- [ ] 权限模块
- [ ] 角色管理
- [ ] 资源树管理

前端页面

- [x] 登录/注册
- [ ] 角色管理页面
- [ ] 资源管理页面
- [ ] 用户管理页面

运维相关

- [ ] CI/CD
- [ ] Nginx 部署
- [x] MySQL 部署
- [x] Redis 部署
- [ ] 监控
- [ ] 日志

{{</admonition>}}

## 数据库设计

单体服务，采用 mysql 作为底层数据库，使用 redis 做缓存数据库。

### 权限模块

通过 RBAC 模型的方式，基于角色控制资源权限，表字段设计如下：

#### 角色表

| 字段名     | 类型            | NULL | Key | Default           | Extra                                         |
| :--------- | :-------------- | :--- | :-- | :---------------- | :-------------------------------------------- |
| id         | bigint unsigned | NO   | PRI | null              | auto_increment                                |
| created_at | datetime        | NO   |     | CURRENT_TIMESTAMP | DEFAULT_GENERATED                             |
| updated_at | datetime        | NO   |     | CURRENT_TIMESTAMP | DEFAULT_GENERATED on update CURRENT_TIMESTAMP |
| deleted_at | datetime        | YES  |     | null              |                                               |
| code       | varchar\(255\)  | NO   | UNI |                   |                                               |
| name       | varchar\(255\)  | NO   | UNI |                   |                                               |
| is_enable  | tinyint\(1\)    | NO   |     | 0                 |                                               |

建表语句：

```sql
DROP TABLE IF EXISTS `role`;
CREATE TABLE `role`
(
    `id`         bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '序号',
    `created_at` datetime        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` datetime        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted_at` datetime        NULL     DEFAULT NULL COMMENT '删除时间',
    `code`       varchar(255)    NOT NULL DEFAULT '' UNIQUE COMMENT '角色编码',
    `name`       varchar(255)    NOT NULL DEFAULT '' UNIQUE COMMENT '角色名',
    `is_enable`  bool            NOT NULL DEFAULT FALSE COMMENT '启用状态:0-禁用;1-启用',
    PRIMARY KEY (`id`)
) ENGINE = INNODB
  DEFAULT CHARSET = UTF8 COMMENT '角色表';
```

#### 资源表

| 字段名     | 类型            | Null | Key | Default           | Extra                                         |
| :--------- | :-------------- | :--- | :-- | :---------------- | :-------------------------------------------- |
| id         | bigint unsigned | NO   | PRI | null              | auto_increment                                |
| created_at | datetime        | NO   |     | CURRENT_TIMESTAMP | DEFAULT_GENERATED                             |
| updated_at | datetime        | NO   |     | CURRENT_TIMESTAMP | DEFAULT_GENERATED on update CURRENT_TIMESTAMP |
| deleted_at | datetime        | YES  |     | null              |                                               |
| name       | varchar\(255\)  | NO   |     |                   |                                               |
| code       | varchar\(255\)  | NO   |     |                   |                                               |
| type       | varchar\(255\)  | NO   |     |                   |                                               |
| parent_id  | bigint unsigned | NO   |     | 0                 |                                               |
| order      | int             | NO   |     | 0                 |                                               |
| icon       | varchar\(512\)  | NO   |     |                   |                                               |
| component  | varchar\(512\)  | NO   |     |                   |                                               |
| path       | varchar\(512\)  | NO   |     |                   |                                               |
| is_show    | tinyint\(1\)    | NO   |     | 0                 |                                               |
| is_enable  | tinyint\(1\)    | NO   |     | 0                 |                                               |

建表语句：

```sql
DROP TABLE IF EXISTS `resource`;
CREATE TABLE `resource`
(
    `id`         bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '序号',
    `created_at` datetime        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` datetime        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted_at` datetime        NULL     DEFAULT NULL COMMENT '删除时间',
    `name`       varchar(255)    NOT NULL DEFAULT '' COMMENT '名称',
    `code`       varchar(255)    NOT NULL DEFAULT '' COMMENT '编码',
    `type`       varchar(255)    NOT NULL DEFAULT '' COMMENT '类型',
    `parent_id`  bigint unsigned NOT NULL DEFAULT 0 COMMENT '父节点id',
    `order`      int(10)         NOT NULL DEFAULT 0 COMMENT '排序',
    `icon`       varchar(512)    NOT NULL DEFAULT '' COMMENT '菜单图标',
    `component`  varchar(512)    NOT NULL DEFAULT '' COMMENT '组件路径',
    `path`       varchar(512)    NOT NULL DEFAULT '' COMMENT '路由地址',
    `is_show`    boolean         NOT NULL DEFAULT FALSE COMMENT '是否显示',
    `is_enable`  boolean         NOT NULL DEFAULT FALSE COMMENT '是否启用',
    PRIMARY KEY (`id`)
) ENGINE = INNODB
  DEFAULT CHARSET = UTF8 COMMENT '资源表';
```

#### 角色-资源关联表

| 字段名      | 类型            | Null | Key | Default           | Extra                                         |
| :---------- | :-------------- | :--- | :-- | :---------------- | :-------------------------------------------- |
| id          | bigint unsigned | NO   | PRI | null              | auto_increment                                |
| created_at  | datetime        | NO   |     | CURRENT_TIMESTAMP | DEFAULT_GENERATED                             |
| updated_at  | datetime        | NO   |     | CURRENT_TIMESTAMP | DEFAULT_GENERATED on update CURRENT_TIMESTAMP |
| deleted_at  | datetime        | YES  |     | null              |                                               |
| role_id     | bigint unsigned | NO   | MUL | 0                 |                                               |
| resource_id | bigint unsigned | NO   | MUL | 0                 |                                               |

建表语句：

```sql
DROP TABLE IF EXISTS `role_resource_rel`;
CREATE TABLE `role_resource_rel`
(
    `id`          bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '序号',
    `created_at`  datetime        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at`  datetime        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted_at`  datetime        NULL     DEFAULT NULL COMMENT '删除时间',
    `role_id`     bigint unsigned NOT NULL DEFAULT 0 COMMENT '角色id',
    `resource_id` bigint unsigned NOT NULL DEFAULT 0 COMMENT '资源id',
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_role` FOREIGN KEY (`role_id`) REFERENCES `role` (`id`),
    CONSTRAINT `fk_resource` FOREIGN KEY (`resource_id`) REFERENCES `resource` (`id`)
) ENGINE = INNODB
  DEFAULT CHARSET = UTF8 COMMENT '角色-资源表';
```

#### 用户表

| Field         | Type            | Null | Key | Default           | Extra                                         |
| :------------ | :-------------- | :--- | :-- | :---------------- | :-------------------------------------------- |
| id            | bigint unsigned | NO   | PRI | null              | auto_increment                                |
| created_at    | datetime        | NO   |     | CURRENT_TIMESTAMP | DEFAULT_GENERATED                             |
| updated_at    | datetime        | NO   |     | CURRENT_TIMESTAMP | DEFAULT_GENERATED on update CURRENT_TIMESTAMP |
| deleted_at    | datetime        | YES  |     | null              |                                               |
| username      | varchar\(50\)   | NO   | UNI | null              |                                               |
| password_hash | varchar\(255\)  | NO   |     | null              |                                               |
| role_id       | bigint unsigned | NO   | MUL | 0                 |                                               |
| last_login    | datetime        | NO   |     | CURRENT_TIMESTAMP | DEFAULT_GENERATED                             |

建表语句：

```sql
DROP TABLE IF EXISTS `user_basic`;
CREATE TABLE IF NOT EXISTS `user_basic`
(
    `id`            bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '序号',
    `created_at`    datetime        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at`    datetime        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted_at`    datetime        NULL     DEFAULT NULL COMMENT '删除时间',
    `username`      VARCHAR(50)     NOT NULL UNIQUE COMMENT '用户名',
    `password_hash` VARCHAR(255)    NOT NULL COMMENT '加密过后的密码',
    `role_id`       bigint unsigned NOT NULL DEFAULT 0 COMMENT '所属角色',
    `last_login`    datetime        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '最后登录时间',
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_user_role` FOREIGN KEY (`role_id`) REFERENCES `role` (`id`)
) ENGINE = INNODB
  DEFAULT CHARSET = UTF8 COMMENT '用户表';
```

### 业务模块

需要给用户提供一个下拉选项，并且对应 prompt 中英文与部位。

#### 造型选项表

| Field      | Type            | Null | Key | Default           | Extra                                         |
| :--------- | :-------------- | :--- | :-- | :---------------- | :-------------------------------------------- |
| id         | bigint unsigned | NO   | PRI | null              | auto_increment                                |
| created_at | datetime        | NO   |     | CURRENT_TIMESTAMP | DEFAULT_GENERATED                             |
| updated_at | datetime        | NO   |     | CURRENT_TIMESTAMP | DEFAULT_GENERATED on update CURRENT_TIMESTAMP |
| deleted_at | datetime        | YES  |     | null              |                                               |
| cprompt    | varchar\(255\)  | NO   |     | null              |                                               |
| prompt     | varchar\(255\)  | NO   |     | null              |                                               |
| type       | varchar\(255\)  | NO   |     | null              |                                               |

建表语句：

```sql
DROP TABLE IF EXISTS `model_option`;
CREATE TABLE IF NOT EXISTS `model_option`
(
    `id`         bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '序号',
    `created_at` datetime        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` datetime        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted_at` datetime        NULL     DEFAULT NULL COMMENT '删除时间',
    `cprompt`    varchar(255)    NOT NULL COMMENT '中文prompt',
    `prompt`     varchar(255)    NOT NULL COMMENT '英文prompt',
    `type`       varchar(255)    NOT NULL COMMENT '对应部位',
    PRIMARY KEY (`id`)
) ENGINE = INNODB
  DEFAULT CHARSET = UTF8 COMMENT '造型选项表';
```

### 系统模块

## AI 模型需求

### PhotoMaker

使用 [PhotoMaker](https://arxiv.org/abs/2312.04461) 作为 AI Work，底层用到了 Stable Diffusion 和 LoRA 微调。

### AI 部署

模型算法部署在了 [Replicate](https://replicate.com/) 上，通过 http 接口的方式暴露给后端使用。

## 前端需求

### 登录/注册

### 角色管理

### 资源管理

### 用户管理

### 造型选项管理

### 首页业务实现

## 后端需求

### 登录/注册

### 角色管理

### 资源管理

### 用户管理

### 造型选项管理

### 业务实现

## 运维需求

### CI/CD

### 监控

### 日志分析
