---
title: "Golang的二三事--channel篇"
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

深入理解 Golang 中的 channel

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

## channel exacmple

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
