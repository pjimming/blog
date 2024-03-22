---
title: "【论文泛读】InstantID: Zero-shot Identity-Preserving Generation in Seconds"
subtitle: ""
date: 2024-03-21T20:21:48+08:00
lastmod: 2024-03-21T20:21:48+08:00
draft: true
author: "PanJM"
authorLink: "https://github.com/pjimming/"
description: ""
license: ""
images: []

tags: [paper, InstantID, AIGC]
categories: [paper]

featuredImage: "https://cdn.jsdelivr.net/gh/pjimming/picx-images-hosting@master/20240321/imageimage.4911b169xh.webp"
featuredImagePreview: "https://cdn.jsdelivr.net/gh/pjimming/picx-images-hosting@master/20240321/imageimage.4911b169xh.webp"

outdatedInfoWarning: true
---

泛读小红书 InstantX 团队与北京大学联合发表的[InstantID](https://arxiv.org/abs/2401.07519)论文

<!--more-->

---

## Motivation

现有 Face Customization 存在的缺点：

- High storage demands: 需要大量的空间去存储训练得到的模型
- Lengthy fine-tuning process: 训练代价大
- Need multiple reference images: 需要多张参考图

InstantID 改善：

- Zero-shot: 零插拔
- Tuning-free: 低代价
- High fidelity: 高保真

## Method

![InstantID的算法流程](https://cdn.jsdelivr.net/gh/pjimming/picx-images-hosting@master/20240321/imageimage.51dwsrmb8x.webp)

## Result

![InstantID的成果](https://cdn.jsdelivr.net/gh/pjimming/picx-images-hosting@master/20240322/imageimage.6ik1vg1qbh.webp)
