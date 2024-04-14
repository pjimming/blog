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
- [x] 资源初始化

后端服务

- [x] 登录/注册/登出
- [x] 权限模块
- [x] 角色管理
- [x] 用户管理
- [x] 资源树管理
- [x] PhotoMaker
- [x] Prompt 管理
- [x] 系统参数管理
- [x] 限流器

前端页面

- [x] 登录/注册/登出
- [x] 角色管理页面
- [x] 资源管理页面
- [x] 用户管理页面
- [x] 首页业务页面
- [x] Prompt 管理
- [x] 系统参数管理
- [ ] 监控面板

测试

- [x] 登录/注册/登出
- [x] 权限模块
- [ ] 用户模块
- [ ] 角色模块
- [x] Prompt 模块
- [x] 业务模块

运维相关

- [x] 流水线发布（前端）
- [x] 流水线发布（后端）
- [x] Nginx 部署
- [x] MySQL 部署
- [x] Redis 部署
- [x] 监控组件部署
  - [x] Prometheus 部署
  - [x] node_exporter 部署
  - [x] mysqld_exporter 部署
  - [x] redis_exporter 部署
- [ ] Grafana 部署
- [ ] SSL/TLS 证书
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
| is_enable     | boolean         | YES  |     | TRUE              |                                               |
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
    `is_enable`     boolean                  DEFAULT TRUE COMMENT '是否启用',
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

### 数据初始化

```sql
insert into magic_camera.resource (id, created_at, updated_at, deleted_at, name, code, type, parent_id, order, icon, component, path, is_show, is_enable)
values  (1, '2024-04-06 07:04:23', '2024-04-06 07:13:28', null, '资源管理', 'Resource_Mgt', 'MENU', 2, 1, 'i-fe:list', '/src/views/sys/resource/index.vue', '/pms/resource', 1, 1),
        (2, '2024-04-06 07:04:53', '2024-04-06 07:04:53', null, '系统管理', 'SysMgt', 'MENU', 0, 2, 'i-fe:grid', '', '', 1, 1),
        (3, '2024-04-06 07:05:00', '2024-04-06 07:13:28', null, '角色管理', 'RoleMgt', 'MENU', 2, 2, 'i-fe:user-check', '/src/views/sys/role/index.vue', '/pms/role', 1, 1),
        (4, '2024-04-06 07:05:00', '2024-04-06 07:13:28', null, '用户管理', 'UserMgt', 'MENU', 2, 3, 'i-fe:user', '/src/views/sys/user/index.vue', '/pms/user', 1, 1),
        (5, '2024-04-06 07:05:01', '2024-04-06 07:13:28', null, '分配用户', 'RoleUser', 'MENU', 3, 1, 'i-fe:user-plus', '/src/views/sys/role/role-user.vue', '/pms/role/user/:roleId', 1, 1),
        (8, '2024-04-06 07:05:01', '2024-04-06 07:05:01', null, '个人资料', 'UserProfile', 'MENU', 0, 99, 'i-fe:user', '/src/views/profile/index.vue', '/profile', 0, 1);
```

## AI 模型需求

### PhotoMaker

使用 [PhotoMaker](https://arxiv.org/abs/2312.04461) 作为 AI Work，底层用到了 Stable Diffusion 和 LoRA 微调。

### AI 部署

模型算法部署在了 [Replicate](https://replicate.com/) 上，通过 http 接口的方式暴露给后端使用。

## 接口列表

### 1. "获取四位验证码"

1. route definition

- Url: /api/v1/captcha
- Method: GET
- Request: `-`
- Response: `GetCaptchaResp`

2. request definition

3. response definition

```golang
type GetCaptchaResp struct {
	CaptchaId string `json:"captcha_id"`
	B64s string `json:"b64s"`
}
```

### 2. "获取 tmp 目录下文件"

1. route definition

- Url: /api/v1/file/:dir/:filename
- Method: GET
- Request: `GetFileReq`
- Response: `-`

2. request definition

```golang
type GetFileReq struct {
	Dir string `path:"dir"`
	Filename string `path:"filename"`
}
```

3. response definition

### 3. "探活 ping"

1. route definition

- Url: /ping
- Method: GET
- Request: `-`
- Response: `-`

2. request definition

3. response definition

### 4. "生成照片"

1. route definition

- Url: /api/v1/generate/photo
- Method: POST
- Request: `GeneratePhotoReq`
- Response: `GeneratePhotoResp`

2. request definition

```golang
type GeneratePhotoReq struct {
	Images []string `form:"-"`
	Style string `form:"style"`
}
```

3. response definition

```golang
type GeneratePhotoResp struct {
	Output string `json:"output"`
}
```

### 5. "获取角色权限树"

1. route definition

- Url: /api/v1/role/permissions/tree
- Method: GET
- Request: `-`
- Response: `GetResourceTreeResp`

2. request definition

3. response definition

```golang
type GetResourceTreeResp struct {
	Resource []*Resource `json:"resource"`
}
```

### 6. "分页查询 Prompt Option"

1. route definition

- Url: /api/v1/prompt-option
- Method: GET
- Request: `GetPromptOptionPageReq`
- Response: `GetPromptOptionResp`

2. request definition

```golang
type GetPromptOptionPageReq struct {
	Page int `form:"page,default=1"`
	Size int `form:"size,default=10"`
	Name string `form:"name,optional"`
	Prompt string `form:"prompt,optional"`
	Desc string `form:"desc,optional"`
}
```

3. response definition

```golang
type GetPromptOptionResp struct {
	Items []*PromptOption `json:"items"`
	Total int64 `json:"total"`
}
```

### 7. "新增 Prompt Option"

1. route definition

- Url: /api/v1/prompt-option
- Method: POST
- Request: `AddPromptOptionReq`
- Response: `AddPromptOptionResp`

2. request definition

```golang
type AddPromptOptionReq struct {
	Name string `json:"name"` // 选项名
	Prompt string `json:"prompt"` // prompt
	Desc string `json:"desc,optional"` // 描述
}
```

3. response definition

```golang
type AddPromptOptionResp struct {
	ID uint64 `json:"id"`
}
```

### 8. "修改 Prompt Option"

1. route definition

- Url: /api/v1/prompt-option
- Method: PUT
- Request: `UpdatePromptOptionReq`
- Response: `-`

2. request definition

```golang
type UpdatePromptOptionReq struct {
	ID uint64 `path:"id"` // 序号
	Name string `json:"name"` // 选项名
	Prompt string `json:"prompt"` // prompt
	Desc string `json:"desc,optional"` // 描述
}
```

3. response definition

### 9. "删除 Prompt Option"

1. route definition

- Url: /api/v1/prompt-option
- Method: DELETE
- Request: `DeletePromptOptionReq`
- Response: `-`

2. request definition

```golang
type DeletePromptOptionReq struct {
	ID uint64 `path:"id"`
}
```

3. response definition

### 10. "新增资源"

1. route definition

- Url: /api/v1/resource
- Method: POST
- Request: `AddResourceReq`
- Response: `AddResourceResp`

2. request definition

```golang
type AddResourceReq struct {
	Name string `json:"name"`
	Code string `json:"code"`
	Type string `json:"type,optional"`
	ParentID int `json:"parentId,optional"`
	Path string `json:"path,optional"`
	Icon string `json:"icon,optional"`
	Component string `json:"component,optional"`
	IsShow bool `json:"isShow,optional"`
	IsEnable bool `json:"isEnable,optional"`
	Order int `json:"order"`
}
```

3. response definition

```golang
type AddResourceResp struct {
	ID uint64 `json:"id"`
}
```

### 11. "修改资源"

1. route definition

- Url: /api/v1/resource/:id
- Method: PUT
- Request: `SaveResourceReq`
- Response: `SaveResourceResp`

2. request definition

```golang
type SaveResourceReq struct {
	ID uint64 `path:"id"`
	Name string `json:"name"`
	Code string `json:"code"`
	Type string `json:"type,optional"`
	ParentID int `json:"parentId,optional"`
	Path string `json:"path,optional"`
	Icon string `json:"icon,optional"`
	Component string `json:"component,optional"`
	IsShow bool `json:"isShow,optional"`
	IsEnable bool `json:"isEnable,optional"`
	Order int `json:"order"`
}
```

3. response definition

```golang
type SaveResourceResp struct {
	ID uint64 `json:"id"`
}
```

### 12. "删除资源"

1. route definition

- Url: /api/v1/resource/:id
- Method: DELETE
- Request: `DeleteResourceReq`
- Response: `DeleteResourceResp`

2. request definition

```golang
type DeleteResourceReq struct {
	ID uint64 `path:"id"`
}
```

3. response definition

```golang
type DeleteResourceResp struct {
	DelectCount int `json:"deleteCount"`
}
```

### 13. "获取菜单资源树"

1. route definition

- Url: /api/v1/resource/menu/tree
- Method: GET
- Request: `-`
- Response: `GetResourceTreeResp`

2. request definition

3. response definition

```golang
type GetResourceTreeResp struct {
	Resource []*Resource `json:"resource"`
}
```

### 14. "给用户分配角色"

1. route definition

- Url: /api/v1/assign/roles
- Method: PUT
- Request: `AssignRolesReq`
- Response: `-`

2. request definition

```golang
type AssignRolesReq struct {
	ID uint64 `json:"id"`
	RoleId uint64 `json:"roleId"`
	Username string `json:"username"`
}
```

3. response definition

### 15. "新增角色"

1. route definition

- Url: /api/v1/role
- Method: POST
- Request: `AddRoleReq`
- Response: `AddRoleResp`

2. request definition

```golang
type AddRoleReq struct {
	Code string `json:"code"`
	Name string `json:"name"`
	IsEnable bool `json:"isEnable"`
	ResourceIds []uint64 `json:"resourceIds"`
}
```

3. response definition

```golang
type AddRoleResp struct {
	ID uint64 `json:"id"`
}
```

### 16. "更新角色"

1. route definition

- Url: /api/v1/role/:id
- Method: PUT
- Request: `UpdateRoleReq`
- Response: `-`

2. request definition

```golang
type UpdateRoleReq struct {
	ID uint64 `path:"id"`
	Code string `json:"code"`
	Name string `json:"name"`
	IsEnable bool `json:"isEnable"`
	ResourceIds []uint64 `json:"resourceIds"`
}
```

3. response definition

### 17. "查询角色"

1. route definition

- Url: /api/v1/role/all
- Method: GET
- Request: `GetRoleAllReq`
- Response: `GetRoleAllResp`

2. request definition

```golang
type GetRoleAllReq struct {
	Code string `form:"code,optional"`
	Name string `form:"name,optional"`
	IsEnable bool `form:"isEnable,default=false"`
}
```

3. response definition

```golang
type GetRoleAllResp struct {
	Items []*Role `json:"items"`
}
```

### 18. "分页查询角色"

1. route definition

- Url: /api/v1/role/page
- Method: GET
- Request: `GetRolePageReq`
- Response: `GetRolePageResp`

2. request definition

```golang
type GetRolePageReq struct {
	Page int `form:"page,default=1"`
	Size int `form:"size,default=10"`
	Code string `form:"code,optional"`
	Name string `form:"name,optional"`
}
```

3. response definition

```golang
type GetRolePageResp struct {
	Items []*Role `json:"items"`
	Total int64 `json:"total"`
}
```

### 19. "用户登录"

1. route definition

- Url: /api/v1/user/login
- Method: POST
- Request: `UserLoginReq`
- Response: `UserLoginResp`

2. request definition

```golang
type UserLoginReq struct {
	Username string `json:"username"`
	Password string `json:"password"`
	Captcha string `json:"captcha"`
	CaptchaId string `json:"captchaId"`
}
```

3. response definition

```golang
type UserLoginResp struct {
	Token string `json:"token"`
}
```

### 20. "用户注册"

1. route definition

- Url: /api/v1/user/register
- Method: POST
- Request: `UserRegisterReq`
- Response: `UserRegisterResp`

2. request definition

```golang
type UserRegisterReq struct {
	Username string `json:"username"`
	Password string `json:"password"`
	Captcha string `json:"captcha"`
	CaptchaId string `json:"captchaId"`
}
```

3. response definition

```golang
type UserRegisterResp struct {
	ID int32 `json:"id"`
}
```

### 21. "用户登出"

1. route definition

- Url: /api/v1/user/logout
- Method: POST
- Request: `-`
- Response: `-`

2. request definition

3. response definition

### 22. "分页查询用户"

1. route definition

- Url: /api/v1/user
- Method: GET
- Request: `GetUserPageReq`
- Response: `GetUserPageResp`

2. request definition

```golang
type GetUserPageReq struct {
	Page int `form:"page,default=1"`
	Size int `form:"size,default=10"`
	Username string `form:"username,optional"` // 用户名
}
```

3. response definition

```golang
type GetUserPageResp struct {
	Items []*User `json:"items"`
	Total int64 `json:"total"`
}
```

### 23. "获取全部角色"

1. route definition

- Url: /api/v1/user/all
- Method: GET
- Request: `-`
- Response: `GetUserPageResp`

2. request definition

3. response definition

```golang
type GetUserPageResp struct {
	Items []*User `json:"items"`
	Total int64 `json:"total"`
}
```

### 24. "获取用户详情"

1. route definition

- Url: /api/v1/user/detail
- Method: GET
- Request: `-`
- Response: `GetUserDetailResp`

2. request definition

3. response definition

```golang
type GetUserDetailResp struct {
	ID uint64 `json:"id"` // 序号
	CreatedAt int64 `json:"createdAt"` // 创建时间
	UpdatedAt int64 `json:"updatedAt"` // 更新时间
	Username string `json:"username"` // 账号
	LastLogin int64 `json:"lastLogin"` // 最后登录时间
	IsEnable bool `json:"isEnable"` // 是否启用:0-禁用;1-启用
	Role *Role `json:"role"` // 角色
}
```

## 运维需求

### CI/CD

### 监控

### 日志分析
