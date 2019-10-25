---
title: 设置context-path不能被服务发现的问题
date: 2019-10-25 14:10:00
tags:	[spring,zookeeper,spring boot]
category: spring
toc: true
comments: false
---

### zookeeper

```
spring.cloud.zookeeper.discovery.metadata.management.context-path=/wxht
```

### eureka:

```
eureka.instance.metadata-map.management.context-path=/pay/actuator
```
