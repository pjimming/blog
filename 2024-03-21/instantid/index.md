# 【论文泛读】InstantID: Zero-shot Identity-Preserving Generation in Seconds


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

![InstantID的算法流程](https://picx-img.pjmcode.top/20240321/imageimage.51dwsrmb8x.webp)

1. 通过 Face Encoder 解码人脸信息，代替 CLIP Encoder，并使用可训练的投影层将其投影到文本特征空间，将投影后得到的特征作为 Face Embedding
2. 引入轻量级解耦交叉注意力自适应模块（Image Adapter），将 Face Embedding 与 Text Embedding 结合，支持图像作为提示，与 IP-Adapter 类似，把 Embedding 注入到 UNet 中
3. 改动 ControlNet，提出 IdentityNet，对输入的图片提取 landmarks，得到五官的点位，与之前得到的 Face Embedding 结合，避免表情、环境、姿势影响身份信息，消除 Text 的影响，对参考人脸图像的详细特征进行编码，并具有额外的空间控制

## Result

![InstantID的成果](https://picx-img.pjmcode.top/20240322/imageimage.6ik1vg1qbh.webp)

## Reference

1. [InstantID: Zero-shot Identity-Preserving Generation in Seconds](https://arxiv.org/pdf/2401.07519.pdf)
2. [【InstantID 论文解析】小红书+北大爆火的项目 InstantID，连 LeCun 都点赞！](https://www.bilibili.com/video/BV1US421P7GG)

