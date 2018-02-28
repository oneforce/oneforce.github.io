---
title: Java 9 Revealed Chapter 12 Process API
description: 转载其他人对于Process API的翻译
date: 2018-2-8 19:00:00
tags:	[Java9,jshell]
category: Java 9 Revealed
toc: true
comments: false
---

[原文地址](http://www.cnblogs.com/IcanFixIt/p/7214359.html)

在本章中，主要介绍以下内容：

* Process API是什么
* 如何创建本地进程
* 如何获取新进程的信息
* 如何获取当前进程的信息
* 如何获取所有系统进程的信息
* 如何设置创建，查询和管理本地进程的权限

## 一. Process API是什么

Process API 由接口和类组成，用来与本地进程一起工作，使用API，可以做以下事情：

* 从Java代码中创建新的本地进程
* 获取本地进程的进程句柄，无论它们是由Java代码还是通过其他方式创建
* 销毁运行进程
* 查询活动的进程及其属性
* 获取进程的子进程和父进程的列表
* 获取本地进程的进程ID（PID）
* 获取新创建的进程的输入，输出和错误流
* 等待进程终止
* 当进程终止时执行任务

Process API由java.lang包中的以下类和接口组成：

* Runtime
* ProcessBuilder
* ProcessBuilder.Redirect
* Process
* ProcessHandle
* ProcessHandle.Info

自Java 1.0以来，支持使用本地进程。`Process`类的实例表示由Java程序创建的本地进程。 通过调用`Runtime`类的`exec()`方法启动一个进程。

JDK 5.0添加了`ProcessBuilder`类，JDK 7.0添加了`ProcessBuilder.Redirect`的嵌套类。 `ProcessBuilder`类的实例保存一个进程的一组属性。 调用其`start()`方法启动本地进程并返回一个表示本地进程的Process类的实例。 可以多次调用其start()方法; 每次使用ProcessBuilder实例中保存的属性启动一个新进程。 在Java 5.0中，ProcessBuilder类接管`Runtime.exec()`方法来启动新进程。

在Java 7和Java 8中的Process API中有一些改进，就是在`Process`和`ProcessBuilder`类中添加几个方法。

在Java 9之前，Process API仍然缺乏对使用本地进程的基本支持，例如获取进程的PID和所有者，进程的开始时间，进程使用了多少CPU时间，多少本地进程正在运行等。请注意，在Java 9之前，可以启动本地进程并使用其输入，输出和错误流。 但是，无法使用未启动的本地进程，无法查询进程的详细信息。 为了更紧密地处理本地进程，Java开发人员不得不使用Java Native Interface（JNI）来编写本地代码。 Java 9使这些非常需要的功能与本地进程配合使用。

Java 9向Process API添加了一个名为`ProcessHandle`的接口。 `ProcessHandle`接口的实例标识一个本地进程; 它允许查询进程状态并管理进程。

比较`Process`类和`ProcessHandle`接口。 Process类的一个实例表示由当前Java程序启动的本地进程，而`ProcessHandle`接口的实例表示本地进程，无论是由当前Java程序启动还是以其他方式启动。 在Java 9中，已经在Process类中添加了几种方法，这些方法也可以在新的`ProcessHandle`接口中使用。 Process类包含一个返回`ProcessHandle`的`toHandle()`方法。

`ProcessHandle.Info`接口的实例表示进程属性的快照。 请注意，进程由不同的操作系统不同地实现，因此它们的属性不同。 过程的状态可以随时更改，例如，当进程获得更多CPU时间时，进程使用的CPU时间增加。 要获取进程的最新信息，需要在需要时使用`ProcessHandle`接口的`info()`方法，这将返回一个新的ProcessHandle.Info实例。

本章中的所有示例都在Windows 10中运行。当使用Windows 10或其他操作系统在机器上运行这些程序时，可能会得到不同的输出。

## 二. 当前进程

`ProcessHandle`接口的`current()`静态方法返回当前进程的句柄。 请注意，此方法返回的当前进程始终是正在执行代码的Java进程。

```java
// Get the handle of the current process
ProcessHandle current = ProcessHandle.current();
```

获取当前进程的句柄后，可以使用ProcessHandle接口的方法获取有关进程的详细信息。

> Tips

> 你不能杀死当前进程。 尝试通过使用`ProcessHandle`接口的`destroy()`或`destroyForcibly()`方法来杀死当前进程会导致`IllegalStateException`异常。


## 三. 查询进程状态

可以使用`ProcessHandle`接口中的方法来查询进程的状态。 下表列出了该接口常用的简单说明方法。 请注意，许多这些方法返回执行快照时进程状态的快照。 不过，由于进程是以异步方式创建，运行和销毁的，所以当稍后使用其属性时，所以无法保证进程仍然处于相同的状态。

|方法|描述|
|----|---|
|static Stream<ProcessHandle> allProcesses()	|返回操作系统中当前进程可见的所有进程的快照。|
|Stream<ProcessHandle> children()	|返回进程当前直接子进程的快照。 使用descendants()方法获取所有级别的子级列表，例如子进程，孙子进程进程等。返回当前进程可见的操作系统中的所有进程的快照。|
|static ProcessHandle current()	|返回当前进程的ProcessHandle，这是执行此方法调用的Java进程。|
|Stream<ProcessHandle> descendants()	|返回进程后代的快照。 与children()方法进行比较，该方法仅返回进程的直接后代。|
|boolean destroy()	|请求进程被杀死。 如果成功请求终止进程，则返回true，否则返回false。 是否可以杀死进程取决于操作系统访问控制。|
|boolean destroyForcibly()	|要求进程被强行杀死。 如果成功请求终止进程，则返回true，否则返回false。 杀死进程会立即强制终止进程，而正常终止则允许进程彻底关闭。 是否可以杀死进程取决于操作系统访问控制。|
|long getPid()	|返回由操作系统分配的进程的本地进程ID（PID）。 注意，PID可以由操作系统重复使用，因此具有相同PID的两个处理句柄可能不一定代表相同的过程。|
|ProcessHandle.Info info()	|返回有关进程信息的快照。|
|boolean isAlive()	|如果此ProcessHandle表示的进程尚未终止，则返回true，否则返回false。 请注意，在成功请求终止进程后，此方法可能会返回一段时间，因为进程将以异步方式终止。|
|static Optional<ProcessHandle> of(long pid)	|返回现有本地进程的Optional<ProcessHandle>。 如果具有指定pid的进程不存在，则返回空的Optional。|
|CompletableFuture <ProcessHandle> onExit()	|返回一个用于终止进程的CompletableFuture<ProcessHandle>。 可以使用返回的对象来添加在进程终止时执行的任务。 在当前进程中调用此方法会引发IllegalStateException异常。|
|Optional<ProcessHandle> parent()	|返回父进程的Optional<ProcessHandle>。|
|boolean supportsNormalTermination()	|如果destroy()的实现正常终止进程，则返回true。|

下表列出ProcessHandle.Info嵌套接口的方法和描述。 此接口的实例包含有关进程的快照信息。 可以使用ProcessHandle接口或Process类的info()方法获取ProcessHandle.Info。 接口中的所有方法都返回一个Optional。

|方法|描述|
|---|---|
|Optional<String[]> arguments()	|返回进程的参数。 该过程可能会更改启动后传递给它的原始参数。 在这种情况下，此方法返回更改的参数。|
|Optional<String> command()	|返回进程的可执行路径名。|
|Optional<String> commandLine()	|它是一个进程的组合命令和参数的便捷的方法。如果command()和arguments()方法都没有返回空Optional, 它通过组合从command()和arguments()方法返回的值来返回进程的命令行。|
|Optional<Instant> startInstant()	|返回进程的开始时间。 如果操作系统没有返回开始时间，则返回一个空Optional。|
|Optional<Duration> totalCpuDuration()	|返回进程使用的CPU时间。 请注意，进程可能运行很长时间，但可能使用很少的CPU时间。|
|Optional<String> user()	|返回进程的用户。|

现在是时候看到`ProcessHandle`和`ProcessHandle.Info`接口的实际用法。 本章中的所有类都在`com.jdojo.process.api`模块中，其声明如下所示。

```java
// module-info.java
module com.jdojo.process.api {
    exports com.jdojo.process.api;
}
```
接下来包含CurrentProcessInfo类的代码。 它的`printInfo()`方法将`ProcessHandle`作为参数，并打印进程的详细信息。 我们还在其他示例中使用此方法打印进程的详细信息。main()方法获取运行进程的当前进程的句柄，这是一个Java进程，并打印其详细信息。 你可能会得到不同的输出。 以下是当程序在Windows 10上运行时生成输出。

```java
// CurrentProcessInfo.java
package com.jdojo.process.api;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.Arrays;
public class CurrentProcessInfo {
    public static void main(String[] args) {
        // Get the handle of the current process
        ProcessHandle current = ProcessHandle.current();
        // Print the process details
        printInfo(current);
    }    
    public static void printInfo(ProcessHandle handle) {
        // Get the process ID
        long pid = handle.getPid();
        // Is the process still running
        boolean isAlive = handle.isAlive();
        // Get other process info
        ProcessHandle.Info info = handle.info();
        String command = info.command().orElse("");
        String[] args = info.arguments()
                            .orElse(new String[]{});
        String commandLine = info.commandLine().orElse("");
        ZonedDateTime startTime = info.startInstant()
                             .orElse(Instant.now())
                             .atZone(ZoneId.systemDefault());
        Duration duration = info.totalCpuDuration()
                                .orElse(Duration.ZERO);
        String owner = info.user().orElse("Unknown");
        long childrenCount = handle.children().count();
        // Print the process details
        System.out.printf("PID: %d%n", pid);        
        System.out.printf("IsAlive: %b%n", isAlive);
        System.out.printf("Command: %s%n", command);
        System.out.printf("Arguments: %s%n", Arrays.toString(args));
        System.out.printf("CommandLine: %s%n", commandLine);
        System.out.printf("Start Time: %s%n", startTime);
        System.out.printf("CPU Time: %s%n", duration);
        System.out.printf("Owner: %s%n", owner);
        System.out.printf("Children Count: %d%n", childrenCount);
    }
}
```

打印输出为：

```bash
PID: 8692
IsAlive: true
Command: C:\java9\bin\java.exe
Arguments: []
CommandLine:
Start Time: 2016-11-27T12:28:20.611-06:00[America/Chicago]
CPU Time: PT0.296875S
Owner: kishori\ksharan
Children Count: 1
```

## 四. 比较进程

比较两个进程是否相等等或顺序是否相同是棘手的。 不能依赖PID来处理相同的进程。 操作系统在进程终止后重用PID。 可以与PID一起检查流程的开始时间；如果两者相同，则两个过程可能相同。 `ProcessHandle`接口的默认实现的equals()方法检查以下三个信息，以使两个进程相等：

* 对于这两个进程，ProcessHandle接口的实现类必须相同。
* 进程必须具有相同的PID。
* 进程必须同一时间启动。

> Tips

> 在`ProcessHandle`接口中使用compareTo()方法的默认实现对于排序来说并不是很有用。 它比较了两个进程的PID。



## 五. 创建进程

需要使用ProcessBuilder类的实例来启动一个新进程。 该类包含几个方法来设置进程的属性。 调用`start()`方法启动一个新进程。 `start()`方法返回一个Process对象，可以使用它来处理进程的输入，输出和错误流。 以下代码段创建一个`ProcessBuilder`在Windows上启动JVM：

```java
ProcessBuilder pb = new ProcessBuilder()
                    .command("C:\\java9\\bin\\java.exe",
                             "--module-path",
                             "myModulePath",
                             "--module",
                             "myModule/className")
                    .inheritIO();
```

有两种方法来设置这个新进程的命令和参数：

* 可以将它们传递给`ProcessBuilder`类的构造函数。
* 可以使用command()方法。

没有参数的`command()`方法返回在`ProcessBuilder`中命令的设置的。 带有参数的其他版本 —— 一个带有一个String的可变参数，一个带有`List<String>`的版本，都用于设置命令和参数。 该方法的第一个参数是命令路径，其余的是命令的参数。

新进程有自己的输入，输出和错误流。 inheritIO()方法将新进程的输入，输出和错误流设置为与当前进程相同。 `ProcessBuilder`类中有几个`redirectXxx()`方法可以为新进程定制标准I/O，例如将标准错误流设置为文件，因此所有错误都会记录到文件中。 配置进程的所有属性后，可以调用start()来启动进程：

```java
// Start a new process
Process newProcess = pb.start();
```

可以多次调用`ProcessBuilder`类的`start()`方法来启动与之前保持的相同属性的多个进程。 这具有性能优势，可以创建一个ProcessBuilder实例，并重复使用它来多次启动相同的进程。

可以使用Process类的`toHandle()`方法获取进程的进程句柄：

```java
// Get the process handle
ProcessHandle handle = newProcess.toHandle();
```

可以使用进程句柄来销毁进程，等待进程完成，或查询进程的状态和属性，如其子进程，后代，父进程，使用的CPU时间等。有关进程的信息，对进程的控制取决于操作系统访问控制。

创建可以在所有操作系统上运行的进程都很棘手。 可以创建一个新进程启动新的JVM来运行一个类。

如下包含一个Job类的代码。 它的`main()`方法需要两个参数：睡眠间隔和睡眠持续时间（以秒为单位）。 如果没有参数传递，该方法将使用5秒和60秒作为默认值。 在第一部分中，该方法尝试提取第一个和第二个参数（如果指定）。 在第二部分中，它使用`ProcessHandle.current()`方法获取当前进程执行此方法的进程句柄。 它读取当前进程的PID并打印包括PID，睡眠间隔和睡眠持续时间的消息。 最后，它开始一个for循环，并持续休眠睡眠间隔，直到达到睡眠持续时间。 在循环的每次迭代中，它打印一条消息。

```java
// Job.java
package com.jdojo.process.api;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;
/**
 * An instance of this class is used as a job that sleeps at a
 * regular interval up to a maximum duration. The sleep
 * interval in seconds can be specified as the first argument
 * and the sleep duration as the second argument while running.
 * this class. The default sleep interval and sleep duration
 * are 5 seconds and 60 seconds, respectively. If these values
 * are less than zero, zero is used instead.
 */
public class Job {
    // The job sleep interval
    public static final long DEFAULT_SLEEP_INTERVAL = 5;
    // The job sleep duration
    public static final long DEFAULT_SLEEP_DURATION = 60;
    public static void main(String[] args) {
        long sleepInterval = DEFAULT_SLEEP_INTERVAL;
        long sleepDuration = DEFAULT_SLEEP_DURATION;
        // Get the passed in sleep interval
        if (args.length >= 1) {
            sleepInterval = parseArg(args[0], DEFAULT_SLEEP_INTERVAL);
            if (sleepInterval < 0) {
                sleepInterval = 0;
            }
        }
        // Get the passed in the sleep duration
        if (args.length >= 2) {
            sleepDuration = parseArg(args[1], DEFAULT_SLEEP_DURATION);
            if (sleepDuration < 0) {
                sleepDuration = 0;
            }
        }
        long pid = ProcessHandle.current().getPid();
        System.out.printf("Job (pid=%d) info: Sleep Interval" +        
                          "=%d seconds, Sleep Duration=%d " +  
                          "seconds.%n",
                          pid, sleepInterval, sleepDuration);
        for (long sleptFor = 0; sleptFor < sleepDuration;
                                sleptFor += sleepInterval) {
            try {
                System.out.printf("Job (pid=%d) is going to" +
                                  " sleep for %d seconds.%n",
                                  pid, sleepInterval);
                // Sleep for the sleep interval
                TimeUnit.SECONDS.sleep(sleepInterval);
            } catch (InterruptedException ex) {
                System.out.printf("Job (pid=%d) was " +
                                  "interrupted.%n", pid);
            }
        }
    }
    /**
     * Starts a new JVM to run the Job class.      
     * @param sleepInterval The sleep interval when the Job
     * class is run. It is passed to the JVM as the first
     * argument.
     * @param sleepDuration The sleep duration for the Job
     * class. It is passed to the JVM as the second argument.
     * @return The new process reference of the newly launched
     * JVM or null if the JVM cannot be launched.
     */
    public static Process startProcess(long sleepInterval,
                                       long sleepDuration) {
        // Store the command to launch a new JVM in a
        // List<String>
        List<String> cmd = new ArrayList<>();
        // Add command components in order
        addJvmPath(cmd);
        addModulePath(cmd);
        addClassPath(cmd);
        addMainClass(cmd);
        // Add arguments to run the class
        cmd.add(String.valueOf(sleepInterval));
        cmd.add(String.valueOf(sleepDuration));
        // Build the process attributes
        ProcessBuilder pb = new ProcessBuilder()
                                .command(cmd)
                                .inheritIO();
        String commandLine = pb.command()
                             .stream()
                             .collect(Collectors.joining(" "));
        System.out.println("Command used:\n" + commandLine);
        // Start the process
        Process p = null;
        try {
            p = pb.start();
        } catch (IOException e) {
            e.printStackTrace();
        }
        return p;
    }
    /**
     * Used to parse the arguments passed to the JVM, which
     * in turn is passed to the main() method.
     * @param valueStr The string value of the argument
     * @param defaultValue The default value of the argument if
     * the valueStr is not an integer.
     * @return valueStr as a long or the defaultValue if
     * valueStr is not an integer.
     */
    private static long parseArg(String valueStr,
                                 long defaultValue) {
        long value = defaultValue;
        if (valueStr != null) {
            try {
                value = Long.parseLong(valueStr);
            } catch (NumberFormatException e) {
                // no action needed
            }
        }
        return value;
    }
    /**
     * Adds the JVM path to the command list. It first attempts
     * to use the command attribute of the current process;
     * failing that it relies on the java.home system property.
     * @param cmd The command list
     */
    private static void addJvmPath(List<String> cmd) {
        // First try getting the command to run the current JVM
        String jvmPath = ProcessHandle.current()
                                      .info()
                                      .command().orElse("");
        if(jvmPath.length() > 0) {
            cmd.add(jvmPath);
        } else {
            // Try composing the JVM path using the java.home
            // system property
            final String FILE_SEPARATOR =
                 System.getProperty("file.separator");
            jvmPath = System.getProperty("java.home") +
                                    FILE_SEPARATOR +  "bin" +
                                    FILE_SEPARATOR + "java";      
            cmd.add(jvmPath);
        }
    }
    /**
     * Adds a module path to the command list.
     * @param cmd The command list
     */
    private static void addModulePath(List<String> cmd) {        
        String modulePath =
            System.getProperty("jdk.module.path");
        if(modulePath != null && modulePath.trim().length() > 0) {
            cmd.add("--module-path");
            cmd.add(modulePath);
        }
    }
    /**
     * Adds class path to the command list.
     * @param cmd The command list
     */
    private static void addClassPath(List<String> cmd) {        
        String classPath = System.getProperty("java.class.path");
        if(classPath != null && classPath.trim().length() > 0) {
            cmd.add("--class-path");
            cmd.add(classPath);
        }
    }
    /**
     * Adds a main class to the command list. Adds
     * module/className or just className depending on whether
     * the Job class was loaded in a named module or unnamed
     * module
     * @param cmd The command list
     */
    private static void addMainClass(List<String> cmd) {        
        Class<Job> cls = Job.class;
        String className = cls.getName();
        Module module = cls.getModule();
        if(module.isNamed()) {
            String moduleName = module.getName();
            cmd.add("--module");
            cmd.add(moduleName + "/" + className);
        } else {            
            cmd.add(className);
        }
    }
}
```

Job类包含一个启动新进程的`startProcess(long sleepInterval，long sleepDuration)`方法。 它以Job类作为主类启动一个JVM。 将睡眠间隔和持续时间作为参数传递给JVM。 该方法尝试构建一个从JDK_HOME\bin目录下启动java的命令。 如果Job类被加载到一个命名的模块中，它将生成一个如下命令：

```bash
JDK_HOME\bin\java --module-path <module-path> --module com.jdojo.process.api/com.jdojo.process.api.Job <sleepInterval> <sleepDuration>
```

如果Job类被加载到一个未命名的模块中，它将尝试构建如下命令：

```bash
JDK_HOME\bin\java -class-path <class-path> com.jdojo.process.api.Job <sleepInterval> <sleepDuration>
```

`startProcess()`方法打印用于启动进程的命令，尝试启动进程，并返回进程引用。

`addJvmPath()`方法将JVM路径添加到命令列表中。 它尝试获取当前JVM进程的命令作为新进程的JVM路径。 如果它不可用，将尝试从java.home系统属性构建它。

Job类包含几个实用程序方法，用于构成命令的一部分并解析参数并传递给main()方法。 具体请参考Javadoc的说明。

如果要启动一个新进程，运行15秒钟并且每5秒钟唤醒，可以使用Job类的startProcess()方法：

```java
// Start a process that runs for 15 seconds
Process p = Job.startProcess(5, 15);
```

可以使用CurrentProcessInfo类的`printInfo()`方法来打印进程细节：

```java
// Get the handle of the current process
ProcessHandle handle = p.toHandle();
// Print the process details
CurrentProcessInfo.printInfo(handle);
```

当进程终止时，可以使用ProcessHandle的onExit()方法的返回值来运行任务。

```java
CompletableFuture<ProcessHandle> future = handle.onExit();
// Print a message when process terminates
future.thenAccept((ProcessHandle ph) -> {
    System.out.printf("Job (pid=%d) terminated.%n", ph.getPid());
});
```

可以等待新进程终止：

```java
// Wait for the process to terminate
future.get();
```

在这个例子中，future.get()返回进程的ProcessHandle。 没有使用返回值，因为已经在handle变量中。

下面包含了StartProcessTest类的代码，它显示了如何使用Job类创建一个新进程。 在`main()`方法中，它创建一个新进程，打印进程详细信息，向进程添加关闭任务，等待进程终止，并再次打印进程细节。 请注意，该进程运行15秒，但它仅使用0.359375秒的CPU时间，因为大多数时间进程的主线程正在休眠。 以下输入结果当程序在Windows 10上运行时生成输出。

```java
// StartProcessTest.java
package com.jdojo.process.api;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;
public class StartProcessTest {
    public static void main(String[] args) {
        // Start a process that runs for 15 seconds
        Process p = Job.startProcess(5, 15);
        if (p == null) {
            System.out.println("Could not create a new process.");
            return;
        }
        // Get the handle of the current process
        ProcessHandle handle = p.toHandle();
        // Print the process details
        CurrentProcessInfo.printInfo(handle);
        CompletableFuture<ProcessHandle> future = handle.onExit();
        // Print a message when process terminates
        future.thenAccept((ProcessHandle ph) -> {
            System.out.printf("Job (pid=%d) terminated.%n", ph.getPid());
        });
        try {
            // Wait for the process to complete
            future.get();
        } catch (InterruptedException | ExecutionException e) {
            e.printStackTrace();
        }
        // Print process details again
        CurrentProcessInfo.printInfo(handle);
    }
}

```

输出结果为：

```bash
C:\java9\bin\java.exe --module-path
C:\Java9Revealed\com.jdojo.process.api\build\classes --class-path
C:\Java9Revealed\com.jdojo.process.api\build\classes --module
com.jdojo.process.api/com.jdojo.process.api.Job 5 15
PID: 10928
IsAlive: true
Command: C:\java9\bin\java.exe
Arguments: []
CommandLine:
Start Time: 2016-11-28T13:43:28.318-06:00[America/Chicago]
CPU Time: PT0S
Owner: kishori\ksharan
Children Count: 1
Job (pid=10928) info: Sleep Interval=5 seconds, Sleep Duration=15 seconds.
Job (pid=10928) is going to sleep for 5 seconds.
Job (pid=10928) is going to sleep for 5 seconds.
Job (pid=10928) is going to sleep for 5 seconds.
Job (pid=10928) terminated.
PID: 10928
IsAlive: false
Command:
Arguments: []
CommandLine:
Start Time: 2016-11-28T13:43:28.318-06:00[America/Chicago]
CPU Time: PT0.359375S
Owner: kishori\ksharan
Children Count: 0
```


## 六. 获取进程句柄

有几种方法来获取本地进程的句柄。 对于由Java代码创建的进程，可以使用Process类的`toHandle()`方法获取一个`ProcessHandle`。 本地进程也可以从JVM外部创建。 ProcessHandle接口包含以下方法来获取本地进程的句柄：

* static Optional<ProcessHandle> of(long pid)
* static ProcessHandle current()
* Optional<ProcessHandle> parent()
* Stream<ProcessHandle> children()
* Stream<ProcessHandle> descendants()
* static Stream<ProcessHandle> allProcesses()

`of()`静态方法返回指定pid的`Optional<ProcessHandle>`。 如果没有此pid的进程，则返回一个空Optional。 要使用此方法，需要知道进程的PID：

```java
// Get the process handle of the process with the pid of 1234
Optional<ProcessHandle> handle = ProcessHandle.of(1234L);
```

静态`current()`方法返回当前进程的句柄，它始终是执行代码的Java进程。

`parent()`方法返回父进程的句柄。 如果进程没有父进程或父进程无法检索，则返回一个空Optional。

`children()`方法返回进程的所有直接子进程的快照。 不能保证此方法返回的进程仍然存在。 请注意，一个不存在的进程没有子进程。

`descendants()`方法返回直接或间接进程的所有子进程的快照。

`allProcesses()`方法返回对此进程可见的所有进程的快照。 不保证流在流处理时包含操作系统中的所有进程。

获取快照后，进程可能已被终止或创建。 以下代码段打印按其PID排序的所有进程的PID：

```java
System.out.printf("All processes PIDs:%n");
ProcessHandle.allProcesses()                    
             .map(ph -> ph.getPid())
             .sorted()                
             .forEach(System.out::println);
```

可以为所有运行的进程计算不同类型的统计信息。 还可以在Java中创建一个任务管理器，显示一个UI，显示所有正在运行的进程及其属性。 下面代码显示了如何获得运行时间最长的进程细节以及最多使用CPU时间的进程。 比较了进程的开始时间，以获得最长的运行进程和总CPU持续时间，以获得使用CPU时间最多的进程。 你可能会得到不同的输出。 代码在Windows 10上运行程序时，得到了这个输出。

```java
// ProcessStats.java
package com.jdojo.process.api;
import java.time.Duration;
import java.time.Instant;
public class ProcessStats {
    public static void main(String[] args) {
        System.out.printf("Longest CPU User Process:%n");
        ProcessHandle.allProcesses()
                     .max(ProcessStats::compareCpuTime)
                     .ifPresent(CurrentProcessInfo::printInfo);
        System.out.printf("%nLongest Running Process:%n");
        ProcessHandle.allProcesses()
                     .max(ProcessStats::compareStartTime)
                     .ifPresent(CurrentProcessInfo::printInfo);
    }
    public static int compareCpuTime(ProcessHandle ph1,
                                     ProcessHandle ph2) {
        return ph1.info()
                .totalCpuDuration()
                .orElse(Duration.ZERO)
                .compareTo(ph2.info()
                        .totalCpuDuration()
                        .orElse(Duration.ZERO));
    }
     public static int compareStartTime(ProcessHandle ph1,
                                        ProcessHandle ph2) {
        return ph1.info()
                .startInstant()
                .orElse(Instant.now())
                .compareTo(ph2.info()
                        .startInstant()
                        .orElse(Instant.now()));
    }
}
```

输出结果为：

```bash
Longest CPU User Process:
PID: 10696
IsAlive: true
Command: C:\Program Files (x86)\Google\Chrome\Application\chrome.exe
Arguments: []
CommandLine:
Start Time: 2016-11-28T10:12:08.537-06:00[America/Chicago]
CPU Time: PT14M26.5S
Owner: kishori\ksharan
Children Count: 0
Longest Running Process:
PID: 0
IsAlive: false
Command:
Arguments: []
CommandLine:
Start Time: 2016-11-29T13:18:22.262776600-06:00[America/Chicago]
CPU Time: PT0S
Owner: Unknown
Children Count: 127
```

## 七. 终止进程

可以使用`ProcessHandle`接口和`Process`类的`destroy()`或`destroyForcibly()`方法终止进程。 如果终止进程的请求成功，则两个方法都返回true，否则返回false。 `destroy()`方法请求正常终止，而`destroyForcibly()`方法请求强制终止。 在执行终止进程的请求后，`isAlive()`方法可以在短时间内返回true。

> Tips

> 无法终止当前进程。 调用当前进程中的`destroy()`或`destroyForcibly()`方法会引发`IllegalStateException`异常。 操作系统访问控制可能会阻止进程终止。

一个进程的正常终止让进程彻底终止。 强制终止流程将立即终止流程。 进程是否正常终止是依赖于实现的。 可以使用`ProcessHandle`接口的supportsNormalTermination()方法和Process类来检查进程是否支持正常终止。 如果进程支持正常终止，该方法返回true，否则返回false。

调用这些方法来终止已经被终止的进程导致没有任何操作。 当进程结束后，`Process`类的`onExit()`返`CompletableFuture<Process>`，`ProcessHandle`接口的`onExit()`方法返回`CompletableFuture<ProcessHandle>`。


## 八. 管理进程权限

运行上一节中的示例时，认为没有安装Java安全管理器。 如果安装了安全管理器，则需要授予适当的权限才能启动，管理和查询本地进程：

如果要创建新进程，则需要具有`FilePermission(cmd,"execute")`权限，其中cmd是将创建进程的命令的绝对路径。 如果cmd不是绝对路径，则需要具有`FilePermission("<<ALL FILES>>","execute")`权限。

使用`ProcessHandle`接口中的方法来查询本地进程的状态并销毁进程，应用程序需要具有`RuntimePermission("manageProcess")`权限。
下面包含一个获取进程计数并创建新进程的程序。 它重复这两个任务，一个任务没有安全管理员权限，而另一个任务有安全管理员权限。

```java
// ManageProcessPermission.java
package com.jdojo.process.api;
import java.util.concurrent.ExecutionException;
public class ManageProcessPermission {    
    public static void main(String[] args) {
        // Get the process count
        long count = ProcessHandle.allProcesses().count();
        System.out.printf("Process Count: %d%n", count);
        // Start a new process
        Process p = Job.startProcess(1, 3);
        try {
            p.toHandle().onExit().get();
        } catch (InterruptedException | ExecutionException e) {
            System.out.println(e.getMessage());
        }
        // Install a security manager
        SecurityManager sm = System.getSecurityManager();
        if(sm == null) {
            System.setSecurityManager(new SecurityManager());
            System.out.println("A security manager is installed.");
        }
        // Get the process count
        try {
            count = ProcessHandle.allProcesses().count();
            System.out.printf("Process Count: %d%n", count);
        } catch(RuntimeException e) {
            System.out.println("Could not get a " +
                          "process count: " + e.getMessage());
        }
        // Start a new process
        try {
            p = Job.startProcess(1, 3);
            p.toHandle().onExit().get();
        } catch (InterruptedException | ExecutionException |
                 RuntimeException e) {
            System.out.println("Could not start a new " +
                               "process: " + e.getMessage());
        }
    }
}
```
假设没有更改任何Java策略文件，请尝试使用以下命令运行ManageProcessPermission类：

```bash
C:\Java9Revealed>java --module-path
C:\Java9Revealed\com.jdojo.process.api\build\classes --module
com.jdojo.process.api/com.jdojo.process.api.ManageProcessPermission
```

输出结果为：

```bash
Command used:
C:\java9\bin\java.exe --module-path
C:\Java9Revealed\com.jdojo.process.api\build\classes --module
com.jdojo.process.api/com.jdojo.process.api.Job 1 3
Job (pid=6320) info: Sleep Interval=1 seconds, Sleep Duration=3 seconds.
Job (pid=6320) is going to sleep for 1 seconds.
Job (pid=6320) is going to sleep for 1 seconds.
Job (pid=6320) is going to sleep for 1 seconds.
A security manager is installed.
Could not get a process count: access denied ("java.lang.RuntimePermission" "manageProcess")
Could not start a new process: access denied ("java.lang.RuntimePermission" "manageProcess")
```

你可能会得到不同的输出。 输出表示可以在安装安全管理器之前获取进程计数并创建新进程。 安装安全管理器后，Java运行时会在请求进程计数和创建新进程时抛出异常。 要解决此问题，需要授予以下四个权限：

“manageProcess” 运行时权限，它将允许应用程序查询本地进程并创建一个新进程。
在Java命令路径上“execute” 文件权限，这将允许启动JVM。
在系统属性“jdk.module.path”和“java.class.path”中“read”的属性权限，因此在创建命令行以启动JVM时，Job类可以读取这些属性。
如下包含一个脚本，将这四个权限授予所有代码。 需要将此脚本添加到计算机上的JDK_HOME\conf\security\java.policy文件中。 Java启动器的路径是C:\java9\bin\java.exe，只有在C:\java9目录中安装了JDK 9，才在Windows上有效。 对于所有其他平台和JDK安装，请修改此路径以指向计算机上正确的Java启动器。

```
grant {
    permission java.lang.RuntimePermission "manageProcess";
    permission java.io.FilePermission "C:\\java9\\bin\\java.exe", "execute";
    permission java.util.PropertyPermission "jdk.module.path", "read";
    permission java.util.PropertyPermission "java.class.path", "read";
};
```

如果使用相同的命令再次运行`ManageProcessPermission`类，则应该获得类似于以下内容的输出：

```
Process Count: 133
Command used:
C:\java9\bin\java.exe --module-path
C:\Java9Revealed\com.jdojo.process.api\build\classes --module
com.jdojo.process.api/com.jdojo.process.api.Job 1 3
Job (pid=3108) info: Sleep Interval=1 seconds, Sleep Duration=3 seconds.
Job (pid=3108) is going to sleep for 1 seconds.
Job (pid=3108) is going to sleep for 1 seconds.
Job (pid=3108) is going to sleep for 1 seconds.
A security manager is installed.
Process Count: 133
Command used:
C:\java9\bin\java.exe --module-path
C:\Java9Revealed\com.jdojo.process.api\build\classes --module
com.jdojo.process.api/com.jdojo.process.api.Job 1 3
Job (pid=3684) info: Sleep Interval=1 seconds, Sleep Duration=3 seconds.
Job (pid=3684) is going to sleep for 1 seconds.
Job (pid=3684) is going to sleep for 1 seconds .
Job (pid=3684) is going to sleep for 1 seconds.
```

## 九. 总结

Process API由使用本地进程的类和接口组成。 Java SE从版本1.0通过运行时和进程类提供了Process API。 它允许创建新的本地进程，管理其I/O流并销毁它们。 Java SE的更新版本改进了API。 直到Java 9，开发人员必须诉诸编写本地代码来获取基本信息，例如进程的ID，用于启动进程的命令等。Java 9添加了一个名为ProcessHandle的接口，表示进程句柄。 可以使用进程句柄来查询和管理本地进程。

以下类和接口组成了Process API：`Runtime`，`ProcessBuilder`，`ProcessBuilder.Redirect`，`Process`，`ProcessHandle`和`ProcessHandle.Info`。

Runtime类的`exec()`方法用于启动本地进程。

`ProcessBuilder`类的`start()`方法是优先于Runtime类的`exec()`方法来启动进程。 `ProcessBuilder.Redirect`类的实例表示进程的进程输入源或进程的目标输出。

`Process`类的实例表示由Java程序创建的本地进程。

`ProcessHandle`接口的实例表示由Java程序或其他方式创建的进程。它在Java 9中添加，并提供了几种方法来查询和管理进程。 `ProcessHandle.Info`接口的实例表示进程的快照信息; 它可以使用`Process`类或`ProcessHandle`接口的`info()`方法获得。 如果有一个进程实例，使用它的`toHandle()`方法获得一个`ProcessHandle`。

`ProcessHandle`接口的`onExit()`方法返回一个用于终止进程的`CompletableFuture<ProcessHandle>`。 可以使用返回的对象来添加在进程终止时执行的任务。 请注意，不能在当前进程中使用此方法。

如果安装了一个安全管理器，则应用程序需要有一个“manageProcess”运行时权限来查询和管理本地进程，并在Java代码启动的进程的命令文件上“execute” 文件权限。
