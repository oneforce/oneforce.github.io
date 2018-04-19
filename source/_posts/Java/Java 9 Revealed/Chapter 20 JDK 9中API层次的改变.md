---
title: JDK 9中API层次的改变
date: 2018-4-19 14:50:00
tags:	[Java9]
category: Java 9 Revealed
toc: true
comments: false
---

[原文地址](http://www.cnblogs.com/IcanFixIt/p/7271461.html)

在最后一章内容中，主要介绍以下内容：

* 下划线作为新关键字
* 改进使用try-with-resources块的语法
* 如何在匿名类中使用<>操作符
* 如何在接口中使用私有方法
* 如何在私有方法上使用@SafeVarargs注解
* 如何丢弃子进程的输出
* 如何在Math和StrictMath类中使用新的方法
* 如何使用Optionals流以及Optionals上的新的操作
* 如何使用等待提示（spin-wait hints）
* 对Time API和Matcher和Objects类的增强
* 如何比较数组和数组的一部分
* Javadoc的增强功能以及如何使用其新的搜索功能
* 本地桌面支持JDK 9以及如何使用它们
* 在对象反序列化过程中如何使用全局和局部过滤器
* 如何将数据从输入流传输到输出流以及如何复制和分片缓冲区

Java SE 9有很多小的变化。大的变化包括引入了模块系统，HTTP/2Client API等。 本章涵盖了对Java开发人员重要的所有更改。 每个部分涵盖一个新的主题。 如果兴趣了解特定主题，可以直接跳转到该主题的部分。

示例的源代码在com.jdojo.misc模块中，其声明如下示。

```java
// module-info.java
module com.jdojo.misc {
    requires java.desktop;
    exports com.jdojo.misc;
}
```

该模块读取了java.desktop模块，需要它来实现特定于平台的桌面功能。

## 一. 下划线成为关键字

在JDK 9中，下划线（`_`）是一个关键字，不能将其本身用作单个字符标识符，例如变量名称，方法名称，类型名称等。但是，仍然可以使用下划线用在多个字符的标识符名称中。 考虑下面程序。

```java
// UnderscoreTest.java
package com.jdojo.misc;
public class UnderscoreTest {    
    public static void main(String[] args) {
        // Use an underscore as an identifier. It is a compile-time warning in JDK 8 and a
        // compile-time error in JDK 9.
        int _ = 19;
        System.out.println(_);
        // Use an underscore in multi-character identifiers. They are fine in JDK 8 and JDK 9.
        final int FINGER_COUNT = 20;
        final String _prefix = "Sha";
    }
}
```

在JDK 8中编译UnderscoreTest类会产生两个警告，用于使用下划线作为标识符，一个用于变量声明，一个用于`System.out.println()`方法调用。 每次使用下划线时都会产生警告。 JDK 8生成以下两个警告：

```java
com.jdojo.misc\src\com\jdojo\misc\UnderscoreTest.java:8: warning: '_' used as an identifier
        int _ = 19;
            ^
  (use of '_' as an identifier might not be supported in releases after Java SE 8)
com.jdojo.misc\src\com\jdojo\misc\UnderscoreTest.java:9: warning: '_' used as an identifier
        System.out.println(_);
                           ^
  (use of '_' as an identifier might not be supported in releases after Java SE 8)
2 warnings
Compiling the UnderscoreTest class in JDK 9 generates the following two compile-time errors:
com.jdojo.misc\src\com\jdojo\misc\UnderscoreTest.java:8: error: as of release 9, '_' is a keyword, and may not be used as an identifier
        int _ = 19;
            ^
com.jdojo.misc\src\com\jdojo\misc\UnderscoreTest.java:9: error: as of release 9, '_' is a keyword, and may not be used as an identifier
        System.out.println(_);
                           ^
2 errors
```

JDK 9中的下划线的特殊含义是什么，在哪里使用它？ 在JDK 9中，被限制不将其用作标识符。 JDK设计人员打算在未来的JDK版本中给它一个特殊的含义。 所以，等到JDK 10或11，将它看作具有特殊含义的关键字。

## 二. 改进使用try-with-resources块的语法

JDK 7向`java.lang`包添加了一个AutoCloseable接口：

```java
public interface AutoCloseable {
    void close() throws Exception;
}
```

JDK 7还添加了一个名为try-with-resources的新块，可用于使用以下步骤管理AutoCloseable对象（或资源）：

* 将该资源的引用分配给块开头的新声明的变量。
* 使用块中的资源。
* 当块的主体被退出时，代表资源的变量的close()方法将被自动调用。

这避免了在JDK 7之前使用finally块编写的样板代码。以下代码片段显示了开发人员如何管理可关闭的资源，假设存在实现AutoCloseable接口的Resource类：

```java
/* Prior to JDK 7*/
Resource res = null;
try{
    // Create the resource
    res = new Resource();
    // Work with res here
} finally {
    try {
        if(res != null) {
            res.close();
        }
    } catch(Exception e) {
        e.printStackTrace();
    }
}
```

JDK 7中的try-with-resources块大大改善了这种情况。 在JDK 7中，可以重写以前的代码段，如下所示：

```java
try (Resource res = new Resource()) {
    // Work with res here
}
```

当控制退出try块时，这段代码将在res上调用close()方法。 可以在try块中指定多个资源，每个资源以分号分隔：

```java
try (Resource res1 = new Resource(); Resource res2 = new Resource()) {
     // Work with res1 and res2 here
}
```

当try块退出时，两个资源res1和res2上的close()方法将被自动调用。 资源以相反的顺序关闭。 在这个例子中，将按顺序调用res2.close()和res1.close()。

JDK 7和8要求在try-with-resources块中声明引用资源的变量。 如果在方法中收到资源引用作为参数，那么无法编写如下所示的逻辑：

```
void useIt(Resource res) {
    // A compile-time error in JDK 7 and 8
    try(res) {
        // Work with res here
    }
}
```

为了规避此限制，必须声明另一个新的变量的Resource类型，并用参数值初始化它。 以下代码段显示了这种方法。 它声明一个新的参考变量res1，当try块退出时，将调用close()方法：

```
void useIt(Resource res) {        
    try(Resource res1 = res) {
        // Work with res1 here
    }
}
```

JDK 9删除了该限制，必须使用try-with-resource块为要管理的资源声明新变量。 现在，可以使用try-with-resources块来管理final或有效的final变量来引用资源。 如果使用final关键字显式声明变量，则该变量为final。

```java
// res is explicitly final
final Resource res = new Resource();
```

如果变量在初始化之后从未更改，则该变量实际上是final的。 在下面的代码片段中，尽管res变量未被声明为final，但是res变量是有效的。 它被初始化，从不再次更改。

```java
void doSomething() {
    // res is effectively final
    Resource res = new Resource();
    res.useMe();
}
```

在JDK 9中，可以这样写：

```java
Resource res = new Resource();
try (res) {
    // Work with res here
}
```

如果有多个资源要使用try-with-resources块来管理，可以这样做：

```java
Resource res1 = new Resource();
Resource res2 = new Resource();
try (res1; res2) {
    // Use res1 and res2 here
}
```

也可以将JDK 8和JDK 9方法混合在同一个资源块中。 以下代码片段在try-with-resources块中使用两个预先声明的有效的final变量和一个新声明的变量：

```java
Resource res1 = new Resource();
Resource res2 = new Resource();
try (res1; res2; Resource res3 = new Resource()) {
    // Use res1, res2, and res3 here
}
```

由于在JDK 7中，在资源块中声明的变量是隐含的final的。 以下代码片段明确声明了这样一个final变量：

```
Resource res1 = new Resource();
Resource res2 = new Resource();
// Declare res3 explicitly final
try (res1; res2; final Resource res3 = new Resource()) {
    // Use res1, res2, and res3 here            
}
```

我们来看一个完整的例子。 JDK中有几个类是AutoCloseable，例如java.io包中的InputStream和OutputStream类。 下面包含实现AutoCloseable接口的Resource类的代码。 Resource类的对象可以作为由try-with-resources管理的资源。 id实例变量用于跟踪资源。 构造方法和其他方法在调用时简单地打印消息。

```java
// Resource.java
package com.jdojo.misc;
public class Resource implements AutoCloseable {    
    private final long id;
    public Resource(long id) {        
        this.id = id;                
        System.out.printf("Created resource %d.%n", this.id);
    }
    public void useIt() {    
        System.out.printf("Using resource %d.%n", this.id);        
    }
    @Override
    public void close() {
        System.out.printf("Closing resource %d.%n", this.id);
    }
}
```

下面包含了ResourceTest类的代码，它显示了如何使用JDK 9的新功能，该功能允许使用final或有效的final变量来引用这些资源，并使用try-with-resources块来管理资源。

```java
// ResourceTest.java
package com.jdojo.misc;
public class ResourceTest {
     public static void main(String[] args) {
         Resource r1 = new Resource(1);
         Resource r2 = new Resource(2);
         try(r1; r2) {
             r1.useIt();
             r2.useIt();
             r2.useIt();
         }
         useResource(new Resource(3));
     }
     public static void useResource(Resource res) {
         try(res; Resource res4 = new Resource(4)) {
             res.useIt();
             res4.useIt();
         }
     }
}
```

输出结果为：

```
Created resource 1.
Created resource 2.
Using resource 1.
Using resource 2.
Using resource 2.
Closing resource 2.
Closing resource 1.
Created resource 3.
Created resource 4.
Using resource 3.
Using resource 4.
Closing resource 4.
Closing resource 3.
```

## 三. 如何在匿名类中使用<>操作符

JDK 7引入了一个钻石操作符（`<>`），用于调用泛型类的构造方法，只要编译器可以推断通用类型即可。 以下两个语句是一样的；第二个使用钻石操作符：

```java
// Specify the generic type explicitly
List<String> list1 = new ArrayList<String>();
// The compiler infers ArrayList<> as ArrayList<String>
List<String> list2 = new ArrayList<>();
```

创建匿名类时，JDK 7不允许使用钻石操作符。 以下代码片段使用带有钻石操作符的匿名类来创建Callable<V>接口的实例：

```
// A compile-time error in JDK 7 and 8
Callable<Integer> c = new Callable<>() {
    @Override
    public Integer call() {
        return 100;
    }
};
```

上面语句在JDK 7和8中生成以下错误：

```
error: cannot infer type arguments for Callable<V>
        Callable<Integer> c = new Callable<>() {
                                          ^
  reason: cannot use '<>' with anonymous inner classes
  where V is a type-variable:
    V extends Object declared in interface Callable
1 error
```

可以通过指定通用类型代替钻石运算符来解决此错误：

```
// Works in JDK 7 and 8
Callable<Integer> c = new Callable<Integer>() {
    @Override
    public Integer call() {
        return 100;
    }
};
```

JDK 9就添加了对匿名类中的钻石操作符的支持，只要推断的类型是可表示的。 不能使用具有匿名类的钻石操作符 —— 即使在JDK 9中，如果推断的类型是不可表示的。 Java编译器使用许多不能用Java程序编写的类型。 可以用Java程序编写的类型称为可表示类型。 编译器知道但不能用Java程序编写的类型称为非可表示类型。 例如，String是一个可表示类型，因为可以在程序中使用它来表示类型；然而，Serializable＆CharSequence不是一个可表示类型的，即使它是编译器的有效类型。 它是一种交叉类型，表示实现两个接口Serializable和CharSequence的类型。 通用类型定义允许使用交集类型，但不能使用此交集类型声明变量：

```
// Not allowed in Java code. Cannot declare a variable of an intersection type.
Serializable & CharSequence var;
// Allowed in Java code
class Magic<T extends Serializable & CharSequence> {        
    // More code goes here
}
```

在JDK 9中，以下是允许使用具有匿名类的钻石操作符的代码片段：

```java
// A compile-time error in JDK 7 and 8, but allowed in JDK 9.
Callable<Integer> c = new Callable<>() {
    @Override
    public Integer call() {
        return 100;
    }
};
```

使用Magic类的这个定义，JDK 9允许使用像这样的匿名类：

```java
// Allowed in JDK 9. The <> is inferred as <String>.
Magic<String> m1 = new Magic<>(){
    // More code goes here
};
```

以下使用Magic类不会在JDK 9中进行编译，因为编译器将通用类型推断为不可表示类型的交集类型：

```java
// A compile-time error in JDK 9. The <> is inferred as <Serializable & CharSequence>,
// which is non-denotable
Magic<?> m2 = new Magic<>(){
    // More code goes here
};
```
上面的代码生成以下编译时错误：

```
error: cannot infer type arguments for Magic<>
        Magic<?> m2 = new Magic<>(){
                               ^
  reason: type argument INT#1 inferred for Magic<> is not allowed in this context
    inferred argument is not expressible in the Signature attribute
  where INT#1 is an intersection type:
    INT#1 extends Object,Serializable,CharSequence
1 error
```

## 四. 接口中使用私有方法

JDK 8在接口中引入了静态和默认的方法。 如果必须在这些方法中多次执行相同的逻辑，则只能重复逻辑或将逻辑移动到另一个类来隐藏实现。 考虑名为Alphabet的接口，如下所示。

```java
// Alphabet.java
package com.jdojo.misc;
public interface Alphabet {
    default boolean isAtOddPos(char c) {
        if (!Character.isLetter(c)) {
            throw new RuntimeException("Not a letter: " + c);
        }
        char uc = Character.toUpperCase(c);
        int pos = uc - 64;
        return pos % 2 == 1;
    }
    default boolean isAtEvenPos(char c) {
        if (!Character.isLetter(c)) {
            throw new RuntimeException("Not a letter: " + c);
        }
        char uc = Character.toUpperCase(c);
        int pos = uc - 64;
        return pos % 2 == 0;
    }
}
```

`isAtOddpos()`和`isAtEvenPos()`方法检查指定的字符是否为奇数或偶数字母顺序，假设我们只处理英文字母。逻辑假定A和a位于位置1，B和b位于位置2等。请注意，两种方法中的逻辑仅在返回语句中有所不同。这些方法的整体是相同的，除了最后的语句。你会同意需要重构这个逻辑。将常用逻辑转移到另一种方法，并从两种方法调用新方法将是理想的情况。但是，不希望在JDK 8中执行此操作，因为接口仅支持公共方法。这样做会使第三种方式公开，这将暴露给你不想做的外部世界。

JDK 9允许在接口中声明私有方法。下显示了使用包含两种方法使用的通用逻辑的专用方法的Alphabet接口的重构版本。这一次，命名了接口AlphabetJdk9，以确保可以在源代码中包含这两个版本。现有的两种方法成为一行代码。

```java
// AlphabetJdk9.java
package com.jdojo.misc;
public interface AlphabetJdk9 {
    default boolean isAtOddPos(char c) {
        return getPos(c) % 2 == 1;
    }
    default boolean isAtEvenPos(char c) {
        return getPos(c) % 2 == 0;
    }
    private int getPos(char c) {
        if (!Character.isLetter(c)) {
            throw new RuntimeException("Not a letter: " + c);
        }
        char uc = Character.toUpperCase(c);
        int pos = uc - 64;
        return pos;
    }
}
```

在JDK 9之前，接口中的所有方法都被隐式公开。 记住这些适用于Java中所有程序的简单规则：

* private方法不能被继承，因此不能被重写。
* final方法不能被重写。
* abstract方法是可以继承的，意图是被重写。
* default方法是一个实例方法，并提供默认实现。 这意味着可以被重写。

通过在JDK 9中引入私有方法，需要在接口声明方法时遵循一些规则。 修饰符的所有组合——abstract，public，private，static。 下表列出了在JDK 9中的接口的方法声明中支持和不支持的修饰符的组合。请注意，接口的方法声明中不允许使用fjinal修饰符。 根据这个列表，可以在一个非抽象，非默认的实例方法或一个静态方法的接口中有一个私有方法。

|Modifiers	|Supported?	|Description|
|-----------|-----------|-----------|
|public static	|Yes	|从JDK 8开始支持|
|public abstract	|Yes	|从JDK 1开始支持|
|public default	|Yes	|从JDK 8开始支持|
|private static	|Yes	|从JDK 9开始支持|
|private	|Yes	|从JDK 9开始支持，这是一个非抽象的实例方法|
|private abstract	|No	|这种组合没有意义|
|private default	|No	|这种组合没有意义，私有方法不被继承，因此不能被重写，而如果需要，默认方法的本意是需要重写的。|

## 五. 私有方法上的@SafeVarargs注解

具体化类型表示其信息在运行时完全可用，例如String，Integer，List等。非具体化类型表示其信息已由编译器使用类型擦除（例如List<String>）删除， 编译后成为List。

当使用非具体化类型的可变（var-args）参数时，该参数的类型仅供编译器使用。 编译器将擦除参数化类型，并将其替换为无界类型的实际类型为Object []的数组，其类型为有界类型的上限的特定数组。 编译器不能保证对方法体内的这种非具体化可变参数执行的操作是安全的。 考虑以下方法的定义：

```
<T> void print(T... args) {
    for(T element : args) {
        System.out.println(element);
    }
}
```
编译器将用`print(Object[] args)`替换`print(T… args)`。 该方法的主体对args参数不执行任何不安全的操作。考虑执行以下不安全操作的方法声明：

```
public static void unsafe(List<Long>... rolls) {
    Object[] list = rolls;        
    list[0] = List.of("One", "Two");
    // Unsafe!!! Will throw a ClassCastException at runtime
    Long roll = rolls[0].get(0);
}
```
unsafe()方法将rolls（它是List<String>的数组）分配给一个Object []数组。 它将List<String>存储到Object []的第一个元素中，这也是允许的。 rolls [0]的类型被推断为List <Long>，get(0)方法应该返回一个Long。 但是，运行时会抛出一个ClassCastException，因为rolls[0].get(0)返回的实际类型是String，而不是Long。

当声明使用非具体化的可变参数类型的print()和unsafe()方法时，Java编译器会发出如下所示的未经检查的警告：

```
warning: [unchecked] Possible heap pollution from parameterized vararg type List<Long>
    public static void unsafe(List<Long>... rolls) {
```
                                          ^
编译器会为此类方法声明生成警告，并为每次调用该方法发出警告。 如果unsafe()方法被调用五次，将收到六个警告（一个用于声明，五个调用）。 可以在方法声明和调用站点上使用`@SafeVarargs`注解来抑制这些警告。 通过将此注解添加到方法声明中，确保方法的用户和编译器在方法的主体中，不对非具体化的可变参数类型执行任何不安全的操作。 你的保证是足够好的，编译器不发出警告。 但是，如果你的保证在运行时证明是不真实的，则运行时将抛出适当类型的异常。

在JDK 9之前，可以在以下可执行的（构造函数和方法）上使用`@SafeVarargs`注解：

* 构造方法
* static方法
* final方法

构造方法，static方法和final方法是不可重写的。 允许`@SafeVarargs`注解仅适用于不可重写的可执行的代码的想法，是为了保护开发人员在重写可执行代码上违反注解约束的重写可执行文件上使用此注解。 假设有一个类X，它包含一个方法m1()，它包含一个`@SafeVarargs`。 进一步假设有一个从类X继承的类Y。类Y可以重写继承的方法m1()，并可能有不安全的操作。 这将产生运行时惊喜，因为开发人员可以根据父类X编写代码，并且可能不会期望任何不安全的操作，如其方法m1()所承诺的。

私有方法也是不可重写的，所以JDK 9决定在私有方法上允许`@SafeVarargs`注解。 下面显示了一个使用@SafeVarargs注解的私有方法的类。 在JDK 9中可以具有`@SafeVarargs`注释的可执行列表如下所示：

* 构造方法
* static方法
* final方法
* 私有方法

```java
// SafeVarargsTest.java
package com.jdojo.misc;
public class SafeVarargsTest {
    // Allowed in JDK 9
    @SafeVarargs
    private <T> void print(T... args) {
        for(T element : args) {
            System.out.println(element);
        }
    }
    // More code goes here
}
```

在JDK 8中编译此类会生成以下错误，它指出`@SafeVarargs`不能在非final方法中使用，这是一种私有方法。 需要使用`-Xlint:unchecked`选项编译源代码以查看错误。

```
com\jdojo\misc\SafeVarargsTest.java:6: error: Invalid SafeVarargs annotation. Instance method <T> print(T...) is not final.
    private <T> void print(T... args) {
                     ^
  where T is a type-variable:
    T extends Object declared in method <T>print(T...)
```

## 六. 丢弃子进程的输出

JDK 9向`ProcessBuilder.Redirect`嵌套类添加了一个`DISCARD`新常量。 它的类型是`ProcessBuilder.Redirect`。 当要丢弃输出时，可以将其用作子进程的输出和错误流的目标。 实现通过写入操作系统特定的“空文件（null file）”来丢弃输出。下面包含一个完整的程序，显示如何丢弃子进程的输出。

```java
// DiscardProcessOutput.java
package com.jdojo.misc;
import java.io.IOException;
public class DiscardProcessOutput {
    public static void main(String[] args) {
        System.out.println("Using Redirect.INHERIT:");
        startProcess(ProcessBuilder.Redirect.INHERIT);
        System.out.println("\nUsing Redirect.DISCARD:");
        startProcess(ProcessBuilder.Redirect.DISCARD);
    }
    public static void startProcess(ProcessBuilder.Redirect outputDest) {        
        try {
            ProcessBuilder pb = new ProcessBuilder()
                    .command("java", "-version")                    
                    .redirectOutput(outputDest)
                    .redirectError(outputDest);
            Process process = pb.start();
            process.waitFor();
        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
        }
    }
}
```

输出结果为：

```
Using Redirect.INHERIT:
java version "9-ea"
Java(TM) SE Runtime Environment (build 9-ea+157)
Java HotSpot(TM) 64-Bit Server VM (build 9-ea+157, mixed mode)
Using Redirect.DISCARD:
Listing 20-8.
Discarding a Process’ Outputs
```

`startProcess()`方法通过使用-version参数启动java程序来开始一个进程。 该方法通过输出目的地参数。 第一次，`Redirect.INHERIT`作为输出目的地传递，这允许子进程使用标准输出和标准错误来打印消息。 第二次，`Redirect.DISCARD`作为输出目标传递，没有子进程的输出。

## 七. StrictMath类中的新方法

JDK在java.lang包中包含两个类`Math`和`StrictMath`。 这两个类只包含静态成员，它们包含提供基本数字操作（如平方根，绝对值，符号，三角函数和双曲线函数）的方法。 为什么有两个类来提供类似的操作？ Math类不需要在所有实现中返回相同的结果。 这允许它使用库的本地实现来进行操作，这可能会在不同的平台上返回稍微不同的结果。StrictMath类必须在所有实现中返回相同的结果。 Math类中的许多方法都调用StrictMath类的方法。 JDK 9将以下静态方法添加到Math和StrictMath类中：

```java
long floorDiv(long x, int y)
int floorMod(long x, int y)
double fma(double x, double y, double z)
float fma(float x, float y, float z)
long multiplyExact(long x, int y)
long multiplyFull(int x, int y)
long multiplyHigh(long x, long y)
```

`floorDiv()``方法返回小于或等于将x除以y的代数商的最大长度值。 当两个参数具有相同的符号时，除法结果将向零舍入（截断模式）。 当它们具有不同的符号时，除法结果将朝向负无穷大。 当被除数为Long.MIN_VALUE而除数为-1时，该方法返回Long.MIN_VALUE。 当除数为零时抛出ArithmeticException。

`floorMod()`方法返回最小的模数，等于

```
 x - (floorDiv(x, y) * y)
```

最小模数的符号与除数y相同，在`-abs(y) < r < +abs(y)`范围内。

fma()方法对应于IEEE 754-2008中定义的`fusedMultiplyAdd`操作。 它返回`(a * b + c)`的结果，如同无限范围和精度一样，并舍入一次到最接近的double或float值。 舍入是使用到最近的偶数舍入模式完成的。 请注意，`fma()`方法返回比表达式`(a * b + c)`更准确的结果，因为后者涉及两个舍入误差——一个用于乘法，另一个用于加法，而前者仅涉及一个舍入误差。

`multiplyExact()`方法返回两个参数的乘积，如果结果超过long类型最大能表示的数字，则抛出ArithmeticException异常。

`multiplyFull()`方法返回两个参数的确切乘积。

`multiplyHigh()`方法返回长度是两个64位参数的128位乘积的最高有效64位。 当乘以两个64位长的值时，结果可能是128位值。 因此，该方法返回significant (high)64位。 下面包含一个完整的程序，用于说明在StrictMath类中使用这些新方法。

```java
// StrictMathTest.java
package com.jdojo.misc;
import static java.lang.StrictMath.*;
public class StrictMathTest {
    public static void main(String[] args) {
        System.out.println("Using StrictMath.floorDiv(long, int):");
        System.out.printf("floorDiv(20L, 3) = %d%n", floorDiv(20L, 3));
        System.out.printf("floorDiv(-20L, -3) = %d%n", floorDiv(-20L, -3));
        System.out.printf("floorDiv(-20L, 3) = %d%n", floorDiv(-20L, 3));
        System.out.printf("floorDiv(Long.Min_VALUE, -1) = %d%n", floorDiv(Long.MIN_VALUE, -1));
        System.out.println("\nUsing StrictMath.floorMod(long, int):");
        System.out.printf("floorMod(20L, 3) = %d%n", floorMod(20L, 3));
        System.out.printf("floorMod(-20L, -3) = %d%n", floorMod(-20L, -3));
        System.out.printf("floorMod(-20L, 3) = %d%n", floorMod(-20L, 3));
        System.out.println("\nUsing StrictMath.fma(double, double, double):");
        System.out.printf("fma(3.337, 6.397, 2.789) = %f%n", fma(3.337, 6.397, 2.789));
        System.out.println("\nUsing StrictMath.multiplyExact(long, int):");
        System.out.printf("multiplyExact(29087L, 7897979) = %d%n",
                multiplyExact(29087L, 7897979));
        try {
            System.out.printf("multiplyExact(Long.MAX_VALUE, 5) = %d%n",
                    multiplyExact(Long.MAX_VALUE, 5));
        } catch (ArithmeticException e) {
            System.out.println("multiplyExact(Long.MAX_VALUE, 5) = " + e.getMessage());
        }
        System.out.println("\nUsing StrictMath.multiplyFull(int, int):");
        System.out.printf("multiplyFull(29087, 7897979) = %d%n", multiplyFull(29087, 7897979));
        System.out.println("\nUsing StrictMath.multiplyHigh(long, long):");
        System.out.printf("multiplyHigh(29087L, 7897979L) = %d%n",
                multiplyHigh(29087L, 7897979L));
        System.out.printf("multiplyHigh(Long.MAX_VALUE, 8) = %d%n",
                multiplyHigh(Long.MAX_VALUE, 8));
    }
}
```

输出结果为：

```
Using StrictMath.floorDiv(long, int):
floorDiv(20L, 3) = 6
floorDiv(-20L, -3) = 6
floorDiv(-20L, 3) = -7
floorDiv(Long.Min_VALUE, -1) = -9223372036854775808
Using StrictMath.floorMod(long, int):
floorMod(20L, 3) = 2
floorMod(-20L, -3) = -2
floorMod(-20L, 3) = 1
Using StrictMath.fma(double, double, double):
fma(3.337, 6.397, 2.789) = 24.135789
Using StrictMath.multiplyExact(long, int):
multiplyExact(29087L, 7897979) = 229728515173
multiplyExact(Long.MAX_VALUE, 5) = long overflow
Using StrictMath.multiplyFull(int, int):
multiplyFull(29087, 7897979) = 229728515173
Using StrictMath.multiplyHigh(long, long):
multiplyHigh(29087L, 7897979L) = 0
multiplyHigh(Long.MAX_VALUE, 8) = 3
```

## 八. 对ClassLoader类的更改

JDK 9将以下构造方法和方法添加到`java.lang.ClassLoader`类中：

```java
protected ClassLoader(String name, ClassLoader parent)
public String getName()
protected Class<?> findClass(String moduleName, String name)
protected URL findResource(String moduleName, String name) throws IOException
public Stream<URL> resources(String name)
public final boolean isRegisteredAsParallelCapable()
public final Module getUnnamedModule()
public static ClassLoader getPlatformClassLoader()
public final Package getDefinedPackage(String name)
public final Package[] getDefinedPackages()
```

这些方法具有直观的名称。受保护的构造方法和方法适用于开发人员创建新的类加载器。

一个类加载器可以有一个可选的名称，可以使用`getName()`方法。 当类加载器没有名称时，该方法返回null。 Java运行时将包括堆栈跟踪和异常消息中的类加载程序名称（如果存在）。 这将有助于调试。

`resources()`方法返回使用特定资源名称找到的所有资源的URL流。

每个类加载器都包含一个未命名的模块，该模块包含该类加载器从类路径加载的所有类型。 `getUnnamedModule()`方法返回类加载器的未命名模块的引用。

静态`getPlatformClassLoader()`方法返回平台类加载器的引用。

## 九. Optional<T>类中的新方法

JDK 9中的java.util.Optional<T>类已经添加了三种新方法：

```java
void ifPresentOrElse(Consumer<? super T> action, Runnable emptyAction)
Optional<T> or(Supplier<? extends Optional<? extends T>> supplier)
Stream<T> stream()
```

在描述这些方法并提供一个显示其使用的完整程序之前，请考虑以下Optional<Integer>列表：

```java
List<Optional<Integer>> optionalList = List.of(Optional.of(1),
                                               Optional.empty(),
                                               Optional.of(2),
                                               Optional.empty(),
                                               Optional.of(3));                                               
```java

该列表包含五个元素，其中两个为空的Optional，三个包含值为1，2和3。

`ifPresentOrElse()`方法可以提供两个备选的操作。 如果存在值，则使用该值执行指定的操作。 否则，它执行指定的可选值。 以下代码片段使用流打印列表中的所有元素，如果Optional不为空，则打印其具体的值，为空的话，替换为“Empty”字符串。

```java
optionalList.stream()
            .forEach(p -> p.ifPresentOrElse(System.out::println,
                                            () -> System.out.println("Empty")));
```
打印结果为：

```
1
Empty
2
Empty
3
```

`or()`方法如果Optional有值则返回Optional本身。否则，返回指定supplier的Optional。以下代码从Optional列表中返回一个流，并使用or()方法映射空的Optionals为带有默认值0的Optionals.

```java
optionalList.stream()
            .map(p -> p.or(() -> Optional.of(0)))
            .forEach(System.out::println);
```

```
Optional[1]
Optional[0]
Optional[2]
Optional[0]
Optional[3]
```


`stream()``方法返回包含Optional中存在的值的元素的顺序流。 如果Optional为空，则返回一个空的流。 假设有一个Optional的列表，并且想收集另一个列表中的所有存在的值。 可以在Java 8中如下实现:

```java
// list8 will contain 1, 2, and 3
List<Integer> list8 = optionalList.stream()
                                  .filter(Optional::isPresent)
                                  .map(Optional::get)
                                  .collect(toList());
```

必须使用过滤器过滤掉所有空的Optionals，并将剩余的可选项映射到其值。 使用JDK 9中的新的stream()方法，可以将filter()和map()操作组合成一个flatMap()操作，如下所示：

```java
// list9 contain 1, 2, and 3
List<Integer> list9 = optionalList.stream()
                                  .flatMap(Optional::stream)
                                  .collect(toList());
```

下面包含一个完整的程序来演示使用这些方法。

```java
// OptionalTest.java
package com.jdojo.misc;
import java.util.List;
import java.util.Optional;
import static java.util.stream.Collectors.toList;
public class OptionalTest {
    public static void main(String[] args) {
        // Create a list of Optional<Integer>
        List<Optional<Integer>> optionalList = List.of(
                Optional.of(1),
                Optional.empty(),
                Optional.of(2),
                Optional.empty(),
                Optional.of(3));
        // Print the original list
        System.out.println("Original List: " + optionalList);
        // Using the ifPresentOrElse() method
        optionalList.stream()
                    .forEach(p -> p.ifPresentOrElse(System.out::println,
                                                    () -> System.out.println("Empty")));
        // Using the or() method
        optionalList.stream()
                    .map(p -> p.or(() -> Optional.of(0)))
                    .forEach(System.out::println);
        // In Java 8
        List<Integer> list8 = optionalList.stream()
                                          .filter(Optional::isPresent)
                                          .map(Optional::get)
                                          .collect(toList());
        System.out.println("List in Java 8: " + list8);
        // In Java 9
        List<Integer> list9 = optionalList.stream()
                                          .flatMap(Optional::stream)
                                          .collect(toList());
        System.out.println("List in Java 9: " + list9);
    }
}
```

输出结果为：

```
Original List: [Optional[1], Optional.empty, Optional[2], Optional.empty, Optional[3]]
1
Empty
2
Empty
3
Optional[1]
Optional[0]
Optional[2]
Optional[0]
Optional[3]
List in Java 8: [1, 2, 3]
List in Java 9: [1, 2, 3]
```

## 十. CompletableFuture<T>中的新方法

在JDK 9 中，`java.util.concurrent`包中的`CompletableFuture<T>``类添加了以下新方法：

```java
<U> CompletableFuture<U> newIncompleteFuture()
Executor defaultExecutor()
CompletableFuture<T> copy()
CompletionStage<T> minimalCompletionStage()
CompletableFuture<T> completeAsync(Supplier<? extends T> supplier, Executor executor)
CompletableFuture<T> completeAsync(Supplier<? extends T> supplier)
CompletableFuture<T> orTimeout(long timeout, TimeUnit unit)
CompletableFuture<T> completeOnTimeout(T value, long timeout, TimeUnit unit)
static Executor delayedExecutor(long delay, TimeUnit unit, Executor executor)
static Executor delayedExecutor(long delay, TimeUnit unit)
static <U> CompletionStage<U> completedStage(U value)
static <U> CompletableFuture<U> failedFuture(Throwable ex)
static <U> CompletionStage<U> failedStage(Throwable ex)
```

有关这些方法的更多信息，请查阅类的Javadoc。

## 十一. 旋转等待提示（Spin-Wait Hints）

在多线程程序中，线程通常需要协调。一个线程可能必须等待另一个线程来更新volatile变量。 当volatile变量以某个值更新时，第一个线程可以继续。 如果等待可能更长，建议第一个线程通过睡眠或等待来放弃CPU，并且可以在恢复工作时通知它。 然而，使线程睡眠或等待具有延迟。 为了短时间等待并减少延迟，线程通常通过检查某个条件为真来循环等待。 考虑使用循环等待为dataReady的volatile变量等于true的类中代码：

```java
volatile boolean dataReady;
...
@Override
public void run() {
    // Wait until data is ready
    while (!dataReady) {
        // No code
    }
    processData();
}
private void processData() {
    // Data processing logic goes here
}
```


该代码中的while循环称为`spin-loop`，`busy-spin`，`busy-wait`或`spin-wait`。 while保持循环，直到dataReady变量为true。
由于不必要的资源使用而不耐心等待，因此通常是需要的。 在这个例子中，优点是一旦dataReady变量变为true，线程就会开始处理数据。 然而，牺牲性能和功耗，因为线程正在活跃地循环。

某些处理器可以暗示线程处于旋转等待状态，如果可能，可以优化资源使用。 例如，x86处理器支持一个PAUSE指令来指示一个旋转等待。 该指令延迟下一条指令对线程的执行有限的少量时间，从而提高了资源的使用。

JDK 9向Thread类添加了一个新的静态onSpinWait()方法。 对处理器来说，这是一个纯粹的提示，即调用者线程暂时无法继续，因此可以优化资源使用。 当底层平台不支持这种提示时，此方法的可能实现可能是无效的。

下面包含示例代码。 请注意，程序的语义不会通过使用旋转等待提示来更改。 如果底层硬件支持提示，它可能会更好。

```java
// SpinWaitTest.java
package com.jdojo.misc;
public class SpinWaitTest implements Runnable {
    private volatile boolean dataReady = false;
    @Override
    public void run() {
        // Wait while data is ready
        while (!dataReady) {
            // Hint a spin-wait
            Thread.onSpinWait();
        }
        processData();
    }
    private void processData() {
        // Data processing logic goes here
    }
    public void setDataReady(boolean dataReady) {
        this.dataReady = dataReady;
    }
}
```

## 十二. Time API 增强

Time API已在JDK 9中得到增强，并在多个接口和类中使用了大量新方法。 Time API由`java.time.*`包组成，它们位于`java.base`模块中。

### 1. Clock类

Clock类中已经添加了以下方法：

```
static Clock tickMillis(ZoneId zone)
```

`tickMillis()`方法返回一个时钟，提供了整个毫秒的当前瞬间记录。 时钟使用最好的系统时钟。时钟以高于毫秒的精度截断时间值。 调用此方法等同于以下内容：

```
Clock.tick(Clock.system(zone), Duration.ofMillis(1))
```

### 2. Duration类

可以根据用途将Duration类中的新方法分为三类：

* 将持续时间划分另一个持续时间的方法
* 根据特定时间单位获取持续时间的方法和获取特定部分持续时间（如天，小时，秒等）的方法。
* 将持续时间缩短到特定时间单位的方法

在这里使用持续时间为23天，3小时45分30秒。 以下代码片段将其创建Duration对象，并将其引用保存在compTime的变量中：

```java
// Create a duration of 23 days, 3 hours, 45 minutes, and 30 seconds
Duration compTime = Duration.ofDays(23)
                        .plusHours(3)
                        .plusMinutes(45)
                        .plusSeconds(30);
System.out.println("Duration: " + compTime);
```

输出结果为：

```
Duration: PT555H45M30S
```

通过将这些日期乘以24小时后，输出显示，此持续时间代表555小时，45分钟和30秒。

#### 1. 将持续时间划分另一个持续时间

此类别中只有一种方法：

```
long dividedBy(Duration divisor)
```

`divideBy()`方法可以将持续时间划分另一个持续时间。 它返回特定除数在调用该方法的持续时间内发生的次数。 要知道在这段时间内有多少整周，可以使用七天作为持续时间来调用`divideBy()`方法。 以下代码片段显示了如何计算持续时间内的整天，周和小时数：

```java
long wholeDays = compTime.dividedBy(Duration.ofDays(1));
long wholeWeeks = compTime.dividedBy(Duration.ofDays(7));
long wholeHours = compTime.dividedBy(Duration.ofHours(7));
System.out.println("Number of whole days: " + wholeDays);
System.out.println("Number of whole weeks: " + wholeWeeks);
System.out.println("Number of whole hours: " + wholeHours);
```

输出结果为：

```
Number of whole days: 23
Number of whole weeks: 3
Number of whole hours: 79
```

#### 转换和检索部分持续时间

此类别中的Duration类添加了几种方法：

```java
long toDaysPart()
int toHoursPart()
int toMillisPart()
int toMinutesPart()
int toNanosPart()
long toSeconds()
int toSecondsPart()
```

Duration类包含两组方法。它们被命名为`toXxx()`和`toXxxPart()`，其中Xxx可以是Days，Hours，Minutes，Seconds，Millis和Nanos。在此列表中，可能会注意到包含`toDaysPart()`，但是丢失了`toDays()`。如果看到某些Xxx中缺少一个方法，则表示这些方法已经存在于JDK 8中。例如，从JDK 8开始，`toDays()`方法已经在Duration类中。


名为`toXxx()`的方法将持续时间转换为Xxx时间单位并返回整个部分。名为`toXxxPart()`的方法会以几天为单位，以时间为单位分解持续时间：小时：分钟：秒：毫秒：纳秒，并从中返回Xxx部分。在这个例子中，toDays()将会将持续时间转换为天数并返回整个部分，这是23。`toDaysPart()`会将持续时间分解为23天：3Hours：45Minutes：30Seconds：0Millis：0Nanos，并返回第一部分，这是23。我们将相同的规则应用于toHours()和`toHoursPart()`方法。 toHours()方法会将持续时间转换为小时，并返回整个小时数，这是555。toHoursPart()方法会将持续时间与toDaysPart()方法一样分分解为一部分，并返回小时部分，这是。以下代码片段显示了几个例子：

```java
System.out.println("toDays(): " + compTime.toDays());
System.out.println("toDaysPart(): " + compTime.toDaysPart());
System.out.println("toHours(): " + compTime.toHours());
System.out.println("toHoursPart(): " + compTime.toHoursPart());
System.out.println("toMinutes(): " + compTime.toMinutes());
System.out.println("toMinutesPart(): " + compTime.toMinutesPart());
```

输出结果为：

```
toDays(): 23
toDaysPart(): 23
toHours(): 555
toHoursPart(): 3
toMinutes(): 33345
toMinutesPart(): 45
```

#### 3 截取持续时间

此类别中的Duration类只添加了一种方法：

```
Duration truncatedTo(TemporalUnit unit)
```

`truncatedTo()`方法返回一个持续时间的副本，其概念时间单位小于被截断的指定单位。 指定的时间单位必须为DAYS或更小。 指定大于DAYS（如WEEKS和YEARS）的时间单位会引发运行时异常。

> Tips
>
> JDK 8中的LocalTime和Instant类中已经存在truncatedTo(TemporalUnit unit)方法。

以下代码片段显示了如何使用此方法：

```java
System.out.println("Truncated to DAYS: " + compTime.truncatedTo(ChronoUnit.DAYS));
System.out.println("Truncated to HOURS: " + compTime.truncatedTo(ChronoUnit.HOURS));
System.out.println("Truncated to MINUTES: " + compTime.truncatedTo(ChronoUnit.MINUTES));

```

输出结果为：

```
Truncated to DAYS: PT552H
Truncated to HOURS: PT555H
Truncated to MINUTES: PT555H45M
```

持续时间为`23Days:3Hours:45Minutes:30Seconds:0Millis:0Nanos`。 当将其截断为DAYS时，小于天数的所有部分将被删除，并返回23天，这与输出中显示的552小时相同。 当截断到HOURS时，它会将所有小于小时的部分删除掉，并返回555小时。 将其截断到MINUTES可保留分钟的部分，删除小于分钟的部分。

### 3. ofInstant() 工厂方法

Time API旨在提高开发人员的便利和效率。 有一些经常使用的用例，日期和时间之间的转换强制开发人员使用更多的方法调用而不是必需的。 两个这样的用例是：

* 将java.util.Date转换为LocalDate
* 将Instant转换为LocalDate和LocalTime

JDK 9在LocalDate和LocalTime类中添加了一个静态工厂方法，`ofInstant(Instant instant, ZoneId zone)`，以简化这两种类型的转换。 在ZonedDateTime，OffsetDateTime，LocalDateTime和OffsetTime类中，JDK 8已经有了这种工厂方法。 以下代码片段显示了JDK 8和JDK 9的两种方法——将java.util.Date转换为LocalDate：

```java
// In JDK 8
Date dt = new Date();
LocalDate ld= dt.toInstant()
                 .atZone(ZoneId.systemDefault())
                 .toLocalDate();
System.out.println("Current Local Date: " + ld);

// In JDK 9
LocalDate ld2 = LocalDate.ofInstant(dt.toInstant(), ZoneId.systemDefault());
System.out.println("Current Local Date: " + ld2);
```

输出结果为：

```
Current Local Date: 2017-02-11
Current Local Date: 2017-02-11
```

以下代码片段显示了两种方式，在DK 8和JDK 9，将Instant转换为LocalDate和LocalTime：

```java
// In JDK 8
Instant now = Instant.now();
ZoneId zone = ZoneId.systemDefault();
ZonedDateTime zdt = now.atZone(zone);
LocalDate ld3 = zdt.toLocalDate();
LocalTime lt3 = zdt.toLocalTime();
System.out.println("Local Date: " + ld3 + ", Local Time:" + lt3);
// In JDK 9        
LocalDate ld4 = LocalDate.ofInstant(now, zone);
LocalTime lt4 = LocalTime.ofInstant(now, zone);
System.out.println("Local Date: " + ld4 + ", Local Time:" + lt4);

```

输出结果为：

```
Local Date: 2017-02-11, Local Time:22:13:31.919339400
Local Date: 2017-02-11, Local Time:22:13:31.919339400
```

### 4. 获取纪元秒

有时想从LocalDate，LocalTime和OffsetTime获取自1970-01-01T00：00：00Z的时代以来的秒数。 在JDK 8中，`OffsetDateTime`类包含一个`toEpochSecond()``方法。 如果要从`ZonedDateTime`获取时代以来的秒数，则必须使用它的`toOffsetDateTime()`方法将其转换为`OffsetDateTime`，并使用`OffsetDateTime类的toEpochSecond()`方法。 JDK 8没有包含用于`LocalDate`，`LocalTime`和`OffsetTime`类的`toEpochSecond()`方法。 JDK 9添加了这些方法：

```java
LocalDate.toEpochSecond(LocalTime time, ZoneOffset offset)
LocalTime.toEpochSecond(LocalDate date, ZoneOffset offset)
OffsetTime.toEpochSecond(LocalDate date)
```

为什么这些类的`toEpochSecond()`方法的签名不同？ 要从时代`1970-01-01T00：00：00Z`获得秒数，需要定义另一个Instant。 一个Instant可以用三个部分定义：日期，时间，区域偏移。 LocalDate和LocalTime类只包含一个Instant的三个部分之一。 OffsetTime类包含两个部分，一个时间和一个偏移量。 缺少的部分需要被这些类指定为参数。 因此，这些类包含toEpochSecond()方法，该方法的参数指定了用于定义Instant的缺失部分。 以下代码片段使用相同的Instant从三个类中获取时代的秒数：

```java
LocalDate ld = LocalDate.of(2017, 2, 12);
LocalTime lt = LocalTime.of(9, 15, 45);
ZoneOffset offset = ZoneOffset.ofHours(6);
OffsetTime ot = OffsetTime.of(lt, offset);
long s1 = ld.toEpochSecond(lt, offset);
long s2 = lt.toEpochSecond(ld, offset);
long s3 = ot.toEpochSecond(ld);
System.out.println("LocalDate.toEpochSecond(): " + s1);
System.out.println("LocalTime.toEpochSecond(): " + s2);
System.out.println("OffsetTime.toEpochSecond(): " + s3);
```


```
LocalDate.toEpochSecond(): 1486869345
LocalTime.toEpochSecond(): 1486869345
OffsetTime.toEpochSecond(): 1486869345
```

### 5. LocalDate流

JDK 9可以轻松地跨越两个给定日期之间的所有日期，可以是某时的一天或给定一个区间时段。 以下两种方法已添加到LocalDate类中：

```
Stream<LocalDate> datesUntil(LocalDate endExclusive)
Stream<LocalDate> datesUntil(LocalDate endExclusive, Period step)
```

这些方法产生LocalDates的顺序排序流。 流中的第一个元素是调用该方法的LocalDate。`datesUntil(LocalDate endExclusive)`方法一次一天地增加流中的元素，而`datesUntil(LocalDate endExclusive, Period step)`方法会按照指定的步骤增加它们。 指定的结束日期是排他的。 可以在返回的流上执行几个有用的计算。 以下代码片段计算了2017年的星期数。请注意，代码使用2018年1月1日作为最后一个日期，它是排他的，这将使流返回2017年的所有日期。

```java
long sundaysIn2017 = LocalDate.of(2017, 1, 1)
                              .datesUntil(LocalDate.of(2018, 1, 1))
                              .filter(ld -> ld.getDayOfWeek() == DayOfWeek.SUNDAY)
                              .count();        
System.out.println("Number of Sundays in 2017: " + sundaysIn2017);
```

打印的结果为：

```
Number of Sundays in 2017: 53
```

以下代码片段将于2017年1月1日（含）之间打印至2022年1月1日（不包含），即星期五落在本月十三日的日期：

```java
LocalDate.of(2017, 1, 1)
         .datesUntil(LocalDate.of(2022, 1, 1))
         .filter(ld -> ld.getDayOfMonth() == 13 && ld.getDayOfWeek() == DayOfWeek.FRIDAY)
         .forEach(System.out::println);
```

输出结果为：

```
Fridays that fall on 13th of the month between 2017 - 2021 (inclusive):
2017-01-13
2017-10-13
2018-04-13
2018-07-13
2019-09-13
2019-12-13
2020-03-13
2020-11-13
2021-08-13
```


以下代码片段打印2017年每月的最后一天：

```java
System.out.println("Last Day of months in 2017:");
LocalDate.of(2017, 1, 31)                
         .datesUntil(LocalDate.of(2018, 1, 1), Period.ofMonths(1))
         .map(ld -> ld.format(DateTimeFormatter.ofPattern("EEE MMM dd, yyyy")))
         .forEach(System.out::println);
```

输出结果为：

```
Last Day of months in 2017:
Tue Jan 31, 2017
Tue Feb 28, 2017
Fri Mar 31, 2017
Sun Apr 30, 2017
Wed May 31, 2017
Fri Jun 30, 2017
Mon Jul 31, 2017
Thu Aug 31, 2017
Sat Sep 30, 2017
Tue Oct 31, 2017
Thu Nov 30, 2017
Sun Dec 31, 2017
```

### 6. 新的格式化选项

JDK 9向Time API添加了一些格式化选项。 以下部分将详细介绍这些改动。

#### 1. 修正儒略日格式

可以在日期时间格式化程序模式中使用小写字母g，它将日期部分格式化为修正儒略日作为整数。 可以多次重复多次使用g，例如ggg，如果结果中的位数小于g指定的数目，则会对结果进行零填充。 http://www.unicode.org/reports/tr35/tr35-41/tr35-dates.html#Date_Format_Patterns上的定义了格式化程序中字母g的含义如下：

修正儒略日。 这与以往的修正儒略日不同。 首先，它在当地时区午夜，而不是格林尼治标准时间中午划定天数。 二是本地数字; 也就是说，这取决于当地的时区。 它可以被认为是包含所有日期相关字段的单个数字。

> Tips
>
> 大写字母G被定义为JDK 8中的日期和时间格式化器符号。

以下代码片段显示了如何使用修正儒略日字符g格式化ZonedDateTime：

```java
ZonedDateTime zdt = ZonedDateTime.now();
System.out.println("Current ZonedDateTime: " + zdt);               
System.out.println("Modified Julian Day (g): " +
                zdt.format(DateTimeFormatter.ofPattern("g")));
System.out.println("Modified Julian Day (ggg): " +
                zdt.format(DateTimeFormatter.ofPattern("ggg")));
System.out.println("Modified Julian Day (gggggg): " +
                zdt.format(DateTimeFormatter.ofPattern("gggggg")));
```

输出结果为：

```
Current ZonedDateTime: 2017-02-12T11:49:03.364431100-06:00[America/Chicago]
Modified Julian Day (g): 57796
Modified Julian Day (ggg): 57796
Modified Julian Day (gggggg): 057796
```

#### 2. 通用时区名称

JDK 8有两个字母V和z来格式化日期和时间的时区。 字母V产生区域ID，例如“America / Los_Angeles; Z; -08：30”，字母z产生区域名称，如中央标准时间和CST。

JDK 9将小写字母v添加为格式化符号，生成通用的非定位区域名称，如中央时间或CT。 “非定位”意味着它不会识别与UTC的偏移量。 它指的是墙上的时间——墙壁上的时钟显示的时间。 例如，中央时间上午8时，2017年3月1日将有UTC-06的偏移量，而2017年3月19日的UTC-05偏移量。通用非定位区域名称不指定时区偏移量。 可以使用两种格式-v和vvvv来分别以短格式（例如CT）和长格式（例如中央时间）生成通用非定位区域名称。 以下代码片段显示了由V，Z和V格式化符号产生的格式化结果的差异：

```java
ZonedDateTime zdt = ZonedDateTime.now();
System.out.println("Current ZonedDateTime: " + zdt);               
System.out.println("Using VV: " +
                zdt.format(DateTimeFormatter.ofPattern("MM/dd/yyyy HH:mm VV")));
System.out.println("Using z: " +
                zdt.format(DateTimeFormatter.ofPattern("MM/dd/yyyy HH:mm z")));
System.out.println("Using zzzz: " +
                zdt.format(DateTimeFormatter.ofPattern("MM/dd/yyyy HH:mm zzzz")));
System.out.println("Using v: " +
                zdt.format(DateTimeFormatter.ofPattern("MM/dd/yyyy HH:mm v")));
System.out.println("Using vvvv: " +
                zdt.format(DateTimeFormatter.ofPattern("MM/dd/yyyy HH:mm vvvv")));
```

输出结果为：

```java
Current ZonedDateTime: 2017-02-12T12:30:08.975373900-06:00[America/Chicago]
Using VV: 02/12/2017 12:30 America/Chicago
Using z: 02/12/2017 12:30 CST
Using zzzz: 02/12/2017 12:30 Central Standard Time
Using v: 02/12/2017 12:30 CT
Using vvvv: 02/12/2017 12:30 Central Time
```

## 十三. 使用Scanner进行流操作

JDK 9将以下三个方法添加到java.util.Scanner中。 每个方法返回一个Stream：

```java
Stream<MatchResult> findAll(String patternString)
Stream<MatchResult> findAll(Pattern pattern)
Stream<String> tokens()
```

`findAll()`方法返回具有所有匹配结果的流。 调用`findAll(patternString)`相当于调用`findAll(Pattern.compile(patternString))`。`tokens()`方法使用当前的分隔符从scanner返回令牌流。下面包含一个程序，显示如何仅使用`findAll()`方法从字符串中收集单词。

```java
// ScannerTest.java
package com.jdojo.misc;
import java.util.List;
import java.util.Scanner;
import java.util.regex.MatchResult;
import static java.util.stream.Collectors.toList;
public class ScannerTest {
    public static void main(String[] args) {
        String patternString = "\\b\\w+\\b";
        String input = "A test string,\n which contains a new line.";
        List<String> words = new Scanner(input)
                .findAll(patternString)
                .map(MatchResult::group)
                .collect(toList());
        System.out.println("Input: " + input);
        System.out.println("Words: " + words);
    }
}
```

输出结果为：

```
Input: A test string,
 which contains a new line.
Words: [A, test, string, which, contains, a, new, line]
```

## 十四. Matcher类的增强

`java.util.regex.Matcher`类在JDK 9中添加了一些新的方法：

```java
Matcher appendReplacement(StringBuilder sb,  String replacement)
StringBuilder appendTail(StringBuilder sb)
String replaceAll(Function<MatchResult,String> replacer)
String replaceFirst(Function<MatchResult,String> replacer)
Stream<MatchResult> results()
```

JDK 8中的Matcher类在此列表中已经有前四个方法。 在JDK 9中，它们已经重载了。 `appendReplacement()`和`appendTail()`方法用于使用StringBuffer。 现在他们也可以使用StringBuilder。 `replaceAll()`和`replaceFirst()`方法将String作为参数。 在JDK 9中，它们已经被重载，以Function<T,R>作为参数。

`results()`方法返回其元素为MatchResult类型的流中的匹配结果。 可以查询MatchResult获取结果作为字符串。 可以将Matcher的结果作为JDK 8中的流进行处理。但是逻辑并不简单。 results()方法不会重置matcher。 如果要重置matcher，不要忘记调用其reset()方法将其重置为所需的位置。下面显示了这种方法的一些有趣的用法。

```java
// MatcherTest.java
package com.jdojo.misc;
import java.util.List;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import static java.util.stream.Collectors.toList;
import static java.util.stream.Collectors.toSet;
public class MatcherTest {
    public static void main(String[] args) {
        // A regex to match 7-digit or 10-digit phone numbers
        String regex = "\\b(\\d{3})?(\\d{3})(\\d{4})\\b";
        // An input string
        String input = "1, 3342229999, 2330001, 6159996666, 123, 3340909090";
        // Create a matcher
        Matcher matcher = Pattern.compile(regex)
                                  .matcher(input);
        // Collect formatted phone numbers into a list
        List<String> phones = matcher.results()
                          .map(mr -> (mr.group(1) == null ? "" : "(" + mr.group(1) + ") ")
                                      + mr.group(2) + "-" + mr.group(3))
                          .collect(toList());
        System.out.println("Phones: " + phones);
        // Reset the matcher, so we can reuse it from start
        matcher.reset();
        // Get distinct area codes
        Set<String> areaCodes = matcher.results()
                                       .filter(mr -> mr.group(1) != null)
                                       .map(mr -> mr.group(1))
                                       .collect(toSet());
        System.out.println("Distinct Area Codes:: " + areaCodes);                
    }
}
```

输出的结果为：

```
Phones: [(334) 222-9999, 233-0001, (615) 999-6666, (334) 090-9090] Distinct Area Codes:: [334, 615]
```

main()方法声明两个名regex和input的局部变量。 正则表达式变量包含一个正则表达式，以匹配7位数或10位数字。 将使用它在输入字符串中查找电话号码。 input变量保存有嵌入电话号码的文本。

```java
// A regex to match 7-digit or 10-digit phone numbers
String regex = "\\b(\\d{3})?(\\d{3})(\\d{4})\\b";
// An input string
String input = "1, 3342229999, 2330001, 6159996666, 123, 3340909090";
```

接下来，将正则表达式编译为Pattern对象并获取matcher：

```java
// Create a matcher
Matcher matcher = Pattern.compile(regex)
                         .matcher(input);
```

要将10位电话号码格式化为（nnn）nnn-nnnn和7位数电话号码为nnn-nnnn的格式。 最后，要将所有格式化的电话号码收集到List<String>中。 以下语句执行：

```java
 // Collect formatted phone numbers into a list
 List<String> phones = matcher.results()
                              .map(mr -> (mr.group(1) == null ? "" : "(" + mr.group(1) + ") ")
                                      + mr.group(2) + "-" + mr.group(3))
                              .collect(toList());
```

请注意使用接收`MatchResult的map()`方法，并将格式化的电话号码返回为String。当一个匹配是一个7位数的电话号码时，组1将为空现在，要重新使用matcher， 以10位数的电话号码查找不同的区号。必须重置matcher，所以下一个匹配从输入字符串的开始处开始：

```java
// Reset the matcher, so we can reuse it from start
matcher.reset();
```

`MatchResult`中的第一个组包含区号。 需要滤除7位数的电话号码，并在Set <String>中收集组1的值，以获得一组不同的区号。 以下语句是这样做的：

```java
// Get distinct area codes
Set<String> areaCodes = matcher.results()
                               .filter(mr -> mr.group(1) != null)
                               .map(mr -> mr.group(1))
                               .collect(toSet());
```

## 十五. Object类的增强

`java.util.Objects`类包含对对象进行操作的静态实用方法。 通常，它们用于验证方法的参数，例如，检查方法的参数是否为空。 JDK 9将以下静态方法添加到此类中：

```java
<T> T requireNonNullElse(T obj, T defaultObj)
<T> T requireNonNullElseGet(T obj, Supplier<? extends T> supplier)
int checkFromIndexSize(int fromIndex, int size, int length)
int checkFromToIndex(int fromIndex, int toIndex, int length)
int checkIndex(int index, int length)
```

JDK 8已经有了三个`requireNonNull()``重载方法。 该方法用于检查值为非空值。 如果值为null，则会抛出NullPointerException。 JDK 9添加了这个方法的两个版本。

如果obj为非空，则`requireNonNullElse(T obj, T defaultObj)``方法返回obj。 如果obj为空，并且defaultObj为非空，则返回defaultObj。 如果obj和defaultObj都为空，则会抛出NullPointerException异常。

`requireNonNullElseGet(T obj, Supplier<? extends T> supplier)`方法的工作方式与`requireNonNullElse(T obj, T defaultObj)`方法相同，前者使用Supplier获取默认值。 如果非空，它返回obj。 如果Supplier非空，并返回非空值，则返回从Supplier返回的值。 否则，抛出NullPointerException异常。

`checkXxx()`的方法意在用于检查索引或子范围是否在某一范围内。当使用数组和集合时，它们很有用，需要处理索引和子范围。如果索引或子范围超出范围，这些方法将抛出IndexOutOfBoundsException。

`checkFromIndexSize(int fromIndex，int size，int length)`方法检查指定的子范围，从inIndex（包括）到fromIndex + size（不包括）是否在范围内，范围是从0（含）到length。如果任何参数为负整数或子范围超出范围，则抛出IndexOutOfBoundsException。如果子范围在范围内，则返回fromIndex。假设有一个接受索引和大小的方法，并从数组或列表返回一个子范围。可以使用此方法来检查所请求的子范围是否在数组或列表的范围内。

`checkFromToIndex(int fromIndex, int toIndex, int length)`方法检查指定的子范围，从inIndex（包括）到toIndex（不包含）是否在范围内，范围为为0（含）到length（不包含）。如果任何参数是负整数或子范围超出范围，则抛出IndexOutOfBoundsException。如果子范围在范围内，则返回fromIndex。在使用数组和List时用于子范围检查是非常有用的。

`checkIndex(int index, int length)`方法检查指定的索引是否在范围内，为0（含）到length（不包含）。如果任何参数为负整数或索引超出范围，则抛出IndexOutOfBoundsException。如果index在范围内，则返回索引。当方法接收到索引并返回数组中的值或该索引的List时，它很有用。

## 十六. 数组比较

`java.util.Arrays`类由静态实用方法组成，可用于对数组执行各种操作，例如排序，比较，转换为流等。在JDK 9中，此类已经获得了几种方法，可以比较数组和切片（slices）。 新方法分为三类：

* 比较两个数组或它们的切片是否相等性
* 按字典顺序比较两个数组
* 查找两个数组中的第一个不匹配的索引

添加到此类的方法列表是很大的。 每个类别中的方法对于所有原始类型和对象数组都是重载的。 有关完整列表，请参阅Arrays类的API文档。

`equals()`方法可以比较两个数组的相等性。 如果数组或部分数组中的元素数量相同，并且数组或部分数组中所有对应的元素对相等，则两个数组被认为是相等的。 以下是int的两个版本的`equals()`方法：

```java
boolean equals(int[] a, int[] b)
boolean equals(int[] a, int aFromIndex, int aToIndex, int[] b, int bFromIndex, int bToIndex)
```


第一个版本允许比较两个数组之间的相等性，并且存在于JDK 9之前。第二个版本允许将两个数组的部分进行比较，以便在JDK 9中添加相等。fromIndex（包含）和toIndex（不包含）参数决定要比较的两个数组的范围。 如果两个数组相等，则该方法返回true，否则返回false。 如果两个数组都为空，则认为两个数组相等。

JDK 9添加了几个`compare()`和`compareUnsigned()`的方法。 这两种方法都按字典顺序比较数组或部分数组中的元素。

compareUnsigned()方法将整数值视为无符号。 空数组的字符拼写小于非空数组。 两个空数组相等。 以下是对于int的compare()方法的两个版本：

```java
int compare(int[] a, int[] b)
int compare(int[] a, int aFromIndex, int aToIndex, int[] b, int bFromIndex, int bToIndex)
```


如果第一个和第二个数组相等并且包含相同的元素，`compare()`方法返回0; 如果第一个数组在字典上小于第二个数组，则返回小于0的值; 并且如果第一个数组在字典上大于第二个数组则返回大于0的值。


`mismatch()`方法比较两个数组或数组的一部分。 以下是int的两个版本的`mismatch()`方法：

```java
int mismatch(int[] a, int[] b)
int mismatch (int[] a, int aFromIndex, int aToIndex, int[] b, int bFromIndex, int bToIndex)
```

`mismatch()`方法返回第一个不匹配的索引。 如果没有不匹配，则返回-1。 如果任一数组为空，则抛出NullPointerException。 下包含一个比较两个数组及其部分数组的完整程序。 该程序使用两个int数组。


```java
// ArrayComparision.java
package com.jdojo.misc;
import java.util.Arrays;
public class ArrayComparison {
    public static void main(String[] args) {
        int[] a1 = {1, 2, 3, 4, 5};
        int[] a2 = {1, 2, 7, 4, 5};
        int[] a3 = {1, 2, 3, 4, 5};
        // Print original arrays
        System.out.println("Three arrays:");
        System.out.println("a1: " + Arrays.toString(a1));
        System.out.println("a2: " + Arrays.toString(a2));
        System.out.println("a3: " + Arrays.toString(a3));
        // Compare arrays for equality
        System.out.println("\nComparing arrays using equals() method:");
        System.out.println("Arrays.equals(a1, a2): " + Arrays.equals(a1, a2));
        System.out.println("Arrays.equals(a1, a3): " + Arrays.equals(a1, a3));
        System.out.println("Arrays.equals(a1, 0, 2, a2, 0, 2): " +
                           Arrays.equals(a1, 0, 2, a2, 0, 2));
        // Compare arrays lexicographically
        System.out.println("\nComparing arrays using compare() method:");
        System.out.println("Arrays.compare(a1, a2): " + Arrays.compare(a1, a2));
        System.out.println("Arrays.compare(a2, a1): " + Arrays.compare(a2, a1));
        System.out.println("Arrays.compare(a1, a3): " + Arrays.compare(a1, a3));
        System.out.println("Arrays.compare(a1, 0, 2, a2, 0, 2): " +
                           Arrays.compare(a1, 0, 2, a2, 0, 2));
        // Find the mismatched index in arrays
        System.out.println("\nFinding mismatch using the mismatch() method:");                
        System.out.println("Arrays.mismatch(a1, a2): " + Arrays.mismatch(a1, a2));
        System.out.println("Arrays.mismatch(a1, a3): " + Arrays.mismatch(a1, a3));
        System.out.println("Arrays.mismatch(a1, 0, 5, a2, 0, 1): " +
                            Arrays.mismatch(a1, 0, 5, a2, 0, 1));
    }
}
```

输出结果为：

```
a1: [1, 2, 3, 4, 5]
a2: [1, 2, 7, 4, 5]
a3: [1, 2, 3, 4, 5]
Comparing arrays using equals() method:
Arrays.equals(a1, a2): false
Arrays.equals(a1, a3): true
Arrays.equals(a1, 0, 2, a2, 0, 2): true
Comparing arrays using compare() method:
Arrays.compare(a1, a2): -1
Arrays.compare(a2, a1): 1
Arrays.compare(a1, a3): 0
Arrays.compare(a1, 0, 2, a2, 0, 2): 0
Finding mismatch using the mismatch() method:
Arrays.mismatch(a1, a2): 2
Arrays.mismatch(a1, a3): -1
Arrays.mismatch(a1, 0, 5, a2, 0, 1): 1
```

## 十七. Applet API已经废弃

Java applets需要Java浏览器插件才能正常工作。 许多浏览器供应商已经删除了对Java浏览器插件的支持，或者将在不久的将来删除它。 如果浏览器不支持Java插件，则不能使用applet，因此没有理由使用Applet API。 JDK 9弃用了Applet API。 但是，它将不会在JDK 10中被删除。如果计划在将来的版本中被删除，开发人员将提前发布一个通知。 以下类和接口已被弃用：

```java
java.applet.AppletStub
java.applet.Applet
java.applet.AudioClip
java.applet.AppletContext
javax.swing.JApplet
```

在JDK 9中，所有AWT和Swing相关类都打包在java.desktop模块中。 这些不推荐的类和接口也在同一个模块中。

appletviewer工具随其JDK在bin目录中提供，用于测试applet。 该工具也在JDK 9中不推荐使用。在JDK 9中运行该工具会打印一个弃用警告。

## 十八. Javadoc增强

TODO

## 十九. 本地桌面功能

TODO

## 二十. 对象反序列化过滤器

Java可以对对象进行序列化和反序列化。 为了解决反序列化带来的安全风险，JDK 9引入了可以用来验证反序列化对象的对象输入过滤器的概念，如果不通过测试，则可以停止反序列化过程。 对象输入过滤器是添加到JDK 9的新接口java.io.ObjectInputFilter的实例。过滤器可以基于以下一个或多个条件：

* 数组的长度反序列化
* 嵌套对象的深度反序列化
* 对象引用数反序列化
* 对象的类被反序列化
* 从输入流消耗的字节数

ObjectInputFilter接口只包含一个方法：

```java
ObjectInputFilter.Status checkInput(ObjectInputFilter.FilterInfo filterInfo)
```

可以指定要用于反序列化所有对象的全局过滤器。 可以通过为对象输入流设置本地过滤器来重写每个ObjectInputStream上的全局过滤器。 可以没有全局过滤器，并为每个对象输入流指定本地过滤器。 有几种方法来创建和指定过滤器。 本节首先介绍添加到JDK 9中的类和接口，需要使用这些类和接口来处理过滤器：

* ObjectInputFilter
* ObjectInputFilter.Config
* ObjectInputFilter.FilterInfo
* ObjectInputFilter.Status

ObjectInputFilter接口的实例表示过滤器。 可以通过在类中实现此接口来创建过滤器。 或者，可以使用`ObjectInputFilter.Config`类的`createFilter(String pattern)`方法从字符串获取其实例。

`ObjectInputFilter.Config`是一个嵌套的静态实用类，用于两个目的：

* 获取并设置全局过滤器
* 从指定字符串的模式中创建过滤器

`ObjectInputFilter.Config`类包含以下三种静态方法：

```java
ObjectInputFilter createFilter(String pattern)
ObjectInputFilter getSerialFilter()
void setSerialFilter(ObjectInputFilter filter)
```

`createFilter()`方法接受一个描述过滤器的模式，并返回`ObjectInputFilter`接口的实例。 以下代码片段创建一个过滤器，指定反序列化数组的长度不应超过4：

```java
String pattern = "maxarray=4";
ObjectInputFilter filter = ObjectInputFilter.Config.createFilter(pattern);
```

可以在一个过滤器中指定多个模式。 它们用分号（;）分隔。 以下代码片段从两种模式创建一个过滤器。 如果遇到长度大于4的数组或串行化对象的大小大于1024字节，则过滤器将拒绝对象反序列化。

```
String pattern = "maxarray=4;maxbytes=1024";
ObjectInputFilter filter = ObjectInputFilter.Config.createFilter(pattern);
```

指定过滤器模式有几个规则。 如果喜欢在Java代码中编写过滤器逻辑，可以通过创建实现`ObjectInputFilter`接口的类并将其写入其`checkInput()`方法来实现。 如果要从字符串中的模式创建过滤器，请遵循以下规则：
有五个过滤条件，其中四个是限制。 它们是`maxarray`，`maxdepth`，`maxrefs`和`maxbytes`。 可以使用name = value来设置它们，其中name是这些关键字，value是限制。 如果模式包含等号（=），则模式必须使用这四个关键字作为名称。 第五个过滤条件用于指定类名形式的模式：

```
<module-name>/<fully-qualified-class-name>
```

* 如果一个类是未命名的模块，则该模式将与类名匹配。 如果对象是一个数组，则数组的组件类型的类名用于匹配模式，而不是数组本身的类名。 以下是匹配类名称的模式的所有规则：
* 如果类名与模式匹配，则允许对象反序列化。
* 以“！” 模式开头的字符被视为逻辑NOT。
* 如果模式包含斜杠（/），斜杠之前的部分是模块名称。 如果模块名称与类的模块名称相匹配，则斜线后面的部分将被用作匹配类名称的模式。 如果模式中没有斜线，则在匹配模式时不考虑类的模块名称。
* 以“.**”结尾的模式匹配包中的任何类和所有子软件包。
* 以“.*”结尾的模式匹配包中的任何类。
* 以“*”结尾的模式匹配任何具有模式作为前缀的类。
* 如果模式等于类名称，则它匹配。
* 另外，模式不匹配，对象被拒绝。
* 如果将com.jdojo.**设置为过滤器模式，它允许com.jdojo包中的所有类及其子包都被反序列化，并将拒绝所有其他类的反序列化对象。 如果将“com.jdojo.**”设置为过滤器模式，它将拒绝com.jdojo包中的所有类及其子包以进行反序列化，并允许反序列化所有其他类的对象。

`getSerialFilter()`和`setSerialFilter()`方法用于获取和设置全局过滤器。 可以使用以下三种方式之一设置全局过滤器：

通过设置名为`jdk.serialFilter`的系统属性，该属性的值是以分号分隔的一系列过滤器模式。
通过在java.security文件中设置一个存储在`JAVA_HOME\conf\security`目录中的`jdk.serialFilter`属性。 如果正在使用JDK运行程序，请将JAVA_HOME作为JDK_HOME读取。 否则，将其读为JRE_HOME。
通过调用`ObjectInputFilter.Config`类的`setSerialFilter()`静态方法。
以下命令在运行类时将jdk.series属性设置为命令行选项。 不要担心这个命令的其他细节。

```
C:\Java9Revealed>java -Djdk.serialFilter=maxarray=100;maxdepth=3;com.jdojo.** --module-path com.jdojo.misc\build\classes --module com.jdojo.misc/com.jdojo.misc.ObjectFilterTest
```
下面显示了`JAVA_HOME\conf\security\java.security`配置文件的部分内容。 该文件包含更多的条目。 只显示一个设置过滤器的条目，这与设置jdk.serialFilter系统属性具有相同的效果，如上一个命令所示。

```
maxarray=100;maxdepth=3;com.jdojo.**
```

> Tips
>
> 如果在系统属性和配置文件中设置过滤器，则优先使用系统属性中的值。

当运行具有全局过滤器的java命令时，会注意到stderr上的消息类似于此处显示的消息：

```
Feb 17, 2017 9:23:45 AM java.io.ObjectInputFilter$Config lambda$static$0
INFO: Creating serialization filter from maxarray=20;maxdepth=3;!com.jdojo.**
```

这些消息使用java.io.serialization的Logger作为平台消息记录java.base模块。 如果指定了平台Logger，这些消息将被记录到Logger中。 其中一条消息在系统属性或配置文件中打印全局过滤器集。

还可以使用ObjectInputFilter.Config类的静态setSerialFilter()方法在代码中设置全局过滤器：

```java
// Create a filter
String pattern = "maxarray=100;maxdepth=3;com.jdojo.**";
ObjectInputFilter globalFilter = ObjectInputFilter.Config.createFilter(pattern);
// Set a global filter
ObjectInputFilter.Config.setSerialFilter(globalFilter);
```

> Tips
>
> 只能设置一次全局过滤器。 例如，如果使用jdk.serialFilter系统属性设置过滤器，则在代码中调用`Config.setSerialFiter()`将抛出IllegalStateException。 当使用`Config.setSerialFiter()`方法设置全局过滤器时，必须设置非空值过滤器。 存在这些规则，以确保在代码中无法覆盖使用系统属性或配置文件的全局过滤器集。

可以使用`ObjectInputFilter.Config`类的静态`getSerialFilter()`方法获取全局过滤器，而不考虑过滤器的设置方式。 如果没有全局过滤器，则此方法返回null。

ObjectInputFilter.FilterInfo是一个嵌套的静态接口，其实例包装了反序列化的当前上下文。`ObjectInputFilter.FilterInfo`的实例被创建并传递给过滤器的checkInput()方法。 不必在程序中实现此接口并创建其实例。 该接口包含以下方法，将在自定义过滤器的`checkInput()`方法中使用以读取当前反序列化上下文：

```java
Class<?> serialClass()
long arrayLength()
long depth();
long references();
long streamBytes();
```

`serialClass()`方法返回反序列化对象的类。对于数组，它返回数组的类，而不是数组的组件类型的类。在反序列化期间未创建新对象时，此方法返回null。

`arrayLength()`方法返回反序列化数组的长度。它被反序列化的对象不是数组，它返回-1。

`depth()`方法返回被反序列化的对象的嵌套深度。它从1开始，对于每个嵌套级别递增1，当嵌套对象返回时，递减1。

`references()`方法返回反序列化的对象引用的当前数量。

`streamBytes()`方法返回从对象输入流消耗的当前字节数。

对象可能根据指定的过滤条件会通过，也可能会失败。根据测试结果，应该返回ObjectInputFilter.Status枚举的以下常量。通常，在自定义过滤器类的`checkInput()`方法中使用这些常量作为返回值。

* ALLOWED
* REJECTED
* UNDECIDED

这些常量表示反序列化允许，拒绝和未定。 通常，返回UNDECIDED表示一些其他过滤器将决定当前对象的反序列化是否继续。 如果正在创建一个过滤器以将类列入黑名单，则可以返回REJECTED以获取黑名单类别的匹配项，而对其他类别则为UNDECIDED。

下面包含一个基于数组长度进行过滤的简单过滤器。

```java
// ArrayLengthObjectFilter.java
package com.jdojo.misc;
import java.io.ObjectInputFilter;
public class ArrayLengthObjectFilter implements ObjectInputFilter {
    private long maxLenth = -1;
    public ArrayLengthObjectFilter(int maxLength) {
        this.maxLenth = maxLength;
    }
    @Override
    public Status checkInput(FilterInfo info) {
        long arrayLength = info.arrayLength();
        if (arrayLength >= 0 && arrayLength > this.maxLenth) {
            return Status.REJECTED;
        }
        return Status.ALLOWED;
    }
}
```

以下代码片段通过将数组的最大长度指定为3来使用自定义过滤器。如果对象输入流包含长度大于3的数组，则反序列化将失败，并显示java.io.InvalidClassException。 代码不显示异常处理逻辑。

```
ArrayLengthObjectFilter filter = new ArrayLengthObjectFilter(3);
File inputFile = ...
ObjectInputStream in =  new ObjectInputStream(new FileInputStream(inputFile))) {            
in.setObjectInputFilter(filter);
Object obj = in.readObject();
```

下面包含一个Item类的代码。为保持代码简洁，省略了getter和setter方法。 使用它的对象来演示反序列化过滤器。

```java
// Item.java
package com.jdojo.misc;
import java.io.Serializable;
import java.util.Arrays;
public class Item implements Serializable {
    private int id;    
    private String name;
    private int[] points;
    public Item(int id, String name, int[] points) {
        this.id = id;
        this.name = name;
        this.points = points;
    }
    /* Add getters and setters here */
    @Override
    public String toString() {
        return "[id=" + id + ", name=" + name + ", points=" + Arrays.toString(points) + "]";
    }
}
```

下面包含ObjectFilterTest类的代码，用于演示在对象反序列化过程中使用过滤器。 代码中有详细的说明。

```java
// ObjectFilterTest.java
package com.jdojo.misc;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.ObjectInputFilter;
import java.io.ObjectInputFilter.Config;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
public class ObjectFilterTest {
    public static void main(String[] args)  {         
        // Relative path of the output/input file
        File file = new File("serialized", "item.ser");
        // Make sure directories exist
        ensureParentDirExists(file);
        // Create an Item used in serialization and deserialization
        Item item = new Item(100, "Pen", new int[]{1,2,3,4});
        // Serialize the item
        serialize(file, item);
        // Print the global filter
        ObjectInputFilter globalFilter = Config.getSerialFilter();
        System.out.println("Global filter: " + globalFilter);
        // Deserialize the item
        Item item2 = deserialize(file);
        System.out.println("Deserialized using global filter: " + item2);
        // Use a filter to reject array size > 2
        String maxArrayFilterPattern = "maxarray=2";
        ObjectInputFilter maxArrayFilter = Config.createFilter(maxArrayFilterPattern);         
        Item item3 = deserialize(file, maxArrayFilter);
        System.out.println("Deserialized with a maxarray=2 filter: " + item3);
        // Create a custom filter
        ArrayLengthObjectFilter customFilter = new ArrayLengthObjectFilter(5);                
        Item item4 = deserialize(file, customFilter);
        System.out.println("Deserialized with a custom filter (maxarray=5): " + item4);
    }
    private static void serialize(File file, Item item) {        
        try (ObjectOutputStream out =  new ObjectOutputStream(new FileOutputStream(file))) {            
            out.writeObject(item);
            System.out.println("Serialized Item: " + item);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
    private static Item deserialize(File file) {
        try (ObjectInputStream in =  new ObjectInputStream(new FileInputStream(file))) {                        
            Item item = (Item)in.readObject();
            return item;
        } catch (Exception e) {
            System.out.println("Could not deserialize item. Error: " + e.getMessage());
        }
        return null;
    }
    private static Item deserialize(File file, ObjectInputFilter filter) {
        try (ObjectInputStream in =  new ObjectInputStream(new FileInputStream(file))) {            
            // Set the object input filter passed in
            in.setObjectInputFilter(filter);
            Item item = (Item)in.readObject();
            return item;
        } catch (Exception e) {
            System.out.println("Could not deserialize item. Error: " + e.getMessage());            
        }
        return null;
    }
    private static void ensureParentDirExists(File file) {
        File parent = file.getParentFile();
        if(!parent.exists()) {
            parent.mkdirs();
        }
        System.out.println("Input/output file is " + file.getAbsolutePath());
    }
}
```

ObjectFilterTest使用不同的过滤器序列化Item类，随后使用相同Item类多个反序列化。`ensureParentDirExists()`方法接受一个文件，并确保其父目录存在，如果需要创建它。 该目录还打印序列化文件的路径。

`serialize()`方法将指定的Item对象序列化为指定的文件。 这个方法从`main()`方法调用一次序列化一个Item对象。

`deserialize()`方法是重载的。 `deserialize(File file)`版本使用全局过滤器（如果有的话）反序列化保存在指定文件中的Item对象。 `deserialize(File file, ObjectInputFilter filter)`版本使用指定的过滤器反序列化保存在指定文件中的Item对象。 注意在此方法中使用`in.setObjectInputFilter(filter)`方法调用。 它为ObjectInputStream设置指定的过滤器。 此过滤器将覆盖全局过滤器（如果有）。

`main()`方法打印全局过滤器，创建一个Item对象并对其进行序列化，创建多个本地过滤器，并使用不同的过滤器对同一个Item对象进行反序列化。 以下命令运行ObjectFilterTest类而不使用全局过滤器。 可能得到不同的输出。

```
C:\Java9Revealed>java --module-path com.jdojo.misc\build\classes
--module com.jdojo.misc/com.jdojo.misc.ObjectFilterTest
```

输出结果为：

```
Input/output file is C:\Java9Revealed\serialized\item.ser
Serialized Item: [id=100, name=Pen, points=[1, 2, 3, 4]]
Global filter: null
Deserialized using global filter: [id=100, name=Pen, points=[1, 2, 3, 4]]
Could not deserialize item. Error: filter status: REJECTED
Deserialized with a maxarray=2 filter: null
Deserialized with a custom filter (maxarray=2): [id=100, name=Pen, points=[1, 2, 3, 4]]
```

以下命令使用全局过滤器maxarray = 1运行ObjectFilterTest类，这将防止具有多个元素的数组被反序列化。 全局过滤器是使用jdk.serialFilter系统属性设置的。 因为正在使用全局过滤器，JDK类将在stderr上记录消息。

```
C:\Java9Revealed>java -Djdk.serialFilter=maxarray=1
--module-path com.jdojo.misc\build\classes
--module com.jdojo.misc/com.jdojo.misc.ObjectFilterTest
```

输出结果为：

```
Input/output file is C:\Java9Revealed\serialized\item.ser
Serialized Item: [id=100, name=Pen, points=[1, 2, 3, 4]]
Feb 17, 2017 1:09:57 PM java.io.ObjectInputFilter$Config lambda$static$0
INFO: Creating serialization filter from maxarray=1
Global filter: maxarray=1
Could not deserialize item. Error: filter status: REJECTED
Deserialized using global filter: null
Could not deserialize item. Error: filter status: REJECTED
Deserialized with a maxarray=2 filter: null
Deserialized with a custom filter (maxarray=5): [id=100, name=Pen, points=[1, 2, 3, 4]]
```

注意使用全局过滤器时的输出。 因为Item对象包含一个包含四个元素的数组，所以全局过滤器阻止它反序列化。 但是，可以使用ArrayLengthObjectFilter对同一对象进行反序列化，因为此过滤器覆盖全局过滤器，并允许数组中最多有五个元素。 这在输出的最后一行是显而易见的。

## 二十一. Java I/O API新增方法

JDK 9向I/O API添加了一些方便的方法。 第一个是InputStream类中的一种新方法：

```java
long transferTo(OutputStream out) throws IOException
```

编写的代码从输入流读取所有字节，以便写入输出流。 现在，不必编写一个循环来从输入流读取字节并将其写入输出流。 `transferTo()`方法从输入流读取所有字节，并将它们读取时依次写入指定的输出流。 该方法返回传输的字节数。

> Tips
>
> transferTo()方法不会关闭任何一个流。 当此方法返回时，输入流将在流的末尾。

忽略异常处理和流关闭逻辑，这里是一行代码，将log.txt文件的内容复制到log_copy.txt文件。

```java
new FileInputStream("log.txt").transferTo(new FileOutputStream("log_copy.txt"));
```

java.nio.Buffer类在JDK 9中增加了两种新方法：

```java
abstract Buffer duplicate()
abstract Buffer slice()
```

两种方法返回一个Buffer，它共享原始缓冲区的内容。 仅当原始缓冲区是直接的或只读时，返回的缓冲区将是直接的或只读的。 `duplicate()`方法返回一个缓冲区，其容量，临界，位置和标记值将与原始缓冲区的值相同。 `slice()`方法返回一个缓冲区，其位置将为零，容量和临界是此缓冲区中剩余的元素数量，标记不定义。 返回的缓冲区的内容从原始缓冲区的当前位置开始。 来自这些方法的返回缓冲区保持与原始缓冲区无关的位置，限定和标记。 以下代码片段显示了duplicated和sliced缓冲区的特征：

```java
IntBuffer b1 = IntBuffer.wrap(new int[]{1, 2, 3, 4});
IntBuffer b2 = b1.duplicate();
IntBuffer b3 = b1.slice();
System.out.println("b1=" + b1);
System.out.println("b2=" + b2);
System.out.println("b2=" + b3);
// Move b1 y 1 pos
b1.get();
IntBuffer b4 = b1.duplicate();
IntBuffer b5 = b1.slice();
System.out.println("b1=" + b1);
System.out.println("b4=" + b4);
System.out.println("b5=" + b5);
```

```
b1=java.nio.HeapIntBuffer[pos=0 lim=4 cap=4]
b2=java.nio.HeapIntBuffer[pos=0 lim=4 cap=4]
b2=java.nio.HeapIntBuffer[pos=0 lim=4 cap=4]
b1=java.nio.HeapIntBuffer[pos=1 lim=4 cap=4]
b4=java.nio.HeapIntBuffer[pos=1 lim=4 cap=4]
b5=java.nio.HeapIntBuffer[pos=0 lim=3 cap=3]
```
