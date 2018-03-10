---
title: 增强的弃用注解
date: 2018-3-10 19:10:00
tags:	[Java9]
category: Java 9 Revealed
toc: true
comments: false
---

[原文地址](http://www.cnblogs.com/IcanFixIt/p/7234054.html)

主要介绍以下内容：

* 如何弃用API
* `@deprecate` Javadoc标签和`@Deprecation`注解在弃用的API中的角色
* 用于生成弃用警告的详细规则
* 在JDK 9中更新@Deprecation注解
* JDK 9中的新的弃用警告
* 如何使用@SuppressWarnings注解来抑制JDK 9中的不同类型的弃用警告
* 如何使用`jdeprscan`静态分析工具来扫描编译的代码库，以查找已弃用的JDK API的用法

## 一. 什么是弃用

Java中的弃用是提供有关API生命周期的信息的一种方式。 可以弃用模块，包，类型，构造函数，方法，字段，参数和局部变量。 当弃用API时，要告诉其用户：

* 不要使用API，因为它存在风险。
* API已经迁移，因为存在API的更好的替代方案。
* API已经迁移，因为API将在以后的版本中被删除。

## 二. 如何弃用API

JDK有两个用于弃用API的结构：

* `@deprecated` Javadoc标签
* `@Deprecated`注解

`@deprecated` Javadoc标签已添加到JDK 1.1中，它允许使用丰富的HTML文本格式功能指定关于弃用的详细信息。JDK 5.0中添加了`java.lang.Deprecated`注解类型，并且可以在已被弃用的API元素上使用。 在JDK 9之前，注解不包含任何元素。 它在运行时保留。

`@deprecated`标签和@Deprecated注解应该一起使用。 两者都应该存在或两者都不存在。 @Deprecation注解不允许指定弃用的描述，因此必须使用@deprecated标签来提供描述。

描述，因此必须使用`@deprecated`标签来提供描述。

> Tips
> 
> 在API元素上使用`@deprecated`标签（而不是`@Deprecated`注解）会生成编译器警告。 在JDK 9之前，需要使用`-Xlint：dep-ann`编译器标志来查看这些警告。

下面包含`FileCopier`类的声明。 假设这个类作为类库迁移的一部分。 该类使用`@Deprecation`注解表示弃用。 它的Javadoc使用`@deprecated`标签来提供不推荐使用的详细信息，例如不推荐使用的时间，它的替换和删除通知。 在JDK 9之前，@Deprecated注解类型不包含任何元素，因此必须使用Javadoc中已弃用的API的@deprecated标签提供有关弃用的所有详细信息。 请注意，Javadoc中使用的@since标签表示FileCopier类自该库的版本1.2以来已经存在，而@deprecated标签表示该类自版本1.4以来已被弃用。

```java
// FileCopier.java
package com.jdojo.deprecation;
import java.io.File;
/**
 * The class consists of static methods that can be used to
 * copy files and directories.
 *
 * @deprecated Deprecated since 1.4. Not safe to use. Use the
 * <code>java.nio.file.Files</code> class instead. This class
 * will be removed in a future release of this library.
 *
 * @since 1.2
 */
@Deprecated
public class FileCopier {
    // No direct instantiation supported.
    private FileCopier() {
    }
    /**
     * Copies the contents of src to dst.
     * @param src The source file
     * @param dst The destination file
     * @return true if the copy is successfully,
     * false otherwise.
     */
    public static boolean copy(File src, File dst) {
        // More code goes here
        return true;
    }
    // More methods go here
}
```

Javadoc工具将`@deprecated`标签的内容移动到生成的Javadoc中的顶部，以引起读者的注意。 当不被弃用的代码使用不推荐使用的API时，编译器会生成警告。 请注意，使用@Deprecated注解标注API不会生成警告；但是，使用已经使用`@Deprecated`注解标注的API。 如果在类本身之外使用`FileCopier`类，则会收到关于使用不推荐使用的类的编译器警告。

## 三. JDK 9中`@Deprecated`注解的更新

假设编译了代码并将其部署到生产环境中。如果升级了JDK版本或包含旧应用程序使用的新的已弃用的API的库/框架，则不会收到任何警告，并且将错过从不推荐使用的API迁移的机会。必须重新编译代码以接收警告。没有任何扫描和分析编译代码（例如JAR文件）的工具，并报告使用已弃用的API。更坏的情况是，从旧版本中删除不推荐使用的API，而旧的编译代码会收到意外的运行时错误。当他们查看不赞成使用的元素Javadoc时，开发人员也感到困惑 —— 当API被废弃时，无法表达何种方式，以及在将来的版本中是否会删除已弃用的API。所有可以做的是在文本中将这些信息指定为@deprecated标签的一部分。 JDK 9尝试通过增强@Deprecated注解来解决这些问题。注解在JDK 9中已增加两个新元素：since和forRemoval。

在JDK 9之前，注解的声明如下：

```java
@Documented
@Retention(RetentionPolicy.RUNTIME)
@Target(value={CONSTRUCTOR, FIELD, LOCAL_VARIABLE, METHOD, PACKAGE, PARAMETER, TYPE})
public @interface Deprecated {
}
```

在JDK 9中，弃用注解的声明更改为以下内容：

```java
@Documented
@Retention(RetentionPolicy.RUNTIME)
@Target(value={CONSTRUCTOR, FIELD, LOCAL_VARIABLE, METHOD, PACKAGE, MODULE, PARAMETER, TYPE})
public @interface Deprecated {
    String since() default "";
    boolean forRemoval() default false;
}
```

两个新元素都具有指定的默认值，因此注解的现有使用不会有问题。 `since`元素指定已注解的API元素已被弃用的版本。 它是一个字符串，将遵循与JDK版本方案相同的版本命名约定，例如“9”。 它默认为空字符串。 请注意，JDK 9没有向`@Deprecated`注解类型添加元素，以指定不推荐的描述。 这是由于两个原因：

* 注解在运行时保留。 向注解添加描述性文本将添加到运行时内存。
* 描述性文字不能只是纯文本。 例如，它需要提供一个链接来替代已弃用的API。 现有的@deprecated Javadoc标签已经提供了这个功能。

`forRemoval`元素表示注解的API元素在将来的版本中被删除，应该迁移API。 它默认为false。

> Tips
> 
> 元素上的@since Javadoc标签表示何时添加了API元素，而@Deprecated注解的since元素表示API元素已被弃用。

在JDK 9之前，弃用警告是基于API元素及其使用场景（use-site）上使用@Deprecated注解的问题，如下所示。 当在没有弃用的使用场景使用不推荐使用的API元素时，会发出警告。 如果声明及其使用场景都已弃用，则不会发出任何警告。 可以通过使用@SuppressWarnings("deprecation")注解标示用户场景来抑制弃用警告。


|API Use-Site	|API Declaration Site	|API Declaration Site|
|-------------|---------------------|--------------------|
|Empty	|Not Deprecated	|Deprecated|
|Not Deprecated	|N	|W|
|Deprecate	|N	|N|
|N = No warning,	W = Warning	|

在`@Deprecation`注解类型中添加`forRemoval`元素增加了多于五个用例。 当`forRemoval`设置为false时，不推荐使用API，则将这种弃用称为普通弃用，在这种情况下发出的警告称为普通弃用警告。 当`forRemoval`设置为true时，不推荐使用API，则将这种弃用称为终止弃用，并且在这种情况下发出的警告称为终止弃用警告或删除警告。

|API Use-Site	|API Declaration Site	|API Declaration Site	|API Declaration Site|
|-------------|---------------------|---------------------|--------------------|
|Empty	|Not Deprecated	|Ordinarily |Deprecated	|TerminallyDeprecated|
|Not Deprecated	|N	|OW	|RW|
|Ordinarily Deprecated	|N	|N	|RW|
|Terminally Deprecated	|N	|N	|RW|
|N = No warning,	|OW = Ordinary deprecation warning,	|RW = Removal deprecation warning	|

为了实现向后兼容，如果代码在JDK 8中生成了弃用警告，它将继续在JDK 9中生成普通的弃用警告。如果API已经被终止使用，其使用场景将生成删除警告，而不考虑使用场景状态。

在JDK 9中，在一个情况下发出的警告，其API和其使用场景都被最终弃用，这些警告需要一点解释。 API和使用它的代码都已被弃用，并且将来都会被删除，所以在这种情况下要发出警告是什么意思？ 这样做是为了涵盖最终弃用的API及其使用场景在两个不同的代码库中并独立维护的情况。 如果使用场景代码库存活超过了API代码库，则用场景将会收到意外的运行时错误，因为它使用的API不再存在。用场景发出警告将提供一个机会，以防在用场景的代码去掉之前，来计划替代最终弃用的API。

## 四. 抑制弃用警告

介绍JDK 9中的removal警告已添加了一个新的用例来抑制弃用警告。 在JDK 9之前，可以通过使用`@SuppressWarnings("deprecation")`注解标示使用场景来抑制所有弃用警告。 考虑以下几种情况：

* 在JDK 8中，弃用的API和使用场景会抑制弃用警告。
* 在JDK 9中，API的弃用从普通的弃用变为最终弃用。
* 由于JDK 8中抑制了弃用警告，所以在JDK 9中使用场景的编译没有问题。
* API被删除，并且使用场景收到意外的运行时错误，而不会在之前接收到任何删除警告。

为了涵盖这种情况，当使用`@SuppressWarnings("deprecation")`，JDK 9不会抑制删除警告。 它只抑制普通的弃用警告。 要抑制删除警告，需要使用`@SuppressWarnings("removal")`。 如果要抑制普通和删除的弃用警告，则需要使用`@SuppressWarnings({“deprecation”, "removal"})`。

## 五. 一个弃用API示例

在本节中，展示弃用API的所有用例，使用弃用使用的API，并通过一个简单的示例来抑制警告。 在该示例中，对方法标示为弃用的，并使用它们来生成编译时警告。 但是，不限于仅弃用方法。 对这些方法的注解可以更好地了解预期的行为。 下面包含一个Box类的代码。 该类包含三种方法 —— 没有弃用的方法，普通的弃用方法和最终弃用的方法。 编译Box类不会生成任何废弃警告，因为该类不使用任何已弃用的API，而是包含过时的API。

```java
// Box.java
package com.jdojo.deprecation;
/**
 * This class is used to demonstrate how to deprecate APIs.
 */
public class Box {
    /**
     * Not deprecated
     */    
    public static void notDeprecated() {
        System.out.println("notDeprecated...");
    }
    /**
     * Deprecated ordinarily.
     * @deprecated  Do not use it.
     */    
    @Deprecated(since="2")
    public static void deprecatedOrdinarily() {
        System.out.println("deprecatedOrdinarily...");
    }
    /**
     * Deprecated terminally.
     * @deprecated  It will be removed in a future release.
     *              Migrate your code.
     */    
    @Deprecated(since="2", forRemoval=true)
    public static void deprecatedTerminally() {
        System.out.println("deprecatedTerminally...");
    }
}
```

下面包含`BoxTest`类的代码。 该类使用`Box`类的所有方法。 BoxTest类中的几种方法已经被普遍和最终弃用了。 `m4X()`的方法，其中X是数字，显示如何抑制弃用警告。

```java
// Box.java
package com.jdojo.deprecation;
/**
 * This class is used to demonstrate how to deprecate APIs.
 */
public class Box {
    /**
     * Not deprecated
     */    
    public static void notDeprecated() {
        System.out.println("notDeprecated...");
    }
    /**
     * Deprecated ordinarily.
     * @deprecated  Do not use it.
     */    
    @Deprecated(since="2")
    public static void deprecatedOrdinarily() {
        System.out.println("deprecatedOrdinarily...");
    }
    /**
     * Deprecated terminally.
     * @deprecated  It will be removed in a future release.
     *              Migrate your code.
     */    
    @Deprecated(since="2", forRemoval=true)
    public static void deprecatedTerminally() {
        System.out.println("deprecatedTerminally...");
    }
}
下面包含BoxTest类的代码。 该类使用Box类的所有方法。 BoxTest类中的几种方法已经被普遍和最终弃用了。 m4X()的方法，其中X是数字，显示如何抑制弃用警告。

// BoxTest.java
package com.jdojo.deprecation;
public class BoxTest {
    /**
     * API: Not deprecated
     * Use-site: Not deprecated
     * Deprecation warning: No warning
     */
    public static void m11() {
        Box.notDeprecated();
    }
    /**
    * API: Ordinarily deprecated
    * Use-site: Not deprecated
    * Deprecation warning: No warning
    */
    public static void m12() {
        Box.deprecatedOrdinarily();
    }
    /**
     * API: Terminally deprecated
     * Use-site: Not deprecated
     * Deprecation warning: Removal warning
     */
    public static void m13() {
        Box.deprecatedTerminally();
    }
    /**
     * API: Not deprecated
     * Use-site: Ordinarily deprecated
     * Deprecation warning: No warning
     * @deprecated Dangerous to use.
     */
    @Deprecated(since="1.1")
    public static void m21() {
        Box.notDeprecated();
    }
    /**
    * API: Ordinarily deprecated
    * Use-site: Ordinarily deprecated
    * Deprecation warning: No warning
    * @deprecated Dangerous to use.
    */
    @Deprecated(since="1.1")    
    public static void m22() {
        Box.deprecatedOrdinarily();
    }
    /**
     * API: Terminally deprecated
     * Use-site: Ordinarily deprecated
     * Deprecation warning: Removal warning
     * @deprecated Dangerous to use.
    */
    @Deprecated(since="1.1")
    public static void m23() {
        Box.deprecatedTerminally();
    }
    /**
     * API: Not deprecated
     * Use-site: Terminally deprecated
     * Deprecation warning: No warning
     * @deprecated Going away.
     */
    @Deprecated(since="1.1", forRemoval=true)
    public static void m31() {
        Box.notDeprecated();
    }
    /**
    * API: Ordinarily deprecated
    * Use-site: Terminally deprecated
    * Deprecation warning: No warning
    * @deprecated Going away.
    */
    @Deprecated(since="1.1", forRemoval=true)
    public static void m32() {
        Box.deprecatedOrdinarily();
    }
    /**
     * API: Terminally deprecated
     * Use-site: Terminally deprecated
     * Deprecation warning: Removal warning
     * @deprecated Going away.
    */
    @Deprecated(since="1.1", forRemoval=true)
    public static void m33() {
        Box.deprecatedTerminally();
    }
    /**
     * API: Ordinarily and Terminally deprecated
     * Use-site: Not deprecated
     * Deprecation warning: Ordinary and removal warnings
    */    
    public static void m41() {
        Box.deprecatedOrdinarily();
        Box.deprecatedTerminally();        
    }
    /**
     * API: Ordinarily and Terminally deprecated
     * Use-site: Not deprecated
     * Deprecation warning: Ordinary warnings
    */    
    @SuppressWarnings("deprecation")
    public static void m42() {
        Box.deprecatedOrdinarily();
        Box.deprecatedTerminally();        
    }
    /**
     * API: Ordinarily and Terminally deprecated
     * Use-site: Not deprecated
     * Deprecation warning: Removal warnings
    */    
    @SuppressWarnings("removal")
    public static void m43() {
        Box.deprecatedOrdinarily();
        Box.deprecatedTerminally();        
    }
    /**
     * API: Ordinarily and Terminally deprecated
     * Use-site: Not deprecated
     * Deprecation warning: Removal warnings
    */    
    @SuppressWarnings({"deprecation", "removal"})
    public static void m44() {
        Box.deprecatedOrdinarily();
        Box.deprecatedTerminally();        
    }
}
```

需要使用`-Xlint：deprecation`编译器标志来编译`BoxTest`类，因此编译会发出弃用警告。 请注意，以下命令在一行上输入，而不是两行。

```
C:\Java9Revealed\com.jdojo.deprecation\src>javac -Xlint:deprecation -d ..\build\classes com\jdojo\deprecation\BoxTest.java
```

输出结果为：

```
com\jdojo\deprecation\BoxTest.java:20: warning: [deprecation] deprecatedOrdinarily() in Box has been deprecated
        Box.deprecatedOrdinarily();
           ^
com\jdojo\deprecation\BoxTest.java:29: warning: [removal] deprecatedTerminally() in Box has been deprecated and marked for removal
        Box.deprecatedTerminally();
           ^
com\jdojo\deprecation\BoxTest.java:62: warning: [removal] deprecatedTerminally() in Box has been deprecated and marked for removal
        Box.deprecatedTerminally();
           ^
com\jdojo\deprecation\BoxTest.java:95: warning: [removal] deprecatedTerminally() in Box has been deprecated and marked for removal
        Box.deprecatedTerminally();
           ^
com\jdojo\deprecation\BoxTest.java:105: warning: [deprecation] deprecatedOrdinarily() in Box has been deprecated
        Box.deprecatedOrdinarily();
           ^
com\jdojo\deprecation\BoxTest.java:106: warning: [removal] deprecatedTerminally() in Box has been deprecated and marked for removal
        Box.deprecatedTerminally();
           ^
com\jdojo\deprecation\BoxTest.java:117: warning: [removal] deprecatedTerminally() in Box has been deprecated and marked for removal
        Box.deprecatedTerminally();
           ^
com\jdojo\deprecation\BoxTest.java:127: warning: [deprecation] deprecatedOrdinarily() in Box has been deprecated
        Box.deprecatedOrdinarily();
           ^
8 warnings
···
```

## 六. 静态分析弃用的API
弃用警告是编译时警告。 如果部署的应用程序的编译代码开始使用通常已弃用的API或生成运行时错误，一旦有效的API已被终止使用并被删除，那么将不会收到任何警告。 在JDK 9之前，必须重新编译源代码，以便在升级JDK或其他库/框架时查看废弃用警告。 JDK 9通过提供一个jdeprscan的静态分析工具来改善这种情况，该工具可用于扫描已编译的代码，以查看所使用的已弃用的API列表。 目前，该工具报告了仅JDK中弃用 API。 如果编译的代码使用其他库中不弃用的API，例如Spring或Hibernate或自己的库，则此工具将不会报告这些。

jdeprscan工具位于JDK_HOME\bin目录中。 使用该工具的一般语法如下：

```
jdeprscan [options] {dir|jar|class}
```

这里，[options]是零个或多个选项的列表。 可以指定一个空格分隔目录，JAR或完全限定类名的列表作为要扫描的参数。 可用选项如下：

```
-l, --list
--class-path <CLASSPATH>
--for-removal
--release <6|7|8|9>
-v, --verbose
--version
--full-version
-h, --help
```

* `--list` 选项列出了Java SE中的一些弃用的API。 当使用此选项时，不应指定编译类的位置的参数。
* `--class-path`指定在扫描期间用于查找依赖类的类路径。
* `--for-removal`选项将扫描或列表限制为只被弃用去除的那些API。 它只能在版本值为9或更高版本中使用，因为@Deprecated注解类型在JDK 9之前不包含forRemoval元素。
* `--release`选项指定Java SE版本，在扫描期间提供一组弃用的API。 例如，要在JDK 6中列出所有已弃用的API，工具将如下所示：`jdeprscan --list --release 6`
* `--verbose`选项在扫描过程中打印其他消息。
* `--version`和`--full-version`选项分别打印jdeprscan工具的缩写和完整版本。
* `--help`选项打印有关jdeprscan工具的详细帮助消息。

下面包含JDeprScanTest类的代码。 代码很简单。 它只是编译，而不是运行。 运行它不会产生任何有趣的输出。 它创建两个线程。 一个线程使用Thread类的stop()方法停止，另一个线程使用Thread类的`destroy()`方法进行销毁。 从JDK 1.2和JDK 1.5开始，`stop()`和`destroy()`方法为普通弃用。 JDK 9已经最终弃用了`destroy()`方法，而继续保持`stop()`方法作为普通弃用。 在下面的例子中使用这个类。

```java
// JDeprScanTest.java
package com.jdojo.deprecation;
public class JDeprScanTest {
    public static void main(String[] args) {
        Thread t = new Thread(() -> System.out.println("Test"));
        t.start();
        t.stop();
        Thread t2 = new Thread(() -> System.out.println("Test"));
        t2.start();
        t2.destroy();
    }
}
```

以下命令打印JDK 9中所有已弃用的API的列表。它将打印一个长列表。 该命令需要几秒钟才能开始打印结果，因为它扫描整个JDK。

```
C:\Java9Revealed>jdeprscan --list
```

输出的结果为：

```
@Deprecated java.lang.ClassLoader
 javax.tools.ToolProvider.getSystemToolClassLoader()
 ...
The following command prints all terminally deprecated APIs in JDK 9. That is, it prints all deprecated APIs that have been marked for removal in a future release:
C:\Java9Revealed>jdeprscan --list --for-removal
 ...
 @Deprecated(since="9", forRemoval=true) class java.lang.Compiler
 ...
The following command prints the list of all APIs deprecated in JDK 8:
C:\Java9Revealed>jdeprscan --list --release 8
 @Deprecated class javax.swing.text.TableView.TableCell
 ...
```

以下命令打印java.lang.Thread类使用的已弃用API的列表。

```
C:\Java9Revealed>jdeprscan java.lang.Thread
```

输出的结果为：

```
 class java/lang/Thread uses deprecated method java/lang/Thread::resume()V
```

请注意，之前的命令不会打印Thread类中已弃用的API列表。 相反，它打印使用弃用的API的Thread类中的API列表。

## 七. 动态分析弃用的API

jdeprscan工具是一个静态分析工具，因此它将跳过动态使用的弃用API。 例如，可以使用反射来调用已弃用的方法，这个工具在扫描过程中会错过。 还可以在由ServiceLoader加载的提供程序中调用弃用的方法，这将被该工具遗漏。

在未来的版本中，JDK可能会提供一个名为jdeprdetect的动态分析工具，该工具将在运行时跟踪弃用的API的使用。 该工具将有助于找到引用由静态分析工具jdeprscan报告的弃用的API的死代码。

## 八 导入时没有弃用警告

直到JDK 9，如果使用import语句导入了弃用类的构造函数，编译器就会生成警告，即使在已弃用导入的构造的所有使用站点上使用了`@SuppressWarnings`注解。 如果试图摆脱代码中的所有弃用警告，这是一个烦恼。 你不能摆脱它们，因为你不能注解import语句。 可以通过省略对导入弃用警告，JDK 9改进了这一点。

考虑下面ImportDeprecationWarning类，它在三个地方使用了弃用的StringBufferInputStream类：

* 在导入语句中
* 在变量声明中
* 在实例创建的表达式中

```
// ImportDeprecationWarning.java
package com.jdojo.deprecation;
import java.io.StringBufferInputStream;
public class ImportDeprecationWarning {
    @SuppressWarnings("deprecation")
    public static void main(String[] args) {
        StringBufferInputStream sbis =
                new StringBufferInputStream("Hello");
        for(int c = sbis.read(); c != -1; c = sbis.read()) {
            System.out.println((char)c);
        }
    }
}
```

请注意，ImportDeprecationWarning类在main()方法上使用@SuppressWarnings注解来抑制弃用警告。 使用Xlint:deprecation`标志在JDK 8中编译此类将生成以下警告。 在JDK 9中编译此类不会生成任何弃用警告。

```
C:\Java9Revealed\com.jdojo.deprecation\src>javac -Xlint:deprecation -d ..\build\classes com\jdojo\deprecation\ImportDeprecationWarning.java
```
输出结果为：

```
com\jdojo\deprecation\ImportDeprecationWarning.java:4: warning: [deprecation] StringBufferInputStream in java.io has been deprecated
import java.io.StringBufferInputStream;
              ^
1 warning
```

在JDK 8中编译此类，在删除main()方法上的@SuppressWarnings注解后，编译器将生成三个弃用的警告 —— 一个用于每次使用弃用的StringBufferInputStream类，而JDK 9将仅生成两个弃用警告 —— 不包括导入声明的警告。

## 九. 总结

Java中的弃用是提供有关API生命周期的信息的一种方式。 弃用API会告诉用户迁移，因为API有使用的危险，更好的替换存在，否则将在以后的版本中被删除。 使用弃用的API会生成编译时弃用警告。

@deprecated Javadoc标签和@Deprecated注解一起用于弃用API元素，如模块，包，类型，构造函数，方法，字段，参数和局部变量。 在JDK 9之前，注解不包含任何元素。 它在运行时保留。

JDK 9为注解添加了两个元素：since和forRemoval。 since元素默认为空字符串。 其值表示弃用的API元素的API版本。forRemoval元素的类型为boolean，默认为false。 其值为true表示API元素将在以后的版本中被删除。

JDK 9编译器根据@Deprecated注解的forRemoval元素的值生成两种类型的弃用警告：forRemoval = false时为普通的弃用警告，forRemoval = true时为最终的删除警告。

在JDK 9之前，可以通过使用@SuppressWarnings("deprecation")注解标示已弃用的API的使用场景来抑制弃用警告。 在JDK 9中，需要使用@SuppressWarnings("deprecation")来抑制普通警告，@SuppressWarnings("removal")来抑制删除警告，而@SuppressWarnings({"deprecation", "removal"}可以抑制两种类型的警告。

在JDK 9之前，使用import语句导入弃用的构造会生成编译时弃用警告。 JDK 9省略了这样的警告。
