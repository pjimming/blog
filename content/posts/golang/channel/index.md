---
title: "深入理解Go语言的Channel"
subtitle: ""
date: 2024-03-08T20:50:19+08:00
lastmod: 2024-03-08T20:50:19+08:00
draft: false
author: "PanJM"
authorLink: "https://github.com/pjimming/"
description: ""
license: ""
images: []

tags: [golang, channel]
categories: [golang]

featuredImage: "featured-image.png"
featuredImagePreview: "featured-image.png"
---

介绍 Golang 中的 channel 是什么，如何使用以及一些 channel 的使用例子

<!--more-->

---

## 什么是 channel

channel(一般简写为 `chan`) 管道提供了一种机制，它是一种类型，类似于队列或管道，可以用于在 goroutine 之间传递数据。

此外，channel 是**并发安全**的。

## channel 的基本使用

通信操作符 <- 的箭头指示数据流向，箭头指向哪里，数据就流向哪里，它是一个二元操作符，可以支持任意类型。

### 创建 channel

channel 有两种类型，区分类型为**无缓冲**与**有缓冲**。

```go
// 无缓冲channel，同步channel，缓冲区大小为0，即必须有同步协程进行读写操作
ch := make(chan T)
// 有缓冲channel，异步channel，缓冲区大小为10，即channel里最多有10个元素
ch := make(chan T, 10)
```

### 向 channel 里写数据

```go
ch <- data // 向channel内写入data的数据
```

### 从 channel 里读数据

```go
// 从 channel 中接收数据并赋值给 data
data := <-ch
// 从 channel 中接收数据并丢弃
<-ch
```

### 关闭 channel

```go
close(ch) // 用于关闭一个channel
```

{{< admonition type=tip title="关闭channel时，需要注意以下细节" open=true >}}

1. 读取关闭后的**无缓存**通道，不管通道中是否有数据，返回值都为 `0` 和 `false`
2. 读取关闭后的**有缓存**通道，将缓存数据读取完后，再读取返回值为 `0` 和 `false`
3. 对于一个关闭的 channel，如果继续向 channel 发送数据，会引起 panic
4. channel 不能 close 两次，多次 close 会 panic

{{< /admonition >}}

## channel 场景分析

|                       | 写操作：`ch<-`             | 读操作：`<-ch`                                                                 | 关闭操作：`close(ch)` |
| --------------------- | -------------------------- | ------------------------------------------------------------------------------ | --------------------- |
| channel 为`nil`       | 阻塞                       | 阻塞                                                                           | `panic`               |
| **无缓冲**的 channel  | 阻塞，除非有其他协程同时读 | 阻塞，除非有其他协程同时写                                                     | 成功                  |
| **有缓冲**的 channel  | 成功，直到缓冲区满时阻塞   | 成功，除非缓冲区为空时阻塞                                                     | 成功                  |
| 已经`close`的 channel | `panic`                    | 读出缓冲区内存在的内容，后续只能读到类型的零值，可以根据断言判断是否获取到数据 | `panic`               |

## channel 使用例子

### 使用 for-range 读 channel

适合场景：需要不断的从 channel 里读取数据

使用`for-range`读取 channel，这样既安全又便利，当 channel 关闭时，for 循环会自动退出，无需主动监测 channel 是否关闭，可以防止读取已经关闭的 channel，造成读到数据为通道所存储的数据类型的零值。

```go
for x := range ch {
	fmt.Println(x)
}
```

### 使用`v,ok := <-ch` + `select`操作判断 channel 是否关闭

ok 的结果和含义：

- `true`：读到通道数据，不确定是否关闭，可能 channel 还有保存的数据，但 channel 已关闭。
- `false`：通道关闭，无数据读到。

从关闭的 channel 读值读到是 channel 所传递数据类型的零值，这个零值有可能是发送者发送的，也可能是 channel 关闭了。

`_, ok := <-ch`与 select 配合使用的，当 ok 为 false 时，代表了 channel 已经 close。下面解释原因，`<span> </span>_,ok := <-ch`对应的函数是`func chanrecv(c *hchan, ep unsafe.Pointer, block bool) (selected, received bool)`，入参 block 含义是当前 goroutine 是否可阻塞，当 block 为 false 代表的是 select 操作，不可阻塞当前 goroutine 的在 channel 操作，否则是普通操作（即`_, ok`不在 select 中）。返回值 selected 代表当前操作是否成功，主要为 select 服务，返回**received 代表是否从 channel 读到有效值**。它有 3 种返回值情况：

1. block 为 false，即执行 select 时，如果 channel 为空，返回(false,false)，代表 select 操作失败，没接收到值。
2. 否则，如果 channel 已经关闭，并且没有数据，ep 即接收数据的变量设置为零值，返回(true,false)，代表 select 操作成功，但 channel 已关闭，没读到有效值。
3. 否则，其他读到有效数据的情况，返回(true,ture)。

```go
package main

func main() {
	ch := make(chan int, 1)

	// 发送1个数据关闭channel
	ch <- 1
	close(ch)
	print("close channel\n")

	// 不停读数据直到channel没有有效数据
	for {
		select {
		case v, ok := <-ch:
			print("v: ", v, ", ok:", ok, "\n")
			if !ok {
				print("channel is close\n")
				return
			}
		default:
			print("nothing\n")
		}
	}
}

// output:
// close channel
// v: 1, ok:true
// v: 0, ok:false
// channel is close
```

### 使用 select 处理多个 channel

适合场景：需要对多个通道进行同时处理，但只处理最先发生的 channel 时

`select`可以同时监控多个通道的情况，只处理未阻塞的 case。**当通道为 nil 时，对应的 case 永远为阻塞，无论读写。特殊关注：普通情况下，对 nil 的通道写操作是要 panic 的**。

```go
// 分配job时，如果收到关闭的通知则退出，不分配job
func (h *Handler) handle(job *Job) {
    select {
    case h.jobCh<-job:
        return
    case <-h.stopCh:
        return
    }
}
```

### 使用 channel 的声明控制读写权限

适合场景：协程对某个通道只读或只写时

目的：

1. 使代码更易读、更易维护，
2. 防止只读协程对通道进行写数据，但通道已关闭，造成 panic。

用法：

- 如果协程对某个 channel 只有写操作，则这个 channel 声明为只写。
- 如果协程对某个 channel 只有读操作，则这个 channe 声明为只读。

```go
// 只有generator进行对outCh进行写操作，返回声明
// <-chan int，可以防止其他协程乱用此通道，造成隐藏bug
func generator(int n) <-chan int {
    outCh := make(chan int)
    go func(){
        for i:=0;i<n;i++{
            outCh<-i
        }
    }()
    return outCh
}

// consumer只读inCh的数据，声明为<-chan int
// 可以防止它向inCh写数据
func consumer(inCh <-chan int) {
    for x := range inCh {
        fmt.Println(x)
    }
}
```

### 为操作加上超时

适用场景：需要超时控制的操作

使用`select`和`time.After`，看操作和定时器哪个先返回，处理先完成的，就达到了超时控制的效果

```go
func doWithTimeOut(timeout time.Duration) (int, error) {
	select {
	case ret := <-do():
		return ret, nil
	case <-time.After(timeout):
		return 0, errors.New("timeout")
	}
}

func do() <-chan int {
	outCh := make(chan int)
	go func() {
		// do work
	}()
	return outCh
}
```

### 使用 time 实现 channel 无阻塞读写

场景：并不希望在 channel 的读写上浪费时间

是为操作加上超时的扩展，这里的操作是 channel 的读或写

```go
// time.After等待可以替换为default，则是channel阻塞时，立即返回的效果
func unBlockRead(ch chan int) (x int, err error) {
	select {
	case x = <-ch:
		return x, nil
	case <-time.After(time.Microsecond):
		return 0, errors.New("read time out")
	}
}

func unBlockWrite(ch chan int, x int) (err error) {
	select {
	case ch <- x:
		return nil
	case <-time.After(time.Microsecond):
		return errors.New("read time out")
	}
}
```

### 无缓冲 channel

1. 可用于协程间同步

   ```go
   package main

   import "fmt"

   func goroutine1(ch chan<- bool) {
       fmt.Println("Goroutine 1 is doing something")
       ch <- true
   }

   func goroutine2(ch <-chan bool, exit chan<- struct{}) {
       <-ch
       fmt.Println("Goroutine 2 received data")
       exit <- struct{}{}
   }

   func main() {
       ch := make(chan bool)
       exit := make(chan struct{})

       go goroutine1(ch)
       go goroutine2(ch, exit)

       <-exit
   }

   // output:
   // Goroutine 1 is doing something
   // Goroutine 2 received data
   ```

### 有缓冲 channel

1. 生产者-消费者模型

   ```go
   package main

   import (
   	"fmt"
   	"time"
   )

   func producer(ch chan<- int) {
   	for i := 0; i < 5; i++ {
   		ch <- i
   		time.Sleep(time.Second)
   	}
   	close(ch)
   }

   func consumer(ch <-chan int, exit chan<- struct{}) {
   	for num := range ch {
   		fmt.Println("Received:", num)
   	}
   	exit <- struct{}{}
   }

   func main() {
   	ch := make(chan int)
   	exit := make(chan struct{})

   	defer close(exit)

   	go producer(ch)
   	go consumer(ch, exit)

   	<-exit
   }

   // output:
   // Received: 0
   // Received: 1
   // Received: 2
   // Received: 3
   // Received: 4
   ```

2. 协程池：控制并发数量

   ```go
   package main

   import (
   	"fmt"
   	"time"
   )

   func worker(id int, jobs <-chan int, results chan<- int) {
   	for job := range jobs {
   		fmt.Printf("Worker %d started job %d\n", id, job)
   		time.Sleep(time.Second)
   		fmt.Printf("Worker %d finished job %d\n", id, job)
   		results <- job * 2
   	}
   }

   func main() {
   	numJobs := 5
   	numWorkers := 3

   	jobs := make(chan int, numJobs)
   	results := make(chan int, numJobs)

   	for w := 1; w <= numWorkers; w++ {
   		go worker(w, jobs, results)
   	}

   	for j := 1; j <= numJobs; j++ {
   		jobs <- j
   	}
   	close(jobs)

   	for r := 1; r <= numJobs; r++ {
   		<-results
   	}
   }

   // output:
   // Worker 3 started job 1
   // Worker 1 started job 2
   // Worker 2 started job 3
   // Worker 2 finished job 3
   // Worker 2 started job 4
   // Worker 3 finished job 1
   // Worker 3 started job 5
   // Worker 1 finished job 2
   // Worker 2 finished job 4
   // Worker 3 finished job 5
   ```

### 与 select 配合

1. 避免协程泄漏

   ```go
   finish := make(chan struct{})
   defer close(finish)

   go func() {
       ...
       select {
       case <-finish:
           // avoid goroutine memory leak
           ... your code ...
           return
       ...
   }()
   ```

   上述代码中，`finish chan` 一直被阻塞读出，父协程退出时，`defer` 执行，此时 channel 关闭，读操作不再收到阻塞，通过 `select` 轮询即可退出子协程，避免协程的内存泄漏。
