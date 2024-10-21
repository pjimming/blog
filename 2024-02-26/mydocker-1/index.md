# 《自己动手写docker》阅读笔记--第一章 容器与开发语言


关于环境配置、docker 简介以及 Go 相关的使用

<!--more-->

---

## 环境配置：

- 操作系统：Ubuntu 20.04.3 LTS

- 内核版本：5.15.133.1-microsoft-standard-WSL2

- Go version：go1.22.0 linux/amd64

## Docker

- 特点：轻量级（共享内核）、开放、安全（将不同的应用隔离起来）

- 与虚拟机比较：都有资源隔离与分配的能力，由于共享操作系统的内核，所以容器更加便携与高效

- 优点：加速开发效率，利用容器合作开发，使开发人员不用担心配置环境的问题。

WSL 环境 docker 使用：[WSL 上的 Docker 容器入门 | Microsoft Learn](https://learn.microsoft.com/zh-cn/windows/wsl/tutorials/wsl-containers)

## GO

golang 安装：[Download and install - The Go Programming Language](https://golang.google.cn/doc/install)

WSL 环境使用 Goland 开发：[使用 WSL 环境在 Goland 中开发 Go 项目 - 掘金](https://juejin.cn/post/7102970555401240607)

