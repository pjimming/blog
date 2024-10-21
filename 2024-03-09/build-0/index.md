# 零成本搭建个人博客系列--第一篇 为什么选择Hugo？


介绍网站类型，框架类型以及为什么选择使用 Hugo 搭建

<!--more-->

---

## 网站分类

1. 动态网站

   > **动态网站并不是指具有动画功能的网站，而是指**​[网站内容](https://baike.baidu.com/item/%E7%BD%91%E7%AB%99%E5%86%85%E5%AE%B9/6694752?fromModule=lemma_inlink)可根据不同情况动态变更的网站，一般情况下动态网站通过数据库进行架构。 动态网站除了要设计网页外，还要通过数据库和[编程序](https://baike.baidu.com/item/%E7%BC%96%E7%A8%8B%E5%BA%8F/645283?fromModule=lemma_inlink)来使网站具有更多自动的和高级的功能。动态网站体现在网页一般是以[asp](https://baike.baidu.com/item/asp/128906?fromModule=lemma_inlink)，[jsp](https://baike.baidu.com/item/jsp/141543?fromModule=lemma_inlink)，[php](https://baike.baidu.com/item/php/9337?fromModule=lemma_inlink)，[aspx](https://baike.baidu.com/item/aspx/203251?fromModule=lemma_inlink)等技术，而[静态网页](https://baike.baidu.com/item/%E9%9D%99%E6%80%81%E7%BD%91%E9%A1%B5/6327183?fromModule=lemma_inlink)一般是[HTML](https://baike.baidu.com/item/HTML/97049?fromModule=lemma_inlink)（[标准通用标记语言](https://baike.baidu.com/item/%E6%A0%87%E5%87%86%E9%80%9A%E7%94%A8%E6%A0%87%E8%AE%B0%E8%AF%AD%E8%A8%80/6805073?fromModule=lemma_inlink)的子集）结尾，动态网站[服务器空间](https://baike.baidu.com/item/%E6%9C%8D%E5%8A%A1%E5%99%A8%E7%A9%BA%E9%97%B4/14687930?fromModule=lemma_inlink)配置要比静态的网页要求高，费用也相应的高，不过[动态网页](https://baike.baidu.com/item/%E5%8A%A8%E6%80%81%E7%BD%91%E9%A1%B5/6327050?fromModule=lemma_inlink)利于网站内容的更新，适合[企业建站](https://baike.baidu.com/item/%E4%BC%81%E4%B8%9A%E5%BB%BA%E7%AB%99/1027109?fromModule=lemma_inlink)。动态是相对于[静态网站](https://baike.baidu.com/item/%E9%9D%99%E6%80%81%E7%BD%91%E7%AB%99/2776875?fromModule=lemma_inlink)而言。
   >
   > ——百度百科

2. 静态网站

   > 技术上来讲，静态网站是指网页不是由服务器动态生成的。HTML、CSS 和 JavaScript 文件就静静地躺在服务器的某个路径下，它们的内容与终端用户接收到的版本是一样的。原始的源码文件已经提前编译好了，源码在每次请求后都不会变化。

## 框架选择

1. WordPress

   官网：[https://wordpress.org/](https://wordpress.org/)

   WordPress 是一款免费开源的内容管理系统（CMS），它是目前世界上使用最广泛的[网站建设](https://cloud.tencent.com/developer/techpedia/1339)平台之一。

   WordPress 可以帮助用户快速创建和管理各种类型的网站，例如博客、企业网站、电子商务网站等。

2. Hexo

   官网：[https://hexo.io/zh-cn/index.html](https://hexo.io/zh-cn/index.html)

   Hexo 是一个快速、简洁且高效的博客框架。它允许用户使用 Markdown 语言编写内容，并将其渲染为静态网页。

   它相当于与一个网站的主题模板，只需要做简单的配置就能够完成页面的渲染。

   其主要特点包括快速部署，Markdown 支持，灵活的布局，丰富的插件。

3. Hugo

   官网：[https://gohugo.io/](https://gohugo.io/)

   Hugo 是由 Go 编写的快速现代静态网站生成器。

## 为什么选择 hugo

1. 了解需求

   - 使用简单，轻量级，尽可能的渲染快
   - 有好看且丰富的主题可供选择
   - 一篇文章需要良好的书写排版，比如支持渲染 markdown
   - 博客并不需要实时更新，且学生党需要考虑服务器等成本
   - 有相关的发布平台支持，比如 netlify、vercel 或 github page

2. 选择 hugo 的原因

   - Hugo 依靠 Go 语言进行开发，号称世界上最快的构建网站工具
   - Hugo 有多种主题可供选择，可自定义配置
   - Hugo 支持 markdown
   - Hugo 是一个静态网站框架
   - Hugo 可以支持基于发布平台进行 CI/CD
   - 由于 Hugo 的强大性能，使得渲染快速，可以所见即所得，方便调试

3. 谁适合 Hugo
   - Hugo 适用于更喜欢在文本编辑器而不是浏览器中编写的人。
   - Hugo 适用于那些想要手动编码自己的网站而又不想担心设置复杂的运行时、依赖和数据库的人。
   - Hugo 适用于构建博客、公司网站、作品集网站、文档、单个落地页或拥有数千个页面的网站的人。

