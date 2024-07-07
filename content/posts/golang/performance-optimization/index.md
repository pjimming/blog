---
title: "Golang高性能优化实战案例"
subtitle: ""
date: 2024-03-21T15:46:58+08:00
lastmod: 2024-03-21T15:46:58+08:00
draft: false
author: "PanJM"
authorLink: "https://github.com/pjimming/"
description: ""
license: ""
images: []

tags: [golang, 性能优化]
categories: [golang]

featuredImage: "https://cdn.jsdelivr.net/gh/pjimming/picx-images-hosting@master/20240321/imageimage.3d4jvb9pj3.webp"
featuredImagePreview: "https://cdn.jsdelivr.net/gh/pjimming/picx-images-hosting@master/20240321/imageimage.3d4jvb9pj3.webp"

outdatedInfoWarning: true
---

介绍 Golang 编码中，对于性能方面的调优方法

<!--more-->

---

{{<admonition note "前言">}}

- 性能优化的前提是满足正确、可靠、健壮、可读
- 性能优化时综合评估，有时候时间效率和空间效率可能会相互对立
- 该文章中涉及到的代码：[https://github.com/pjimming/blog-code/tree/main/go-performance-optimization](https://github.com/pjimming/blog-code/tree/main/go-performance-optimization)

{{</admonition>}}

## 性能衡量工具：Benchmark

[Go benchmark 详解 ](https://www.cnblogs.com/yahuian/p/go-benchmark.html)

接下来测试下列代码的性能

```go
func Fib(n int) int {
	if n < 2 {
		return n
	}
	return Fib(n-1) + Fib(n-2)
}

func BenchmarkFib10(b *testing.B) {
	for i := 0; i < b.N; i++ {
		Fib(10)
	}
}
```

通过运行 `go test -bench=. -benchmem` 来统计代码占用内存信息

```bash
(base) ➜  benchmark git:(main) ✗ go test -bench=. -benchmem
goos: darwin
goarch: amd64
pkg: go-performance-optimization/benchmark
cpu: Intel(R) Core(TM) i5-7360U CPU @ 2.30GHz
BenchmarkFib10-4         4193748               291.2 ns/op             0 B/op          0 allocs/op
PASS
ok      go-performance-optimization/benchmark   2.111s
(base) ➜  benchmark git:(main) ✗
```

对于运行结果第六行的参数解析：

- `BenchmarkFib10-4`：`BenchmarkFib10` 是测试函数名，`-4` 代表 `GOMAXPROCS` 的值为 4
- `4193748`：表示一共执行了 4193748，即 `b.N` 的值
- `291.2 ns/op`：每次执行花费 `291.2ns`
- `0 B/op`：每次执行申请的内存
- `0 allocs/op`：每次执行申请几次内存

## Slice：优化内存空间

### 预分配内存

尽可能在使用 make()初始化切片时提供容量信息

测试代码：

```go
func NoPreAlloc(size int) {
	data := make([]int, 0)
	for i := 0; i < size; i++ {
		data = append(data, i)
	}
}

func PreAlloc(size int) {
	data := make([]int, 0, size)
	for i := 0; i < size; i++ {
		data = append(data, i)
	}
}

func BenchmarkNoPreAlloc(b *testing.B) {
	for i := 0; i < b.N; i++ {
		NoPreAlloc(1000)
	}
}

func BenchmarkPreAlloc(b *testing.B) {
	for i := 0; i < b.N; i++ {
		PreAlloc(1000)
	}
}
```

运行结果：

```bash
(base) ➜  go-performance-optimization git:(main) ✗ go test ./slice -bench=. -benchmem
goos: darwin
goarch: amd64
pkg: go-performance-optimization/slice
cpu: Intel(R) Core(TM) i5-7360U CPU @ 2.30GHz
BenchmarkNoPreAlloc-4             217953              4963 ns/op           25208 B/op         12 allocs/op
BenchmarkPreAlloc-4               640620              1809 ns/op            8192 B/op          1 allocs/op
PASS
ok      go-performance-optimization/slice       2.890s
```

### 陷阱：大内存未释放

在已有切片的基础上创建切片，不会创建新的底层数组

场景：

- 原切片较大，代码在原切片的基础上新建小切片
- 原底层数组在内存中有引用，得不到释放

解决：使用 copy 替代 re-slice

代码：

```go
func generateWithCap(n int) []int {
	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	nums := make([]int, 0, n)
	for i := 0; i < n; i++ {
		nums = append(nums, r.Int())
	}
	return nums
}

func printMem(t *testing.T) {
	t.Helper()
	var rtm runtime.MemStats
	runtime.ReadMemStats(&rtm)
	t.Logf("%.2f MB", float64(rtm.Alloc)/1024./1024.)
}

func testLastChars(t *testing.T, f func([]int) []int) {
	t.Helper()
	ans := make([][]int, 0)
	for k := 0; k < 100; k++ {
		origin := generateWithCap(128 * 1024) // 1M
		ans = append(ans, f(origin))
	}
	printMem(t)
	_ = ans
}

func GetLastBySlice(origin []int) []int {
	return origin[len(origin)-2:]
}

func GetLastByCopy(origin []int) []int {
	ret := make([]int, 2)
	copy(ret, origin[len(origin)-2:])
	return ret
}

func TestLastCharsBySlice(t *testing.T) {
	testLastChars(t, GetLastBySlice)
}

func TestLastCharsByCopy(t *testing.T) {
	testLastChars(t, GetLastByCopy)
}
```

运行结果：

```bash
(base) ➜  go-performance-optimization git:(main) ✗ go test ./slice -run=^TestLastChars -v
=== RUN   TestLastCharsBySlice
    slice_test.go:74: 100.24 MB
--- PASS: TestLastCharsBySlice (0.15s)
=== RUN   TestLastCharsByCopy
    slice_test.go:78: 3.12 MB
--- PASS: TestLastCharsByCopy (0.15s)
PASS
ok      go-performance-optimization/slice       0.759s
```

结果差异非常明显，`lastNumsBySlice` 耗费了 100.24 MB 内存，也就是说，申请的 100 个 1 MB 大小的内存没有被回收。因为切片虽然只使用了最后 2 个元素，但是因为与原来 1M 的切片引用了相同的底层数组，底层数组得不到释放，因此，最终 100 MB 的内存始终得不到释放。而 `lastNumsByCopy` 仅消耗了 3.12 MB 的内存。这是因为，通过 `copy`，指向了一个新的底层数组，当 origin 不再被引用后，内存会被垃圾回收(garbage collector, GC)。

如果在循环里面显性的调用 `runtime.GC()`，效果更明显：

```go
func testLastChars(t *testing.T, f func([]int) []int) {
	t.Helper()
	ans := make([][]int, 0)
	for k := 0; k < 100; k++ {
		origin := generateWithCap(128 * 1024) // 1M
		ans = append(ans, f(origin))
		runtime.GC() // 显性垃圾回收
	}
	printMem(t)
	_ = ans
}
```

执行结果：

```bash
(base) ➜  go-performance-optimization git:(main) ✗ go test ./slice -run=^TestLastChars -v
=== RUN   TestLastCharsBySlice
    slice_test.go:75: 100.11 MB
--- PASS: TestLastCharsBySlice (0.14s)
=== RUN   TestLastCharsByCopy
    slice_test.go:79: 0.11 MB
--- PASS: TestLastCharsByCopy (0.09s)
PASS
ok      go-performance-optimization/slice       0.812s
```

## Map：预分配内存

- 不断向 `map` 里添加元素的操作会触发 `map` 的扩容
- 提前分配好空间可以减少内存拷贝以及 `Rehash` 的消耗
- 根据实际需求提前预估好需要的空间

代码：

```go
func NoPreAlloc(size int) {
	data := make(map[int]int)
	for i := 0; i < size; i++ {
		data[i] = i
	}
}

func PreAlloc(size int) {
	data := make(map[int]int, size)
	for i := 0; i < size; i++ {
		data[i] = i
	}
}

func BenchmarkNoPreAlloc(b *testing.B) {
	for i := 0; i < b.N; i++ {
		NoPreAlloc(1000)
	}
}

func BenchmarkPreAlloc(b *testing.B) {
	for i := 0; i < b.N; i++ {
		PreAlloc(1000)
	}
}
```

运行结果：

```bash
(base) ➜  go-performance-optimization git:(main) ✗ go test ./map -bench=. -benchmem
goos: darwin
goarch: amd64
pkg: go-performance-optimization/map
cpu: Intel(R) Core(TM) i5-7360U CPU @ 2.30GHz
BenchmarkNoPreAlloc-4              16059             74349 ns/op           86551 B/op         64 allocs/op
BenchmarkPreAlloc-4                37770             29789 ns/op           41097 B/op          6 allocs/op
PASS
ok      go-performance-optimization/map 3.938s
```

## 字符串：使用`strings.Builder`

常见的字符串拼接方式：

```go
func Plus(n int, str string) string {
	s := ""
	for i := 0; i < n; i++ {
		s += str
	}
	return s
}

func StrBuilder(n int, str string) string {
	var builder strings.Builder
	for i := 0; i < n; i++ {
		builder.WriteString(str)
	}
	return builder.String()
}

func ByteBuffer(n int, str string) string {
	buf := new(bytes.Buffer)
	for i := 0; i < n; i++ {
		buf.WriteString(str)
	}
	return buf.String()
}

func BenchmarkPlus(b *testing.B) {
	for i := 0; i < b.N; i++ {
		Plus(100, "abc")
	}
}

func BenchmarkStrBuilder(b *testing.B) {
	for i := 0; i < b.N; i++ {
		StrBuilder(100, "abc")
	}
}

func BenchmarkByteBuffer(b *testing.B) {
	for i := 0; i < b.N; i++ {
		ByteBuffer(100, "abc")
	}
}
```

运行结果：

```bash
(base) ➜  go-performance-optimization git:(main) ✗ go test ./string -bench=. -benchmem
goos: darwin
goarch: amd64
pkg: go-performance-optimization/string
cpu: Intel(R) Core(TM) i5-7360U CPU @ 2.30GHz
BenchmarkPlus-4                   181742              6054 ns/op           15992 B/op         99 allocs/op
BenchmarkStrBuilder-4            2173779               689.9 ns/op          1016 B/op          7 allocs/op
BenchmarkByteBuffer-4            1253618               915.8 ns/op          1280 B/op          5 allocs/op
PASS
ok      go-performance-optimization/string      5.977s
```

结论：使用`+`拼接性能最差，`strings.Builder`, `bytes.Buffer` 相近，`strings.Buffer` 更快

分析：

- 字符串在 Go 中是不可变类型，所占内存大小是固定的
- 每次`+`操作都会重新分配内存
- 而`strings.Builder` 和 `bytes.Buffer` 底层都是`[]byte` 数组
- 通过 `slice` 扩容策略，不需要每次拼接都分配内存

### 为什么 `strings.Builder` 更快？

先上源码：

```go
// strings.Builder
// String returns the accumulated string.
func (b *Builder) String() string {
	return unsafe.String(unsafe.SliceData(b.buf), len(b.buf))
}

// bytes.Buffer
// String returns the contents of the unread portion of the buffer
// as a string. If the [Buffer] is a nil pointer, it returns "<nil>".
//
// To build strings more efficiently, see the strings.Builder type.
func (b *Buffer) String() string {
	if b == nil {
		// Special case, useful in debugging.
		return "<nil>"
	}
	return string(b.buf[b.off:])
}
```

根据源码可知：

- `bytes.Buffer` 转化为字符串时重新分配了一块空间
- `strings.Builder` 直接将底层的 `[]byte` 转换成了字符串

### 字符串也可以预分配内存

```go
func PreStrBuilder(n int, str string) string {
	var builder strings.Builder
	builder.Grow(n * len(str))
	for i := 0; i < n; i++ {
		builder.WriteString(str)
	}
	return builder.String()
}

func PreByteBuffer(n int, str string) string {
	buf := new(bytes.Buffer)
	buf.Grow(n * len(str))
	for i := 0; i < n; i++ {
		buf.WriteString(str)
	}
	return buf.String()
}

func BenchmarkPreStrBuilder(b *testing.B) {
	for i := 0; i < b.N; i++ {
		PreStrBuilder(100, "abc")
	}
}

func BenchmarkPreByteBuffer(b *testing.B) {
	for i := 0; i < b.N; i++ {
		PreByteBuffer(100, "abc")
	}
}
```

运行结果：

```bash
(base) ➜  go-performance-optimization git:(main) ✗ go test ./string -bench=. -benchmem
goos: darwin
goarch: amd64
pkg: go-performance-optimization/string
cpu: Intel(R) Core(TM) i5-7360U CPU @ 2.30GHz
BenchmarkPlus-4                   191355              6443 ns/op           15992 B/op         99 allocs/op
BenchmarkStrBuilder-4            2216818               503.1 ns/op          1016 B/op          7 allocs/op
BenchmarkByteBuffer-4            1288650              1528 ns/op            1280 B/op          5 allocs/op
BenchmarkPreStrBuilder-4         2805319               468.2 ns/op           320 B/op          1 allocs/op
BenchmarkPreByteBuffer-4         1594519               877.2 ns/op           640 B/op          2 allocs/op
PASS
ok      go-performance-optimization/string      12.373s
```

根据上面的运行结果可知，`bytes.Buffer` 分配了两次内存

## 空结构体：节省内存资源

空结构体实例不占据任何内存空间，可作为各场景下的占位符使用，比如用 `map` 实现 `set`

```go
func EmptyStructMap(n int) {
	m := make(map[int]struct{})
	for i := 0; i < n; i++ {
		m[i] = struct{}{}
	}
}

func BoolMap(n int) {
	m := make(map[int]bool)
	for i := 0; i < n; i++ {
		m[i] = false
	}
}

func BenchmarkEmptyStructMap(b *testing.B) {
	for i := 0; i < b.N; i++ {
		EmptyStructMap(1000)
	}
}

func BenchmarkBoolMap(b *testing.B) {
	for i := 0; i < b.N; i++ {
		BoolMap(1000)
	}
}
```

运行结果：

```bash
(base) ➜  go-performance-optimization git:(main) ✗ go test ./struct -bench=. -benchmem
goos: darwin
goarch: amd64
pkg: go-performance-optimization/struct
cpu: Intel(R) Core(TM) i5-7360U CPU @ 2.30GHz
BenchmarkEmptyStructMap-4          17043             84522 ns/op           47735 B/op         65 allocs/op
BenchmarkBoolMap-4                 10000            130275 ns/op           53316 B/op         73 allocs/op
PASS
ok      go-performance-optimization/struct      4.088s
```

## `atomic` 包：并发情况下的资源保护

- 锁的实现是通过操作系统来实现，属于系统调用
- `atomic` 通过硬件实现，效率比锁高
- `sync.Mutex` 应该用于保护一段逻辑，而非仅仅保护一个变量
- 对于非数值操作，可以使用 `atomic.Value`，可以承载一个 `interface{}`

代码：

```go
type atomicCounter struct {
	i int32
}

func AtomicAddOne(c *atomicCounter) {
	atomic.AddInt32(&c.i, 1)
}

type mutexCounter struct {
	i int32
	sync.Mutex
}

func MutexAddOne(c *mutexCounter) {
	c.Lock()
	c.i++
	c.Unlock()
}

func BenchmarkAtomicAddOne(b *testing.B) {
	for i := 0; i < b.N; i++ {
		c := new(atomicCounter)
		AtomicAddOne(c)
	}
}

func BenchmarkMutexAddOne(b *testing.B) {
	for i := 0; i < b.N; i++ {
		c := new(mutexCounter)
		MutexAddOne(c)
	}
}
```

运行结果：

```bash
(base) ➜  go-performance-optimization git:(main) ✗ go test ./atomic -bench=. -benchmem
goos: darwin
goarch: amd64
pkg: go-performance-optimization/atomic
cpu: Intel(R) Core(TM) i5-7360U CPU @ 2.30GHz
BenchmarkAtomicAddOne-4         69622866                17.44 ns/op            4 B/op          1 allocs/op
BenchmarkMutexAddOne-4          34958937                32.44 ns/op           16 B/op          1 allocs/op
PASS
ok      go-performance-optimization/atomic      3.967s
```

## 小结

- 避免常见的性能陷阱可以保证大部分程序的性能
- 普通应用，不要一味地追求程序的性能
- 越高深的性能优化手段越容易出现问题
- 在满足正确、可靠、简洁、清晰等质量要求的前提下，提高程序性能

## 参考

- [Go 语言高性能编程](https://geektutu.com/post/high-performance-go.html)
