---
title: "Golang中使用defer语句修改返回值会发生什么？"
subtitle: ""
date: 2024-03-18T15:41:27+08:00
lastmod: 2024-03-18T15:41:27+08:00
draft: false
author: "PanJM"
authorLink: "https://github.com/pjimming/"
description: ""
license: ""
images: []

tags: [golang, defer, interview]
categories: [golang]

featuredImage: "https://fastly.jsdelivr.net/gh/pjimming/picx-images-hosting@master/20240318/imageimage.6wqhguvv2r.webp"
featuredImagePreview: "https://fastly.jsdelivr.net/gh/pjimming/picx-images-hosting@master/20240318/imageimage.6wqhguvv2r.webp"

outdatedInfoWarning: true
---

探究在 `defer` 中修改返回值，对结果是否产生变化

<!--more-->

---

## 无名返回值

```go
// Result: 1
func test01() int {
	ret := 1
	defer func() {
		ret++
	}()
	return ret
}


// Result: 1
func test02() int {
	ret := 1
	defer func(ret int) {
		ret++
	}(ret)
	return ret
}
```

其中`ret`在函数内定义，是一个局部变量，此时执行`return ret`时，函数的返回值就等于了`ret = 1`，因此后续在`defer`语句中，无论如何修改`ret`的值，返回值不变。

## 有名返回值

```go
// Result: 2
func test03() (ret int) {
	ret = 1
	defer func() {
		ret++
	}()
	return ret
}
```

其中 `ret` 在函数签名时就已经定义，因此返回值就是 `ret`，后续对 `ret` 的修改，就是对返回值的修改。

```go
// Result: 1
func test04() (ret int) {
	ret = 1
	defer func(ret int) {
		ret++
	}(ret)
	return
}
```

需要注意的是，在 `defer` 中传入 `ret` 参数时，此时 `defer` 中的 `ret` 为形参，指向的是一个新的内存地址，因此不会对返回值进行影响。

## 返回值为指针

```go
// Result: 10
func test05() *int {
	var ret int
	defer func() {
		ret = 10
	}()
	return &ret
}

// Result: 0
func test06() *int {
	var ret int
	defer func(ret int) {
		ret = 10
	}(ret)
	return &ret
}

// Result: 10
func test07() *int {
	var ret int
	defer func(ret *int) {
		*ret = 10
	}(&ret)
	return &ret
}
```

此时函数的返回值为指向`ret`的指针，后续对`ret`进行内容上的修改，指针指向`ret`的内容，因此返回值会因为`defer`的操作而改变。

同时需要注意，在`defer`里如果没有传入指针，而是`ret`的形参时，由于拷贝赋值，修改的不是`ret`所指向的内存空间，因此返回值不变。

## 总结

`defer` 对返回值修改的情况：

- **无名返回值**：不会修改返回值；
- **有名返回值**：如果在 `defer` 里修改返回值，并且以闭包的形式修改，那么返回值会被修改；
- **返回值为指针**：如果修改返回值指向的内存空间，那么 `defer` 会修改返回值。

### 代码

```go
package defer_test

import (
	"testing"
)

func test01() int {
	ret := 1
	defer func() {
		ret++
	}()
	return ret
}

func test02() int {
	ret := 1
	defer func(ret int) {
		ret++
	}(ret)
	return ret
}

func test03() (ret int) {
	ret = 1
	defer func() {
		ret++
	}()
	return ret
}

func test04() (ret int) {
	ret = 1
	defer func(ret int) {
		ret++
	}(ret)
	return
}

func test05() *int {
	var ret int
	defer func() {
		ret = 10
	}()
	return &ret
}

func test06() *int {
	var ret int
	defer func(ret int) {
		ret = 10
	}(ret)
	return &ret
}

func test07() *int {
	var ret int
	defer func(ret *int) {
		*ret = 10
	}(&ret)
	return &ret
}

func TestDefer(t *testing.T) {
	t.Logf("test01: %d", test01())
	t.Logf("test02: %d", test02())
	t.Logf("test03: %d", test03())
	t.Logf("test04: %d", test04())
	t.Logf("test05: %d", *test05())
	t.Logf("test06: %d", *test06())
	t.Logf("test07: %d", *test07())
}
```

### 执行结果

```
=== RUN   TestDefer
    defer_test.go:64: test01: 1
    defer_test.go:65: test02: 1
    defer_test.go:66: test03: 2
    defer_test.go:67: test04: 1
    defer_test.go:68: test05: 10
    defer_test.go:69: test06: 0
    defer_test.go:70: test07: 10
--- PASS: TestDefer (0.00s)
PASS
```
