---
title: 平台和JVM日志
date: 2018-4-19 14:10:00
tags:	[Java9,long]
category: Java 9 Revealed
toc: true
comments: false
---


[原文地址](http://www.cnblogs.com/IcanFixIt/p/7253559.html)

在这章中，主要介绍以下内容：

* 新的平台日志（logging）API
* JVM日志的命令行选项

JDK 9已经对平台类（JDK类）和JVM组件的日志系统进行了大整。 有一个新的API可以指定所选择的日志框架作为从平台类记录消息的日志后端。 还有一个新的命令行选项，可以从所有JVM组件访问消息。 在本章中，详细介绍两个记录工具。


## 一. 平台日志API

Java SE 9添加了一个平台日志API，可用于指定可由Java平台类（JDK中的类）记录消息的记录器（Logger），例如Log4j，SLF4J或自定义记录器。 有关这个API的几点要注意。 该API旨在由JDK中的类使用，而不是应用程序类。 因此，不应该使用此API来记录应用程序消息。 需要使用Log4j等日志框架来记录应用程序消息。 API不允许以编程方式配置记录器。 API由以下内容组成：

* 一个服务接口`java.lang.System.LoggerFinder`，它是一个抽象的静态类
* 一个接口`java.lang.System.Logger`，它提供了日志API
* `java.lang.System`类中的重载方法`getLogger()`返回一个`System.Logger`

配置平台记录器的细节取决于要使用的记录器。 例如，如果使用Log4j，则需要单独配置Log4j框架，并配置平台记录器。 配置平台记录器需要执行以下步骤：

* 创建一个实现`System.Logger`接口的类。
* 为`System.LoggerFinder`服务接口创建一个实现。
* 在模块声明中指定实现。

在这里配置Log4j 2.0为平台记录器。 配置和使用Log4j是一个广泛的话题。 这里仅涵盖配置平台记录器所需的Log4i的详细信息。

> Tips
>
> 如果不配置自定义平台记录器，JDK将使用System.LoggerFinder的默认实现，它在java.logging模块存在时使用java.util.logging作为后端框架。 它返回一个将日志消息路由到java.util.logging.Logger的记录器实例。 否则，如果不存在java.logging模块，则默认实现将返回一个简单的记录器实例，它将INFO级别及以上的日志消息传递到控制台（System.err）。

### 1. 设置Log4j类库

需要下载Log4j 2.0库，以便用在本节中的示例中。可以从https://logging.apache.org/log4j/2.0/download.html下载Log4J 2.0类库。 解压缩下载的文件并将以下两个JAR复制到C:\Java8Revealed\extlib目录。 如果将它们复制到另一个目录，请务必更换路径。

* log4j-api-2.8.jar
* log4j-core-2.8.jar

如果下载不同版本的Log4j，则这些JAR文件名中的版本可能不同。 在这个例子中，使用这些JAR作为自动模块。 自动模块名称将从JAR文件名派生，它们是log4j.api和log4j.core。

### 2. 设置NetBeans项目
在NetBeans中创建了名为com.jdojo.logger的Java项目。 上一节讨论的两个Log4j JAR被添加到项目的模块路径中，如下图所示。 要将这些JAR添加到NetBeans中的模块路径，需要从扩展菜单中选择“添加JAR/文件夹”选项以添加到模块路径。

### 3. 定义一个模块
此示例的所有类和资源将位于com.jdojo.logger的模块中，其声明如下所示。

```java
// module-info.java
module com.jdojo.logger {    
    requires log4j.api;
    requires log4j.core;
    exports com.jdojo.logger;
    provides java.lang.System.LoggerFinder
        with com.jdojo.logger.Log4jLoggerFinder;
}
```

前两个requires语句对Log4j JAR的依赖关系，这是这种情况下的自动模块。exports语句导出此模块的com.jdojo.logger包中的所有类型。 provides语句对于设置平台记录器很重要。 它声明提供了`com.jdojo.logger.Log4jLoggerFinder`类作为服务接口`java.lang.System.LoggerFinder`的实现。 很快就会创建这个类。 com.jdojo.logger模块的模块图如下所示。

![](http://blog.oneforce.cn/images/20180419/log_level.png)

注意模块图中的循环依赖关系和未命名的模块。 它们是因为在本模块声明中使用的自动模块。com.jdojo.logger模块读取两个自动模块。 每个自动模块读取所有其他模块，可以在从log4j.code和log4j.api模块中的箭头中看到所有其他模块。 即使在模块图的显示中，此示例中没有任何未命名的模块。 在这个例子中，未命名的模块将不包含任何类型。 未命名的模块出现在图表中，因为自动模块读取所有其他模块，包括未命名的模块。

### 4. 添加Log4J配置文件

如下显示了log4j2.xml的配置文件，它位于NetBeans项目源代码的根目录下。 换句话说，log4j2.xml文件放在一个未命名的包中。 此配置使Log4j将消息记录在当前目录下的logs/platform.log文件中。 有关此配置的更多信息，请参阅Log4j文档。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Configuration status="error">
    <Appenders>
        <File name="JdojoLogFile" fileName="logs/platform.log">
            <PatternLayout>
                <Pattern>%d %p %c [%t] %m%n</Pattern>
            </PatternLayout>
        </File>
        <Async name="Async">
            <AppenderRef ref="JdojoLogFile"/>
        </Async>
    </Appenders>
    <Loggers>
        <Root level="info">
            <AppenderRef ref="Async"/>
        </Root>
    </Loggers>
</Configuration>
```

### 5. 创建系统记录器

需要创建一个系统记录器，它是一个实现System.Logger接口的类。 该接口包含以下方法：

```java
String getName()
boolean isLoggable(System.Logger.Level level)
default void log(System.Logger.Level level, Object obj)
default void log(System.Logger.Level level, String msg)
default void log(System.Logger.Level level, String format, Object... params)
default void log(System.Logger.Level level, String msg, Throwable thrown)
default void log(System.Logger.Level level, Supplier<String> msgSupplier)
default void log(System.Logger.Level level, Supplier<String> msgSupplier, Throwable thrown)
void log(System.Logger.Level level, ResourceBundle bundle, String format, Object... params)
void log(System.Logger.Level level, ResourceBundle bundle, String msg, Throwable thrown)
```

需要在`System.Logger`接口中提供四种抽象方法的实现。 `getName()`方法返回记录器的名称。 可以任何你想要的名字。 如果记录器可以记录指定级别的消息，则`isLoggable()`方法返回true。 `log()`方法的两个版本方法用于记录消息，他们被其他默认`log()`方法所调用。

`System.Logger.Level`枚举定义要记录的消息级别的常量。 级别具有名称和严重程度。 级别值为ALL，TRACE，DEBUG，INFO，WARNING，ERROR，OFF，按照严重程度增加。 可以使用其getName()和getSeverity()方法获取级别的名称和严重程度。

下面包含一个Log4jLogger类的代码，它实现了System.Logger接口。

```java
// Log4jLogger.java
package com.jdojo.logger;
import java.util.ResourceBundle;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
public class Log4jLogger implements System.Logger {
    // The backend logger. Our logger will delegate all loggings
    // to this backend logger, which is Log4j
    private final Logger logger = LogManager.getLogger();
    @Override
    public String getName() {
        return "Log4jLogger";
    }
    @Override
    public boolean isLoggable(Level level) {
        // Get the log4j level from System.Logger.Level
        org.apache.logging.log4j.Level log4jLevel = toLog4jLevel(level);
        // Check if log4j can handle this level of logging and return the result
        return logger.isEnabled(log4jLevel);
    }
    @Override
    public void log(Level level, ResourceBundle bundle, String msg, Throwable thrown) {                              
        logger.log(toLog4jLevel(level), msg, thrown);
    }
    @Override
    public void log(Level level, ResourceBundle bundle, String format, Object... params) {        
        logger.printf(toLog4jLevel(level), format, params);
    }
    private static org.apache.logging.log4j.Level toLog4jLevel(Level level) {        
          switch (level) {
              case ALL:
                  return org.apache.logging.log4j.Level.ALL;
              case DEBUG:
                  return org.apache.logging.log4j.Level.DEBUG;
              case ERROR:
                  return org.apache.logging.log4j.Level.ERROR;
              case INFO:
                  return org.apache.logging.log4j.Level.INFO;
              case OFF:
                  return org.apache.logging.log4j.Level.OFF;
              case TRACE:
                  return org.apache.logging.log4j.Level.TRACE;
              case WARNING:
                  return org.apache.logging.log4j.Level.WARN;
              default:
                  throw new RuntimeException("Unknown Level: " + level);
          }        
    }
}
```

Log4jLogger的实例用作平台记录器来记录平台类的消息。它将所有日志记录工作委托给一个后端记录器，这是基础的Log4j。 logger实例变量保存对Log4j Logger实例的引用。

现在正在处理两个日志API，一个由`System.Logger`定义，另一个由Log4j定义。它们使用不同的日志级别，它们由两种不同的类型表示：`System.Logger.Leve`l和`org.apache.logging.log4j.Level`。要记录消息，JDK类将将System.Logger.Level传递给System.Logger接口的log()方法，该方法又需要将级别映射到Log4j级别。 toLog4jLevel（）方法执行此映射。它收到一个System.Logger.Level并返回一个相应的org.apache.logging.log4j.Level。`isLoggable()`方法将系统级别映射到Log4j级别，如果启用日志记录功能，则查询Log4j。可以使用其配置文件配置Log4j来启用任何级别的日志记录。

在本例中保持执行的两个log()方法逻辑简单。它们只是把他们的工作委托给Log4j。这些方法不使用ResourceBundle参数。如果要在记录之前本地化消息，则需要使用它。

现在已经写了平台记录器的主要逻辑，但还没有准备好测试。需要更多的工作才能看到它的实际效果。

### 6. 创建日志查找器（Finder）

Java运行时需要找到平台记录器。 它使用服务定位器模式来查找它。 在模块声明中回想一下以下语句。

```java
provides java.lang.System.LoggerFinder
        with com.jdojo.logger.Log4jLoggerFinder;
```

在本节中，创建了Log4jLoggerFinder实现类，它实现服务接口System.LoggerFinder。 记住，服务接口不需要是Java接口。 它可以是一个抽象类。 在这种情况下，`System.LoggerFinder`是一个抽象类，Log4jLoggerFinder类将继承System.LoggerFinder类。 下面包含Log4jLoggerFinder类的代码，它作为服务接口 System.LoggerFinder的实现。

```java
// Log4jLoggerFinder.java
package com.jdojo.logger;
import java.lang.System.LoggerFinder;
public class Log4jLoggerFinder extends LoggerFinder {
    // A logger to be used as a platform logger
    private final Log4jLogger logger = new Log4jLogger();
    @Override
    public System.Logger getLogger(String name, Module module) {        
        System.out.printf("Log4jLoggerFinder.getLogger(): " +
                          "[name=%s, module=%s]%n", name, module.getName());
        // Use the same logger for all modules        
        return logger;
    }
}
```
`Log4jLoggerFinder`类创建了Log4jLogger类的实例，并将其引用保存在logger的实例变量中。 当JDK要求记录器时，getLogger()方法返回相同的记录器。 `getLogger()`方法中的名称和模块参数是请求的记录器和请求者的模块的名称。 例如，当`java.util.Currency`类需要记录消息时，它会请求一个名`java.util.Currency`的记录器，并且请求者模块是java.base模块。 如果要为每个模块使用单独的记录器，可以根据模块参数返回不同的记录器。 此示例为所有模块返回相同的记录器，因此所有消息都将记录到同一个位置。 在getLogger()方法中留下了`System.out.println()`语句，因此可以在运行此示例时看到名称和模块参数的值。

### 7. 测试平台记录器

下面包含PlatformLoggerTest类的代码，用于测试平台记录器。 你可能得到不同的输出。

```java
// PlatformLoggerTest.java
package com.jdojo.logger;
import java.lang.System.Logger;
import static java.lang.System.Logger.Level.TRACE;
import static java.lang.System.Logger.Level.ERROR;
import static java.lang.System.Logger.Level.INFO;
import java.util.Currency;
import java.util.Set;
public class PlatformLoggerTest {    
    public static void main(final String... args) {
        // Let us load all currencies  
        Set<Currency> c = Currency.getAvailableCurrencies();
        System.out.println("# of currencies: " + c.size());
        // Let us test the platform logger by logging a few messages
        Logger logger = System.getLogger("Log4jLogger");
        logger.log(TRACE, "Entering application.");
        logger.log(ERROR, "An unknown error occurred.");
        logger.log(INFO, "FYI");
        logger.log(TRACE, "Exiting application.");
    }
}
```
输出结果为：

```
# of currencies: 225
Log4jLoggerFinder.getLogger(): [name=javax.management.mbeanserver, module=java.management]
Log4jLoggerFinder.getLogger(): [name=javax.management.misc, module=java.management]
Log4jLoggerFinder.getLogger(): [name=Log4jLogger, module=com.jdojo.logger]
```

`main()`方法尝试获取可用的货币符号列表并打印货币符号数量。 这样做的目的是什么？ 稍后解释其目的。 现在，它只是`java.util.Currency`类中的一个方法调用。

即使不应该使用记录器来记录应用程序的消息，但可以这样做进行测试。 可以使用System.getLogger()方法获取平台记录器的引用，并开始记录消息。main()方法中的以下代码段执行此操作。

```java
Logger logger = System.getLogger("Log4jLogger");
logger.log(TRACE, "Entering application.");
logger.log(ERROR, "An unknown error occurred.");
logger.log(INFO, "FYI");
logger.log(TRACE, "Exiting application.");
```

> Tips
>
> 在JDK 9中，System类包含两个可用于获取平台日志录引用的静态方法。 方法是getLogger(String name)和getLogger(String name, ResourceBundle bundle)。 两种方法都返回System.Logger接口的实例。

输出中不显示四条消息。 他们去哪儿了？ 回想一下，配置了Log4j将消息记录到当前目录下logs/platform.log的文件中。 当前目录取决于如何运行PlatformLoggerTest类。 如果从NetBeans运行它，项目的目录`C:\Java9Revealed\com.jdojo.logger`是当前目录。 如果从命令提示符运行它，则可以控制当前目录。 假设从NetBeans内部运行此类，将在`C:\Java9Revealed\com.jdojo.logger\logs\platform.log`中找到一个文件。 其内容如下所示。

```
2017-02-09 09:58:34,644 ERROR com.jdojo.logger.Log4jLogger [main] An unknown error occurred.
2017-02-09 09:58:34,646 INFO com.jdojo.logger.Log4jLogger [main] FYI
```

每次运行PlatformLoggerTest类时，Log4j都会将消息附加到logs\platform.log文件中。 可以在运行程序之前删除日志文件的内容，也可以删除日志文件，每次运行程序时都会重新创建该文件。

日志文件指示只记录了两个消息ERROR和INFO，丢弃了TRACE消息。 这与Log4j配置文件中的记录级别设置有关，如下所示。 已在记录器中启用INFO级别日志记录：

```xml
<Loggers>
    <Root level="info">
        <AppenderRef ref="Async"/>
    </Root>
</Loggers>
```

每个记录器级别都有一个严重程度，它是一个整数。 如果启用具有级别x的记录器，则会记录其级别严重程度大于或等于x的所有消息。 下表显示了由System.Logger.Level枚举及其相关严重程度定义的所有级别的名称。 请注意，在示例中，正在使用Log4j记录器级别，而不是System.Logger.Level枚举定义的级别。 但是，Log4j定义的级别的相对值与下表所示的顺序相同。

|Name	|Severity|
|-----|--------|
|ALL	|Integer.MIN_VALUE|
|TRACE	|400|
|DEBUG	|500|
|INFO	|800|
|WARNING	|900|
|ERROR	|1000|
|OFF	|Integer.MAX_VALUE|

如果启用记录器的级别INFO，记录器将记录在INFO，WARNING和ERROR级别上的所有消息。 如果要在各级记录消息，可以使用TRACE或ALL作为Log4j配置文件中的级别值。

请注意，输出中平台类通过调用Log4jLoggerFinder类的getLogger()方法请求记录器三次。前两次，请求由javax.management模块进行。第三个请求出现在输出中，因为从PlatformLoggerTest类的main()方法请求了一个记录器。

在日志中看到自己的消息，但没有从JDK类记录的任何消息。相信你好奇地看到日志中的JDK类的消息。如何知道将消息记录到平台记录器的JDK类的名称以及如何使其记录消息？没有简单直接的方式来知道这一点。查看JDK的源代码，并找到用于记录平台消息的sun.util.logging.PlatformLogger类的引用，发现javax.management模块记录了TRACE级别的消息。要查看这些消息，需要设置Log4j记录器的级别来跟踪并重新运行PlatformLoggerTest类。这在日志文件中记录大量消息。

让我们回到在PlatformLoggerTest类中使用Currency类。 用它来显示JDK类记录的消息，在这种情况下，这是java.util.Currency类。 当请求所有货币的列表时，JDK会读取其自身的货币列表（JDK内置的货币列表），以及位于JAVA_HOME\lib目录中的自定义currency.properties文件。 在这种情况下，正在使用JDK运行此示例，因此JAVA_HOME是指JDK_HOME。 创建一个文本文件，该文件的路径将是JDK_HOME\lib\currency.properties。 请注意，该文件只包含一个单词，即ABadCurrencyFile。 可以使用任何一个单词。

Currency类尝试将currency.properties文件加载为Java属性文件，该文件应包含j键值对。 此文件不是有效的属性文件。 当Currency类尝试加载它时，将抛出异常，并且该类向平台记录器记录错误消息。 现在，知道创建了无效的货币文件，因此可以通过JDK类查看平台记录器。

再次运行PlatformLoggerTest类，它提供以下输出：

```
Log4jLoggerFinder.getLogger(): [name=javax.management.mbeanserver, module=java.management]
Log4jLoggerFinder.getLogger(): [name=javax.management.misc, module=java.management]
Log4jLoggerFinder.getLogger(): [name=java.util.Currency, module=java.base]
# of currencies: 225
Log4jLoggerFinder.getLogger(): [name=Log4jLogger, module=com.jdojo.logger]
```

输出表明java.base模块请求了java.util.Currency的平台记录器。 这是因为使用的无效的货币文件。 日志文件的内容如下所示，它显示了Currency类中记录的消息。

```
2017-02-09 10:45:52,413 INFO com.jdojo.logger.Log4jLogger [main] currency.properties entry for ABADCURRENCYFILE is ignored because of the invalid country code.
2017-02-09 10:45:52,420 ERROR com.jdojo.logger.Log4jLogger [main] An unknown error occurred.
2017-02-09 10:45:52,420 INFO com.jdojo.logger.Log4jLogger [main] FYI
```

### 8. 进一步的工作

展示了使用Log4j 2.0作为后端记录器配置平台记录器的示例。在生产环境中可以使用此示例之前，还有很多工作要做。其中一个改进是记录正在记录消息的类的名称。在上面的例子中，发现所有记录的消息使用相同的类名称，即com.jdojo.logger.Log4jLogger作为记录器的类，这是不正确的。从com.jdojo.logger.PlatformLoggerTest类中记录了两条消息，并从java.util.Currency类中记录了一条消息。怎么解决这个问题？

先来尝试理解这个问题。 Logger的类名由Log4j决定。它只是查看其log()方法的调用者，并将该类用作记录消息的那个类。在之前的例子中，两个log()方法调用Log4j的log()方法来委托日志记录工作。 Log4j将com.jdojo.logger.Log4jLogger类视为消息的记录器，并将其名称作为记录消息中的记录器类。

这里有两种方法来解决它：

* 在Log4jLogger类中，使用使用添加到JDK 9的栈遍历API自己格式化消息。栈遍历API提供调用者的类名和其他详细信息。这将更改Log4j配置文件中的模式布局，因此Log4j不会在消息中确定并包含记录器的类名称。
* 可以等待下一个版本的Log4j，这可能会支持开箱即用的JDK 9平台记录器。

## 二. 统一JVM日志

JDK 9添加了一个新的命令行选项-Xlog，它可以访问从JVM的所有组件记录的所有消息的单点访问。 该选项的使用语法有点复杂。 先解释一下已记录消息的详细信息。

> Tips
>
> 可以使用-Xlog:help选项与java命令打印-Xlog选项的描述。 该描述包含具有示例的所有选项的语法和值。

当JVM记录消息或当正在寻找JVM记录的消息时，请记住以下几点：

* JVM需要确定消息所属的主题（或JVM组件）。 例如，如果消息与垃圾回收有关，那么消息应该被标记为这样。 消息可能属于多个主题。 例如，消息可能属于垃圾回收和堆管理。 因此，消息可以具有与其相关联的多个标签(（tag）。

像任何其他日志记录工具一样，JVM日志可能会发生在不同的级别，如信息，警告等。

应该能够使用附加的上下文信息（如当前日期和时间，线程记录消息，消息使用的标签等）来装饰已记录的消息。

信息应该在哪里记录？ 他们应该记录到stdout，stderr，还是一个或多个文件？ 是否可以指定日志文件的选项策略，例如文件名，大小和文件轮换策略。

如果了解了这些要点，现在是学习用于描述JVM日志记录的以下术语的时候了：

* Tag（标签）
* Level（级别）
* Decoration（装饰）
* Output（输出）

以下是运行com.jdojo.Welcome类的示例，它使用标准输出上的严格级别为trace或以上的gc标签（tag）记录所有消息，其级别，时间和标签装饰。

```
C:\Java9revealed> java -Xlog:gc=trace:stdout:level,time,tags
--module-path com.jdojo.intro\dist
--module com.jdojo.intro/com.jdojo.intro.Welcome
```

输出结果为：

```
[2017-02-10T12:50:11.412-0600][trace][gc] MarkStackSize: 4096k  MarkStackSizeMax: 16384k
[2017-02-10T12:50:11.427-0600][debug][gc] ConcGCThreads: 1
[2017-02-10T12:50:11.432-0600][debug][gc] ParallelGCThreads: 4
[2017-02-10T12:50:11.433-0600][debug][gc] Initialize mark stack with 4096 chunks, maximum 16384
[2017-02-10T12:50:11.436-0600][info ][gc] Using G1
Welcome to the Module System.
Module Name: com.jdojo.intro
```

### 1. 消息标签

每个日志的消息与一个或多个称为标签集的标签相关联。以下是所有可用标签的列表。此列表将来可能会更改。要获取支持的标签列表，使用-Xlog:help选项与java命令。

```
add, age, alloc, aot, annotation, arguments, attach, barrier, biasedlocking, blocks, bot, breakpoint, census, class, classhisto, cleanup, compaction, constraints, constantpool, coops, cpu, cset, data, defaultmethods, dump, ergo, exceptions, exit, fingerprint, freelist, gc, hashtables, heap, humongous, ihop, iklass, init, itables, jni, jvmti, liveness, load, loader, logging, mark, marking, methodcomparator, metadata, metaspace, mmu, modules, monitorinflation, monitormismatch, nmethod, normalize, objecttagging, obsolete, oopmap, os, pagesize, patch, path, phases, plab, promotion, preorder, protectiondomain, ref, redefine, refine, region, remset, purge, resolve, safepoint, scavenge, scrub, stacktrace, stackwalk, start, startuptime, state, stats, stringdedup, stringtable, stackmap, subclass, survivor, sweep, task, thread, tlab, time, timer, update, unload, verification, verify, vmoperation, vtables, workgang, jfr, system, parser, bytecode, setting, event
```

如果有兴趣记录垃圾收集和启动的消息，则可以使用带有-Xlog选项的gc和startuptime标签。列表中的大多数标签都有深奥的名称，实际上它们适用于在JVM上工作的开发人员，而不是应用程序开发人员。

> Tips
>
> 可以使用-Xlog选项使用all这个特别标签，通知JVM记录所有消息，而不考虑与它们相关联的标记。 标签的默认值就是all。

### 2. 消息级别

级别是根据消息的严重程度确定要记录的消息日志的严重性级别。 级别具有以下严重性顺序的值：trace，debug，info，warning和error。 如果为严重级别S启用日志记录，则将记录严重级别为S和更大的所有消息。 例如，如果在info级别启用日志记录，将记录info，warning和error级别的所有消息。

> Tips
>
> 可以使用-Xlog选项命名的特殊严重成都级别off来禁用所有级别的日志记录。 级别的默认值为info。

### 3. 消息装饰

记录JVM消息之前，可以增加其他信息。 这些额外的信息被称为装饰，它们是前面的消息。 每个装饰都在括号内——“[]”。 下表含所有具有长名称和短名称的装饰的列表。长名称或短名称与-Xlog选项 一起使用。

|长名字	|短名字	|描述|
|------|-------|----|
|hostname	|hn	|计算机名称|
|level|	l	|消息的严重程度|
|pid	|p	|进程标识符|
|tags	|tg	|与消息相关联的所有标签|
|tid	|ti	|线程标识符|
|time	|t	|当前时间和日期为ISO-8601格式（例如：2017-02-10T18：42：58.418 + 0000）|
|timemillis	|tm	|当前时间以毫秒为单位，与System.currentTimeMillis()生成的值相同|
|timenanos	|tn	|当前时间以纳秒为单位，与System.nanoTime()生成的值相同|
|uptime	|u	|自JVM启动以来运行的时间，以秒和毫秒为单位（例如9.219s）|
|uptimemillis	|um	|自JVM启动以来运行的毫秒数|
|uptimenanos	|un	|自JVM启动以来运行的纳秒数|
|utctime	|utc	|UTC格式的当前时间和日期（例如：2017-02-10T12：42：58.418-0600）|

> Tips
>
> 可以使用none的特殊装饰与-Xlog选项关闭装饰。 装饰的默认值为uptime，level和tag。

### 4. 消息输出装饰

可以指定JVM日志发送的三个目的地：

* stdout
* stderr
* file=

使用stdout和stderr值分别在标准输出和标准错误上打印JVM日志。 默认的输出目标是stdout。

使用文件值指定文本文件名将日志发送到文本文件。 可以在文件名中使用％p和％t，这将分别扩展到JVM的PID和启动时间。 例如，如果使用-Xlog选项指定`file=jvm%p_%t.log`作为输出目标，则对于每个JVM运行，消息将被记录到名称如下所示的文件中：

```
jvm2348_2017-02-10_13-26-05.log
jvm7292_2017-02-10_13-26-06.log
```

每次启动JVM时，将创建一个类似于此列表中显示的日志文件。 这里，2348和7292是两个运行的JVM的PID。

> Tips
>
> 缺少stdout和stderr作为输出目的地表示输出目的地是一个文本文件。 代替使用file=jvm.log，可以简单地使用jvm.log作为输出目的地。

可以指定用于将输出发送到文本文件的其他选项：

* filecount=
* filesize=
这些选项用于控制每个日志文件的最大大小和最大日志文件数。 考虑以下选项：

```
file=jvm.log::filesize=1M,filecount= 3
```

注意使用两个连续的冒号（`::`）。 此选项使用jvm.log作为日志文件。 日志文件的最大大小为1M，日志文件的最大计数为3。它将创建四个日志文件：jvm.log，jvm.log.0，jvm.log.1和jvm.log0.2。 当前消息被记录到jvm.log文件，当前文件中记录的消息超过1MB时，其他三个文件轮换。 可以使用K指定千字节的文件大小，M表示兆字节。 如果在不包含K或M后缀的情况下指定文件大小，则该选项假定为字节。

### 5. -Xlog语法

以下是使用-Xlog选项的语法：

```
-Xlog[:<contents>][:[<output>][:[<decorators>][:<output-options>]]]
```

与-Xlog使用的选项用冒号（:)分隔。 所有选项都是可选的。 如果缺少-Xlog中的前一部分，则必须对该部分使用冒号。 例如，-Xlog :: stderr表示所有部分都是默认值，除了指定为stderr的<output>部分。

-Xlog的最简单的使用方法如下，将所有JVM消息记录到标准输出：

```
java -Xlog --module-path com.jdojo.intro\dist --module com.jdojo.intro/com.jdojo.intro.Welcome
```

有两个特殊的-XLog选项：help和disable，可以用作-Xlog：-Xlog:help打印-Xlog的帮助，-Xlog:disable禁用所有JVM日志。 你可能会认为，不是使用-Xlog:disable，你根本不会使用-Xlog选项。 你是对的。 但是，由于不同的原因存在disable选项。 -Xlog选项可以使用相同的命令多次使用。 如果多次出现-Xlog包含相同类型的设置，则最后一个-Xlog的设置将生效。 因此，可以指定-Xlog:disable作为第一个选项，并指定另一个-Xlog打开特定类型的日志记录。 这样，首先关闭所有默认值，然后指定你感兴趣的选项。

<contents>部分指定要记录的消息的标签和严重程度级别。 其语法如下：

```
tag1[+tag2...][*][=level][,...]
```

<contents>部分中的“+”表示逻辑AND。例如，`gc + exit`表示记录其标签集完全包含两个tag——`gc`和`exit`的所有消息。标签名末尾的“`*`”用作通配符，这意味着“至少”。例如，`gc *`表示记录标签集至少包含gc的所有消息，它将使用标签集[gc]，[gc，exit]，[gc，remset，exit]等记录消息。如果使用`gc + exit *`，表示记录包含至少包含gc和exit标签的标签集的所有消息，它将使用标签集[gc，exit]，[gc，remset，exit]等记录消息。可以指定严重程度每个要记录的标签名称的级别。例如，gc = trace记录所有带有标签集的消息，其中只包含严重级别为trace或更高的gc。可以指定以逗号分隔的多个条件。例如，gc = trace,heap = error将使用gc标签集在trace或更高级别或使用heap标签集在错误级别记录所有消息。

运行这些命令时可能会得到不同的输出。以下命令将gc和startuptime指定为标签，将其他设置保留为默认值：

```
C:\Java9Revealed>java -Xlog:gc,startuptime --module-path com.jdojo.intro\dist
--module com.jdojo.intro/com.jdojo.intro.Welcome
```

输出结果为；

```
[0.017s][info][startuptime] StubRoutines generation 1, 0.0002258 secs
[0.022s][info][gc         ] Using G1
[0.022s][info][startuptime] Genesis, 0.0045639 secs
...
```
使用`-Xlog与-Xlog:all=info:stdout:uptime,level,tags`相同。 它记录严重级别info或更高级别的所有信息，并包括带有装饰器的uptime，level和tag。 以下命令显示如何使用默认设置获取JVM日志。

```
C:\Java9Revealed>java -Xlog --module-path com.jdojo.intro\dist
--module com.jdojo.intro/com.jdojo.intro.Welcome
```

显示部分输出：
```
[0.015s][info][os] SafePoint Polling address: 0x000001195fae0000
[0.015s][info][os] Memory Serialize Page address: 0x000001195fdb0000
[0.018s][info][biasedlocking] Aligned thread 0x000001195fb37f40 to 0x000001195fb38000
[0.019s][info][class,path   ] bootstrap loader class path=C:\java9\lib\modules
[0.019s][info][class,path   ] classpath:
[0.020s][info][class,path   ] opened: C:\java9\lib\modules
[0.020s][info][class,load   ] opened: C:\java9\lib\modules
[0.027s][info][os,thread    ] Thread is alive (tid: 17724).
[0.027s][info][os,thread    ] Thread is alive (tid: 6436).
[0.033s][info][gc           ] Using G1
[0.034s][info][startuptime  ] Genesis, 0.0083975 secs
[0.038s][info][class,load   ] java.lang.Object source: jrt:/java.base
[0.226s][info][os,thread               ] Thread finished (tid: 7584).
[0.226s][info][gc,heap,exit            ] Heap
[0.226s][info][gc,heap,exit            ]  Metaspace       used 6398K, capacity 6510K,
[0.226s][info][safepoint,cleanup       ] mark nmethods, 0.0000057 secs
[0.226s][info][os,thread               ] Thread finished (tid: 3660).
...
```

以下命令将所有具有至少gc严重级别debug或更高标记的消息记录到当前目录中具有时间装饰器的gc.log的文件。 请注意，该命令在标准输出上打印两行消息，这些消息来自Welcome类的main()方法。

```
C:\java9revealed>java -Xlog:gc*=trace:file=gc.log:time --module-path com.jdojo.intro\dist
--module com.jdojo.intro/com.jdojo.intro.Welcome
```

但是，显示了gc.log文件的部分输出，而不是标准输出上打印的内容。

```
[2017-02-11T08:40:23.942-0600]   Maximum heap size 2113804288
[2017-02-11T08:40:23.942-0600]   Initial heap size 132112768
[2017-02-11T08:40:23.942-0600]   Minimum heap size 6815736
[2017-02-11T08:40:23.942-0600] MarkStackSize: 4096k  MarkStackSizeMax: 16384k
[2017-02-11T08:40:23.966-0600] Heap region size: 1M
[2017-02-11T08:40:23.966-0600] WorkerManager::add_workers() : created_workers: 4
[2017-02-11T08:40:23.966-0600] Initialize Card Live Data
[2017-02-11T08:40:23.966-0600] ParallelGCThreads: 4
[2017-02-11T08:40:23.966-0600] WorkerManager::add_workers() : created_workers: 1
...
```

以下命令记录与上一个命令相同的消息，除了它记录没有任何装饰的消息：

```
C:\java9revealed>java -Xlog:gc*=trace:file=gc.log:none --module-path com.jdojo.intro\dist
--module com.jdojo.intro/com.jdojo.intro.Welcome

```

输出的部分消息为：

```
Maximum heap size 2113804288
   Initial heap size 132112768
   Minimum heap size 6815736
MarkStackSize: 4096k  MarkStackSizeMax: 16384k
Heap region size: 1M
WorkerManager::add_workers() : created_workers: 4
Initialize Card Live Data
ParallelGCThreads: 4
WorkerManager::add_workers() : created_workers: 1
...
```
以下命令记录与上一个命令相同的消息，除了它使用有10个文件的轮换文件集，大小为5MB，基本名称为gc.log：

```
C:\Java9Revealed>java -Xlog:gc*=trace:file=gc.log:none:filesize=m,filecount=10
--module-path com.jdojo.intro\dist --module com.jdojo.intro/com.jdojo.intro.Welcome
```

以下命令记录包含严重级别为debug或更高版本的gc标签的所有消息。 它关闭所有包含exit标签的消息。 它不会记录包含gc和exit标签的消息。 消息以默认装饰输出在stdout上。

```
C:\Java9Revealed>java -Xlog:gc*=debug,exit*=off --module-path com.jdojo.intro\dist
--module com.jdojo.intro/com.jdojo.intro.Welcome
```

以下显示部分输出。
```
[0.015s][info][gc,heap] Heap region size: 1M
[0.015s][debug][gc,heap] Minimum heap 8388608  Initial heap 132120576  Maximum heap 2113929216
[0.015s][debug][gc,ergo,refine] Initial Refinement Zones: green: 4, yellow: 12, red: 20, min yellow size: 8
[0.016s][debug][gc,marking,start] Initialize Card Live Data
[0.016s][debug][gc,marking      ] Initialize Card Live Data 0.024ms
[0.016s][debug][gc              ] ConcGCThreads: 1
[0.018s][debug][gc,ihop         ] Target occupancy update: old: 0B, new: 132120576B
[0.019s][info ][gc              ] Using G1
[0.182s][debug][gc,metaspace,freelist]    space @ 0x000001e7dbeb8260 704K,  99% used [0x000001e7fe880000, 0x000001e7fedf8400, 0x000001e7fee00000, 0x000001e7ff080000)
[0.191s][debug][gc,refine            ] Stopping 0
...
```
以下命令记录startuptime标签的信息，同时使用了hostname，uptime，level 和tag的装饰器。 所有其他设置都保留为默认设置。 它在info级别或更高级别记录消息，并将它们记录到stdout。 注意在命令中使用两个连续的冒号（：:）。 它们是必需的，因为没有指定输出目的地。

```
C:\Java9Revealed>java -Xlog:startuptime::hostname,uptime,level,tags
--module-path com.jdojo.intro\dist --module com.jdojo.intro/com.jdojo.intro.Welcome
```

输出信息为：

```
[0.015s][kishori][info][startuptime] StubRoutines generation 1, 0.0002574 secs
[0.019s][kishori][info][startuptime] Genesis, 0.0038339 secs
[0.019s][kishori][info][startuptime] TemplateTable initialization, 0.0000081 secs
[0.020s][kishori][info][startuptime] Interpreter generation, 0.0010698 secs
[0.032s][kishori][info][startuptime] StubRoutines generation 2, 0.0001518 secs
[0.032s][kishori][info][startuptime] MethodHandles adapters generation, 0.0000229 secs
[0.033s][kishori][info][startuptime] Start VMThread, 0.0001491 secs
[0.055s][kishori][info][startuptime] Initialize java.lang classes, 0.0224295 secs
[0.058s][kishori][info][startuptime] Initialize java.lang.invoke classes, 0.0015945 secs
[0.162s][kishori][info][startuptime] Create VM, 0.1550707 secs
Welcome to the Module System.
Module Name: com.jdojo.intro
```

## 三. 总结

JDK 9已经对平台类（JDK类）和JVM组件的日志系统进行了大修。有一个新的API可以指定所选择的日志记录框架作为从平台类记录消息的日志后端。还有一个新的命令行选项，可让从所有JVM组件访问消息。

平台日志API允许指定将由所有平台类用于记录其消息的自定义记录器。可以使用现有的日志记录框架，如Log4j作为记录器。该API由java.lang.System.LoggerFinder类和java.lang.System.Logger接口组成。

System.Logger接口的实例代表平台记录器。 System.LogFinder类是一个服务接口。需要为此服务接口提供一个实现，该接口返回System.Logger接口的实例。可以使用java.lang.System类中的getLogger()方法获取System.Logger。应用程序中的一个模块必须包含一个表示System.LogFinder服务接口实现的provides语句。否则，将使用默认记录器。

JDK 9允许使用-Xlog的单个选项从所有组件记录所有JVM消息。该选项允许指定消息的类型，消息的严重程度级别，日志目标，记录消息的装饰和日志文件属性。消息由一组标签标识。System.Logger.Level枚举的常量指定消息的严重程度级别。日志目标可以是stdout，stderr或一个文件。
