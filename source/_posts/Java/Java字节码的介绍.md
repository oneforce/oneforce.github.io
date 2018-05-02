---
title: Java字节码的介绍
description: 这个我计划分为几个部分一起来说明下JAVA的SPI机制。
date: 2018-5-2 9:00:00
tags:	[入门系列]
toc: true
finished: false
comments: true
---

* [原文地址](https://dzone.com/articles/introduction-to-java-bytecode)
* [原文翻译地址](https://www.oschina.net/translate/introduction-to-java-bytecode?from=20180422)

即便对那些有经验的Java开发人员来说，阅读已编译的Java字节码也很乏味。为什么我们首先需要了解这种底层的东西？这是上周发生在我身上的一个简单故事：很久以前，我在机器上做了一些代码更改，编译了一个JAR，并将其部署到服务器上，以测试性能问题的一个潜在修复方案。不幸的是，代码从未被检入到版本控制系统中，并且出于某种原因，本地更改被删除了而没有追踪。几个月后，我再次修改源代码，但是我找不到上一次更改的版本！

幸运的是编译后的代码仍然存在于该远程服务器上。我于是松了一口气，我再次抓取JAR并使用反编译器编辑器打开它......只有一个问题：反编译器GUI不是一个完美的工具，并且出于某种原因，在该JAR中的许多类中找到我想要反编译的特定类并在我打开它时会在UI中导致了一个错误，并且反编译器崩溃！


绝望的时候需要采取孤注一掷的措施。幸运的是，我对原始字节码很熟悉，我宁愿花些时间手动地对一些代码进行反编译，而不是通过不断的更改和测试它们。因为我仍然记得在哪里可以查看代码，所以阅读字节码帮助我精确地确定了具体的变化，并以源代码形式构建它们。（我一定要从我的错误中吸取教训，这次要珍惜好这些教训！）

字节码的好处是，您可以只用学习它的语法一次，然后它适用于所有Java支持的平台——因为它是代码的中间表示，而不是底层CPU的实际可执行代码。此外，字节码比本机代码更简单，因为JVM架构相当简单，因此简化了指令集，另一件好事是，这个集合中的所有指令都是由Oracle提供[完整的文档](https://docs.oracle.com/javase/specs/jvms/se9/html/jvms-6.html)。

不过，在学习字节码指令集之前，让我们熟悉一下JVM的一些事情，这是进行下一步的先决条件。

## JVM 数据类型

Java是静态类型的，它会影响字节码指令的设计，这样指令就会期望自己对特定类型的值进行操作。例如，就会有好几个add指令用于两个数字相加：iadd、ladd、fadd、dadd。他们期望类型的操作数分别是int、long、float和double。大多数字节码都有这样的特性，它具有不同形式的相同功能，这取决于操作数类型。

VM定义的数据类型包括:

* 基本类型:
** 数值类型: byte (8位), short (16位), int (32位), long (64-bit位), char (16位无符号Unicode), float(32-bit IEEE 754 单精度浮点型), double (64-bit IEEE 754 双精度浮点型)
** 布尔类型
** 指针类型: 指令指针。
* 引用类型:
** 类
** 数组
** 接口

在字节码中布尔类型的支持是受限的。举例来说，没有结构能直接操作布尔值。布尔值被替换转换成 int 是通过编译器来进行的，并且最终还是被转换成 int 结构。

Java 开发者应该熟悉所有上面的类型，除了 returnAddress，它没有等价的编程语言类型。

### 基于栈的架构

字节码指令集的简单性很大程度上是由于 Sun 设计了基于堆栈的 VM 架构，而不是基于寄存器架构。有各种各样的进程使用基于JVM 的内存组件, 但基本上只有 JVM 堆需要详细检查字节码指令：

* PC寄存器：对于Java程序中每个正在运行的线程，都有一个PC寄存器保存着当前执行的指令地址。
* JVM 栈：对于每个线程，都会分配一个栈，其中存放本地变量、方法参数和返回值。下面是一个显示3个线程的堆栈示例。

![](http://blog.oneforce.cn/images/20180502/stack1.png)

* 堆：所有线程共享的内存和存储对象（类实例和数组）。对象回收是由垃圾收集器管理的。

![](http://blog.oneforce.cn/images/20180502/stack2.png)

* 方法区：对于每个已加载的类，它储存方法的代码和一个符号表（例如对字段或方法的引用）和常量池。

![](http://blog.oneforce.cn/images/20180502/class_data.png)


JVM堆栈是由帧组成的，当方法被调用时，每个帧都被推到堆栈上，当方法完成时从堆栈中弹出（通过正常返回或抛出异常）。每一帧还包括：

* 本地变量数组，索引从0到它的长度-1。长度是由编译器计算的。一个局部变量可以保存任何类型的值，long和double类型的值占用两个局部变量。
* 用来存储中间值的栈，它存储指令的操作数，或者方法调用的参数。

![](http://blog.oneforce.cn/images/20180502/stack3.png)

## 字节码探索

关于JVM内部的看法，我们能够从示例代码中看到一些被生成的基本字节码例子。Java类文件中的每个方法都有代码段，这些代码段包含了一系列的指令，格式如下：

```
opcode (1 byte)      operand1 (optional)      operand2 (optional)      ...
```

这个指令是由一个一字节的opcode和零个或若干个operand组成的，这个operand包含了要被操作的数据。

在当前执行方法的栈帧里，一条指令可以将值在操作栈中入栈或出栈，可以在本地变量数组中悄悄地加载或者存储值。让我们来看一个例子：

```java
public static void main(String[] args) {
    int a = 1;
    int b = 2;
    int c = a + b;
}
```

为了打印被编译的类中的结果字节码（假设在Test.class文件中），我们运行javap工具：

```
javap -v Test.class
```

我们可以得到如下结果：

```
public static void main(java.lang.String[]);
descriptor: ([Ljava/lang/String;)V
flags: (0x0009) ACC_PUBLIC, ACC_STATIC
Code:
stack=2, locals=4, args_size=1
0: iconst_1
1: istore_1
2: iconst_2
3: istore_2
4: iload_1
5: iload_2
6: iadd
7: istore_3
8: return
...
```

我们可以看到main方法的方法声明，descriptor说明这个方法的参数是一个字符串数组([Ljava/lang/String; )，而且返回类型是void（V）。下面的flags这行说明该方法是公开的(ACC_PUBLIC)和静态的 (ACC_STATIC)。

Code属性是最重要的部分，它包含了这个方法的一系列指令和信息，这些信息包含了操作栈的最大深度（本例中是2）和在这个方法的这一帧中被分配的本地变量的数量（本例中是4）。所有的本地变量在上面的指令中都提到了，除了第一个变量（索引为0），这个变量保存的是args参数。其他三个本地变量就相当于源码中的a，b和c。


从地址0到8的指令将执行以下操作：
iconst_1:将整形常量1放入操作数栈。


![](http://blog.oneforce.cn/images/20180502/step1.png)

istore_1:在索引为1的位置将第一个操作数出栈（一个int值）并且将其存进本地变量，相当于变量a。

![](http://blog.oneforce.cn/images/20180502/step2.png)

iconst_2:将整形常量2放入操作数栈。

![](http://blog.oneforce.cn/images/20180502/step3.png)

istore_2:在索引为2的位置将第一个操作数出栈并且将其存进本地变量，相当于变量b。

![](http://blog.oneforce.cn/images/20180502/step4.png)

iload_1:从索引1的本地变量中加载一个int值，放入操作数栈。

![](http://blog.oneforce.cn/images/20180502/step5.png)

iload_2:从索引2的本地变量中加载一个int值，放入操作数栈。


![](http://blog.oneforce.cn/images/20180502/step6.png)

iadd:把操作数栈中的前两个int值出栈并相加，将相加的结果放入操作数栈。

![](http://blog.oneforce.cn/images/20180502/step7.png)
