---
title: Mysql的on update 的说明
date: 2019-10-21 14:10:00
tags:	[mysql]
category: mysql
toc: true
comments: false
---

```

drop table if exists test;
create table test (
    id int auto_increment primary key
    ,info varchar(1000)
    ,created_time timestamp default CURRENT_TIMESTAMP  comment '创建时间'
    ,updated_time timestamp default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP comment '更新时间'
);

insert into test (info) value ('test');

```

## 如果更新的数据相同，那么`updated_time`不会更新

```
-- updated_time没有更新
update test set info = 'test'
where id = 1;

-- updated_time更新了
update test set info = 'test1'
where id = 1;
```

## 如果修改表结构，增加字段/删除字段不会更新

```
alter table test add (name varchar(100) default 'test');
```

## 如果不想更新更新字段，请使用 updated_time = updated_time

```
update test set info = 'test',updated_time = updated_time
where id = 1;
```

## 如果有事务，那么更新时间是该记录的更新时间，不是该事务的提交时间

1. 如果事务在14:00:00 开启
1. 记录在14:00:01更新
1. 事务在14:01:00 提交

那么数据的的更新时间是14:00:01，而不是14:01:00

