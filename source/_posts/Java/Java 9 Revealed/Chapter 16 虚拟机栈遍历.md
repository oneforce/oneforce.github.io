---
title: 虚拟机栈遍历
date: 2018-4-19 17:30:00
tags:	[Java9,JVM]
category: Java 9 Revealed
toc: true
comments: false
---



[原文地址](http://www.cnblogs.com/IcanFixIt/p/7238835.html)

在本章中，主要介绍以下内容：

* 什么是虚拟机栈（JVM Stack）和栈帧（Stack Frame）
* 如何在JDK 9之前遍历一个线程的栈
* 在JDK 9中如何使用StackWalker API遍历线程的栈
* 在JDK 9中如何获取调用者的类

## 一. 什么是虚拟机栈

JVM中的每个线程都有一个私有的JVM栈，它在创建线程的同时创建。 该栈是后进先出（LIFO）数据结构。 栈保存栈帧。 每次调用一个方法时，都会创建一个新的栈帧并将其推送到栈的顶部。 当方法调用完成时，栈帧销毁（从栈中弹出）。 堆栈中的每个栈帧都包含自己的局部变量数组，以及它自己的操作数栈，返回值和对当前方法类的运行时常量池的引用。 JVM的具体实现可以扩展一个栈帧来保存更多的信息。

JVM栈上的一个栈帧表示给定线程中的Java方法调用。 在给定的线程中，任何点只有一个栈帧是活动的。 活动栈帧被称为当前栈帧，其方法称为当前方法。 定义当前方法的类称为当前类。 当方法调用另一种方法时，栈帧不再是当前栈帧 —— 新的栈帧被推送到栈，并且执行方法成为当前方法，并且新栈帧成为当前栈帧。 当方法返回时，旧栈帧再次成为当前帧。 有关JVM栈和栈帧的更多详细信息，请参阅 https://docs.oracle.com/javase/specs/jvms/se8/html/index.html 上的Java虚拟机规范。

> Tips
>
> 如果JVM支持本地方法，则线程还包含本地方法栈，该栈包含每个本地方法调用的本地方法栈帧。

下图显示了两个线程及其JVM栈。 第一个线程的JVM栈包含四个栈帧，第二个线程的JVM栈包含三个栈帧。 Frame 4是Thread-1中的活动栈帧，Frame 3是Thread-2中的活动栈帧。

![](http://blog.oneforce.cn/images/20180419/thread_stack.png)

## 二. 什么是虚拟机栈遍历

虚拟机栈遍历是遍历线程的栈帧并检查栈帧的内容的过程。 从Java 1.4开始，可以获取线程栈的快照，并获取每个栈帧的详细信息，例如方法调用发生的类名称和方法名称，源文件名，源文件中的行号等。 栈遍历中使用的类和接口位于Stack-Walking API中。

## 三. JDK 8 中的栈遍历

在JDK 9之前，可以使用java.lang包中的以下类遍历线程栈中的所有栈帧：

* Throwable
* Thread
* StackTraceElement

`StackTraceElement`类的实例表示栈帧。 `Throwable`类的`getStackTrace()`方法返回一含当前线程栈的栈帧的`StackTraceElement []`数组。 Thread类的`getStackTrace()`方法返回一个`StackTraceElement []`数组，它包含线程栈的栈帧。 数组的第一个元素是栈中的顶层栈帧，表示序列中最后一个方法调用。 JVM的一些实现可能会在返回的数组中省略一些栈帧。

`StackTraceElement`类包含以下方法，它返回由栈帧表示的方法调用的详细信息：

```java
String getClassLoaderName()
String getClassName()
String getFileName()
int getLineNumber()
String getMethodName()
String getModuleName()
String getModuleVersion()
boolean isNativeMethod()
```

> Tips
>
> 在JDK 9中将`getModuleName()`，`getModuleVersion()`和`getClassLoaderName()`方法添加到此类中。


`StackTraceElement`类中的大多数方法都有直观的名称，例如，`getMethodName()`方法返回调用由此栈帧表示的方法的名称。 `getFileName()`方法返回包含方法调用代码的源文件的名称，getLineNumber()返回源文件中的方法调用代码的行号。

以下代码片段显示了如何使用Throwable和Thread类检查当前线程的栈：

```java
// Using the Throwable class
StackTraceElement[] frames = new Throwable().getStackTrace();
// Using the Thread class
StackTraceElement[] frames2 = Thread.currentThread()
                                   .getStackTrace();
// Process the frames here...
```

本章中的所有程序都是`com.jdojo.stackwalker`模块的一部分，其声明如下所示。

```java
// module-info.java
module com.jdojo.stackwalker {
    exports com.jdojo.stackwalker;
}
```

下面包含一个LegacyStackWalk类的代码。 该类的输出在JDK 8中运行时生成。

```java
// LegacyStackWalk.java
package com.jdojo.stackwalker;
import java.lang.reflect.InvocationTargetException;
public class LegacyStackWalk {
    public static void main(String[] args) {
        m1();
    }
    public static void m1() {
        m2();
    }
    public static void m2() {
        // Call m3() directly
        System.out.println("\nWithout using reflection: ");
        m3();
        // Call m3() using reflection        
        try {
            System.out.println("\nUsing reflection: ");
            LegacyStackWalk.class
                         .getMethod("m3")
                         .invoke(null);
        } catch (NoSuchMethodException |  
                 InvocationTargetException |
                 IllegalAccessException |
                 SecurityException e) {
            e.printStackTrace();
        }        
    }
    public static void m3() {
        // Prints the call stack details
        StackTraceElement[] frames = Thread.currentThread()
                                           .getStackTrace();
        for(StackTraceElement frame : frames) {
            System.out.println(frame.toString());
        }
    }
}
```

输出结果：

```
java.lang.Thread.getStackTrace(Thread.java:1552)
com.jdojo.stackwalker.LegacyStackWalk.m3(LegacyStackWalk.java:37)
com.jdojo.stackwalker.LegacyStackWalk.m2(LegacyStackWalk.java:18)
com.jdojo.stackwalker.LegacyStackWalk.m1(LegacyStackWalk.java:12)
com.jdojo.stackwalker.LegacyStackWalk.main(LegacyStackWalk.java:8)
Using reflection:
java.lang.Thread.getStackTrace(Thread.java:1552)
com.jdojo.stackwalker.LegacyStackWalk.m3(LegacyStackWalk.java:37)
sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
java.lang.reflect.Method.invoke(Method.java:498)
com.jdojo.stackwalker.LegacyStackWalk.m2(LegacyStackWalk.java:25)
com.jdojo.stackwalker.LegacyStackWalk.m1(LegacyStackWalk.java:12)
com.jdojo.stackwalker.LegacyStackWalk.main(LegacyStackWalk.java:8)
```

`LegacyStackWalk`类的`main()`方法调用`m1()`方法，它调用`m2()`方法。`m2()`方法直接调用`m3()`方法两次，其中一次使用了反射。 `m3()`方法使用Thread类的`getStrackTrace()`方法获取当前线程栈快照，并使用`StackTraceElement`类的toString()方法打印栈帧的详细信息。 可以使用此类的方法来获取每个栈帧的相同信息。 当在JDK 9中运行LegacyStackWalk类时，输出包括每行开始处的模块名称和模块版本。 JDK 9的输出如下：

```
Without using reflection:
java.base/java.lang.Thread.getStackTrace(Thread.java:1654)
com.jdojo.stackwalker/com.jdojo.stackwalker.LegacyStackWalk.m3(LegacyStackWalk.java:37)
com.jdojo.stackwalker/com.jdojo.stackwalker.LegacyStackWalk.m2(LegacyStackWalk.java:18)
com.jdojo.stackwalker/com.jdojo.stackwalker.LegacyStackWalk.m1(LegacyStackWalk.java:12)
com.jdojo.stackwalker/com.jdojo.stackwalker.LegacyStackWalk.main(LegacyStackWalk.java:8)
Using reflection:
java.base/java.lang.Thread.getStackTrace(Thread.java:1654)
com.jdojo.stackwalker/com.jdojo.stackwalker.LegacyStackWalk.m3(LegacyStackWalk.java:37)
java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
java.base/jdk.internal.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
java.base/java.lang.reflect.Method.invoke(Method.java:538)
com.jdojo.stackwalker/com.jdojo.stackwalker.LegacyStackWalk.m2(LegacyStackWalk.java:25)
com.jdojo.stackwalker/com.jdojo.stackwalker.LegacyStackWalk.m1(LegacyStackWalk.java:12)
com.jdojo.stackwalker/com.jdojo.stackwalker.LegacyStackWalk.main(LegacyStackWalk.java:8)
```

## 四. JDK 8 的栈遍历的缺点

在JDK 9之前，Stack-Walking API存在以下缺点：

* 效率不高。Throwable类的getStrackTrace()方法返回整个栈的快照。 没有办法在栈中只得到几个顶部栈帧。
* 栈帧包含方法名称和类名称，而不是类引用。 类引用是Class<?>类的实例，而类名只是字符串。
* JVM规范允许虚拟机实现在栈中省略一些栈帧来提升性能。 因此，如果有兴趣检查整个栈，那么如果虚拟机隐藏了一些栈帧，则无法执行此操作。
* JDK和其他类库中的许多API都是调用者敏感（caller-sensitive）的。 他们的行为基于调用者的类而有所不同。 例如，如果要调用Module类的addExports()方法，调用者的类必须在同一个模块中。 否则，将抛出一个IllegalCallerException异常。 在现有的API中，没有简单而有效的方式来获取调用者的类引用。 这样的API依赖于使用JDK内部API —— sun.reflect.Reflection类的getCallerClass()静态方法。
* 没有简单的方法来过滤特定实现类的栈帧。

## 五. JDK 9 中的栈遍历

JDK 9引入了一个新的Stack-Walking API，它由java.lang包中的`StackWalker`类组成。 该类提供简单而有效的栈遍历。 它为当前线程提供了一个顺序的栈帧流。 从栈生成的最上面的到最下面的栈帧，栈帧按顺序记录。 StackWalker类非常高效，因为它可以懒加载的方式地评估栈帧。 它还包含一个便捷的方法来获取调用者类的引用。 `StackWalker`类由以下成员组成：

* StackWalker.Option嵌套枚举
* StackWalker.StackFrame嵌套接口
* 获取StackWalker类实例的方法
* 处理栈帧的方法
* 获取调用者类的方法

### 1. 指定遍历选项

可以指定零个或多个选项来配置StackWalker。 选项是StackWalker.Option枚举的常量。 常量如下：

* RETAIN_CLASS_REFERENCE
* SHOW_HIDDEN_FRAMES
* SHOW_REFLECT_FRAMES

如果指定了`RETAIN_CLASS_REFERENCE`选项，则 `StackWalker`返回的栈帧将包含声明由该栈帧表示的方法的类的Class对象的引用。 如果要获取Class对象的方法调用者的引用，也需要指定此选项。 默认情况下，此选项不存在。

默认情况下，实现特定的和反射栈帧不包括在StackWalker类返回的栈帧中。 使用SHOW_HIDDEN_FRAMES选项来包括所有隐藏的栈帧。

如果指定了`SHOW_REFLECT_FRAMES`选项，则`StackWalker`类返回的栈帧流并包含反射栈帧。 使用此选项可能仍然隐藏实现特定的栈帧，可以使用`SHOW_HIDDEN_FRAMES`选项显示。

### 2. 表示一个栈帧

在JDK 9之前，StackTraceElement类的实例被用来表示栈帧。 JDK 9中的Stack-Walker API使用`StackWalker.StackFrame`接口的实例来表示栈帧。

> Tips
>
> StackWalker.StackFrame接口没有具体的实现类，可以直接使用。 JDK中的Stack-Walking API在检索栈帧时为你提供了接口的实例。

`StackWalker.StackFrame`接口包含以下方法，其中大部分与StackTraceElement类中的方法相同：

```java
int getByteCodeIndex()
String getClassName()
Class<?> getDeclaringClass()
String getFileName()
int getLineNumber()
String getMethodName()
boolean isNativeMethod()
StackTraceElement toStackTraceElement()
```


在类文件中，使用为method_info的结构描述每个方法。 method_info结构包含一个保存名为Code的可变长度属性的属性表。 Code属性包含一个code的数组，它保存该方法的字节码指令。 getByteCodeIndex()方法返回到包含由此栈帧表示的执行点的方法的Code属性中的代码数组的索引。 它为本地方法返回-1。 有关代码数组和代码属性的更多信息，请参阅“Java虚拟规范”第4.7.3节，网址为 https://docs.oracle.com/javase/specs/jvms/se8/html/。


如何使用方法的代码数组？ 作为应用程序开发人员，不会在方法中使用字节码索引作为执行点。 JDK确实支持使用内部API读取类文件及其所有属性。 可以使用位于`JDK_HOME\bin`目录中的javap工具查看方法中每条指令的字节码索引。 需要使用-c选项与javap打印方法的代码数组。 以下命令显示LegacyStackWalk类中所有方法的代码数组：

```
C:\Java9Revealed>javap -c com.jdojo.stackwalker\build\classes\com\jdojo\stackwalker\LegacyStackWalk.class
```

输出结果为：

```
Compiled from "LegacyStackWalk.java"
public class com.jdojo.stackwalker.LegacyStackWalk {
  public com.jdojo.stackwalker.LegacyStackWalk();
    Code:
       0: aload_0
       1: invokespecial #1                  // Method java/lang/Object."<init>":()V
       4: return
  public static void main(java.lang.String[]);
    Code:
       0: invokestatic  #2                  // Method m1:()V
       3: return
  public static void m1();
    Code:
       0: invokestatic  #3                  // Method m2:()V
       3: return
  public static void m2();
    Code:
       0: getstatic     #4                  // Field java/lang/System.out:Ljava/io/PrintStream;
       3: ldc           #5                  // String \nWithout using reflection:
       5: invokevirtual #6                  // Method java/io/PrintStream.println:(Ljava/lang/String;)V
       8: invokestatic  #7                  // Method m3:()V
...
      32: anewarray     #13                 // class java/lang/Object
      35: invokevirtual #14                 // Method java/lang/reflect/Method.invoke:(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;
...
  public static void m3();
    Code:
       0: invokestatic  #20                 // Method java/lang/Thread.currentThread:()Ljava/lang/Thread;
       3: invokevirtual #21                 // Method java/lang/Thread.getStackTrace:()[Ljava/lang/StackTraceElement;
...
}
```

当在方法m3()中获取调用栈的快照时，m2()方法调用m3()两次。 对于第一次调用，字节码索引为8，第二次为35。

`getDeclaringClass()`方法返回声明由栈帧表示的方法的类的Class对象的引用。 如果该StackWalker没有配置RETAIN_CLASS_REFERENCE选项，它会抛出UnsupportedOperationException异常。

`toStackTraceElement()`方法返回表示相堆栈帧的StackTraceElement类的实例。 如果要使用JDK 9 API来获取StackWalker.StackFrame，但是继续使用使用StackTraceElement类的旧代码来分析栈帧，这种方法非常方便。

### 3. 获取StackWalker

StackWalker类包含返回StackWalker实例的静态工厂方法：

```java
StackWalker getInstance()
StackWalker getInstance (StackWalker.Option option)
StackWalker getInstance (Set<StackWalker.Option> options)
StackWalker getInstance (Set<StackWalker.Option> options, int estimateDepth)
```

可以使用不同版本的getInstance()方法来配置StackWalker。 默认配置是排除所有隐藏的栈帧，不保留类引用。 允许指定StackWalker.Option的版本使用这些选项进行配置。

estimateDepth参数是一个提示，指示StackWalker预计将遍历的栈帧的评估数，因此可能会优化内部缓冲区的大小。

以下代码片段创建了具有不同配置的StackWalker类的四个实例：

```java
import java.util.Set;
import static java.lang.StackWalker.Option.*;
...
// Get a StackWalker with a default configuration
StackWalker sw1 = StackWalker.getInstance();
// Get a StackWalker that shows reflection frames
StackWalker sw2 = StackWalker.getInstance(SHOW_REFLECT_FRAMES);
// Get a StackWalker that shows all hidden frames
StackWalker sw3 = StackWalker.getInstance(SHOW_HIDDEN_FRAMES);
// Get a StackWalker that shows reflection frames and retains class references
StackWalker sw4 = StackWalker.getInstance(Set.of(SHOW_REFLECT_FRAMES, RETAIN_CLASS_REFERENCE));
```

> Tips
>
> StackWalker是线程安全且可重用的。 多个线程可以使用相同的实例遍历自己的栈。

### 4. 遍历栈

现在是遍历线程的栈帧的时候了。StackWalker类包含两个方法，可以遍历当前线程的栈：

```java
void forEach(Consumer<? super StackWalker.StackFrame> action)
<T> T walk(Function<? super Stream<StackWalker.StackFrame>,? extends T> function)
```

如果需要遍历整个栈，使用forEach()方法。 指定的Consumer将从栈中提供一个栈帧，从最上面的栈帧开始。 以下代码段打印了StackWalker返回的每个栈帧的详细信息：

```java
// Prints the details of all stack frames of the current thread
StackWalker.getInstance()
           .forEach(System.out::println);
```

如果要定制栈遍历，例如使用过滤器和映射，使用`walk()`方法。 `walk()`方法接受一个Function，它接受一个`Stream <StackWalker.StackFrame>`作为参数，并可以返回任何类型的对象。 StackWalker将创建栈帧流并将其传递给function。 当功能完成时，StackWalker将关闭流。 传递给walk()方法的流只能遍历一次。 第二次尝试遍历流时会抛出IllegalStateException异常。

以下代码片段使用walk()方法遍历整个栈，打印每个栈帧的详细信息。 这段代码与前面的代码片段使用forEach()方法相同。

```java
// Prints the details of all stack frames of the current thread
StackWalker.getInstance()
           .walk(s -> {
               s.forEach(System.out::println);
               return null;
            });
```

> Tips
>
> `StackWalker的forEach()`方法用于一次处理一个栈帧，而walk()方法用于处理将整个栈为帧流。 可以使用walk()方法来模拟forEach()方法的功能，但反之亦然。

可能会想知道为什么walk()方法不返回栈帧流而是将流传递给函数。 没有从方法返回堆栈帧流是有意为之的。 流的元素被懒加载的方式评估。 一旦创建了栈帧流，JVM就可以自由地重新组织栈，并且没有确定的方法来检测栈已经改变，仍然保留对其流的引用。 这就是创建和关闭栈帧流由StackWalker类控制的原因。

由于Streams API是广泛的，所以使用walk()方法。 以下代码片段获取列表中当前线程的栈帧的快照。

```java
import java.lang.StackWalker.StackFrame;
import java.util.List;
import static java.util.stream.Collectors.toList;
...
List<StackFrame> frames = StackWalker.getInstance()
                            .walk(s -> s.collect(toList()));
```

以下代码段收集列表中当前线程的所有栈帧的字符串形式，不包括表示以m2开头的方法的栈帧：

```java
import java.util.List;
import static java.util.stream.Collectors.toList;
...
List<String> list = StackWalker.getInstance()
  .walk(s -> s.filter(f -> !f.getMethodName().startsWith("m2"))
              .map(f -> f.toString())
              .collect(toList())
       );
```

以下代码片段收集列表中当前线程的所有栈帧的字符串形式，不包括声明类名称以Test结尾的方法的框架：

```java
import static java.lang.StackWalker.Option.RETAIN_CLASS_REFERENCE;
import java.util.List;
import static java.util.stream.Collectors.toList;
...
List<String> list = StackWalker
    .getInstance(RETAIN_CLASS_REFERENCE)
    .walk(s -> s.filter(f -> !f.getDeclaringClass()
                               .getName().endsWith("Test"))
                .map(f -> f.toString())
                .collect(toList())
          );
```

以下代码段以字符串的形式收集整个栈信息，将每个栈帧与平台特定的行分隔符分隔开：

```java
import static java.util.stream.Collectors.joining;
...
String stackStr = StackWalker.getInstance()
$.walk(s -> s.map(f -> f.toString())
             .collect(joining(System.getProperty("line.separator")
       )));
```

下面包含一个完整的程序，用于展示StackWalker类及其walk()方法的使用。 它的main()方法调用m1()方法两次，每次通过StackWalker的一组不同的选项。 m2()方法使用反射来调用m3()方法，它打印堆栈帧细节信息。 第一次，反射栈帧是隐藏的，类引用不可用。

```java
// StackWalking.java
package com.jdojo.stackwalker;
import java.lang.StackWalker.Option;
import static java.lang.StackWalker.Option.RETAIN_CLASS_REFERENCE;
import static java.lang.StackWalker.Option.SHOW_REFLECT_FRAMES;
import java.lang.StackWalker.StackFrame;
import java.lang.reflect.InvocationTargetException;
import java.util.Set;
import java.util.stream.Stream;
public class StackWalking {
    public static void main(String[] args) {
        m1(Set.of());
        System.out.println();
        // Retain class references and show reflection frames
        m1(Set.of(RETAIN_CLASS_REFERENCE, SHOW_REFLECT_FRAMES));
    }
    public static void m1(Set<Option> options) {
        m2(options);
    }
    public static void m2(Set<Option> options) {
        // Call m3() using reflection
        try {
            System.out.println("Using StackWalker Options: " + options);
            StackWalking.class
                     .getMethod("m3", Set.class)
                     .invoke(null, options);
        } catch (NoSuchMethodException
                | InvocationTargetException
                | IllegalAccessException
                | SecurityException e) {
            e.printStackTrace();
        }
    }
    public static void m3(Set<Option> options) {
        // Prints the call stack details
        StackWalker.getInstance(options)
                   .walk(StackWalking::processStack);
    }
    public static Void processStack(Stream<StackFrame> stack) {
        stack.forEach(frame -> {
            int bci = frame.getByteCodeIndex();
            String className = frame.getClassName();        
            Class<?> classRef = null;
            try {
                classRef = frame.getDeclaringClass();
            } catch (UnsupportedOperationException e) {
                // No action to take
            }
            String fileName = frame.getFileName();
            int lineNumber = frame.getLineNumber();
            String methodName = frame.getMethodName();
            boolean isNative = frame.isNativeMethod();
            StackTraceElement sfe = frame.toStackTraceElement();
            System.out.printf("Native Method=%b", isNative);
            System.out.printf(", Byte Code Index=%d", bci);
            System.out.printf(", Module Name=%s", sfe.getModuleName());
            System.out.printf(", Module Version=%s", sfe.getModuleVersion());
            System.out.printf(", Class Name=%s", className);
            System.out.printf(", Class Reference=%s", classRef);
            System.out.printf(", File Name=%s", fileName);
            System.out.printf(", Line Number=%d", lineNumber);
            System.out.printf(", Method Name=%s.%n", methodName);
        });
        return null;
    }
}
```

输出的结果为：

```
Using StackWalker Options: []
Native Method=false, Byte Code Index=9, Module Name=null, Module Version=null, Class Name=com.jdojo.stackwalker.StackWalking, Class Reference=null, FileName=StackWalking.java, Line Number=44, Method Name=m3.
Native Method=false, Byte Code Index=37, Module Name=null, Module Version=null, Class Name=com.jdojo.stackwalker.StackWalking, Class Reference=null, File Name=StackWalking.java, Line Number=32, Method Name=m2.
Native Method=false, Byte Code Index=1, Module Name=null, Module Version=null, Class Name=com.jdojo.stackwalker.StackWalking, Class Reference=null, File Name=StackWalking.java, Line Number=23, Method Name=m1.
Native Method=false, Byte Code Index=3, Module Name=null, Module Version=null, Class Name=com.jdojo.stackwalker.StackWalking, Class Reference=null, File Name=StackWalking.java, Line Number=14, Method Name=main .
Using StackWalker Options: [SHOW_REFLECT_FRAMES, RETAIN_CLASS_REFERENCE]
Native Method=false, Byte Code Index=9, Module Name=null, Module Version=null, Class Name=com.jdojo.stackwalker.StackWalking, Class Reference=class com.jdojo.stackwalker.StackWalking, File Name=StackWalking.java, Line Number=44, Method Name=m3.
Native Method=true, Byte Code Index=-1, Module Name=java.base, Module Version=9-ea, Class Name=jdk.internal.reflect.NativeMethodAccessorImpl, Class Reference=class jdk.internal.reflect.NativeMethodAccessorImpl, File Name=NativeMethodAccessorImpl.java, Line Number=-2, Method Name=invoke0.
Native Method=false, Byte Code Index=100, Module Name=java.base, Module Version=9-ea, Class Name=jdk.internal.reflect.NativeMethodAccessorImpl, Class Reference=class jdk.internal.reflect.NativeMethodAccessorImpl, File Name=NativeMethodAccessorImpl.java, Line Number=62, Method Name=invoke.
Native Method=false, Byte Code Index=6, Module Name=java.base, Module Version=9-ea, Class Name=jdk.internal.reflect.DelegatingMethodAccessorImpl, Class Reference=class jdk.internal.reflect.DelegatingMethodAccessorImpl, File Name=DelegatingMethodAccessorImpl.java, Line Number=43, Method Name=invoke.
Native Method=false, Byte Code Index=59, Module Name=java.base, Module Version=9-ea, Class Name=java.lang.reflect.Method, Class Reference=class java.lang.reflect.Method, File Name=Method.java, Line Number=538, Method Name=invoke.
Native Method=false, Byte Code Index=37, Module Name=null, Module Version=null, Class Name=com.jdojo.stackwalker.StackWalking, Class Reference=class com.jdojo.stackwalker.StackWalking, File Name=StackWalking.java, Line Number=32, Method Name=m2.
Native Method=false, Byte Code Index=1, Module Name=null, Module Version=null, Class Name=com.jdojo.stackwalker.StackWalking, Class Reference=class com.jdojo.stackwalker.StackWalking, File Name=StackWalking.java, Line Number=23, Method Name=m1.
Native Method=false, Byte Code Index=21, Module Name=null, Module Version=null, Class Name=com.jdojo.stackwalker.StackWalking, Class Reference=class com.jdojo.stackwalker.StackWalking, File Name=StackWalking.java, Line Number=19, Method Name=main .
```

### 5. 认识调用者的类

在JDK 9之前，开发人员依靠以下方法来获取调用者的调用：


`SecurityManager`类的`getClassContext()`方法，由于该方法受到保护，因此需要进行子类化。
`sun.reflect.Reflection`类的`getCallerClass()`方法，它是一个JDK内部类。
JDK 9通过在StackWalker类中添加一个`getCallerClass()`的方法，使得获取调用者类引用变得容易。 方法的返回类型是Class<?>。 如果StackWalker未配置RETAIN_CLASS_REFERENCE选项，则调用此方法将抛出UnsupportedOperationException异常。 如果栈中没有调用者栈帧，则调用此方法会引发IllegalStateException，例如，运行main()方法调用此方法的类。

那么，哪个类是调用类？ 在Java中，方法和构造函数可调用。 以下讨论使用方法，但是它也适用于构造函数。 假设在S的方法中调用getCallerClass()方法，该方法从T的方法调用。另外假设T的方法在名为C的类中。在这种情况下，C类是调用者类。

> Tips
>
> `StackWalker`类的`getCallerClass()`方法在查找调用者类时会过滤所有隐藏和反射栈帧，而不管用于获取StackWalker实例的选项如何。

下面包含一个完整的程序来显示如何获取调用者的类。 它的main()方法调用m1()方法，m1调用m2()方法，m2调用m3()方法。 m3()方法获取StackWalker类的实例并获取调用者类。 请注意，m2()方法使用反射来调用m3()方法。 最后，main()方法尝试获取调用者类。 当运行CallerClassTest类时，main()方法由JVM调用，栈上不会有调用者栈帧。 这将抛出一个IllegalStateException异常。

```java
// CallerClassTest.java
package com.jdojo.stackwalker;
import java.lang.StackWalker.Option;
import static java.lang.StackWalker.Option.RETAIN_CLASS_REFERENCE;
import static java.lang.StackWalker.Option.SHOW_REFLECT_FRAMES;
import java.lang.reflect.InvocationTargetException;
import java.util.Set;
public class CallerClassTest {
    public static void main(String[] args) {
        /* Will not be able to get caller class because because the RETAIN_CLASS_REFERENCE
           option is not specified.
        */
        m1(Set.of());
        // Will print the caller class
        m1(Set.of(RETAIN_CLASS_REFERENCE, SHOW_REFLECT_FRAMES));
        try {
            /* The following statement will throw an IllegalStateException if this class is run
               because there will be no caller class; JVM will call this method. However,
               if the main() method is called in code, no exception will be thrown.            
            */
            Class<?> cls = StackWalker.getInstance(RETAIN_CLASS_REFERENCE)
                                      .getCallerClass();
            System.out.println("In main method, Caller Class: " + cls.getName());
        } catch (IllegalCallerException e) {
            System.out.println("In main method, Exception: " + e.getMessage());
        }
    }
    public static void m1(Set<Option> options) {
        m2(options);
    }
    public static void m2(Set<Option> options) {
        // Call m3() using reflection
        try {
            CallerClassTest.class
                           .getMethod("m3", Set.class)
                           .invoke(null, options);
        } catch (NoSuchMethodException | InvocationTargetException
                | IllegalAccessException | SecurityException e) {
            e.printStackTrace();
        }
    }
    public static void m3(Set<Option> options) {
        try {
            // Print the caller class
            Class<?> cls = StackWalker.getInstance(options)                  
                                      .getCallerClass();
            System.out.println("Caller Class: " + cls.getName());
        } catch (UnsupportedOperationException e) {
            System.out.println("Inside m3(): " + e.getMessage());
        }
    }
}
```

输出结果为：

```
Inside m3(): This stack walker does not have RETAIN_CLASS_REFERENCE access
Caller Class: com.jdojo.stackwalker.CallerClassTest
In main method, Exception: no caller frame
```

在前面的例子中，收集栈帧的方法是从同一个类的另一个方法中调用的。 我们从另一个类的方法中调用这个方法来看到一个不同的结果。 下面显示了CallerClassTest2的类的代码。

```java
// CallerClassTest2.java
package com.jdojo.stackwalker;
import java.lang.StackWalker.Option;
import java.util.Set;
import static java.lang.StackWalker.Option.RETAIN_CLASS_REFERENCE;
public class CallerClassTest2 {
    public static void main(String[] args) {
        Set<Option> options = Set.of(RETAIN_CLASS_REFERENCE);
        CallerClassTest.m1(options);
        CallerClassTest.m2(options);
        CallerClassTest.m3(options);
        System.out.println("\nCalling the main() method:");
        CallerClassTest.main(null);
        System.out.println("\nUsing an anonymous class:");
        new Object() {
            {
                CallerClassTest.m3(options);
            }   
        };
        System.out.println("\nUsing a lambda expression:");
        new Thread(() -> CallerClassTest.m3(options))
            .start();
    }
}
```

输出结果为：

```java
Caller Class: com.jdojo.stackwalker.CallerClassTest
Caller Class: com.jdojo.stackwalker.CallerClassTest
Caller Class: com.jdojo.stackwalker.CallerClassTest2
Calling the main() method:
Inside m3(): This stack walker does not have RETAIN_CLASS_REFERENCE access
Caller Class: com.jdojo.stackwalker.CallerClassTest
In main method, Caller Class: com.jdojo.stackwalker.CallerClassTest2
Using an anonymous class:
Caller Class: com.jdojo.stackwalker.CallerClassTest2$1
Using a lambda expression:
Caller Class: com.jdojo.stackwalker.CallerClassTest2
```

`CallerClassTest2`类的`main()`方法调用CallerClassTest类的四个方法。 当CallerClassTest.m3()从CallerClassTest2类直接调用时，调用者类是CallerClassTest2。 当从CallerClassTest2类调用CallerClassTest.main()方法时，有一个调用者栈帧，调用者类是CallerClassTest2类。 当运行CallerClassTest类时，将其与上一个示例的输出进行比较。 那时，CallerClassTest.main()方法是从JVM调用的，不能在CallerClassTest.main()方法中获得一个调用者类，因为没有调用者栈帧。 最后，CallerClassTest.m3()方法从匿名类和lambda表达式调用。 匿名类被报告为调用者类。 在lambda表达式的情况下，它的闭合类被报告为调用者类。

### 6. 栈遍历权限

当存在Java安全管理器并且使用RETAIN_CLASS_REFERENCE选项配置StackWalker时，将执行权限检查，以确保代码库被授予retainClassReference的java.lang.StackFramePermission值。 如果未授予权限，则抛出SecurityException异常。 在创建StackWalker实例时执行权限检查，而不是在执行栈遍历时。

下包含StackWalkerPermissionCheck类的代码。 它的printStackFrames()方法使用RETAIN_CLASS_REFERENCE选项创建StackWalker实例。 假设没有安全管理器，main()方法调用此方法，它打印堆栈跟踪没有任何问题。 安装安全管理器以后，再次调用printStackFrames()方法。 这一次，抛出一个SecurityException异常，这在输出中显示。

```java
// StackWalkerPermissionCheck.java
package com.jdojo.stackwalker;
import static java.lang.StackWalker.Option.RETAIN_CLASS_REFERENCE;
public class StackWalkerPermissionCheck {
    public static void main(String[] args) {
        System.out.println("Before installing security manager:");
        printStackFrames();
        SecurityManager sm = System.getSecurityManager();
        if (sm == null) {
            sm = new SecurityManager();
            System.setSecurityManager(sm);
        }
        System.out.println(
            "\nAfter installing security manager:");
        printStackFrames();
    }
    public static void printStackFrames() {
        try {
            StackWalker.getInstance(RETAIN_CLASS_REFERENCE)
                       .forEach(System.out::println);
        } catch(SecurityException  e){
            System.out.println("Could not create a " +
                "StackWalker. Error: " + e.getMessage());
        }
    }
}
```

输出结果为：

```
Before installing security manager:
com.jdojo.stackwalker/com.jdojo.stackwalker.StackWalkerPermissionCheck.printStackFrames(StackWalkerPermissionCheck.java:24)
com.jdojo.stackwalker/com.jdojo.stackwalker.StackWalkerPermissionCheck.main(StackWalkerPermissionCheck.java:9)
After installing security manager:
Could not create a StackWalker. Error: access denied ("java.lang.StackFramePermission" "retainClassReference")

```

下面显示了如何使用RETAIN_CLASS_REFERENCE选项授予创建StackWalker所需的权限。 授予所有代码库的权限，需要将此权限块添加到位于机器上的JAVA_HOME\conf\security目录中的java.policy文件的末尾。

```
grant {
    permission java.lang.StackFramePermission "retainClassReference";
};
```

当授予权限以后再运行上面的类时，应该会收到以下输出：

```
Before installing security manager:
com.jdojo.stackwalker/com.jdojo.stackwalker.StackWalkerPermissionCheck.printStackFrames(StackWalkerPermissionCheck.java:24)
com.jdojo.stackwalker/com.jdojo.stackwalker.StackWalkerPermissionCheck.main(StackWalkerPermissionCheck.java:9)
After installing security manager:
com.jdojo.stackwalker/com.jdojo.stackwalker.StackWalkerPermissionCheck.printStackFrames(StackWalkerPermissionCheck.java:24)
com.jdojo.stackwalker/com.jdojo.stackwalker.StackWalkerPermissionCheck.main(StackWalkerPermissionCheck.java:18)
```

## 六. 总结

JVM中的每个线程都有一个私有的JVM栈，它在创建线程的同时创建。 栈保存栈帧。 JVM栈上的一个栈帧表示给定线程中的Java方法调用。 每次调用一个方法时，都会创建一个新的栈帧并将其推送到栈的顶部。 当方法调用完成时，框架被销毁（从堆栈中弹出）。 在给定的线程中，任何点只有一个栈帧是活动的。 活动栈帧被称为当前栈帧，其方法称为当前方法。 定义当前方法的类称为当前类。

在JDK 9之前，可以使用以下类遍历线程栈中的所有栈帧：Throwable，hread和StackTraceElement。 StackTraceElement类的实例表示栈帧。 Throwable类的getStrackTrace()方法返回包含当前线程栈帧的StackTraceElement []。 Thread类的getStrackTrace()方法返回包含线程栈帧的StackTraceElement []。 数组的第一个元素是栈中的顶层栈帧，表示序列中最后一个方法调用。 一些JVM的实现可能会在返回的数组中省略一些栈帧。

JDK 9使栈遍历变得容易。 它在java.lang包中引入了一个StackWalker的新类。 可以使用getInstance()的静态工厂方法获取StackWalker的实例。 可以使用StackWalker.Option的枚举中定义的常量来表示的选项来配置StackWalker。 `StackWalker.StackFrame`的嵌套接口的实例表示栈帧。 StackWalker类与StackWalker.StackFrame实例配合使用。 该接口定义了`toStackTraceElement()`的方法，可用于从`StackWalker.StackFrame`获取`StackTraceElement`类的实例。

可以使用StackWalker实例的`forEach()`和`walk()`方法遍历当前线程的栈帧。 StackWalker实例的getCallerClass()方法返回调用者类引用。 如果想要代表栈帧的类的引用和调用者类的引用，则必须使用RETAIN_CLASS_REFERENCE配置StackWalker实例。 默认情况下，所有反射栈帧和实现特定的栈帧都不会被StackWalker记录。 如果希望这些框架包含在栈遍历中，请使用SHOW_REFLECT_FRAMES和SHOW_HIDDEN_FRAMES选项来配置StackWalker。 使用SHOW_HIDDEN_FRAMES选项也包括反栈帧。

当存在Java安全管理器并且使用RETAIN_CLASS_REFERENCE选项配置StackWalker时，将执行权限检查，以确保代码库被授予retainClassReference的java.lang.StackFramePermission值。 如果未授予权限，则抛出SecurityException异常。 在创建StackWalker实例时执行权限检查，而不是执行栈遍历时。
