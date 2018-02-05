---
title: mermaid使用说明
toc: true
date: 2018-2-25 14:00:00
description: mermaid使用说明
---

## Graph

关键字graph表示一个流程图的开始，同时需要指定该图的方向。例如

```
graph LR
    A –> B
```

{% mermaid %}
graph LR
    A –> B
{% endmermaid %}

流程图的定义仅由graph开始，但是方向的定义不止一种。

>> * TB（ top bottom）表示从上到下
>> * BT（bottom top）表示从下到上
>> * RL（right left）表示从右到左
>> * TD与TB一样表示从上到下
>> * LR（left right）表示从左到右


## 节点

有以下几种节点和形状：

>> * 默认节点 A
>> * 文本节点 B[bname]
>> * 圆角节点 C(cname)
>> * 圆形节点 D((dname))
>> * 非对称节点 E>ename]
>> * 菱形节点 F{fname}

以上大写字母表示节点，name表示它的名字，如下图。默认节点的A同时表示该节点和它的名字，例如上图的A和B。

```
graph TB
  A
  B[bname]
  C(cname)
  D((dname))
  E>ename]
  F{fname}
```

{% mermaid %}
graph TB
  A
  B[bname]
  C(cname)
  D((dname))
  E>ename]
  F{fname}
{% endmermaid %}

## 连线

节点间的连接线有多种形状，而且可以在连接线中加入标签：

>> * 箭头连接 A1–>B1
>> * 开放连接 A2—B2
>> * 标签连接 A3–text—B3 或者 A3—|text|B3
>> * 箭头标签连接 A4–text –>B4 或者 A4–>|text|B4
>> * 虚线开放连接 A5.-B5 或者 A5-.-B5 或者 A5..-B5
>> * 虚线箭头连接 A6.->B6 或者 A6-.->B6
>> * 标签虚线连接 A7-.text.-B7
>> * 标签虚线箭头连接 A8-.text.->B8
>> * 粗线开放连接 A9===B9
>> * 粗线箭头连接 A10==>B10
>> * 标签粗线开放连接 A11==text===B11
>> * 标签粗线箭头连接 A12==text==>B12

```
grahp TB
  A1–>B1
  A2—B2
  A3—|text|B3
  A4–>|text|B4
  A5..-B5
  A6-.->B6
```

{% mermaid %}
grahp TB
  A1–>B1
  A2—B2
  A3—|text|B3
  A4–>|text|B4
  A5..-B5
  A6-.->B6
{% endmermaid %}

```
grahp TB
  A7-.text.-B7
  A8-.text.->B8
  A9===B9
  A10==>B10
  A11==text===B11
  A12==text==>B12
```

{% mermaid %}
grahp TB
  A7-.text.-B7
  A8-.text.->B8
  A9===B9
  A10==>B10
  A11==text===B11
  A12==text==>B12
{% endmermaid %}


## 子图(Subgraphs)

```
graph TB
        subgraph one
        a1 --> a2
        en
        subgraph two
        b2 --> b2
        end
        subgraph three
        c1 --> c2
        end
        c1 --> a2
```

{% mermaid %}
graph TB
        subgraph one
        a1 --> a2
        en
        subgraph two
        b2 --> b2
        end
        subgraph three
        c1 --> c2
        end
        c1 --> a2
{% endmermaid %}

## 基础fontawesome支持

如果想加入来自frontawesome的图表字体,需要像frontawesome网站上那样引用的那样。详情请点击：[fontawdsome](https://fontawesome.com/)

引用的语法为：`fa:#icon class name#`

```
graph TD
      B["fa:fa-twitter for peace"]
      B-->C[fa:fa-ban forbidden]
      B-->D(fa:fa-spinner);
      B-->E(A fa:fa-camerra-retro perhaps?);
```

{% mermaid %}
graph TD
      B["fa:fa-twitter for peace"]
      B-->C[fa:fa-ban forbidden]
      B-->D(fa:fa-spinner);
      B-->E(A fa:fa-camerra-retro perhaps?);
{% endmermaid %}

## 甘特图(gantt)

```
gantt
dateFormat YYYY-MM-DD
section S1
T1: 2014-01-01, 9d
section S2
T2: 2014-01-11, 9d
section S3
T3: 2014-01-02, 9d
```

{% mermaid %}
gantt
dateFormat YYYY-MM-DD
section S1
T1: 2014-01-01, 9d
section S2
T2: 2014-01-11, 9d
section S3
T3: 2014-01-02, 9d
{% endmermaid %}

## Basic sequence diagram
{% mermaid %}

sequenceDiagram
    Alice ->> Bob: Hello Bob, how are you?
    Bob-->>John: How about you John?
    Bob--x Alice: I am good thanks!
    Bob-x John: I am good thanks!
    Note right of John: Bob thinks a long<br/>long time, so long<br/>that the text does<br/>not fit on a row.

    Bob-->Alice: Checking with John...
    Alice->John: Yes... John, how are you?
{% endmermaid %}

## Basic flowchart

{% mermaid %}
graph LR
    A[Square Rect] -- Link text --> B((Circle))
    A --> C(Round Rect)
    B --> D{Rhombus}
    C --> D
{% endmermaid %}


## Larger flowchart with some styling

{% mermaid %}
graph TB
    sq[Square shape] --> ci((Circle shape))

    subgraph A subgraph
        od>Odd shape]-- Two line<br/>edge comment --> ro
        di{Diamond with <br/> line break} -.-> ro(Rounded<br>square<br>shape)
        di==>ro2(Rounded square shape)
    end

    %% Notice that no text in shape are added here instead that is appended further down
    e --> od3>Really long text with linebreak<br>in an Odd shape]

    %% Comments after double percent signs
    e((Inner / circle<br>and some odd <br>special characters)) --> f(,.?!+-\*ز)

    cyr[Cyrillic]-->cyr2((Circle shape Начало));

     classDef green fill:#9f6,stroke:#333,stroke-width:2px;
     classDef orange fill:#f96,stroke:#333,stroke-width:4px;
     class sq,e green
     class di orange

{% endmermaid %}

## Loops, alt and opt

{% mermaid%}
sequenceDiagram
    loop Daily query
        Alice->>Bob: Hello Bob, how are you?
        alt is sick
            Bob->>Alice: Not so good :(
        else is well
            Bob->>Alice: Feeling fresh like a daisy
        end

        opt Extra response
            Bob->>Alice: Thanks for asking
        end
    end
{% endmermaid%}

## Message to self in loop

{% mermaid %}
sequenceDiagram
    participant Alice
    participant Bob
    Alice->>John: Hello John, how are you?
    loop Healthcheck
        John->>John: Fight against hypochondria
    end
    Note right of John: Rational thoughts<br/>prevail...
    John-->>Alice: Great!
    John->>Bob: How about you?
    Bob-->>John: Jolly good!
{% endmermaid %}


## gantt diagrams

{% mermaid %}
  gantt
         dateFormat  YYYY-MM-DD
         title Adding GANTT diagram functionality to mermaid

         section A section
         Completed task            :done,    des1, 2014-01-06,2014-01-08
         Active task               :active,  des2, 2014-01-09, 3d
         Future task               :         des3, after des2, 5d
         Future task2              :         des4, after des3, 5d

         section Critical tasks
         Completed task in the critical line :crit, done, 2014-01-06,24h
         Implement parser and jison          :crit, done, after des1, 2d
         Create tests for parser             :crit, active, 3d
         Future task in critical line        :crit, 5d
         Create tests for renderer           :2d
         Add to mermaid                      :1d

         section Documentation
         Describe gantt syntax               :active, a1, after des1, 3d
         Add gantt diagram to demo page      :after a1  , 20h
         Add another diagram to demo page    :doc1, after a1  , 48h

         section Last section
         Describe gantt syntax               :after doc1, 3d
         Add gantt diagram to demo page      :20h
         Add another diagram to demo page    :48h
{% endmermaid %}
