---
title: 个人blog搭建总结
description: 回顾oneforce blog搭建的全过程，记录各类问题和相关的解决方案
date: 2018-2-7 9:00:00
tags:	[hexo]
toc: true
comments:	开启文章的评论功能	true
---

## 主要的构想

> **初衷** 个人需要督促下。很多东西，都是在自己的大脑中，没有经过整理。这个blog就是一个自我总结的展示。

**markdown** 我喜欢markdown，用文本展示一切。

**支持书写图形** 我讨厌画图，因为画图没有修改历史。我喜欢使用文本来画图。

**自动化** 当每次我完成新的文件提交，我的blog网站可以自动提交。

**无后台服务依赖** 这样我可以做到后续的快速迁移而不用考虑复杂的关联系统，关联的服务越多，迁移的成本就越高，复杂度也是越高

**永久免费**

**永久支持** 坚持是很难的，我希望我的blog至少要能比我有耐心和韧劲，不要我没有放弃，它门就放弃了。

**快速** 能很快上手，需要

## 相关实现

基于上面的设计原则，我做了下面的技术选型

### hexo作为blog基础

[hexo](https://hexo.io/)使用markdown来构建文章。而且它是基于nodejs来编写的，做二次开发也很容易。支持的插件也很多。

### maupassant-hexo

选择[maupassant-hexo](https://github.com/tufu9441/maupassant-hexo)作为主题，也是简洁的原因

### 使用disqus

评论区我最后选定了disqus，下面是我不使用其他的原因 

* ~~畅言 收集用户手机/微博/微信~~
* ~~gitment:默认依赖https://gh-oauth.imsun.net，替换需要一个独立的后台服务，用来支持github oauth~~

### mermaid

使用[mermaid](./_posts/mermaid使用说明.md)作为画图工具，暂时就这样，后续可以优化下

### travis-ci自动构建

### 使用github管理项目

这里我放弃了在本地预览的功能。如果这样，那么每次我在新的设备上写blog，就需要下载整个hexo及相关的配置。
这个网络消耗比较大，而且可能会不小心修改了错误的配置文件，造成travis-ci不能正确编译。
blog的文章是单独提交的，blog的配置是在另外的系统上，当构建blog时，将两者汇总到一起。
基于上面的设计，我设计了`oneforce/oneforce.github.io`的branch结构

```
  blog: blog的内容，仅包含所有个人文章的md格式和一个.travis.yml,用于触发travis-ci的自动构建
  hexo: 所有hexo的配置文件和theme
  master: github page展示的内容，主要是由travis-ci提交hexo g的内容
```

这里有几个点需要说明下

1. 请首先创建blog分支，然后创建hexo，master分支是由travis-ci构建脚本自动触发的。这样做的好处是每次登陆github，都可以直接编辑你的文章，而不是每次需要切换分支

## 问题总结

## 后续优化

### mermaid使用markdown语法支持，而不是hexo tag方式
暂时我使用了mermaid来支持图形化工具，但是这个实现不好。我希望使用markdown 的` ```mermaid `语法，而不是hexo的tag标签。使用tag标签后续迁移会很麻烦。
但是找了几个markdown的解析器，都没有能很好的支持mermaid语法

### 支持echart3 的markdown

### travis-ci构建信息在blog上展示
