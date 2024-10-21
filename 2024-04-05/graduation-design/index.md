# 【毕业季】本科毕设《Magic Camera》需求清单


记录本科毕设的需求、进度

<!--more-->

---

{{<admonition info "目前进度">}}

数据库

- [x] 数据库设计
  - [x] prompt_option: prompt 选项表
  - [x] resource: 资源表
  - [x] role: 角色表
  - [x] role_resource_rel: 角色-资源关联表
  - [x] sys_param: 系统参数表
  - [x] user_basic: 用户表
  - [x] api_log: API 日志表
- [x] 资源初始化

后端服务

- [x] API
  - [x] 登录/注册/登出
  - [x] PhotoMaker
  - [x] 权限模块
    - [x] 角色管理：增删改查
    - [x] 用户管理：增删改查
    - [x] 资源树管理：增删改查
  - [x] Prompt 管理：增删改查
  - [x] 系统参数管理：增删改查
  - [x] API 日志模块：增查
- [x] 中间件
  - [x] JWT 认证
  - [x] 业务限流器
    - [x] 缓存限流次数
  - [x] API 日志记录
    - [x] 字段脱敏
- [x] 优化
  - [x] 对 DB 封装一层 Redis 缓存

前端页面

- [x] 身份认证功能：登录/注册/登出
- [x] 首页业务页面：魔力照相机
- [x] 系统管理页面
  - [x] 角色管理页面
  - [x] 资源管理页面
  - [x] 用户管理页面
  - [x] Prompt 管理页面
  - [x] 系统参数管理页面
- [x] 监控视图页面
  - [x] 服务器监控面板
  - [x] Go 进程监控面板
  - [x] Redis 监控面板
  - [x] MySQL 监控面板
  - [x] WEB API 监控面板
- [x] API 日志查询页面

测试

- [x] 登录/注册/登出
- [x] 业务模块
- [x] 后台管理模块
  - [x] 权限模块
  - [x] 用户模块
  - [x] 角色模块
  - [x] Prompt 模块
  - [x] 系统参数模块
- [x] 监控模块
  - [x] 服务器监控面板
  - [x] Go 进程监控面板
  - [x] Redis 监控面板
  - [x] MySQL 监控面板
  - [x] WEB API 监控面板
- [x] 日志模块

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
- [x] Grafana 部署
  - [x] 服务器 Dashboard
  - [x] Go 进程 Dashboard
  - [x] Redis Dashboard
  - [x] MySQL Dashboard
  - [x] WEB API Dashboard
- [ ] SSL/TLS 证书
- [x] 日志
- [ ] Prompt 设置

{{</admonition>}}

## 数据库设计

单体服务，采用 mysql 作为底层数据库，使用 redis 做缓存数据库。

### 权限模块

通过 RBAC 模型的方式，基于角色控制资源权限，表字段设计如下：

#### 用户表

| 字段名        | 类型            | NULL | Key | Default | Extra          |
| :------------ | :-------------- | :--- | :-- | :------ | :------------- |
| id            | bigint unsigned | NO   | PRI | null    | auto_increment |
| created_at    | datetime        | YES  |     | null    |                |
| updated_at    | datetime        | YES  |     | null    |                |
| deleted_at    | datetime        | YES  |     | null    |                |
| username      | varchar\(50\)   | NO   | UNI | null    |                |
| password_hash | varchar\(255\)  | NO   |     | null    |                |
| role_id       | bigint unsigned | NO   | MUL | 0       |                |
| last_login    | datetime        | YES  |     | null    |                |
| is_enable     | tinyint\(1\)    | YES  |     | null    |                |
| biz_count     | bigint unsigned | YES  |     | 0       |                |

建表语句：

```sql
CREATE TABLE `user_basic` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '序号',
  `created_at` datetime DEFAULT NULL COMMENT '创建时间',
  `updated_at` datetime DEFAULT NULL COMMENT '更新时间',
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  `username` varchar(50) NOT NULL COMMENT '用户名',
  `password_hash` varchar(255) NOT NULL COMMENT '加密过后的密码',
  `role_id` bigint unsigned NOT NULL DEFAULT '0' COMMENT '所属角色',
  `last_login` datetime DEFAULT NULL COMMENT '最后登录时间',
  `is_enable` tinyint(1) DEFAULT NULL COMMENT '是否启用:1-启用;0-禁用',
  `biz_count` bigint unsigned DEFAULT '0' COMMENT '使用业务接口次数',
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`),
  KEY `fk_user_role` (`role_id`),
  CONSTRAINT `fk_user_role` FOREIGN KEY (`role_id`) REFERENCES `role` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb3 COMMENT='用户表';
```

#### 资源表

| 字段名     | 类型            | Null | Key | Default | Extra          |
| :--------- | :-------------- | :--- | :-- | :------ | :------------- |
| id         | bigint unsigned | NO   | PRI | null    | auto_increment |
| created_at | datetime        | YES  |     | null    |                |
| updated_at | datetime        | YES  |     | null    |                |
| deleted_at | datetime        | YES  |     | null    |                |
| name       | varchar\(255\)  | NO   |     |         |                |
| code       | varchar\(255\)  | NO   |     |         |                |
| type       | varchar\(255\)  | NO   |     |         |                |
| parent_id  | bigint unsigned | NO   |     | 0       |                |
| order      | int             | NO   |     | 0       |                |
| icon       | varchar\(512\)  | NO   |     |         |                |
| component  | varchar\(512\)  | NO   |     |         |                |
| path       | varchar\(512\)  | NO   |     |         |                |
| is_show    | tinyint\(1\)    | NO   |     | 0       |                |
| is_enable  | tinyint\(1\)    | NO   |     | 0       |                |

建表语句：

```sql
CREATE TABLE `resource` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '序号',
  `created_at` datetime DEFAULT NULL COMMENT '创建时间',
  `updated_at` datetime DEFAULT NULL COMMENT '更新时间',
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  `name` varchar(255) NOT NULL DEFAULT '' COMMENT '名称',
  `code` varchar(255) NOT NULL DEFAULT '' COMMENT '编码',
  `type` varchar(255) NOT NULL DEFAULT '' COMMENT '类型',
  `parent_id` bigint unsigned NOT NULL DEFAULT '0' COMMENT '父节点id',
  `order` int NOT NULL DEFAULT '0' COMMENT '排序',
  `icon` varchar(512) NOT NULL DEFAULT '' COMMENT '菜单图标',
  `component` varchar(512) NOT NULL DEFAULT '' COMMENT '组件路径',
  `path` varchar(512) NOT NULL DEFAULT '' COMMENT '路由地址',
  `is_show` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否显示',
  `is_enable` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否启用',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb3 COMMENT='资源表';
```

#### 角色-资源关联表

| 字段名      | 类型            | Null | Key | Default | Extra          |
| :---------- | :-------------- | :--- | :-- | :------ | :------------- |
| id          | bigint unsigned | NO   | PRI | null    | auto_increment |
| created_at  | datetime        | YES  |     | null    |                |
| updated_at  | datetime        | YES  |     | null    |                |
| deleted_at  | datetime        | YES  |     | null    |                |
| role_id     | bigint unsigned | NO   | MUL | 0       |                |
| resource_id | bigint unsigned | NO   | MUL | 0       |                |

建表语句：

```sql
CREATE TABLE `role_resource_rel` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '序号',
  `created_at` datetime DEFAULT NULL COMMENT '创建时间',
  `updated_at` datetime DEFAULT NULL COMMENT '更新时间',
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  `role_id` bigint unsigned NOT NULL DEFAULT '0' COMMENT '角色id',
  `resource_id` bigint unsigned NOT NULL DEFAULT '0' COMMENT '资源id',
  PRIMARY KEY (`id`),
  KEY `fk_role` (`role_id`),
  KEY `fk_resource` (`resource_id`),
  CONSTRAINT `fk_resource` FOREIGN KEY (`resource_id`) REFERENCES `resource` (`id`),
  CONSTRAINT `fk_role` FOREIGN KEY (`role_id`) REFERENCES `role` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb3 COMMENT='角色-资源表';
```

#### 角色表

| 字段名     | 类型            | Null | Key | Default | Extra          |
| :--------- | :-------------- | :--- | :-- | :------ | :------------- |
| id         | bigint unsigned | NO   | PRI | null    | auto_increment |
| created_at | datetime        | YES  |     | null    |                |
| updated_at | datetime        | YES  |     | null    |                |
| deleted_at | datetime        | YES  |     | null    |                |
| code       | varchar\(255\)  | NO   | UNI |         |                |
| name       | varchar\(255\)  | NO   | UNI |         |                |
| is_enable  | tinyint\(1\)    | NO   |     | 0       |                |

建表语句：

```sql
CREATE TABLE `role` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '序号',
  `created_at` datetime DEFAULT NULL COMMENT '创建时间',
  `updated_at` datetime DEFAULT NULL COMMENT '更新时间',
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  `code` varchar(255) NOT NULL DEFAULT '' COMMENT '角色编码',
  `name` varchar(255) NOT NULL DEFAULT '' COMMENT '角色名',
  `is_enable` tinyint(1) NOT NULL DEFAULT '0' COMMENT '启用状态:0-禁用;1-启用',
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb3 COMMENT='角色表';
```

### 业务模块

需要给用户提供一个下拉选项，并且对应 prompt 中英文。

#### 造型选项表

|      Field      |      Type       | Null | Key | Default |     Extra      |
| :-------------: | :-------------: | :--: | :-: | :-----: | :------------: |
|       id        | bigint unsigned |  NO  | PRI |  null   | auto_increment |
|   created_at    |    datetime     | YES  |     |  null   |                |
|   updated_at    |    datetime     | YES  |     |  null   |                |
|   deleted_at    |    datetime     | YES  |     |  null   |                |
|      name       | varchar\(255\)  |  NO  | UNI |         |                |
|     prompt      |      text       | YES  |     |  null   |                |
| negative_prompt |      text       | YES  |     |  null   |                |
|      desc       | varchar\(255\)  |  NO  |     |         |                |

建表语句：

```sql
CREATE TABLE `prompt_option` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '序号',
  `created_at` datetime DEFAULT NULL COMMENT '创建时间',
  `updated_at` datetime DEFAULT NULL COMMENT '更新时间',
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  `name` varchar(255) NOT NULL DEFAULT '' COMMENT '选项名',
  `prompt` text COMMENT 'prompt',
  `negative_prompt` text COMMENT '负面prompt',
  `desc` varchar(255) NOT NULL DEFAULT '' COMMENT '描述',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb3 COMMENT='prompt选项表';
```

### 系统模块

#### 系统参数表

|   字段名   |    字段类型     | Null | Key | Default |     Extra      |
| :--------: | :-------------: | :--: | :-: | :-----: | :------------: |
|     id     | bigint unsigned |  NO  | PRI |  null   | auto_increment |
| created_at |    datetime     | YES  |     |  null   |                |
| updated_at |    datetime     | YES  |     |  null   |                |
| deleted_at |    datetime     | YES  |     |  null   |                |
|    key     | varchar\(255\)  |  NO  | UNI |  null   |                |
|   value    |      text       | YES  |     |  null   |                |
|    desc    | varchar\(255\)  |  NO  |     |         |                |

建表语句：

```sql
CREATE TABLE `sys_param` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '序号',
  `created_at` datetime DEFAULT NULL COMMENT '创建时间',
  `updated_at` datetime DEFAULT NULL COMMENT '更新时间',
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  `key` varchar(255) NOT NULL COMMENT '键',
  `value` text COMMENT '值',
  `desc` varchar(255) NOT NULL DEFAULT '' COMMENT '描述',
  PRIMARY KEY (`id`),
  UNIQUE KEY `key` (`key`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb3 COMMENT='系统参数表';
```

### 日志模块

| 字段名      | 字段类型        | Null | Key | Default | Extra          |
| :---------- | :-------------- | :--- | :-- | :------ | :------------- |
| id          | bigint unsigned | NO   | PRI | null    | auto_increment |
| created_at  | datetime        | YES  |     | null    |                |
| method      | varchar\(64\)   | NO   |     | null    |                |
| api_path    | text            | NO   |     | null    |                |
| req_header  | mediumtext      | YES  |     | null    |                |
| req_body    | mediumtext      | YES  |     | null    |                |
| status      | varchar\(64\)   | NO   |     | null    |                |
| operator    | varchar\(255\)  | NO   |     | null    |                |
| remote_ip   | varchar\(255\)  | YES  |     | null    |                |
| remote_city | varchar\(255\)  | YES  |     | null    |                |
| response    | longtext        | YES  |     | null    |                |
| cost_time   | bigint unsigned | NO   |     | null    |                |

建表语句：

```sql
CREATE TABLE `api_log` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '序号',
  `created_at` datetime DEFAULT NULL COMMENT '创建时间',
  `method` varchar(64) NOT NULL COMMENT 'http方法',
  `api_path` text NOT NULL COMMENT 'api路径',
  `req_header` mediumtext COMMENT '请求头',
  `req_body` mediumtext COMMENT '请求body',
  `status` varchar(64) NOT NULL COMMENT '状态',
  `operator` varchar(255) NOT NULL COMMENT '操作人',
  `remote_ip` varchar(255) DEFAULT NULL COMMENT '操作ip',
  `remote_city` varchar(255) DEFAULT NULL COMMENT '操作地点',
  `response` longtext COMMENT '返回结果',
  `cost_time` bigint unsigned NOT NULL COMMENT '请求耗时，单位：ms',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=85 DEFAULT CHARSET=utf8mb3 COMMENT='API日志表';
```

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

### 1. "分页查询 API 日志"

1. route definition

- Url: /api/v1/api-log
- Method: GET
- Request: `GetApiLogReq`
- Response: `GetApiLogResp`

2. request definition

```golang
type GetApiLogReq struct {
	Page int `form:"page,default=1"`
	Size int `form:"size,default=10"`
	Method string `form:"method,optional"`
	APIPath string `form:"apiPath,optional"`
	Status string `form:"status,optional"`
	Operator string `form:"operator,optional"`
	RemoteIP string `form:"remoteIp,optional"`
	RemoteCity string `form:"remoteCity,optional"`
}
```

3. response definition

```golang
type GetApiLogResp struct {
	Items []*ApiLog `json:"items"`
	Total int64 `json:"total"`
}
```

### 2. "用户登录"

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

### 3. "用户注册"

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
	Token string `json:"token"`
}
```

### 4. "用户登出"

1. route definition

- Url: /api/v1/user/logout
- Method: POST
- Request: `-`
- Response: `-`

2. request definition

3. response definition

### 5. "获取四位验证码"

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

### 6. "获取 tmp 目录下文件"

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

### 7. "探活 ping"

1. route definition

- Url: /ping
- Method: GET
- Request: `-`
- Response: `-`

2. request definition

3. response definition

### 8. "生成照片"

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
	Gender string `form:"gender"`
	PromptId uint64 `form:"promptId"`
	Version string `form:"version"`
}
```

3. response definition

```golang
type GeneratePhotoResp struct {
	Output string `json:"output"`
	Images []string `json:"images"`
	Style string `json:"style"`
	Gender string `json:"gender"`
	PromptId uint64 `json:"promptId"`
	Version string `json:"version"`
}
```

### 9. "获取角色权限树"

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

### 10. "分页查询 Prompt Option"

1. route definition

- Url: /api/v1/prompt-option
- Method: GET
- Request: `GetPromptOptionReq`
- Response: `GetPromptOptionResp`

2. request definition

```golang
type GetPromptOptionReq struct {
	Page int `form:"page,default=1"`
	Size int `form:"size,default=10"`
	Name string `form:"name,optional"`
	Prompt string `form:"prompt,optional"`
	NegativePrompt string `form:"negativePrompt,optional"` // 负面prompt
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

### 11. "新增 Prompt Option"

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
	NegativePrompt string `json:"negativePrompt"` // 负面prompt
	Desc string `json:"desc,optional"` // 描述
}
```

3. response definition

```golang
type AddPromptOptionResp struct {
	ID uint64 `json:"id"`
}
```

### 12. "修改 Prompt Option"

1. route definition

- Url: /api/v1/prompt-option/:id
- Method: PUT
- Request: `UpdatePromptOptionReq`
- Response: `-`

2. request definition

```golang
type UpdatePromptOptionReq struct {
	ID uint64 `path:"id"` // 序号
	Name string `json:"name"` // 选项名
	Prompt string `json:"prompt"` // prompt
	NegativePrompt string `json:"negativePrompt"` // 负面prompt
	Desc string `json:"desc,optional"` // 描述
}
```

3. response definition

### 13. "删除 Prompt Option"

1. route definition

- Url: /api/v1/prompt-option/:id
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

### 14. "获取全部 Prompt Option"

1. route definition

- Url: /api/v1/prompt-option/all
- Method: GET
- Request: `GetPromptOptionReq`
- Response: `GetPromptOptionResp`

2. request definition

```golang
type GetPromptOptionReq struct {
	Page int `form:"page,default=1"`
	Size int `form:"size,default=10"`
	Name string `form:"name,optional"`
	Prompt string `form:"prompt,optional"`
	NegativePrompt string `form:"negativePrompt,optional"` // 负面prompt
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

### 15. "新增资源"

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

### 16. "修改资源"

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

### 17. "删除资源"

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

### 18. "获取菜单资源树"

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

### 19. "给用户分配角色"

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

### 20. "新增角色"

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

### 21. "更新角色"

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

### 22. "删除角色"

1. route definition

- Url: /api/v1/role/:id
- Method: DELETE
- Request: `DeleteRoleReq`
- Response: `-`

2. request definition

```golang
type DeleteRoleReq struct {
	ID uint64 `path:"id"`
}
```

3. response definition

### 23. "查询角色"

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

### 24. "分页查询角色"

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

### 25. "分页查询系统参数"

1. route definition

- Url: /api/v1/sys-param
- Method: GET
- Request: `GetSysParamReq`
- Response: `GetSysParamResp`

2. request definition

```golang
type GetSysParamReq struct {
	Page int `form:"page,default=1"`
	Size int `form:"size,default=10"`
	Key string `form:"key,optional"`
	Value string `form:"value,optional"`
	Desc string `form:"desc,optional"`
}
```

3. response definition

```golang
type GetSysParamResp struct {
	Items []*SysParam `json:"items"`
	Total int64 `json:"total"`
}
```

### 26. "新增系统参数"

1. route definition

- Url: /api/v1/sys-param
- Method: POST
- Request: `AddSysParamReq`
- Response: `AddSysParamResp`

2. request definition

```golang
type AddSysParamReq struct {
	Key string `json:"key"` // 键
	Value string `json:"value"` // 值
	Desc string `json:"desc,optional"` // 描述
}
```

3. response definition

```golang
type AddSysParamResp struct {
	ID uint64 `json:"id"`
}
```

### 27. "修改系统参数"

1. route definition

- Url: /api/v1/sys-param/:id
- Method: PUT
- Request: `UpdateSysParamReq`
- Response: `-`

2. request definition

```golang
type UpdateSysParamReq struct {
	ID uint64 `path:"id"` // 序号
	Key string `json:"key"` // 键
	Value string `json:"value"` // 值
	Desc string `json:"desc,optional"` // 描述
}
```

3. response definition

### 28. "删除系统参数"

1. route definition

- Url: /api/v1/sys-param/:id
- Method: DELETE
- Request: `DeleteSysParamReq`
- Response: `-`

2. request definition

```golang
type DeleteSysParamReq struct {
	ID uint64 `path:"id"`
}
```

3. response definition

### 29. "获取单个系统参数"

1. route definition

- Url: /api/v1/sys-param/single
- Method: GET
- Request: `GetSysParamReq`
- Response: `SysParam`

2. request definition

```golang
type GetSysParamReq struct {
	Page int `form:"page,default=1"`
	Size int `form:"size,default=10"`
	Key string `form:"key,optional"`
	Value string `form:"value,optional"`
	Desc string `form:"desc,optional"`
}
```

3. response definition

```golang
type SysParam struct {
	ID uint64 `json:"id"` // 序号
	CreatedAt int64 `json:"createdAt"` // 创建时间
	UpdatedAt int64 `json:"updatedAt"` // 更新时间
	Key string `json:"key"` // 键
	Value string `json:"value"` // 值
	Desc string `json:"desc"` // 描述
}
```

### 30. "分页查询用户"

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

### 31. "更新角色"

1. route definition

- Url: /api/v1/user/:id
- Method: PUT
- Request: `UpdateUserReq`
- Response: `-`

2. request definition

```golang
type UpdateUserReq struct {
	ID uint64 `path:"id"` // 序号
	IsEnable bool `json:"isEnable"` // 是否启用:0-禁用;1-启用
}
```

3. response definition

### 32. "获取全部角色"

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

### 33. "获取用户详情"

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

### 34. "用户修改密码"

1. route definition

- Url: /api/v1/user/password/change
- Method: POST
- Request: `ChangeUserPasswordReq`
- Response: `-`

2. request definition

```golang
type ChangeUserPasswordReq struct {
	OldPassword string `json:"oldPassword"`
	NewPassword string `json:"newPassword"`
}
```

3. response definition

### 35. "重置密码"

1. route definition

- Url: /api/v1/user/password/reset/:id
- Method: PUT
- Request: `ResetUserPasswordReq`
- Response: `-`

2. request definition

```golang
type ResetUserPasswordReq struct {
	ID uint64 `path:"id"`
	Password string `json:"password"`
}
```

3. response definition

## 运维需求

### MySQL 服务部署

使用 docker 部署，具体见 [docker compose](#docker-compose) 文件

### Redis 服务部署

使用 docker 部署，具体见 [docker compose](#docker-compose) 文件

### Nginx 服务部署

使用 docker 部署，具体见 [docker compose](#docker-compose) 文件

`/usr/local/nginx/nginx.conf`文件

```conf
user  nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    # 注意要添加这一行
    include /etc/nginx/conf.d/*.conf;
}
```

`/usr/local/nginx/conf.d/default.conf`文件

```
server{
        listen 80;
        server_name localhost docker.xieboke.net;
        charset utf-8;
        client_max_body_size 32m;

        location / {
                # 此处一定要改成nginx容器中的目录地址，宿主机上的地址容器访问不到
                # 命令必须用 root, 不能用 alias
                root   /usr/share/nginx/html;
                try_files $uri $uri/ /index.html;
                index  index.html index.htm;
        }

        location /file/ {
                proxy_pass http://[your_ip]:[your_port]/api/v1/file/;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }

        location ^~ /api/ {
                proxy_pass http://[your_ip]:[your_port]/api/v1/;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header REMOTE-HOST $remote_addr;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "upgrade";
                proxy_set_header X-Forwarded-Proto $scheme;
}



        #error_page  404              /404.html;

        # redirect server error pages to the static page /50x.html

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
                root   html;
        }
}
```

### Docker Compose

新建 docker-compose.yaml 文件，写入下列内容：

```yaml
version: "3.7"
services:
  mysql:
    image: mysql:latest
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: your_mysql_password # 需要修改
      MYSQL_DATABASE: your_database # 需要修改
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql

  redis:
    image: redis:latest
    restart: always
    command: [
        "redis-server",
        "--requirepass",
        your_redis_password, # 需要修改
        "--maxmemory",
        "512mb",
        "--maxmemory-policy",
        "allkeys-lru",
      ]
    ports:
      - "6379:6379"

  nginx:
    image: nginx:latest
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /usr/local/nginx/html:/usr/share/nginx/html
      - /usr/local/nginx/www:/var/www
      - /usr/local/nginx/logs:/var/log/nginx
      - /usr/local/nginx/nginx.conf/:/etc/nginx/nginx.conf
      - /usr/local/nginx/etc/cert:/etc/nginx/cert
      - /usr/local/nginx/conf.d:/etc/nginx/conf.d
    restart: always
    environment:
      - NGINX_PORT=80
      - TZ=Asia/Shanghai
    privileged: true

volumes:
  mysql_data:
```

执行命令：

```shell
docker compose up -d
```

### 前端部署

通过自写脚本，完成自动化发布流程：

1. 打包 `src`
2. 压缩 `dist` 目录成 `dist.tar.gz`
3. 把压缩包上传到服务器
4. 服务器解压缩目录到`/usr/local/nginx/html`
5. 删除`dist.tar.gz`文件

```makefile
deploy:
	@pnpm run build
	@tar -czvf dist.tar.gz -C dist .
	@scp dist.tar.gz server:/home/ubuntu
	@ssh server "sudo tar -xzvf /home/ubuntu/dist.tar.gz -C /usr/local/nginx/html"
	@rm dist.tar.gz
```

### 后端部署

通过 ansible 进行自动化部署

`inventory`文件：

```toml
[web_servers]
user@ip # 自行修改
```

`ansible.yaml`文件：

```yaml
---
- name: Deploy and restart service
  hosts: user@ip # 自行修改
  become: yes
  tasks:
    - name: Stop remote service
      systemd:
        name: magic-camera.service
        state: stopped
      ignore_errors: yes

    - name: Copy compiled binary to remote server
      ansible.builtin.copy:
        src: ../target/magic-camera-amd64-linux
        dest: /usr/local/bin/magic-camera-backend/magic-camera
        mode: "0755" # 设置文件权限为可执行

    - name: Copy config file to remote server
      ansible.builtin.copy:
        src: ../app/etc/config-product.yaml
        dest: /usr/local/bin/magic-camera-backend/config.yaml
        mode: "0644"

    - name: Start remote service
      systemd:
        name: magic-camera.service
        state: started

    - name: Get service status
      command: "systemctl status magic-camera.service"
      register: status_output

    - debug:
        msg: "Service status: {{ status_output }}"
```

`Makefile`文件：

```makefile
TARGET_DIR="target"
BINARY_NAME="magic-camera"

MAIN_GO=app/app.go

dep:
	@go mod download

check:
	@go fmt ./...
	@go vet ./...

build: dep check
	@mkdir -p ${TARGET_DIR}
	@GOARCH=arm64 GOOS=darwin go build -o ${TARGET_DIR}/${BINARY_NAME}-arm64-darwin ${MAIN_GO}
	@GOARCH=amd64 GOOS=darwin go build -o ${TARGET_DIR}/${BINARY_NAME}-amd64-darwin ${MAIN_GO}
	@GOARCH=amd64 GOOS=linux go build -o ${TARGET_DIR}/${BINARY_NAME}-amd64-linux ${MAIN_GO}
	@GOARCH=amd64 GOOS=windows go build -o ${TARGET_DIR}/${BINARY_NAME}-amd64-windows ${MAIN_GO}

deploy: build
	@ansible-playbook -i ansible/inventory ansible/ansible.yaml
```

### Prometheus 部署

1. 下载 Prometheus 文件，并且放置到各个文件夹下

```shell
wget https://github.com/prometheus/prometheus/releases/download/v2.45.4/prometheus-2.45.4.linux-amd64.tar.gz
tar -xvf prometheus-2.45.4.linux-amd64.tar.gz
cd prometheus-2.45.4.linux-amd64.tar.gz
sudo cp prometheus promtool /usr/local/bin
sudo cp -r prometheus.yml consoles console_libraries /etc/prometheus
```

2. 创建 Prometheus 服务

新建文件`/etc/systemd/system/prometheus.service`

```toml
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target
[Service]
User=root
Group=root
Type=simple
Restart=always
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries
[Install]
WantedBy=multi-user.target
```

3. 启动服务

```shell
sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl status prometheus
```

出现下列 `active` 信息即可，`Prometheus` 服务运行在`:9090`端口

```
● prometheus.service - Prometheus
     Loaded: loaded (/etc/systemd/system/prometheus.service; disabled; vendor preset: enabled)
     Active: active (running) since Sun 2024-04-14 20:15:00 CST; 4 days ago
   Main PID: 3218298 (prometheus)
      Tasks: 9 (limit: 2247)
     Memory: 129.0M
     CGroup: /system.slice/prometheus.service
             └─3218298 /usr/local/bin/prometheus --config.file /etc/prometheus/prometheus.yml --storage.tsdb.path /var/>
```

4. Prometheus 配置文件：`/etc/prometheus/prometheus.yml`

```yaml
# my global config
global:
  scrape_interval: 15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          # - alertmanager:9093

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: "prometheus"

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
      - targets: ["localhost:9090"]

  - job_name: "node_exporter"
    static_configs:
      - targets: ["localhost:9100"]

  - job_name: "mysqld_exporter"
    static_configs:
      - targets: ["localhost:9104"]

  - job_name: "magic_camera"
    static_configs:
      - targets: ["localhost:6470"]

  - job_name: "redis_exporter"
    static_configs:
      - targets: ["localhost:9121"]
```

### 部署 Node Exporter

1. 下载 node_exporter 文件，并且放置到各个文件夹下

```shell
wget wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
tar -xvf node_exporter-1.7.0.linux-amd64.tar.gz
cd node_exporter-1.7.0.linux-amd64.tar.gz
sudo cp node_exporter /usr/local/bin
```

2. 创建 node_exporter 服务

新建文件`/etc/systemd/system/node_exporter.service`

```toml
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target
[Service]
User=root
Group=root
Type=simple
Restart=always
ExecStart=/usr/local/bin/node_exporter
[Install]
WantedBy=multi-user.target
```

3. 启动服务

```shell
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl status node_exporter
```

出现下列 `active` 信息即可，`node_exporter` 服务运行在`:9100`端口

```
● node_exporter.service - Node Exporter
     Loaded: loaded (/etc/systemd/system/node_exporter.service; disabled; vendor preset: enabled)
     Active: active (running) since Sun 2024-04-14 19:36:13 CST; 4 days ago
   Main PID: 3207091 (node_exporter)
      Tasks: 4 (limit: 2247)
     Memory: 14.4M
     CGroup: /system.slice/node_exporter.service
             └─3207091 /usr/local/bin/node_exporter
```

### 部署 MySQLd Exporter

1. 下载 mysqld_exporter 文件，并且放置到各个文件夹下

```shell
wget https://github.com/prometheus/mysqld_exporter/releases/download/v0.15.1/mysqld_exporter-0.15.1.linux-amd64.tar.gz
tar -xvf mysqld_exporter-0.15.1.linux-amd64.tar.gz
cd mysqld_exporter-0.15.1.linux-amd64.tar.gz
sudo cp mysqld_exporter /usr/local/bin
```

2. mysqld_exporter 配置文件：`/etc/prometheus/mysqld_exporter/my.cnf`

```toml
[client]
user=root
password=your_mysql_password
host=127.0.0.1
```

3. 创建 mysqld_exporter 服务

新建文件`/etc/systemd/system/mysqld_exporter.service`

```toml
[Unit]
Description=mysqld_exporter
Wants=network-online.target
After=network-online.target
[Service]
Type=simple
User=root
Group=root
Environment=DATA_SOURCE_NAME=your_mysql_user:your_mysql_password@(127.0.0.1:3306)/
ExecStart=/usr/local/bin/mysqld_exporter --config.my-cnf=/etc/prometheus/mysqld_exporter/my.cnf
Restart=always
[Install]
WantedBy=multi-user.targe
```

4. 启动服务

```shell
sudo systemctl daemon-reload
sudo systemctl start mysqld_exporter
sudo systemctl status mysqld_exporter
```

出现下列 `active` 信息即可，`mysqld_exporter` 服务运行在`:9104`端口

```
● mysqld_exporter.service - mysqld_exporter
     Loaded: loaded (/etc/systemd/system/mysqld_exporter.service; disabled; vendor preset: enabled)
     Active: active (running) since Mon 2024-04-15 14:48:22 CST; 4 days ago
   Main PID: 3504637 (mysqld_exporter)
      Tasks: 6 (limit: 2247)
     Memory: 12.3M
     CGroup: /system.slice/mysqld_exporter.service
             └─3504637 /usr/local/bin/mysqld_exporter --config.my-cnf=/etc/prometheus/mysqld_exporter/my.cnf
```

### 部署 Redis Exporter

1. 下载 redis_exporter 文件，并且放置到各个文件夹下

```shell
wget https://github.com/oliver006/redis_exporter/releases/download/v1.58.0/redis_exporter-v1.58.0.linux-amd64.tar.gz
tar -xvf redis_exporter-v1.58.0.linux-amd64.tar.gz
cd redis_exporter-v1.58.0.linux-amd64.tar.gz
sudo cp redis_exporter /usr/local/bin
```

2. 创建 redis_exporter 服务

新建文件`/etc/systemd/system/redis_exporter.service`

```toml
[Unit]
Description=Redis Exporter
Wants=network-online.target
After=network-online.target
[Service]
User=root
Group=root
Type=simple
Restart=always
ExecStart=/usr/local/bin/redis_exporter \
    --redis.password=your_redis_password
[Install]
WantedBy=multi-user.target
```

4. 启动服务

```shell
sudo systemctl daemon-reload
sudo systemctl start redis_exporter
sudo systemctl status redis_exporter
```

出现下列 `active` 信息即可，`redis_exporter` 服务运行在`:9121`端口

```
● redis_exporter.service - Redis Exporter
     Loaded: loaded (/etc/systemd/system/redis_exporter.service; disabled; vendor preset: enabled)
     Active: active (running) since Sun 2024-04-14 20:13:14 CST; 4 days ago
   Main PID: 3217820 (redis_exporter)
      Tasks: 9 (limit: 2247)
     Memory: 13.6M
     CGroup: /system.slice/redis_exporter.service
             └─3217820 /usr/local/bin/redis_exporter --redis.password=your_redis_password
```

### 部署 Grafana

```shell
sudo apt-get install -y adduser libfontconfig1 musl
wget https://dl.grafana.com/enterprise/release/grafana-enterprise_10.4.2_amd64.deb
sudo dpkg -i grafana-enterprise_10.4.2_amd64.deb
sudo systemctl status grafana-server.service
```

检测服务，服务运行在 `:3000` 端口：

```
● grafana-server.service - Grafana instance
     Loaded: loaded (/lib/systemd/system/grafana-server.service; enabled; vendor preset: enabled)
     Active: active (running) since Mon 2024-04-15 00:38:00 CST; 4 days ago
       Docs: http://docs.grafana.org
   Main PID: 3286698 (grafana)
      Tasks: 19 (limit: 2247)
     Memory: 109.8M
     CGroup: /system.slice/grafana-server.service
             └─3286698 /usr/share/grafana/bin/grafana server --config=/etc/grafana/grafana.ini --pidfile=/run/grafana/g>
```

## 遇到的问题

### 图片上传前后端交互

#### 前端代码

```vue
<script>
async function submitForm() {
  const { value } = formValue
  const { imgList, version, promptId, style, gender } = value

  ...

  const formData = new FormData()
  imgList.forEach(({ file }) => formData.append('images', file))

  ...

  try {
    const { data } = await api.generatePhoto(formData)
  }
  ...
}
</script>
```

#### 后端代码

处理图片上传：

```go
fileDir := path.Join("tmp", "image")
if _, err := os.Stat(fileDir); os.IsNotExist(err) {
  _ = os.MkdirAll(fileDir, os.ModePerm)
}
for _, fileHeader := range r.MultipartForm.File["images"] {
  file, _ := fileHeader.Open()
  filename := fmt.Sprintf("%d%s", time.Now().UnixMicro(), path.Ext(fileHeader.Filename))
  filePath := path.Join(fileDir, filename)
  dst, _ := os.Create(filePath)
  _, _ = io.Copy(dst, file)
  req.Images = append(req.Images, filename)
  _ = file.Close()
  _ = dst.Close()
}
// 异步删除
go func(images []string) {
  for _, item := range images {
    if err = os.Remove(path.Join(fileDir, item)); err != nil {
      logx.Error(err)
    }
  }
}(req.Images)
```

文件（图片）服务器

```go
func GetFileHandler(svcCtx *svc.ServiceContext) http.HandlerFunc {
  return func(w http.ResponseWriter, r *http.Request) {
    var req types.GetFileReq
    if err := httpx.Parse(r, &req); err != nil {
      httpresp.HttpError(w, r, errors.BadRequest(errors.DefaultBadRequestID, err.Error()))
      return
    }

    filename := path.Join("tmp", req.Dir, req.Filename)
    if _, err := os.Stat(filename); err != nil {
      if os.IsNotExist(err) {
        _, _ = w.Write([]byte("file not exist"))
        httpx.Ok(w)
        return
      } else {
        httpresp.HttpError(w, r, errors.NotFound(errors.DefaultNotFoundID, err.Error()))
      }
    }

    http.ServeFile(w, r, filename)
  }
}
```

### 数据库软删除与唯一索引冲突

暂无解决方案

### 前端 json 展示

使用 vue-json-viewer 包

```vue
<template>
  <n-form
    ref="modalFormRef"
    label-placement="top"
    label-align="left"
    :model="modalForm"
  >
    <n-form-item label="请求头" path="reqHeader">
      <JsonViewer
        :value="JSON.parse(modalForm.reqHeader)"
        copyable
        sort
        boxed
        expanded
        :theme="appStore.isDark ? 'jv-dark' : 'jv-light'"
      />
      <!-- <n-input v-model:value="modalForm.reqHeader" /> -->
    </n-form-item>
    <n-form-item label="请求体" path="reqBody">
      <JsonViewer
        :value="JSON.parse(modalForm.reqBody)"
        copyable
        boxed
        sort
        :theme="appStore.isDark ? 'jv-dark' : 'jv-light'"
      />
      <!-- <n-input v-model:value="modalForm.reqBody" /> -->
    </n-form-item>
    <n-form-item label="返回结果" path="response">
      <JsonViewer
        :value="JSON.parse(modalForm.response)"
        copyable
        boxed
        sort
        expanded
        :theme="appStore.isDark ? 'jv-dark' : 'jv-light'"
      />
      <!-- <n-input v-model:value="modalForm.response" /> -->
    </n-form-item>
  </n-form>
</template>

<script>
import JsonViewer from "vue-json-viewer";
import "vue-json-viewer/style.css";
import "vue3-json-viewer/dist/index.css";
</script>
```

