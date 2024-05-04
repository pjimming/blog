---
title: "『实战』使用Golang实现Redis经典应用案例"
subtitle: ""
date: 2024-03-26T14:18:00+08:00
lastmod: 2024-03-26T14:18:00+08:00
draft: false
author: "PanJM"
authorLink: "https://github.com/pjimming/"
description: ""
license: ""
images: []

tags: [redis, golang, 实战]
categories: [redis]

featuredImage: "https://www.jsdelivr.ren/gh/pjimming/picx-images-hosting@master/20240326/image-image.969ibnzd46.webp"
featuredImagePreview: "https://www.jsdelivr.ren/gh/pjimming/picx-images-hosting@master/20240326/image-image.969ibnzd46.webp"

outdatedInfoWarning: true
---

使用 Golang+Redis 实现一些经典业务案例，如签到功能、分布式锁、限流器、消息队列、计数器、排行榜、订阅发布等

<!--more-->

---

{{<admonition note "前言">}}

该文章中涉及到的代码：[https://github.com/pjimming/blog-code/tree/main/go-redis-example](https://github.com/pjimming/blog-code/tree/main/go-redis-example)

{{</admonition>}}

## 00-预先准备

项目文件架构：

```bash
(base) ➜  go-redis-example git:(main) tree .
.
├── Makefile
├── README.md
├── common
│   ├── concurrent_event_log.go
│   └── coucurrent_routine.go
├── example
│   ├── ex01_checkin.go
│   ├── ex02_setnx.go
│   ├── ex03_limiter.go
│   ├── ex04_message.go
│   ├── ex05_hash_count.go
│   ├── ex06_ranking.go
│   ├── ex07_pubsub.go
│   ├── redis_client.go
│   └── redis_client_test.go
├── go.mod
├── go.sum
└── main.go

3 directories, 16 files
```

### 下载 Go 第三方包依赖

```bash
go get github.com/redis/go-redis/v9
go get github.com/stretchr/testify
```

### 初始化 Redis 连接

1. 确保有一个 Redis 环境，若本地没有，请自行使用搜索引擎进行安装
2. 编写以下代码，初始化 Redis 连接

   ```go
   // example/redis_client.go
   package example

   import (
       "context"

       "github.com/redis/go-redis/v9"
   )

   var RedisCli *redis.Client

   func init() {
       RedisCli = redis.NewClient(&redis.Options{
           Addr:     "127.0.0.1:6379", // Your Redis Address
           Password: "123456",         // Your Redis Password
       })
       if err := RedisCli.Ping(context.Background()).Err(); err != nil {
           panic(err)
       }
   }
   ```

3. 编写测试代码，测试连接是否成功

   ```go
   // example/redis_client_test.go
   package example

   import (
       "context"
       "testing"

       "github.com/stretchr/testify/assert"
   )

   func TestNewRedis(t *testing.T) {
       ast := assert.New(t)
       ast.NotNil(RedisCli)

       ast.Nil(RedisCli.Ping(context.Background()).Err())
   }
   ```

   执行命令：`go test ./example -run="^TestNewRedis"`

   得到如下结果表示测试通过，Redis 连接初始化成功：

   ```bash
   (base) ➜  go-redis-example git:(main) ✗ go test ./example -run="^TestNewRedis"
   ok      go-redis-example/example        0.287s
   ```

### 通用方法

在 `common` 文件夹下新建两个文件，分别是 `concurrent_event_log.go` 和 `concurrent_routine.go`

#### `common/concurrent_event_log.go`: 日志收集及打印工具

```go
package common

import (
	"context"
	"fmt"
	"sort"
	"time"
)

type ConcurrentEventLogger struct {
	eventLogs []EventLog
}

// EventLog 搜集日志的结构
type EventLog struct {
	EventTime time.Time
	Log       string
}

func NewConcurrentEventLog(ctx context.Context, logsLength int) *ConcurrentEventLogger {
	if logsLength <= 0 {
		logsLength = 32
	}
	logContainer := make([]EventLog, 0, logsLength)
	return &ConcurrentEventLogger{eventLogs: logContainer}
}

// Append 追加日志
func (ceLog *ConcurrentEventLogger) Append(mLog EventLog) {
	ceLog.eventLogs = append(ceLog.eventLogs, mLog)
}

// PrintLogs  日志按时间正序输出
func (ceLog *ConcurrentEventLogger) PrintLogs() {
	sort.Slice(ceLog.eventLogs, func(i, j int) bool {
		return ceLog.eventLogs[i].EventTime.Before(ceLog.eventLogs[j].EventTime)
	})
	for i := range ceLog.eventLogs {
		fmt.Println(ceLog.eventLogs[i].Log)
	}
}

// LogFormat 包含通用日志前缀 [2022-11-27T12:36:00.213454+08:00] routine[5]
func LogFormat(routine int, format string, a ...any) string {
	tpl := "[%s] routine[%d] " + format
	sr := []any{
		time.Now().Format(time.RFC3339Nano),
		routine,
	}
	sr = append(sr, a...)
	return fmt.Sprintf(tpl, sr...)
}
```

#### `common/concurrent_routine.go`: 并发执行器

```go
package common

import (
	"context"
	"sync"
)

// ConcurrentRoutine 并发执行器对象定义
type ConcurrentRoutine struct {
	routineNums           int                    // 定义并发协程的数量
	concurrentEventLogger *ConcurrentEventLogger // 并发日志搜集器
}

// CInstParams 定义传入callBack的参数
type CInstParams struct {
	Routine               int // 协程编号
	ConcurrentEventLogger *ConcurrentEventLogger
	CustomParams          interface{} // 用户自定义参数
}

type callBack func(ctx context.Context, params CInstParams) // 定义一个用户自定义执行函数

// NewConcurrentRoutine 初始化一个并发执行器
func NewConcurrentRoutine(
	routineNums int,
	concurrentEventLog *ConcurrentEventLogger,
) *ConcurrentRoutine {
	return &ConcurrentRoutine{
		routineNums:           routineNums,
		concurrentEventLogger: concurrentEventLog,
	}
}

// Run 并发执行用户自定义函数 workFun
func (cInst *ConcurrentRoutine) Run(ctx context.Context, customParams interface{}, workFun callBack) {
	wg := &sync.WaitGroup{}
	for i := 0; i < cInst.routineNums; i++ {
		mRoutine := i
		wg.Add(1)
		// 启动协程模拟并发逻辑
		go func(mCtx context.Context, mRoutine int, mParams interface{}) {
			defer wg.Done()
			workFun(
				mCtx,
				CInstParams{
					Routine:               mRoutine,
					ConcurrentEventLogger: cInst.concurrentEventLogger,
					CustomParams:          mParams,
				},
            )
		}(ctx, mRoutine, customParams)
	}
	wg.Wait()
}
```

### main 方法

作为程序的入口，我们为了更好的运行实现好的案例，需要对输入的参数进行解析。例如要运行的 Example，运行需要的参数信息等。

`main.go`代码如下：

```go
package main

import (
	"context"
	"fmt"
	"os"
	"strings"

	"go-redis-example/example"
)

func main() {
	defer func() {
		_ = example.RedisCli.Close()
	}()

	argsProg := os.Args
	var argsWithoutProg []string
	if len(argsProg) > 0 {
		argsWithoutProg = os.Args[1:]
		fmt.Printf("输入参数:\n%s\n----------\n", strings.Join(argsWithoutProg, "\n"))
	}
	ctx := context.Background()
	runExample := argsWithoutProg[0]
	exampleParams := argsWithoutProg[1:]

	switch runExample {
	case "Ex01":
		example.Ex01(ctx, exampleParams)
	case "Ex02":
		example.Ex02(ctx)
	case "Ex03":
		example.Ex03(ctx)
	case "Ex04":
		example.Ex04(ctx)
	case "Ex05":
		example.Ex05(ctx, exampleParams)
	case "Ex06":
		example.Ex06(ctx, exampleParams)
	case "Ex07":
		example.Ex07(ctx)
	default:
		panic(fmt.Sprintf("not support type: %s", runExample))
	}
}
```

暂未实现的 example 注释即可，等实现完成之后，记得取消注释，否则无法运行。

到此为止，我们预先的准备工作都已经就绪，现在开始实战案例。

## 01-基于`Incr`的签到功能

### 业务分析

对于每日签到功能，我们需要记录连续签到天数，并且如果用户在当天没有签到的话，清空计数。

可以发现使用 Redis 的 String 类型搭配设置过期时间就可以很好的解决这个问题。

对于过期时间的设置，如果我们在当天签到成功，则第二天不签到就会清空计数。所以把过期时间设置在第三天的凌晨 0 点即可。

### 代码实现

```go
package example

import (
	"context"
	"fmt"
	"log"
	"strconv"
	"time"
)

const continueCheckKey = "cc_uid_%d"

func Ex01(ctx context.Context, params []string) {
	userID, err := strconv.ParseInt(params[0], 10, 64)
	if err != nil {
		err = fmt.Errorf("参数错误：params = %+v, error = %v", params, err)
		panic(err)
	}
	ex01AddContinueDays(ctx, userID)
}

// 用户签到
func ex01AddContinueDays(ctx context.Context, userID int64) {
	key := ex01GetContinueCheckKey(userID)
	// 1. 签到天数+1
	if err := RedisCli.Incr(ctx, key).Err(); err != nil {
		err = fmt.Errorf("user[%d]签到失败, %v", userID, err)
		panic(err)
	}

	// 2. 设置签到时间为后天0点过期
	expAt := ex01BeginningOfDay().Add(48 * time.Hour)
	if err := RedisCli.ExpireAt(ctx, key, expAt).Err(); err != nil {
		panic(err)
	}

	// 3. 打印用户签到天数
	day, err := ex01GetUserCheckInDays(ctx, userID)
	if err != nil {
		panic(err)
	}
	log.Printf("User[%d]连续签到：%d天，过期时间：%s", userID, day, expAt.Format("2006-01-02 15:04:05"))
}

// 获取用户签到天数
func ex01GetUserCheckInDays(ctx context.Context, userID int64) (int64, error) {
	key := ex01GetContinueCheckKey(userID)
	days, err := RedisCli.Get(ctx, key).Result()
	if err != nil {
		return 0, err
	}

	daysInt, err := strconv.ParseInt(days, 10, 64)
	if err != nil {
		return 0, err
	}
	return daysInt, nil
}

// 获取今天0点时间
func ex01BeginningOfDay() time.Time {
	now := time.Now()
	y, m, d := now.Date()
	return time.Date(y, m, d, 0, 0, 0, 0, time.Local)
}

// 获取记录签到天数的key
func ex01GetContinueCheckKey(userID int64) string {
	return fmt.Sprintf(continueCheckKey, userID)
}
```

### 测试功能：`go run main.go Ex01 1165894833417101`

```bash
(base) ➜  go-redis-example git:(main) ✗ go run main.go Ex01 1165894833417101
输入参数:
Ex01
1165894833417101
----------
2024/03/26 15:25:05 User[1165894833417101]连续签到：1天，过期时间：2024-03-28 00:00:00
(base) ➜  go-redis-example git:(main) ✗ go run main.go Ex01 1165894833417101
输入参数:
Ex01
1165894833417101
----------
2024/03/26 15:25:09 User[1165894833417101]连续签到：2天，过期时间：2024-03-28 00:00:00
```

## 02-基于`SETNX`的分布式锁

并发场景下，要求同时只有一个进程执行。即分布式情况下的逻辑、资源保护。

使用 redis 的 `setnx` 实现：

- 单线程，且可以保证原子性
- 只有不存在 key 时才可以执行成功

{{<admonition warning>}}
只是体验 SetNX 的特性，不是高可用的分布式锁实现

该实现存在的问题:

1. 业务超时解锁，导致并发问题。业务执行时间超过锁超时时间
2. redis 主备切换临界点问题。主备切换后，A 持有的锁还未同步到新的主节点时，B 可在新主节点获取锁，导致并发问题。
3. redis 集群脑裂，导致出现多个主节点

{{</admonition>}}

### 代码实现

```go
package example

import (
	"context"
	"fmt"
	"strconv"
	"time"

	"go-redis-example/common"
)

const (
	resourceKey = "syncKey"              // 分布式锁的key
	expTime     = 800 * time.Millisecond // 锁的过期时间，避免死锁
)

type Ex02Params struct {
}

// Ex02 只是体验SetNX的特性，不是高可用的分布式锁实现
// 该实现存在的问题:
// (1) 业务超时解锁，导致并发问题。业务执行时间超过锁超时时间
// (2) redis主备切换临界点问题。主备切换后，A持有的锁还未同步到新的主节点时，B可在新主节点获取锁，导致并发问题。
// (3) redis集群脑裂，导致出现多个主节点
func Ex02(ctx context.Context) {
	eventLogger := common.NewConcurrentEventLog(ctx, 32)
	// new一个并发执行器
	cInst := common.NewConcurrentRoutine(10, eventLogger)
	// 并发执行自定义work
	cInst.Run(ctx, Ex02Params{}, ex02Work)
	// 按时间顺序输出日志
	eventLogger.PrintLogs()
}

func ex02Work(ctx context.Context, cInstParams common.CInstParams) {
	routine := cInstParams.Routine
	eventLogger := cInstParams.ConcurrentEventLogger
	defer ex02ReleaseLock(ctx, routine, eventLogger)
	for {
		// 1. 尝试获取锁
		acquired, err := RedisCli.SetNX(ctx, resourceKey, routine, expTime).Result()
		if err != nil {
			err = fmt.Errorf("[%s] error routine[%d], %v", time.Now().Format(time.RFC3339Nano), routine, err)
			eventLogger.Append(common.EventLog{
				EventTime: time.Now(),
				Log:       err.Error(),
			})
			panic(err)
		}

		if acquired {
			// 2. 成功获取
			eventLogger.Append(common.EventLog{
				EventTime: time.Now(),
				Log:       fmt.Sprintf("[%s] routine[%d] 获取锁", time.Now().Format(time.RFC3339Nano), routine),
			})
			// 3. 模拟业务
			time.Sleep(10 * time.Millisecond)
			eventLogger.Append(common.EventLog{
				EventTime: time.Now(),
				Log:       fmt.Sprintf("[%s] routine[%d] 完成业务逻辑", time.Now().Format(time.RFC3339Nano), routine),
			})
			return
		}
		// 没有获取到锁，等待后重试
		time.Sleep(100 * time.Millisecond)
	}
}

func ex02ReleaseLock(ctx context.Context, routine int, eventLogger *common.ConcurrentEventLogger) {
	routineMark, _ := RedisCli.Get(ctx, resourceKey).Result()
	if strconv.FormatInt(int64(routine), 10) != routineMark {
		// 其它协程误删lock
		panic(fmt.Sprintf("del err lock[%s] can not del by [%d]", routineMark, routine))
	}
	result, err := RedisCli.Del(ctx, resourceKey).Result()
	if result == 1 {
		eventLogger.Append(common.EventLog{
			EventTime: time.Now(),
			Log:       fmt.Sprintf("[%s] routine[%d] 释放锁", time.Now().Format(time.RFC3339Nano), routine),
		})
	} else {
		eventLogger.Append(common.EventLog{
			EventTime: time.Now(),
			Log:       fmt.Sprintf("[%s] routine[%d] no lock to del", time.Now().Format(time.RFC3339Nano), routine),
		})
	}
	if err != nil {
		err = fmt.Errorf("[%s] error routine=%d, %v", time.Now().Format(time.RFC3339Nano), routine, err)
		eventLogger.Append(common.EventLog{
			EventTime: time.Now(),
			Log:       err.Error(),
		})
		panic(err)
	}
}
```

### 测试功能：`go run main.go Ex02`

```bash
(base) ➜  go-redis-example git:(main) go run main.go Ex02
输入参数:
Ex02
----------
[2024-03-26T15:53:27.623764+08:00] routine[9] 获取锁
[2024-03-26T15:53:27.634651+08:00] routine[9] 完成业务逻辑
[2024-03-26T15:53:27.664945+08:00] routine[9] 释放锁
[2024-03-26T15:53:27.743436+08:00] routine[6] 获取锁
[2024-03-26T15:53:27.753794+08:00] routine[6] 完成业务逻辑
[2024-03-26T15:53:27.754277+08:00] routine[6] 释放锁
[2024-03-26T15:53:27.852915+08:00] routine[3] 获取锁
[2024-03-26T15:53:27.863014+08:00] routine[3] 完成业务逻辑
[2024-03-26T15:53:27.864108+08:00] routine[3] 释放锁
[2024-03-26T15:53:27.950776+08:00] routine[5] 获取锁
[2024-03-26T15:53:27.961898+08:00] routine[5] 完成业务逻辑
[2024-03-26T15:53:27.96241+08:00] routine[5] 释放锁
[2024-03-26T15:53:28.052261+08:00] routine[2] 获取锁
[2024-03-26T15:53:28.062988+08:00] routine[2] 完成业务逻辑
[2024-03-26T15:53:28.063701+08:00] routine[2] 释放锁
[2024-03-26T15:53:28.152431+08:00] routine[0] 获取锁
[2024-03-26T15:53:28.162493+08:00] routine[0] 完成业务逻辑
[2024-03-26T15:53:28.162897+08:00] routine[0] 释放锁
[2024-03-26T15:53:28.253946+08:00] routine[7] 获取锁
[2024-03-26T15:53:28.264098+08:00] routine[7] 完成业务逻辑
[2024-03-26T15:53:28.264486+08:00] routine[7] 释放锁
[2024-03-26T15:53:28.354901+08:00] routine[4] 获取锁
[2024-03-26T15:53:28.365065+08:00] routine[4] 完成业务逻辑
[2024-03-26T15:53:28.36569+08:00] routine[4] 释放锁
[2024-03-26T15:53:28.458786+08:00] routine[8] 获取锁
[2024-03-26T15:53:28.469094+08:00] routine[8] 完成业务逻辑
[2024-03-26T15:53:28.471307+08:00] routine[8] 释放锁
[2024-03-26T15:53:28.560792+08:00] routine[1] 获取锁
[2024-03-26T15:53:28.584265+08:00] routine[1] 完成业务逻辑
[2024-03-26T15:53:28.618252+08:00] routine[1] 释放锁
```

## 03-基于`Incr`和`Decr`的简单限流器

要求 1s 内放行的请求为 N，超过 N 的请求次数则禁止访问。

通过 redis 的 string 类型，对 key 进行 `Incr` 和 `Decr` 操作。value 与 N 比对，判断是否放行。

### 代码实现

```go
package example

import (
	"context"
	"fmt"
	"log"
	"sync/atomic"
	"time"

	"go-redis-example/common"
)

type Ex03Params struct {
}

const (
	ex03LimitKeyPreFix = "common_freq_limit" // 限流key前缀
	ex03MaxQPS         = 10                  // 限流次数
)

var (
	accessQueryNum = int32(0)
)

// 返回key格式为：comment_freq_limit-1669524458,
// 用来记录这1秒内的请求数量
func ex03LimitKey(currentTimeStamp time.Time) string {
	return fmt.Sprintf("%s-%d", ex03LimitKeyPreFix, currentTimeStamp.Unix())
}

// Ex03 简单限流
func Ex03(ctx context.Context) {
	eventLogger := common.NewConcurrentEventLog(ctx, 1000)
	// new一个并发执行器
	cInst := common.NewConcurrentRoutine(500, eventLogger)
	// 并发执行自定义函数
	cInst.Run(ctx, Ex03Params{}, ex03Work)
	// 输出日志
	eventLogger.PrintLogs()
	log.Printf("放行总数：%d", accessQueryNum)

	time.Sleep(1 * time.Second)
	fmt.Printf("\n------\n下一秒请求\n------\n")
	// 清空日志信息
	eventLogger = common.NewConcurrentEventLog(ctx, 1000)
	accessQueryNum = 0
	// new一个并发执行器
	cInst = common.NewConcurrentRoutine(10, eventLogger)
	// 并发执行用户自定义函数work
	cInst.Run(ctx, Ex03Params{}, ex03Work)
	// 按日志时间正序打印日志
	eventLogger.PrintLogs()
	log.Printf("放行总数：%d", accessQueryNum)
}

func ex03Work(ctx context.Context, cInstParams common.CInstParams) {
	routine := cInstParams.Routine
	eventLogger := cInstParams.ConcurrentEventLogger
	key := ex03LimitKey(time.Now())
	currentQPS, err := RedisCli.Incr(ctx, key).Result()
	if err != nil {
		panic(err)
	}
	if currentQPS > ex03MaxQPS {
		// 超过流量限制，请求受限
		eventLogger.Append(common.EventLog{
			EventTime: time.Now(),
			Log:       common.LogFormat(routine, "被限流[%d]", currentQPS),
		})
		// sleep模拟业务耗时
		time.Sleep(50 * time.Millisecond)
		if err = RedisCli.Decr(ctx, key).Err(); err != nil {
			panic(err)
		}
	} else {
		// 流量放行
		eventLogger.Append(common.EventLog{
			EventTime: time.Now(),
			Log:       common.LogFormat(routine, "流量放行[%d]", currentQPS),
		})
		atomic.AddInt32(&accessQueryNum, 1)
		time.Sleep(20 * time.Millisecond)
	}
}
```

### 测试功能：`go run main.go Ex03`

```bash
(base) ➜  go-redis-example git:(main) ✗ go run main.go Ex03
输入参数:
Ex03
----------
[2024-03-26T15:59:52.869876+08:00] routine[2] 流量放行[1]
[2024-03-26T15:59:52.87983+08:00] routine[32] 流量放行[2]
[2024-03-26T15:59:52.881233+08:00] routine[33] 流量放行[5]
[2024-03-26T15:59:52.881636+08:00] routine[6] 流量放行[4]
[2024-03-26T15:59:52.88164+08:00] routine[36] 流量放行[3]
[2024-03-26T15:59:52.881844+08:00] routine[25] 被限流[40]
[2024-03-26T15:59:52.881856+08:00] routine[8] 被限流[42]
···
[2024-03-26T15:59:52.894559+08:00] routine[448] 被限流[490]
[2024-03-26T15:59:52.894576+08:00] routine[442] 被限流[491]
[2024-03-26T15:59:52.894657+08:00] routine[450] 被限流[488]
[2024-03-26T15:59:52.894666+08:00] routine[451] 被限流[489]
[2024-03-26T15:59:52.894673+08:00] routine[444] 被限流[487]
[2024-03-26T15:59:52.89473+08:00] routine[498] 被限流[486]
[2024-03-26T15:59:52.89475+08:00] routine[443] 被限流[485]
2024/03/26 15:59:52 放行总数：10

------
下一秒请求
------
[2024-03-26T15:59:53.977507+08:00] routine[1] 流量放行[10]
[2024-03-26T15:59:53.977535+08:00] routine[3] 流量放行[9]
[2024-03-26T15:59:53.977601+08:00] routine[2] 流量放行[8]
[2024-03-26T15:59:53.977656+08:00] routine[8] 流量放行[7]
[2024-03-26T15:59:53.977743+08:00] routine[6] 流量放行[4]
[2024-03-26T15:59:53.977752+08:00] routine[7] 流量放行[5]
[2024-03-26T15:59:53.977759+08:00] routine[0] 流量放行[6]
[2024-03-26T15:59:53.977772+08:00] routine[9] 流量放行[1]
[2024-03-26T15:59:53.977781+08:00] routine[5] 流量放行[3]
[2024-03-26T15:59:53.977785+08:00] routine[4] 流量放行[2]
2024/03/26 15:59:53 放行总数：10
```

## 04-基于`List`的消息队列

{{<admonition info "消息队列的定义">}}

1. 消息队列是一种先进先出的队列型数据结构。消息被顺序插入队列中，其中发送进程将消息添加到队列末尾，接受进程从队列头读取消息。
2. 多个进程可同时向一个消息队列发送消息，也可以同时从一个消息队列中接收消息。发送进程把消息发送到队列尾部，接受进程从消息队列头部读取消息，消息一旦被读出就从队列中删除。

{{</admonition>}}

使用 redis 的 List 的 `lpush` 和 `rpop` 可以实现一个简易的消息队列。

### 代码实现

```go
package example

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/redis/go-redis/v9"

	"go-redis-example/common"
)

const ex04ListenList = "ex04_list_0" // lpush ex04_list_0 AA BB

// Ex04Params Ex04的自定义函数
type Ex04Params struct {
}

func Ex04(ctx context.Context) {
	eventLogger := common.NewConcurrentEventLog(ctx, 0)
	// new一个并发执行器
	// routineNums是消费端的数量，多消费的场景，可以使用ex04ConsumerPop，使用ex04ConsumerRange存在消息重复消费的问题。
	cInst := common.NewConcurrentRoutine(3, eventLogger)
	go cInst.Run(ctx, Ex04Params{}, ex04ProducerPush)
	// 并发执行用户自定义函数work
	cInst.Run(ctx, Ex04Params{}, ex04ConsumerPop)
	// 按日志时间正序打印日志
	eventLogger.PrintLogs()
}

func ex04ProducerPush(ctx context.Context, cInstParam common.CInstParams) {
	routine := cInstParam.Routine
	cnt := 0
	for {
		RedisCli.LPush(ctx, ex04ListenList, fmt.Sprintf("producer[%d] push %d", routine, cnt))
		if cnt > 3 {
			break
		}
		cnt++
	}
}

// ex04ConsumerPop 使用rpop逐条消费队列中的信息，数据从队列中移除
// 生成端使用：lpush ex04_list_0 AA BB
func ex04ConsumerPop(ctx context.Context, cInstParam common.CInstParams) {
	routine := cInstParam.Routine
	for {
		items, err := RedisCli.BRPop(ctx, time.Second, ex04ListenList).Result()
		if err != nil {
			if err == redis.Nil {
				fmt.Println(common.LogFormat(routine, "任务执行结束"))
				return
			}
			panic(err)
		}
		fmt.Println(common.LogFormat(routine, "读取文章[%s]标题、正文，发送到ES更新索引", items[1]))
		// 将文章内容推送到ES
		time.Sleep(1 * time.Second)
	}
}

// ex04ConsumerRange 使用lrange批量消费队列中的数据，数据保留在队列中
// 生成端使用：rpush ex04_list_0 AA BB
// 消费端：
// 方法1 lrange ex04_list_0 -3 -1 // 从FIFO队尾中一次消费3条信息
// 方法2 rpop ex04_list_0 3
func ex04ConsumerRange(ctx context.Context, cInstParam common.CInstParams) {
	routine := cInstParam.Routine
	consumeBatchSize := int64(3) // 一次取N个消息
	for {
		// 从index(-consumeBatchSize)开始取，直到最后一个元素index(-1)
		items, err := RedisCli.LRange(ctx, ex04ListenList, -consumeBatchSize, -1).Result()
		if err != nil {
			panic(err)
		}
		if len(items) > 0 {
			fmt.Println(common.LogFormat(routine, "收到信息:%s", strings.Join(items, "->")))
			// 清除已消费的队列
			// 方法1 使用LTrim
			// 保留从index(0)开始到index(-(consumeBatchSize + 1))的部分，即为未消费的部分
			// RedisCli.LTrim(ctx, ex04ListenList, 0, -(consumeBatchSize + 1))

			// 方法2 使用RPop
			RedisCli.RPopCount(ctx, ex04ListenList, int(consumeBatchSize))
		}
		time.Sleep(3 * time.Second)
	}
}
```

### 测试功能：`go run main.go Ex04`

```bash
(base) ➜  go-redis-example git:(main) ✗ go run main.go Ex04
输入参数:
Ex04
----------
[2024-03-26T16:18:35.394455+08:00] routine[1] 读取文章[producer[1] push 0]标题、正文，发送到ES更新索引
[2024-03-26T16:18:35.396198+08:00] routine[2] 读取文章[producer[0] push 0]标题、正文，发送到ES更新索引
[2024-03-26T16:18:35.396556+08:00] routine[0] 读取文章[producer[0] push 1]标题、正文，发送到ES更新索引
[2024-03-26T16:18:36.397106+08:00] routine[1] 读取文章[producer[0] push 2]标题、正文，发送到ES更新索引
[2024-03-26T16:18:36.397123+08:00] routine[2] 读取文章[producer[2] push 0]标题、正文，发送到ES更新索引
[2024-03-26T16:18:36.39716+08:00] routine[0] 读取文章[producer[1] push 1]标题、正文，发送到ES更新索引
[2024-03-26T16:18:37.398938+08:00] routine[2] 读取文章[producer[1] push 2]标题、正文，发送到ES更新索引
[2024-03-26T16:18:37.398954+08:00] routine[0] 读取文章[producer[2] push 1]标题、正文，发送到ES更新索引
[2024-03-26T16:18:37.398978+08:00] routine[1] 读取文章[producer[1] push 3]标题、正文，发送到ES更新索引
[2024-03-26T16:18:38.399928+08:00] routine[2] 读取文章[producer[2] push 3]标题、正文，发送到ES更新索引
[2024-03-26T16:18:38.399967+08:00] routine[1] 读取文章[producer[2] push 2]标题、正文，发送到ES更新索引
[2024-03-26T16:18:38.399979+08:00] routine[0] 读取文章[producer[1] push 4]标题、正文，发送到ES更新索引
[2024-03-26T16:18:39.401791+08:00] routine[2] 读取文章[producer[0] push 4]标题、正文，发送到ES更新索引
[2024-03-26T16:18:39.401869+08:00] routine[1] 读取文章[producer[2] push 4]标题、正文，发送到ES更新索引
[2024-03-26T16:18:39.401923+08:00] routine[0] 读取文章[producer[0] push 3]标题、正文，发送到ES更新索引
[2024-03-26T16:18:41.463624+08:00] routine[0] 任务执行结束
[2024-03-26T16:18:41.463655+08:00] routine[1] 任务执行结束
[2024-03-26T16:18:41.46367+08:00] routine[2] 任务执行结束
```

## 05-基于`Hash`的计数器

对于一个用户有多个计数需求，例如点赞数量、粉丝数量、文章收藏数量、关注数量等，可以使用 Hash 的数据结构进行存储。

### 代码实现

```go
package example

import (
	"context"
	"fmt"
	"log"
	"strconv"
)

const ex05UserCountKey = "ex05_user_count"

// Ex05 hash数据结果的运用（参考掘金应用）
// go run main.go Ex05 init 初始化用户计数值
// go run main.go Ex05 get 1556564194374926  // 打印用户(1556564194374926)的所有计数值
// go run main.go Ex05 incr_like 1556564194374926 // 点赞数+1
// go run main.go Ex05 incr_collect 1556564194374926 // 收藏数+1
// go run main.go Ex05 decr_like 1556564194374926 // 点赞数-1
// go run main.go Ex05 decr_collect 1556564194374926 // 收藏数-1
func Ex05(ctx context.Context, args []string) {
	if len(args) <= 0 {
		panic("args can't be empty")
	}
	arg1 := args[0]
	switch arg1 {
	case "init":
		Ex05InitUserCount(ctx)
	case "get":
		userID, err := strconv.ParseInt(args[1], 10, 64)
		if err != nil {
			panic(err)
		}
		Ex05GetUserCount(ctx, userID)
	case "incr_like":
		userID, err := strconv.ParseInt(args[1], 10, 64)
		if err != nil {
			panic(err)
		}
		IncrByUserLike(ctx, userID)
	case "incr_collect":
		userID, err := strconv.ParseInt(args[1], 10, 64)
		if err != nil {
			panic(err)
		}
		IncrByUserCollect(ctx, userID)
	case "decr_like":
		userID, err := strconv.ParseInt(args[1], 10, 64)
		if err != nil {
			panic(err)
		}
		DecrByUserLike(ctx, userID)
	case "decr_collect":
		userID, err := strconv.ParseInt(args[1], 10, 64)
		if err != nil {
			panic(err)
		}
		DecrByUserCollect(ctx, userID)
	default:
		panic("do not support now...")
	}
}

func Ex05InitUserCount(ctx context.Context) {
	pipe := RedisCli.Pipeline()
	userCounters := []map[string]interface{}{
		{"user_id": "1556564194374926", "got_digg_count": 10693, "got_view_count": 2238438, "followee_count": 176, "follower_count": 9895, "follow_collect_set_count": 0, "subscribe_tag_count": 95},
		{"user_id": "1111", "got_digg_count": 19, "got_view_count": 4},
		{"user_id": "2222", "got_digg_count": 1238, "follower_count": 379},
	}

	for _, counter := range userCounters {
		uid, err := strconv.ParseInt(counter["user_id"].(string), 10, 64)
		if err != nil {
			panic(err)
		}
		key := ex05GetUserCounterKey(uid)
		if err = pipe.Del(ctx, key).Err(); err != nil {
			panic(err)
		}
		if err = pipe.HMSet(ctx, key, counter).Err(); err != nil {
			panic(err)
		}

		log.Printf("设置uid[%d], key=%s", uid, key)
	}
	if _, err := pipe.Exec(ctx); err != nil {
		// 再执行一次
		if _, err = pipe.Exec(ctx); err != nil {
			panic(err)
		}
	}
}

// ex05GetUserCounterKey 获取用户计数的key
func ex05GetUserCounterKey(userID int64) string {
	return fmt.Sprintf("%s_%d", ex05UserCountKey, userID)
}

func Ex05GetUserCount(ctx context.Context, userID int64) {
	pipe := RedisCli.Pipeline()
	pipe.HGetAll(ctx, ex05GetUserCounterKey(userID))
	results, err := RedisCli.HGetAll(ctx, ex05GetUserCounterKey(userID)).Result()
	if err != nil {
		panic(err)
	}
	fmt.Printf("User[%d]:\n", userID)
	for k, v := range results {
		fmt.Printf("%s: %s\n", k, v)
	}
}

// IncrByUserLike 点赞数+1
func IncrByUserLike(ctx context.Context, userID int64) {
	incrByUserField(ctx, userID, "got_digg_count")
}

// IncrByUserCollect 收藏数+1
func IncrByUserCollect(ctx context.Context, userID int64) {
	incrByUserField(ctx, userID, "follow_collect_set_count")
}

// DecrByUserLike 点赞数-1
func DecrByUserLike(ctx context.Context, userID int64) {
	decrByUserField(ctx, userID, "got_digg_count")
}

// DecrByUserCollect 收藏数-1
func DecrByUserCollect(ctx context.Context, userID int64) {
	decrByUserField(ctx, userID, "follow_collect_set_count")
}

func incrByUserField(ctx context.Context, userID int64, field string) {
	change(ctx, userID, field, 1)
}

func decrByUserField(ctx context.Context, userID int64, field string) {
	change(ctx, userID, field, -1)
}

func change(ctx context.Context, userID int64, field string, delta int64) {
	key := ex05GetUserCounterKey(userID)
	before, err := RedisCli.HGet(ctx, key, field).Result()
	if err != nil {
		panic(err)
	}
	beforeInt, err := strconv.ParseInt(before, 10, 64)
	if err != nil {
		panic(err)
	}

	if beforeInt+delta < 0 {
		fmt.Printf("禁止变更计数，计数变更后小于0. %d + (%d) = %d\n", beforeInt, delta, beforeInt+delta)
		return
	}
	fmt.Printf("user[%d]: \n更新前\n%s = %s\n--------\n", userID, field, before)
	if err = RedisCli.HIncrBy(ctx, key, field, delta).Err(); err != nil {
		panic(err)
	}
	count, err := RedisCli.HGet(ctx, key, field).Result()
	if err != nil {
		panic(err)
	}
	fmt.Printf("user_id: %d\n更新后\n%s = %s\n--------\n", userID, field, count)
}
```

### 测试功能

测试脚本：

```shell
go run main.go Ex05 init # 初始化用户计数值
go run main.go Ex05 get 1556564194374926  # 打印用户(1556564194374926)的所有计数值
go run main.go Ex05 incr_like 1556564194374926 # 点赞数+1
go run main.go Ex05 incr_collect 1556564194374926 # 收藏数+1
go run main.go Ex05 decr_like 1556564194374926 # 点赞数-1
go run main.go Ex05 decr_collect 1556564194374926 # 收藏数-1
go run main.go Ex05 decr_collect 1556564194374926 # 收藏数-1
```

执行结果：

```bash
输入参数:
Ex05
init
----------
设置uid[1556564194374926], key=ex05_user_count_1556564194374926
设置uid[1111], key=ex05_user_count_1111
设置uid[2222], key=ex05_user_count_2222
输入参数:
Ex05
get
1556564194374926
----------
User[1556564194374926]:
got_view_count: 2238438
followee_count: 176
follower_count: 9895
follow_collect_set_count: 0
subscribe_tag_count: 95
user_id: 1556564194374926
got_digg_count: 10693
输入参数:
Ex05
incr_like
1556564194374926
----------
user[1556564194374926]:
更新前
got_digg_count = 10693
--------
user_id: 1556564194374926
更新后
got_digg_count = 10694
--------
输入参数:
Ex05
incr_collect
1556564194374926
----------
user[1556564194374926]:
更新前
follow_collect_set_count = 0
--------
user_id: 1556564194374926
更新后
follow_collect_set_count = 1
--------
输入参数:
Ex05
decr_like
1556564194374926
----------
user[1556564194374926]:
更新前
got_digg_count = 10694
--------
user_id: 1556564194374926
更新后
got_digg_count = 10693
--------
输入参数:
Ex05
decr_collect
1556564194374926
----------
user[1556564194374926]:
更新前
follow_collect_set_count = 1
--------
user_id: 1556564194374926
更新后
follow_collect_set_count = 0
--------
输入参数:
Ex05
decr_collect
1556564194374926
----------
禁止变更计数，计数变更后小于0. 0 + (-1) = -1
```

## 06-基于`Zset`的排行榜

积分榜变化时，排名要实时改变。通过 Zset 可以很好的实现功能

### 代码实现

```go
package example

import (
	"context"
	"fmt"
	"strconv"

	"github.com/redis/go-redis/v9"
)

const ex06RankKey = "ex06_rank_zset"

type ex06ItemScore struct {
	ItemName string
	Score    float64
}

// Ex06 排行榜
// go run main.go Ex06 init // 初始化积分
// go run main.go Ex06 rev_order // 输出完整榜单
// go run main.go Ex06 order_page 1 // 逆序分页输出，page=1
// go run main.go Ex06 get_rank user2 // 获取user2的排名
// go run main.go Ex06 get_score user2 // 获取user2的分数
// go run main.go Ex06 add_user_score user2 10 // 为user2设置为10分
// zadd ex06_rank_zset 15 andy
// zincrby ex06_rank_zset -9 andy // andy 扣9分，排名掉到最后一名
func Ex06(ctx context.Context, args []string) {
	arg1 := args[0]
	switch arg1 {
	case "init":
		ex06Init(ctx)
	case "rev_order":
		ex06GetOrderListAll(ctx)
	case "order_page":
		pageSize := int64(2)
		if len(args[1]) > 0 {
			offset, err := strconv.ParseInt(args[1], 10, 64)
			if err != nil {
				panic(err)
			}
			ex06GetOrderListByPage(ctx, offset, pageSize)
		}
	case "get_rank":
		ex06GetUserRankByName(ctx, args[1])
	case "get_score":
		ex06GetUserScoreByName(ctx, args[1])
	case "add_user_score":
		if len(args) < 3 {
			fmt.Printf("参数错误，可能是缺少需要增加的分值。eg：go run main.go  Ex06 add_user_score user2 10\n")
			return
		}
		score, err := strconv.ParseFloat(args[2], 64)
		if err != nil {
			panic(err)
		}
		ex06AddUserScore(ctx, args[1], score)
	default:
		panic("unsupported type")
	}
}

func ex06Init(ctx context.Context) {
	initList := []redis.Z{
		{Member: "user1", Score: 10},
		{Member: "user2", Score: 232},
		{Member: "user3", Score: 129},
		{Member: "user4", Score: 232},
	}
	// 清空榜单
	if err := RedisCli.Del(ctx, ex06RankKey).Err(); err != nil {
		panic(err)
	}

	nums, err := RedisCli.ZAdd(ctx, ex06RankKey, initList...).Result()
	if err != nil {
		panic(err)
	}
	fmt.Printf("初始化榜单Item数量：%d\n", nums)
}

// 获取全部榜单
// 榜单逆序输出
// ZRANGE ex06_rank_zset +inf -inf BYSCORE  rev WITHSCORES
// 正序输出
// ZRANGE ex06_rank_zset 0 -1 WITHSCORES
func ex06GetOrderListAll(ctx context.Context) {
	resList, err := RedisCli.ZRevRangeWithScores(ctx, ex06RankKey, 0, -1).Result()
	if err != nil {
		panic(err)
	}
	fmt.Println("\n榜单：")
	for i, z := range resList {
		fmt.Printf("第%d名，name=%s, score=%.2f\n", i+1, z.Member, z.Score)
	}
}

// 分页获取榜单
func ex06GetOrderListByPage(ctx context.Context, page, pageSize int64) {
	// zrange ex06_rank_zset 300 0 byscore rev limit 1 2 withscores // 取300分到0分之间的排名
	// zrange ex06_rank_zset -inf +inf byscore withscores 正序输出
	// zrange ex06_rank_zset +inf -inf byscore rev WITHSCORES 逆序输出所有排名
	// zrange ex06_rank_zset +inf -inf byscore rev limit 0 2 withscores 逆序分页输出排名
	offset := int((page - 1) * pageSize)
	zRangeArgs := redis.ZRangeArgs{
		Key:     ex06RankKey,
		ByScore: true,
		Rev:     true,
		Start:   "-inf",
		Stop:    "+inf",
		Offset:  int64(offset),
		Count:   pageSize,
	}
	resList, err := RedisCli.ZRangeArgsWithScores(ctx, zRangeArgs).Result()
	if err != nil {
		panic(err)
	}
	fmt.Printf("榜单(page=%d, pageSize=%d)\n", page, pageSize)
	for i, z := range resList {
		rank := i + 1 + offset
		fmt.Printf("第%d名 %s\t%.2f\n", rank, z.Member, z.Score)
	}
}

// 获取用户排名
func ex06GetUserRankByName(ctx context.Context, name string) {
	rank, err := RedisCli.ZRevRank(ctx, ex06RankKey, name).Result()
	if err != nil {
		panic(err)
	}
	fmt.Printf("name=%s, rank=%d\n", name, rank+1)
}

// 获取用户分数信息
func ex06GetUserScoreByName(ctx context.Context, name string) {
	score, err := RedisCli.ZScore(ctx, ex06RankKey, name).Result()
	if err != nil {
		panic(err)
	}
	fmt.Printf("name=%s, score=%.2f\n", name, score)
}

// ex06AddUserScore 增加用户分数
func ex06AddUserScore(ctx context.Context, name string, score float64) {
	num, err := RedisCli.ZIncrBy(ctx, ex06RankKey, score, name).Result()
	if err != nil {
		panic(err)
	}
	fmt.Printf("name=%s, add_score=%.2f, score=%.2f\n", name, score, num)
}
```

### 测试功能

测试脚本：

```shell
go run main.go Ex06 init # 初始化积分
go run main.go Ex06 rev_order # 输出完整榜单
go run main.go Ex06 order_page 1 # 逆序分页输出，page=1
go run main.go Ex06 order_page 2 # 逆序分页输出，page=2
go run main.go Ex06 get_rank user2 # 获取user2的排名
go run main.go Ex06 get_score user2 # 获取user2的分数
go run main.go Ex06 add_user_score user2 10 # 为user2增加10分
go run main.go Ex06 get_rank user2 # 获取user2的排名
go run main.go Ex06 get_score user2 # 获取user2的分数
```

执行结果：

```bash
输入参数:
Ex06
init
----------
初始化榜单Item数量：4
输入参数:
Ex06
rev_order
----------

榜单：
第1名，name=user4, score=232.00
第2名，name=user2, score=232.00
第3名，name=user3, score=129.00
第4名，name=user1, score=10.00
输入参数:
Ex06
order_page
1
----------
榜单(page=1, pageSize=2)
第1名 user4	232.00
第2名 user2	232.00
输入参数:
Ex06
order_page
2
----------
榜单(page=2, pageSize=2)
第3名 user3	129.00
第4名 user1	10.00
输入参数:
Ex06
get_rank
user2
----------
name=user2, rank=2
输入参数:
Ex06
get_score
user2
----------
name=user2, score=232.00
输入参数:
Ex06
add_user_score
user2
10
----------
name=user2, add_score=10.00, score=242.00
输入参数:
Ex06
get_rank
user2
----------
name=user2, rank=1
输入参数:
Ex06
get_score
user2
----------
name=user2, score=242.00
```

## 07-基于`PubSub`的消息订阅

对于文章的发布与订阅，也可以使用 PubSub 实现

### 代码实现

```go
package example

import (
	"context"
	"fmt"
	"log"
	"strconv"
	"time"
)

const ex07Channel = "es_ch"

func Ex07(ctx context.Context) {
	pubSub := RedisCli.Subscribe(ctx, ex07Channel)

	go func() {
		for i := 0; i < 5; i++ {
			RedisCli.Publish(ctx, ex07Channel, i)
		}
		time.Sleep(time.Second)
		if err := pubSub.Unsubscribe(ctx, ex07Channel); err != nil {
			log.Fatal(err)
		}
		_ = pubSub.Close()
	}()

	for msg := range pubSub.Channel() {
		arcId, err := strconv.ParseInt(msg.Payload, 10, 64)
		if err != nil {
			panic(err)
		}
		fmt.Printf("读取文章[%d]标题、正文，发送到ES更新索引\n", arcId)
	}
}
```

### 测试结果：`go run main.go Ex07`

```bash
(base) ➜  go-redis-example git:(main) ✗ go run main.go Ex07
输入参数:
Ex07
----------
读取文章[0]标题、正文，发送到ES更新索引
读取文章[1]标题、正文，发送到ES更新索引
读取文章[2]标题、正文，发送到ES更新索引
读取文章[3]标题、正文，发送到ES更新索引
读取文章[4]标题、正文，发送到ES更新索引
```

## 总结

通过上述的 Redis 实战案例，管中窥豹地了解了 Redis 的一些经典用法。实际上 Redis 的功能并不止于此，在日后的学习工作中，Redis 也将会继续发挥更大的作用。
