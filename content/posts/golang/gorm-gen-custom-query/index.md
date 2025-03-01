---
title: "实现Gorm Gen自定义查询语句"
subtitle: ""
date: 2025-03-01T14:55:25+08:00
lastmod: 2025-03-01T14:55:25+08:00
draft: false
author: "PanJM"
authorLink: "https://github.com/pjimming/"
description: ""
license: ""
images: []

tags: [golang, gorm]
categories: [golang]

featuredImage: "https://cdn-cf.pjmcode.top/picgo/1740813737.png"
featuredImagePreview: "https://cdn-cf.pjmcode.top/picgo/1740813737.png"

outdatedInfoWarning: true
---

通过自定义 datatypes，实现 gorm gen 自定义查询语句。

<!--more-->

---

## 背景

MySQL 在 5.7 版本后就支持了 json 类型的存储，这为某个字段提供了一种结构化的能力。在部分后台场景会有针对 json 数据查询的场景，调研了下，可以使用 json 内置了部分函数 `JSON_EXTRACT`, `JSON_OVERLAPS`, `JSON_CONTAINS` 来支持。

Gorm 针对这类场景有一个 [datatypes](https://github.com/go-gorm/datatypes) 项目，来支持这种结构化的查询条件。但接口设计和定义上还是比较鸡肋的，对 json 支持的也不够完整。

## 详细设计

在 Gorm 的接口设计上，可以看到`Where()`条件接收的是一个 `Condition` 的 `interface{}`

```go
type (
	// Condition query condition
	// field.Expr and subquery are expect value
	Condition interface {
		BeCond() interface{}
		CondError() error
	}
)
```

就很自然的想到了使用自定义 Condition 实现，代码也非常精简，如下：

```go
// pkg/cdatatypes/cdatatypes.go
package cdatatypes

import (
    "gorm.io/gen/field"
    "gorm.io/gorm/clause"
)

type ExprCond struct {
    clause.Expr
    field.String
}

func Cond(expr clause.Expr) *ExprCond {
    return &ExprCond{
        Expr:   expr,
        String: field.String{},
    }
}

func (c *ExprCond) BeCond() interface{} { return c.Expr }

func (c *ExprCond) CondError() error { return nil }
```

在实际使用中，就可以通过下面的方式生产 `Where()` 需要的条件：

```go
cdatatypes.Cond(gorm.Expr("JSON_OVERLAPS(JSON_EXTRACT(`query`, '$.query_list'), ?)", querys))

// JSON_OVERLAPS(JSON_EXTRACT(`query`, '$.query_list'), '["自定义查询"]')
```

这样既不会打破 gorm gen 提供的语义化模型，还很灵活的支持了各种自定义 SQL。
