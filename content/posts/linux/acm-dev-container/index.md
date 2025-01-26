---
title: "使用Dev Container打造轻量级算法竞赛环境"
subtitle: ""
date: 2025-01-26T11:46:45+08:00
lastmod: 2025-01-26T11:46:45+08:00
draft: false
author: "PanJM"
authorLink: "https://github.com/pjimming/"
description: ""
license: ""
images: []

tags: [docker, devcontainer, vscode, acm]
categories: [docker]

featuredImage: "https://picx-img.pjmcode.top/20250126/image-image.7egvm1czon.webp"
featuredImagePreview: "https://picx-img.pjmcode.top/20250126/image-image.7egvm1czon.webp"

outdatedInfoWarning: true
---

使用 DevContainer 打造一个轻量级算法竞赛环境，无需担忧环境变更即可轻松写题

<!--more-->

---

## 什么是 Dev Container

Dev Container 是一种基于容器化技术的开发环境配置方式，由 VS Code 扩展支持。它允许你为一个项目定义一个完全隔离的开发环境，从而确保开发者的工具链、依赖和配置在任何机器上都一致。

### Dev Container 的核心概念

1. 开发环境即代码：
   通过配置文件（通常是 .devcontainer/devcontainer.json 和 Dockerfile），你可以将开发环境定义为代码的一部分，版本化并与团队共享。
   所有开发者拉取项目后，都可以在几分钟内启动一个相同的开发环境。

2. 基于容器：
   使用 Docker 容器作为运行环境，将代码和依赖隔离在独立的环境中，而不会污染宿主系统。
   容器可以基于通用的镜像（如 ubuntu, node, python）或自定义的镜像。

3. 集成 VS Code：
   VS Code 可以连接到容器内部，通过 Remote - Containers 插件使开发体验无缝。
   开发者几乎感觉不到自己是在容器中工作，因为所有操作（如调试、终端、文件操作）都与本地开发一致。

## 前置环境

- [Vs Code](https://code.visualstudio.com/)
- [Docker](https://www.docker.com/)
- [Dev Container](https://code.visualstudio.com/docs/devcontainers/tutorial)

## 使用 Dev Container

目录结构如下所示：

```
.
├── .clang-format // C++格式化配置
├── .devcontainer // devcontainer主要目录
│   ├── Dockerfile
│   ├── devcontainer.json // 描述 Dev Container 的核心配置，比如基础镜像、安装扩展、转发端口、环境变量等
│   └── setup.sh
├── .vscode // vscode相关配置
│   ├── cpp.code-snippets // 代码块模版
│   └── settings.json // 自定义设置
└── code // 代码文件，懂得都懂
    ├── atcoder
    └── codeforces
```

拉取仓库：

```bash
git clone git@github.com:pjimming/acm-dev-container.git
code acm-dev-container
```

打开这个目录后，点击左下角的链接 UI（箭头所指）

![点击蓝色小块](https://picx-img.pjmcode.top/20250126/image-image.7snbcz47ed.webp)

选择 Reopen in Container
![选择在容器里重新打开](https://picx-img.pjmcode.top/20250126/image-image.1ovjajq46g.webp)

Docker 会根据 Dockerfile 自动拉取镜像，构建容器，配置所需要的环境

```docker
# 使用基于 GCC 的镜像作为基础镜像
FROM gcc:latest

# 更新系统并安装常用开发工具
RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y \
        build-essential \
        g++ \
        gdb \
        cmake \
        git \
        vim \
        wget \
        curl \
        unzip \
        zsh && \
    apt-get clean

# 安装 Oh My Zsh
RUN sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" --unattended && \
    chsh -s /bin/zsh && \
    echo "export TERM=xterm-256color" >> ~/.zshrc

# 安装 Zsh 插件：zsh-autosuggestions 和 zsh-syntax-highlighting
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting && \
    sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/g' ~/.zshrc

# 设置默认工作目录
WORKDIR /workspace

# 设置环境变量，使用 C++20 编译
ENV CXXFLAGS="-std=c++20 -D_GLIBCXX_DEBUG"

# 安装 C++ 工具：Clang Tidy、Clang Format（可选）
RUN apt-get install -y clang-tidy clang-format

# 设置默认终端为 Zsh
CMD ["/bin/zsh"]
```

等待启动完成后，就是一个可以愉快写题的环境了。
![ABC390_A](https://picx-img.pjmcode.top/20250126/image-image.2yyggvvlj8.webp)
