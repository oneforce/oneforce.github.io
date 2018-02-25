


[原文地址](http://www.cnblogs.com/IcanFixIt/p/7199108.html)

在本章节中，主要介绍以下内容：

* 什么是Java shell
* JShell工具和JShell API是什么
* 如何配置JShell工具
* 如何使用JShell工具对Java代码片段求值
* 如何使用JShell API对Java代码片断求值

## 一. 什么是Java shell

Java Shell在JDK 9中称为JShell，是一种提供交互式访问Java编程语言的命令行工具。 它允许对Java代码片段求值，而不是强制编写整个Java程序。 它是Java的REPL（Read-Eval-Print loop）。 JShell也是一个API，可用于开发应用程序以提供与JShell命令行工具相同的功能。

REPL（Read-Eval-Print loop）是一种命令行工具（也称为交互式编程语言环境），可让用户快速求出代码片段的值，而无需编写完整的程序。 REPL来自Lisp语言的循环语句中read，eval和print中使用的三个原始函数。 read功能读取用户输入并解析成数据结构；eval函数评估已解析的用户输入以产生结果；print功能打印结果。 打印结果以后，该工具已准备好再次接受用户输入，从而Read-Eval-Print 循环。 术语REPL用于交互式工具，可与编程语言交互。 图下显示了REPL的概念图。 UNIX shell或Windows命令提示符的作用类似于读取操作系统命令的REPL，执行它，打印输出，并等待读取另一个命令。

![]()

为什么JDK 9中引入了JShell？ 将其包含在JDK 9中的主要原因之一是来自学术界的反馈，其学习曲线陡峭。 再是其他编程语言（如Lisp，Python，Ruby，Groovy和Clojure）一直支持REPL已经很长一段时间。 只要在Java中编写一个“Hello，world！”程序，你就必须使用一个编辑 - 编译 - 执行循环（Edit-Compile-Execute loop）来编写一个完整的程序，编译它并执行它。 如果需要进行更改，则必须重复以下步骤。 除了定义目录结构，编译和执行程序等其他内务工作外，以下是使用JDK 9中的模块化Java程序打印“Hello，world！”消息的最低要求：

```
// module-info.java
module HelloWorld {
}
```
```
// HelloWorld.java
package com.jdojo.intro;
public class HelloWorld {
    public static void main(String[] args) {
        System.out.println("Hello, world!");
    }
}
```

此程序执行时，会在控制台上打印一条消息：“Hello，world！”。 编写一个完整的程序来对一个简单表达式求值，如这样就是过分的。 这是学术界不会将Java作为初始编程语言教授给学生的主要原因。 Java设计人员听取了教学团体的反馈意见，并在JDK 9中介绍了JShell工具。要实现与此程序相同的操作，只需在jshell命令提示符下只写一行代码：

```
jshell> System.out.println("Hello, world!")
Hello, world!
jshell>
```

第一行是在jshell命令提示符下输入的代码; 第二行是输出。 打印输出后，jshell提示符返回，可以输入另一个表达式进行求值。

> Tips
> JShell不是一种新的语言或编译器。 它是一种交互式访问Java编程语言的工具和API。 对于初学者，它提供了一种快速探索Java编程语言的方法。 对于有经验的开发人员，它提供了一种快速的方式来查看代码段的结果，而无需编译和运行整个程序。 它还提供了一种使用增量方法快速开发原型的方法。 添加一段代码，获取即时反馈，并添加另一个代码片段代码，直到原型完成。

JDK 9附带了一个JShell命令行工具和JShell API。 该工具支持的所有功能API也同样支持。 也就是说，可以使用工具运行代码片段或使用API以编程方式运行代码段。

## 二. JShell架构

Java编译器不能自己识别代码段，例如方法声明或变量声明。 只有类和`import`语句可以是顶层结构，它们可以自己存在。 其他类型的片段必须是类的一部分。 JShell允许执行Java代码片段，并进行改进。

目前JShell架构的指导原则是使用JDK中现有的Java语言支持和其他Java技术来保持与当前和将来版本的语言兼容。 随着Java语言随着时间的推移而变化，对JShell的支持也将受到JShell实现而修改。 图下显示了JShell的高层次体系结构。

![]()

JShell工具使用版本2的JLine，它是一个用于处理控制台输入的Java库。 标准的JDK编译器不知道如何解析和编译Java代码片断。 因此，JShell实现具有自己的解析器，解析片段并确定片段的类型，例如方法声明，变量声明等。一旦确定了片段类型，包装在合成类的代码片段遵循以下规则：

* 导入语句作为“as-is”使用。 也就是说，所有导入语句都按原样放置在合成类的顶部。
* 变量，方法和类声明成为合成类的静态成员。
* 表达式和语句包含在合成类中的合成方法中。

所有合成类都属于REPL的包。 一旦片段被包装，包装的源代码由标准Java编译器使用Compiler API进行分析和编译。 编译器将包装的源代码以字符串格式作为输入，并将其编译为字节码，该字节码存储在内存中。 生成的字节码通过套接字发送到运行JVM的远程进程，用于加载和执行。 有时，加载到远程JVM中的现有代码片段需要由JShell工具替代，该工具使用Java Debugger API来实现。

## 三. JShell 工具

JDK 9带一个位于JDK_HOME\bin目录中的JShell工具。 该工具名为jshell。 如果在Windows上的C:\java9目录中安装了JDK 9，那么将有一个C:\java9\bin\jshell.exe的可执行文件，它是JShell工具。 要启动JShell工具，需要打开命令提示符并输入jshell命令：

```
C:\Java9Revealed>jshell
|  Welcome to JShell -- Version 9-ea
|  For an introduction type: /help intro
jshell>
```

在命令提示符下输入jshell命令可能会报出一个错误：

```
C:\Java9Revealed>jshell
'jshell' is not recognized as an internal or external command,
operable program or batch file.
C:\Java9Revealed>
```

此错误表示JDK_HOME\bin目录未包含在计算机上的PATH环境变量中。 在C:\java9目录中安装了JDK 9，所以JDK_HOME是C:\java9。 要解决此错误，可以在PATH环境变量中包含C:\java9\bin目录，或者使用jshell命令的完整路径：C:\java9\bin\jshell。 以下命令序列显示如何在Windows上设置PATH环境变量并运行JShell工具：

```
C:\Java9Revealed>SET PATH=C:\java9\bin;%PATH%
C:\Java9Revealed>jshell
|  Welcome to JShell -- Version 9-ea
|  For an introduction type: /help intro
jshell>
```

当jshell成功启动时，它会打印一个欢迎消息及其版本信息。 它还有一个打印命令，这是/ help intro。 可以使用此命令打印工具本身的简短介绍：

```
jshell> /help intro
|
|  intro
|
|  The jshell tool allows you to execute Java code, getting immediate results.
|  You can enter a Java definition (variable, method, class, etc), like:  int x = 8
|  or a Java expression, like:  x + x
|  or a Java statement or import.
|  These little chunks of Java code are called 'snippets'.
|
|  There are also jshell commands that allow you to understand and
|  control what you are doing, like:  /list
|
|  For a list of commands: /help
jshell>
```

如果需要关于该工具的帮助，可以在jshell上输入命令/ help，以简短描述打印一份命令列表：

```
jshell> /help
<<The output is not shown here.>>
jshell>
```

可以使用几个命令行选项与jshell命令将值传递到工具本身。例如，可以将值传递给用于解析和编译代码段的编译器，以及用于执行/求值代码段的远程JVM。使用--help选项运行jshell程序，以查看所有可用的标准选项的列表。使用`--help-extra`或`-X`选项运行它以查看所有可用的非标准选项的列表。例如，使用这些选项，可以为JShell工具设置类路径和模块路径。

还可以使用命令行`--start`选项自定义jshell工具的启动脚本。可以使用`DEFAULT`和`PRINTING`作为此选项的参数。 `DEFAULT`参数使用多个`import`语句启动jshell，因此在使用jshell时不需要导入常用的类。以下两个命令以相同的方式启动jshell：如果需要对该工具的帮助，可以在jshell上输入命令`/help`，以简单描述打印命令列表：

```
jshell
jshell --start DEFAULT
```

可以使用`System.out.println()`方法将消息打印到标准输出。 可以使用带有PRINTING参数的`--start`选项启动jshell，该参数将包括`System.out.print()`，`System.out.println()`和`System.out.printf()`方法的所有版本作为`print()`，`println()`和`printf()`的上层方法。 这将允许在jshell上使用`print()`，`println()`和`printf()`方法，而不是使用更长版本的`System.out.print()`，`System.out.println()`和`System.out.printf()`。

```
C:\Java9Revealed>jshell --start PRINTING
|  Welcome to JShell -- Version 9-ea
|  For an introduction type: /help intro
jshell> println("hello")
hello
jshell>
```

当启动jshell以包括默认的导入语句和打印方法时，可以重复--start选项：

```
C:\Java9Revealed>jshell --start DEFAULT --start PRINTING
|  Welcome to JShell -- Version 9-ea
|  For an introduction type: /help intro
jshell>
```

## 四. 退出JShell工具

要退出jshell，请在jshell提示符下输入/exit，然后按Enter键。 该命令打印一个再见消息，退出该工具，并返回到命令提示符：

```
C:\Java9Revealed>jshell
|  Welcome to JShell -- Version 9-ea
|  For an introduction type: /help intro
jshell> /exit
|  Goodbye
C:\Java9Revealed>
```

## 五. 什么是片段和命令？

你可以使用JShell工具：

* 对Java代码片段求值，这在JShell术语中简称为片段。
* 执行命令，用于查询JShell状态并设置JShell环境。

要区分命令和片段，所有命令都以斜杠（/）开头。 您已经在之前的部分中看到过其中的一些，如`/exit`和`/help`。 命令用于与工具本身进行交互，例如定制其输出，打印帮助，退出工具以及打印命令和代码段的历史记录。了解有关可用命令的全部信息，请使用`/help`命令。

使用JShell工具，一次编写一个Java代码片段并对其进行求值。 这些代码段被称为片段。 片段必须遵循Java语言规范中指定的语法。 片段可以是：

* 导入声明
* 类声明
* 接口声明
* 方法声明
* 字段声明
* 语句
* 表达式

> Tips
> 可以使用JShell中的所有Java语言结构，但包声明除外。 JShell中的所有片段都出现在名为REPL的内部包中，并在内部合成类中。

JShell工具知道何时完成输入代码段。 当按Enter键时，该工具将执行该片段，如果它完成或带你到下一行，并等待完成该片段。 如果一行以...开头，则表示代码段不完整，需要输入更多文本才能完成代码段。 可以自定义更多输入的默认提示，即...>。 以下是几个例子：

```
C:\Java9Revealed>jshell
|  Welcome to JShell -- Version 9-ea
|  For an introduction type: /help intro
jshell> 2 + 2
$1 ==> 4
jshell> 2 +
   ...> 2
$2 ==> 4
jshell> 2
$3 ==> 2
jshell>
```

当输入`2 + 2`并按Enter键时，jshell将其视为完整的片段（表达式）。 它对表达式求值并将反馈打印到`4`，并将结果分配给名为`$1`的变量。 名为`$1`的变量由JShell工具自动生成。 当输入`2 +`并按Enter键时，jshell会提示输入更多内容，因为`2 +`不是Java中的完整代码段。 当在第二行输入`2`时，代码段已完成； jshell对片段求值并打印反馈。 当输入`2`并按Enter键时，jshell对代码片段求值，因为2本身是一个完整的表达式。

## 六. 表达式求值

可以在jshell中执行任何有效的Java表达式。 比如以下示例：

```
jshell> 2 + 2
$1 ==> 4
jshell> 9.0 * 6
$2 ==> 54.0
```

在第一个表达式中 计算结果4被分配给临时变量$1，第二个表达式的结果分配给了$2， 你可以直接使用这些变量：

```
jshell> $1
$1 ==> 4
jshell> $2
$2 ==> 54.0
jshell> System.out.println($1)
4
jshell> System.out.println($2)
54.0
```

> Tips
> 在jshell中，不需要使用分号来终止语句。 工具将为你插入缺少的分号。

在Java中，每个变量都有一个数据类型。 在这些示例中，`$1`和`$2`的变量的数据类型是什么？ 在Java中，`2 + 2`计算结果为`int`，`9.0 * 6`求值为`double`类型。 因此，`$1`和`$2`变量的数据类型应分别为`int`和`double`。 你如何验证这个？ 可以将`$1`和`$2`转换成`Object`对象，并调用它们的`getClass()`方法，结果应为`Integer`和 `Double`对象。 当把它们转换为`Object`时，基本类型`int`和`double`类型进行自动装箱：

```
jshell> 2 + 2
$1 ==> 4
jshell> 9.0 * 6
$2 ==> 54.0
jshell> ((Object)$1).getClass()
$3 ==> class java.lang.Integer
jshell> ((Object)$2).getClass()
$4 ==> class java.lang.Double
jshell>
```

有一个更简单的方法来确定由jshell创建的变量的数据类型 ——只需要告诉jshell给你详细的反馈，它将打印它创建的变量的数据类型的更多信息！ 以下命令将反馈模式设置为详细并对相同的表达式求值：

```
jshell> /set feedback verbose
|  Feedback mode: verbose
jshell> 2 + 2
$1 ==> 4
|  created scratch variable $1 : int
jshell> 9.0 * 6
$2 ==> 54.0
|  created scratch variable $2 : double
jshell>
```

jshell分别为`$1`和`$2`的变量的数据类型打印为`int`和`double`。 初学者使用`-retain`选项执行以下命令获得更多帮助，因此详细的反馈模式将在jshell会话中持续存在：

```
jshell> /set feedback -retain verbose
```

还可以使用/vars命令列出在jshell中定义的所有变量：

```
jshell> /vars
|    int $1 = 4
|    double $2 = 54.0
jshell>
```

如果要再次使用正常的反馈模式，请使用以下命令：

```
jshell> /set feedback -retain normal
|  Feedback mode: normal
Jshell>
```

不限于评估简单的表达式，例如`2 + 2`。可以对任何Java表达式求值。 以下示例字符串连接表达式并使用`String`类的方法。 它还显示了如何使用`for`循环：

```
jshell> "Hello " + "world! " + 2016
$1 ==> "Hello world! 2016"
jshell> $1.length()
$2 ==> 17
jshell> $1.toUpperCase()
$3 ==> "HELLO WORLD! 2016"
jshell> $1.split(" ")
$4 ==> String[3] { "Hello", "world!", "2016" }
jshell> for(String s : $4) {
   ...> System.out.println(s);
   ...> }
Hello
world!
2016
jshell>
```

## 七. 列表片段

无论在jshell中输入的内容最终都是片段的一部分。 每个代码段都会分配一个唯一的代码段ID，可以稍后引用该代码段，例如删除该代码段。 /list命令列出所有片段。 它有以下形式：

```
/list
/list -all
/list -start
/list <snippet-name>
/list <snippet-id>
```

没有参数或选项的`/list`命令打印所有用户输入的有效代码片段，这些片段也可能是使用`/open`命令从文件中打开的。

使用`-all`选项列出所有片段——有效的，无效的，错误的和启动时的。

使用`-start`选项仅列出启动时代码片段。 启动片段被缓存，并且`-start`选项打印缓存的片段。 即使在当前会话中删除它们，它也会打印启动片段。

一些片段类型有一个名称（例如，变量，方法声明），所有片段都有一个ID。 `/list`命令使用代码片段的名称或ID将打印由该名称或ID标识的片段。

`/list`命令以以下格式打印片段列表：

```
<snippet-id> : <snippet-source-code>
<snippet-id> : <snippet-source-code>
<snippet-id> : <snippet-source-code>
...
```

JShell工具生成唯一的代码段ID。 它们是s1，s2，s3 ...，用于启动片段，1，2，3 ...等都是有效的片段，e1，e2，e3 ...用于错误的片段。 以下jshell会话将显示如何使用`/list`命令列出片段。 这些示例演示了`/drop`命令来使用代码段名称和代码段ID来删除片段。

```
C:\Java9Revealed>jshell
|  Welcome to JShell -- Version 9-ea
|  For an introduction type: /help intro
jshell> /list
jshell> 2 + 2
$1 ==> 4
jshell> /list
   1 : 2 + 2
jshell> int x = 100
x ==> 100
jshell> /list
   1 : 2 + 2
   2 : int x = 100;
jshell> /list -all
  s1 : import java.io.*;
  s2 : import java.math.*;
  s3 : import java.net.*;
  s4 : import java.nio.file.*;
  s5 : import java.util.*;
  s6 : import java.util.concurrent.*;
  s7 : import java.util.function.*;
  s8 : import java.util.prefs.*;
  s9 : import java.util.regex.*;
 s10 : import java.util.stream.*;
   1 : 2 + 2
   2 : int x = 100;
jshell> /list -start
  s1 : import java.io.*;
  s2 : import java.math.*;
  s3 : import java.net.*;
  s4 : import java.nio.file.*;
  s5 : import java.util.*;
  s6 : import java.util.concurrent.*;
  s7 : import java.util.function.*;
  s8 : import java.util.prefs.*;
  s9 : import java.util.regex.*;
 s10 : import java.util.stream.*;
jshell> string str = "using invalid type string"
|  Error:
|  cannot find symbol
|    symbol:   class string
|  string str = "using invalid type string";
|  ^----^
jshell> /list
   1 : 2 + 2
   2 : int x = 100;
jshell> /list -all
  s1 : import java.io.*;
  s2 : import java.math.*;
  s3 : import java.net.*;
  s4 : import java.nio.file.*;
  s5 : import java.util.*;
  s6 : import java.util.concurrent.*;
  s7 : import java.util.function.*;
  s8 : import java.util.prefs.*;
  s9 : import java.util.regex.*;
 s10 : import java.util.stream.*;
   1 : 2 + 2
   2 : int x = 100;
  e1 : string str = "using invalid type string";
jshell> /drop 1
|  dropped variable $1
jshell> /list
   2 : int x = 100;
jshell> /drop x
|  dropped variable x
jshell> /list
jshell> /list -all
  s1 : import java.io.*;
  s2 : import java.math.*;
  s3 : import java.net.*;
  s4 : import java.nio.file.*;
  s5 : import java.util.*;
  s6 : import java.util.concurrent.*;
  s7 : import java.util.function.*;
  s8 : import java.util.prefs.*;
  s9 : import java.util.regex.*;
 s10 : import java.util.stream.*;
   1 : 2 + 2
   2 : int x = 100;
  e1 : string str = "using invalid type string";
jshell>
```

变量，方法和类的名称成为代码段名称。 请注意，Java允许使用与变量，方法和具有相同名称的类，因为它们出现在其自己的命名空间中。 可以使用这些实体的名称通过/list命令列出它们：

```
C:\Java9Revealed>jshell
|  Welcome to JShell -- Version 9-ea
|  For an introduction type: /help intro
jshell> /list x
|  No such snippet: x
jshell> int x = 100
x ==> 100
jshell> /list x
   1 : int x = 100;
jshell> void x(){}
|  created method x()
jshell> /list x
   1 : int x = 100;
   2 : void x(){}
jshell> void x(int n) {}
|  created method x(int)
jshell> /list x
   1 : int x = 100;
   2 : void x(){}
   3 : void x(int n) {}
jshell> class x{}
|  created class x
jshell> /list x
   1 : int x = 100;
   2 : void x(){}
   3 : void x(int n) {}
   4 : class x{}
jshell>
```

## 八. 编辑代码片段

JShell工具提供了几种编辑片段和命令的方法。 可以使用下表中列出的导航键在命令行中导航，同时在jshell中输入代码段和命令。

|键盘按键|描述|
|-------|---|
|Enter	|进入当前行|
|左箭头	|向后移动一个字符|
|右箭头	|向前移动一个字符|
|Ctrl-A	|移动到行首|
|Ctrl-E	|移动到行末|
|Meta-B (or Alt-B)	|向后移动一个单词|
|Meta-F (or Alt-F)	|向前移动一个单词|

可以使用下表列出的键来编辑在jshell中的一行输入的文本。

|键盘按键	|描述|
|-------|----|
|Delete	|删除光标后的字符|
|Backspace	|删除光标前的字符|
|Ctrl-K	|删除从光标位置到行末的文本|
|Meta-D (or Alt-D)	|删除光标位置后面的单词|
|Ctrl-W	|删除光标位置到前面最近的空格之间的文本|
|Ctrl-Y	|将最近删除的文本粘贴到行中|
|Meta-Y (or Alt-Y)	|在Ctrl-Y之后，此组合键将循环选择先前删除的文本|

即使可以访问丰富的编辑键的组合，也很难在JShell工具中编辑多行片段。 工具设计人员意识到了这个问题，并提供了一个内置的代码段编辑器。 可以将JShell工具配置为使用选择的特定于平台的代码段编辑器。

需要使用`/edit`命令开始编辑代码段。 该命令有三种形式：

```
/edit <snippet-name>
/edit <snippet-id>
/edit
```

可以使用片段名称或代码段ID来编辑特定的片段。 没有参数的/edit命令打开编辑器中的所有有效代码片段进行编辑。 默认情况下，`/edit`命令打开一个名为JShell Edit Pad内置编辑器，如图所示。

![]()

JShell Edit Pad是用Swing编写的，它显示了一个带有JTextArea和三个JButton的JFrame控件。 如果编辑片段，请确保在退出窗口之前单击接受按钮，以使编辑生效。 如果在不接受更改的情况下取消或退出编辑器，编辑的内容将会丢失。

如果知道变量，方法或类的名称，则可以使用其名称进行编辑。 以下jshell会话创建一个变量，方法和具有相同名称x的类，并使用`/edit x`命令一次编辑它们：

```
C:\Java9Revealed>jshell
|  Welcome to JShell -- Version 9-ea
|  For an introduction type: /help intro
jshell> int x = 100
x ==> 100
jshell> void x(){}
|  created method x()
jshell> void x (int n) {}
|  created method x(int)
jshell> class x{}
|  created class x
jshell> 2 + 2
$5 ==> 4
jshell> /edit x
```

`/edit x`命令在JShell Edit Pad中打开名称为x的所有片段，如下图所示。 可以编辑这些片段，接受更改并退出编辑，以继续执行jshell会话。

![]()

## 九. 重新运行上一个片段

在像jshell这样的命令行工具中，通常需要重新运行以前的代码段。 可以使用向上/向下箭头来浏览片段/命令历史记录，然后在上一个代码段/命令时按Enter键。 还可以使用三个命令之一来重新运行以前的代码段（而不是命令）：

```
/!
/<snippet-id>
/-<n>
```

`/!` 命令重新运行最后一个代码段。 `/<snippet-id>`命令重新运行由<snippet-id>标识的片段。 `/ -<n>`命令重新运行第n个最后一个代码段。 例如，`/ -1`重新运行最后一个代码段，`/-2`重新运行第二个代码段，依此类推。 `/!` 和`/-1`命令具有相同的效果，它们都重新运行最后一个代码段。

## 十. 声明变量

可以像在Java程序中一样在jshell中声明变量。 一个变量声明可能发生在顶层，方法内部，或者类中的字段声明。 顶级变量声明中不允许使用`static`和`final`修饰符。 如果使用它们，它们将被忽略并发出警告。 `static`修饰符指定一个类上下文，`final`修饰符限制更改变量的值。 不能使用这些修饰符，因为该工具允许通过随时间更改其值来声明你想要尝试的独立变量。 以下示例说明如何声明变量：

```
c:\Java9Revealed>jshell
|  Welcome to JShell -- Version 9-ea
|  For an introduction type: /help intro
jshell> int x
x ==> 0
jshell> int y = 90
y ==> 90
jshell> side = 90
|  Error:
|  cannot find symbol
|    symbol:   variable side
|  side = 90
|  ^--^
jshell> static double radius = 2.67
|  Warning:
|  Modifier 'static'  not permitted in top-level declarations, ignored
|  static double radius = 2.67;
|  ^----^
radius ==> 2.67
jshell> String str = new String("Hello")
str ==> "Hello"
jshell>
```

在顶级表达式中使用未声明的变量会生成错误。 请注意在上一个示例中使用未声明的变量side，这会产生错误。 稍后会介绍，可以在方法体中使用未声明的变量。

也可以更改变量的数据类型。 可以将一个名为x的变量声明为int，然后再将其声明为double或String。 以下示例显示了此功能：

```
jshell> int x = 10;
x ==> 10
jshell> int y = x + 2;
y ==> 12
jshell> double x = 2.71
x ==> 2.71
jshell> y
y ==> 12
jshell> String x = "Hello"
x ==> "Hello"
jshell> y
y ==> 12
jshell>
```

还可以使用`/drop`命令删除变量，该命令将变量名称作为参数。 以下命令将删除名为x的变量：

```
jshell> /drop x
```

可以使用`/vars`命令在jshell中列出所有变量。 它将列出用户声明的变量和由jshell自动声明的变量。该命令具有以下形式：

```
/vars
/vars <variable-name>
/vars <variable-snippet-id>
/vars -start
/vars -all
```

没有参数的命令列出当前会话中的所有有效变量。 如果使用代码段名称或ID，则会使用该代码段名称或ID来列出变量声明。 如果使用-start选项，它将列出添加到启动脚本中的所有变量。 如果使用`-all`选项，它将列出所有变量，包括失败，覆盖，删除和启动。 以下示例说明如何使用/vars命令：

```
c:\Java9Revealed>jshell
|  Welcome to JShell -- Version 9-ea
|  For an introduction type: /help intro
jshell> /vars
jshell> 2 + 2
$1 ==> 4
jshell> /vars
|    int $1 = 4
jshell> int x = 20;
x ==> 20
jshell> /vars
|    int $1 = 4
|    int x = 20
jshell> String str = "Hello";
str ==> "Hello"
jshell> /vars
|    int $1 = 4
|    int x = 20
|    String str = "Hello"
jshell> double x = 90.99;
x ==> 90.99
jshell> /vars
|    int $1 = 4
|    String str = "Hello"
|    double x = 90.99
jshell> /drop x
|  dropped variable x
jshell> /vars
|    int $1 = 4
|    String str = "Hello"
jshell>
```

## 十一. import语句

可以在jshell中使用import语句。在Java程序中，默认情况下会导入`java.lang`包中的所有类型。 要使用其他包中的类型，需要在编译单元中添加适当的import语句。 我们将从一个例子开始。 创建三个对象：一个`String`，一个`List<Integer>`和一个`ZonedDateTime`。 请注意，String类在java.lang包中; `List`和`Integer`类分别在`java.util`和`java.lang`包中; `ZonedDateTime`类在`java.time`包中。

```
jshell> String str = new String("Hello")
str ==> "Hello"
jshell> List<Integer> nums = List.of(1, 2, 3, 4, 5)
nums ==> [1, 2, 3, 4, 5]
jshell> ZonedDateTime now = ZonedDateTime.now()
|  Error:
|  cannot find symbol
|    symbol:   class ZonedDateTime
|  ZonedDateTime now = ZonedDateTime.now();
|  ^-----------^
|  Error:
|  cannot find symbol
|    symbol:   variable ZonedDateTime
|  ZonedDateTime now = ZonedDateTime.now();
|                      ^-----------^
jshell>
```

如果尝试使用`java.time`包中的`ZonedDateTime`类，这些示例会生成错误。 当我们尝试创建一个`List`时，也期待着类似的错误，因为它在`java.util`包中，默认情况下它不会在Java程序中导入。

JShell工具的唯一目的是在对代码片段求值时使开发人员的生活更轻松。 为了实现这一目标，该工具默认从几个包导入所有类型。 那些导入类型的默认包是什么？ 可以使用`/imports`命令在jshell中打印所有有效导入的列表：

```
jshell> /imports
|    import java.io.*
|    import java.math.*
|    import java.net.*
|    import java.nio.file.*
|    import java.util.*
|    import java.util.concurrent.*
|    import java.util.function.*
|    import java.util.prefs.*
|    import java.util.regex.*
|    import java.util.stream.*
jshell>
```

注意从`java.util`包导入所有类型的默认import语句。 这是可以创建`List`而不用导入的原因。 也可以将自己的导入添加到jshell。 以下示例说明如何导入`ZonedDateTime`类并使用它。 当jshell使用时区打印当前日期的值时，将获得不同的输出。

```shell
jshell> /imports
|    import java.util.*
|    import java.io.*
|    import java.math.*
|    import java.net.*
|    import java.util.concurrent.*
|    import java.util.prefs.*
|    import java.util.regex.*
jshell> import java.time.*
jshell> /imports
|    import java.io.*
|    import java.math.*
|    import java.net.*
|    import java.nio.file.*
|    import java.util.*
|    import java.util.concurrent.*
|    import java.util.function.*
|    import java.util.prefs.*
|    import java.util.regex.*
|    import java.util.stream.*
|    import java.time.*
jshell> ZonedDateTime now = ZonedDateTime.now()
now ==> 2016-11-11T10:39:10.497234400-06:00[America/Chicago]
jshell>
```

注意，当退出会话时，添加到jshell会话的任何导入都将丢失。 还可以删除import语句 ——包括导入和添加的。 需要知道代码段ID才能删除代码段。 启动片段的ID为s1，s2，s3等，对于用户定义的片段，它们为1,2,3等等。以下示例说明如何在jshell中添加和删除import语句：

```
C:\Java9Revealed>jshell
|  Welcome to JShell -- Version 9-ea
|  For an introduction type: /help intro
jshell> import java.time.*
jshell> List<Integer> list = List.of(1, 2, 3, 4, 5)
list ==> [1, 2, 3, 4, 5]
jshell> ZonedDateTime now = ZonedDateTime.now()
now ==> 2017-02-9T21:08:08.802099-06:00[America/Chicago]
jshell> /list -all
  s1 : import java.io.*;
  s2 : import java.math.*;
  s3 : import java.net.*;
  s4 : import java.nio.file.*;
  s5 : import java.util.*;
  s6 : import java.util.concurrent.*;
  s7 : import java.util.function.*;
  s8 : import java.util.prefs.*;
  s9 : import java.util.regex.*;
 s10 : import java.util.stream.*;
   1 : import java.time.*;
   2 : List<Integer> list = List.of(1, 2, 3, 4, 5);
   3 : ZonedDateTime now = ZonedDateTime.now();
jshell> /drop s5
jshell> /drop 1
jshell> /list -all
  s1 : import java.io.*;
  s2 : import java.math.*;
  s3 : import java.net.*;
  s4 : import java.nio.file.*;
  s5 : import java.util.*;
  s6 : import java.util.concurrent.*;
  s7 : import java.util.function.*;
  s8 : import java.util.prefs.*;
  s9 : import java.util.regex.*;
 s10 : import java.util.stream.*;
   1 : import java.time.*;
   2 : List<Integer> list = List.of(1, 2, 3, 4, 5);
   3 : ZonedDateTime now = ZonedDateTime.now();
jshell> /imports
|    import java.io.*
|    import java.math.*
|    import java.net.*
|    import java.nio.file.*
|    import java.util.concurrent.*
|    import java.util.function.*
|    import java.util.prefs.*
|    import java.util.regex.*
|    import java.util.stream.*
jshell> List<Integer> list2 = List.of(1, 2, 3, 4, 5)
|  Error:
|  cannot find symbol
|    symbol:   class List
|  List<Integer> list2 = List.of(1, 2, 3, 4, 5);
|  ^--^
|  Error:
|  cannot find symbol
|    symbol:   variable List
|  List<Integer> list2 = List.of(1, 2, 3, 4, 5);
|                        ^--^
jshell> import java.util.*
|    update replaced variable list, reset to null
jshell> List<Integer> list2 = List.of(1, 2, 3, 4, 5)
list2 ==> [1, 2, 3, 4, 5]
jshell> /list -all
  s1 : import java.io.*;
  s2 : import java.math.*;
  s3 : import java.net.*;
  s4 : import java.nio.file.*;
  s5 : import java.util.*;
  s6 : import java.util.concurrent.*;
  s7 : import java.util.function.*;
  s8 : import java.util.prefs.*;
  s9 : import java.util.regex.*;
 s10 : import java.util.stream.*;
   1 : import java.time.*;
   2 : List<Integer> list = List.of(1, 2, 3, 4, 5);
   3 : ZonedDateTime now = ZonedDateTime.now();
  e1 : List<Integer> list2 = List.of(1, 2, 3, 4, 5);
   4 : import java.util.*;
   5 : List<Integer> list2 = List.of(1, 2, 3, 4, 5);
jshell> /imports
|    import java.io.*
|    import java.math.*
|    import java.net.*
|    import java.nio.file.*
|    import java.util.concurrent.*
|    import java.util.function.*
|    import java.util.prefs.*
|    import java.util.regex.*
|    import java.util.stream.*
|    import java.util.*
jshell>
```


## 十二. 方法声明

可以在jshell中声明和调用方法。 可以声明顶级方法，这些方法直接在jshell中输入，不在任何类中。 也可以在类中声明方法。 在本节中，展示如何声明和调用顶级方法。 也可以调用现有类的方法。 以下示例声明一个名为square()的方法并调用它：

```
jshell> long square(int n) {
   ...>    return n * n;
   ...> }
|  created method square(int)
jshell> square(10)
$2 ==> 100
jshell> long n2 = square(37)
n2 ==> 1369
jshell>
```

在方法体中允许向前引用。 也就是说，可以在方法体中引用尚未声明的方法或变量。 在定义所有缺少的引用方法和变量之前，无法调用声明的方法。

```
jshell> long multiply(int n) {
   ...>     return multiplier * n;
   ...> }
|  created method multiply(int), however, it cannot be invoked until variable multiplier is declared
jshell> multiply(10)
|  attempted to call method multiply(int) which cannot be invoked until variable multiplier is declared
jshell> int multiplier = 2
multiplier ==> 2
jshell> multiply(10)
$6 ==> 20
jshell> void printCube(int n) {
   ...>     System.out.printf("Cube of %d is %d.%n", n, cube(n));
   ...> }
|  created method printCube(int), however, it cannot be invoked until method cube(int) is declared
jshell> long cube(int n) {
   ...>     return n * n * n;
   ...> }
|  created method cube(int)
jshell> printCube(10)
Cube of 10 is 1000.
jshell>
```

此示例声明一个名为`multiply(int n)`的方法。 它将参数与名为`multiplier`的变量相乘，该变量尚未声明。 注意在声明此方法后打印的反馈。 反馈清楚地表明，在声明乘数变量之前，不能调用`multiply()`方法。 调用该方法会生成错误。 后来，`multiplier变量`被声明，并且`multiply()`方法被成功调用。

> Tips
> 可以使用向前引用的方式声明递归方法。


## 十三. 类型声明

可以像在Java中一样在jshell中声明所有类型，如类，接口，枚举和注解。 以下jshell会话创建一个Counter类，创建对象并调用方法：

```
jshell> class Counter {
   ...>     private int counter;
   ...>     public synchronized int next() {
   ...>         return ++counter;
   ...>     }
   ...>
   ...>     public int current() {
   ...>         return counter;
   ...>     }
   ...> }
|  created class Counter
jshell> Counter c = new Counter();
c ==> Counter@25bbe1b6
jshell> c.current()
$3 ==> 0
jshell> c.next()
$4 ==> 1
jshell> c.next()
$5 ==> 2
jshell> c.current()
$6 ==> 2
jshell>
```

可以使用`/types`命令在jshell中打印所有声明类型的列表。 该命令具有以下形式：

```
/types
/types <type-name>
/types <snippet-id>
/types -start
/types -all
```

注意，Counter类的源代码不包含包声明，因为jshell不允许在包中声明类（或任何类型）。 在jshell中声明的所有类型都被视为内部合成类的静态类型。 但是，可能想要测试自己的包中的类。 可以在jshell中使用一个包中已经编译的类。 当使用类库开发应用程序时，通常需要它，并且想通过针对类库编写代码段来实验应用程序逻辑。 需要使用`/env`命令设置类路径，因此可能会找到需要的类。

`com.jdojo.jshell`包中的Person类声明如下所示。

```
// Person.java
package com.jdojo.jshell;
public class Person {
    private String name;
    public Person() {
        this.name = "Unknown";
    }
    public Person(String name) {
        this.name = name;
    }
    public String getName() {
        return name;
    }
    public void setName(String name) {
        this.name = name;
    }
}
```

以下jshell命令将Windows上的类路径设置为C:\中。

```
jshell> /env -class-path C:\Java9Revealed\com.jdojo.jshell\build\classes
|  Setting new options and restoring state.
jshell> Person guy = new Person("Martin Guy Crawford")
|  Error:
|  cannot find symbol
|    symbol:   class Person
|  Person guy = new Person("Martin Guy Crawford");
|  ^----^
|  Error:
|  cannot find symbol
|    symbol:   class Person
|  Person guy = new Person("Martin Guy Crawford");
|                   ^----^
```

我们使用类的简单类名称`Person`，而不导入它，而jshell无法找到该类。 我们需要导入Person类或使用其全限定名。 以下是此jshell会话的延续，可以修复此错误：

```
jshell> import com.jdojo.jshell.Person
jshell> Person guy = new Person("Martin Guy Crawford")
guy ==> com.jdojo.jshell.Person@192b07fd
jshell> guy.getName()
$9 ==> "Martin Guy Crawford"
jshell> guy.setName("Forrest Butts")
jshell> guy.getName()
$11 ==> "Forrest Butts"
jshell>
```

## 十四. 设置执行环境

在上一节中，学习了如何使用/env命令设置类路径。 该命令可用于设置执行上下文的许多其他组件，如模块路径。 还可以使用来解析模块，因此可以使用jshell模块中的类型。 其完整语法如下：

```
/env [-class-path <path>] [-module-path <path>] [-add-modules <modules>] [-add-exports <m/p=n>]
```

没有参数的`/env`命令打印当前执行上下文的值。`-class-path`选项设置类路径。 `-module-path`选项设置模块路径。 `-add-modules`选项将模块添加到默认的根模块中，因此可以解析。 可以使用 `-add-modules`选项来使用特殊值`ALL-DEFAULT`，`ALL-SYSTEM`和`ALL-MODULE-PATH`来解析模块。`-add-exports`选项将未导出的包从模块导出到一组模块。 这些选项与使用javac和java命令时具有相同的含义。

> Tips
> 在命令行中，这些选项必须以两个“--”开头，例如`--module-path`。 在jshell中，可以是一个破折号或者两个破折号开始。 例如，在jshell中允许使用`--module-path`和`-module-path`。

当设置执行上下文时，当前会话将被重置，并且当前会话中的所有先前执行的代码片段将以安静模式回放。 也就是说，未显示回放的片段。 但是，回放时的错误将会显示出来。

可以使用`/env`，`/reset`和`/reload`命令设置执行上下文。 每个命令都有不同的效果。 上下文选项（如`-class-path和-module-path`）的含义是相同的。 可以使用命令`/help`上下文列出可用于设置执行上下文的所有选项。

来看一下使用`/env`命令使用模块相关设置的例子。 在第3章中创建了一个`com.jdojo.intro`模块。该模块包含`com.jdojo.intro`的包，但它不导出包。 现在，要调用非导出包中的`Welcome类`的`main(String [] args)`方法。 以下是需要在jshell中执行的步骤：

* 设置模块路径，因此可以找到模块。
* 通过将模块添加到默认的根模块中来解决该模块。 可以使用`/env`命令中的`-add-modules`选项来执行此操作。
* 使用`-add-exports`命令导出包。 在jshell中输入的片段在未命名的模块中执行，因此需要使用`ALL-UNNAMED`关键字将包导出到所有未命名的模块。 如果在`-add-exports`选项中未提供目标模块，则假定为`ALL-UNNAMED`，并将软件包导出到所有未命名的模块。
*（可选）如果要在代码段中使用其简单名称，请导入com.jdojo.intro.Welcome类。

现在，可以从jshell调用`Welcome.main()`方法。

以下jshell会话将显示如何执行这些步骤。 假设以`C:\Java9Revealed`作为当前目录启动jshell会话，`C:\Java9Revealed\com.jdojo.intro\build  classes`目录包含`com.jdojo.intro`模块的编译代码。 如果你的目录结构和当前目录不同，请将会话中使用的目录路径替换为你的目录路径。

```
C:\Java9Revealed>jshell
|  Welcome to JShell -- Version 9-ea
|  For an introduction type: /help intro
jshell> /env -module-path com.jdojo.intro\build\classes
|  Setting new options and restoring state.
jshell> /env -add-modules com.jdojo.intro
|  Setting new options and restoring state.
jshell> /env -add-exports com.jdojo.intro/com.jdojo.intro=ALL-UNNAMED
|  Setting new options and restoring state.
jshell> import com.jdojo.intro.Welcome
jshell> Welcome.main(null)
Welcome to the Module System.
Module Name: com.jdojo.intro
jshell> /env
|     --module-path com.jdojo.intro\build\classes
|     --add-modules com.jdojo.intro
|     --add-exports com.jdojo.intro/com.jdojo.intro=ALL-UNNAMED
jshell>
```

## 十五. 没有检查异常

在Java程序中，如果调用抛出检查异常的方法，则必须使用`try-catch块`或通过添加`throws子句`来处理这些异常。 JShell工具应该是一种快速简单的方法来评估片段，因此不需要处理jshell片段中检查的异常。 如果代码段在执行时抛出一个被检查的异常，jshell将打印堆栈跟踪并继续。

```
jshell> FileReader fr = new FileReader("secrets.txt")
|  java.io.FileNotFoundException thrown: secrets.txt (The system cannot find the file specified)
|        at FileInputStream.open0 (Native Method)
|        at FileInputStream.open (FileInputStream.java:196)
|        at FileInputStream.<init> (FileInputStream.java:139)
|        at FileInputStream.<init> (FileInputStream.java:94)
|        at FileReader.<init> (FileReader.java:58)
|        at (#1:1)
jshell>
```

此片段抛出`FileNotFoundException`，因为当前目录中不存在名为*secrets.txt*的文件。 如果文件存在，可以创建一个`FileReader`，而无需使用`try-catch块`。 请注意，如果尝试在方法中使用此片段，则适用正常的Java语法规则，并且此方法声明不会编译：

```
jshell> void readSecrets() {
   ...> FileReader fr = new FileReader("secrets.txt");
   ...> // More code goes here
   ...> }
|  Error:
|  unreported exception java.io.FileNotFoundException; must be caught or declared to be thrown
|  FileReader fr = new FileReader("secrets.txt");
|                  ^---------------------------^
jshell>
```

## 十六. 自动补全

JShell工具具有自动补全功能，可以通过输入部分文本并按Tab键进行调用。 当输入命令或代码段时，此功能可用。 该工具将检测上下文并帮助自动完成命令。 当有多种可能性时，它显示所有可能性，需要手动输入其中一个。 当它发现一个独特的可能性，它将完成文本。

> Tips
> 可以在JShell工具上使用/help shortcuts命令查看当前可用的自动补全的键。

以下是查找多种可能性的工具的示例。 需要输入/e并按Tab键：

```
jshell> /e
/edit    /exit
jshell> /e
```

该工具检测到尝试输入命令，因为文本以斜杠（/）开头。 有两个以`/e`开头的命令（`/edit`和`/exit`），它们打印出来。 现在，需要通过输入命令的其余部分来完成命令。 在命令的情况下，如果输入足够的文本以使命令名称唯一，然后按Enter，该工具将执行该命令。 在这种情况下，可以输入`/ed`或`/ex`，然后按Enter键分别执行`/edit`或`/exit`命令。 您可以输入斜杠（/），然后按Tab键查看命令列表：

```
jshell> /
/!          /?          /drop       /edit       /env        /exit       /help       /history
```

以下代码段创建一个名为str的`String`变量，初始值为“GoodBye”：

```
jshell> String str = "GoodBye"
str ==> "GoodBye"
```

继续这个jshell会话中，输入“str.”， 并按Tab键：

```
jshell> str.
charAt(                chars()                codePointAt(
codePointBefore(       codePointCount(        codePoints()
compareTo(             compareToIgnoreCase(   concat(
contains(              contentEquals(         endsWith(
equals(                equalsIgnoreCase(      getBytes(
getChars(              getClass()             hashCode()
indexOf(               intern()               isEmpty()
lastIndexOf(           length()               matches(
notify()               notifyAll()            offsetByCodePoints(
regionMatches(         replace(               replaceAll(
replaceFirst(          split(                 startsWith(
subSequence(           substring(             toCharArray()
toLowerCase(           toString()             toUpperCase(
trim()                 wait(
```

此片段可以在变量str上调用的`String类`打印所有方法名称。 请注意，一些方法名以“()”结尾，而其他结尾只有“(”这不是一个错误，如果一个方法没有参数，它的名称跟随一个“()”，如果一个方法接受参数，它的名称将跟随一个“(”。

继续这个例子，输入`str.sub`并按Tab键：

```
jshell> str.sub
subSequence(   substring(
```

这一次，该工具在String类中发现了两个以sub开头的方法。 可以输入整个方法调用，`str.substring(0，4)`，然后按Enter键来求值代码段：

```
jshell> str.substring(0, 4)
$2 ==> "Good"
```

或者，可以通过输入`str.subs`来让工具自动补全方法名称。 当输入`str.subs`并按Tab时，该工具将完成方法名称，插入一个“(”，并等待输入方法的参数：

```
jshell> str.substring(
substring(
jshell> str.substring(
Now you can enter the method’s argument and press Enter to evaluate the expression:
jshell> str.substring(0, 4)
$3 ==> "Good"
jshell>
```

当一个方法接受参数时，很可能你想看到这些参数的类型。 可以在输入整个方法/构造函数名称和开始圆括号后按Shift + Tab查看该方法的概要。 在上一个例子中，如果输入`str.substring(`并按 **Shift + Tab**，该工具将打印substring()方法的概要：

```
jshell> str.substring(
String String.substring(int beginIndex)
String String.substring(int beginIndex, int endIndex)
<press shift-tab again to see javadoc>
```

注意输出。 它说如果再次按Shift + Tab，它将显示substring()方法的Javadoc。 在下面的提示中，再次按下Shift + Tab打印Javadoc。 如果需要显示更多的Javadoc，请按空格键或键入Q以返回到jshell提示符：

```
jshell> str.substring(
String String.substring(int beginIndex)
Returns a string that is a substring of this string.The substring begins with
the character at the specified index and extends to the end of this string.
Examples:
     "unhappy".substring(2) returns "happy"
     "Harbison".substring(3) returns "bison"
     "emptiness".substring(9) returns "" (an empty string)
Parameters:
beginIndex - the beginning index, inclusive.
Returns:
the specified substring.
String String.substring(int beginIndex, int endIndex)
Returns a string that is a substring of this string.The substring begins at the
specified beginIndex and extends to the character at index endIndex - 1 . Thus
the length of the substring is endIndex-beginIndex .
Examples:
     "hamburger".substring(4, 8) returns "urge"
     "smiles".substring(1, 5) returns "mile"
Parameters:
beginIndex - the beginning index, inclusive.
endIndex - the ending index, exclusive.
Returns:
the specified substring.
jshell> str.substring(
```

## 十七. 片段和命令历史

JShell维护了在所有会话中输入的所有命令和片段的历史记录。 可以使用向上和向下箭头键浏览历史记录。 也可以使用/history命令打印当前会话中输入的所有历史记录：

```
jshell> 2 + 2
$1 ==> 4
jshell> System.out.println("Hello")
Hello
jshell> /history
2 + 2
System.out.println("Hello")
/history
jshell>
```

此时，按向上箭头显示`/history`命令，按两次显示`System.out.println("Hello")`，然后按三次显示`2 + 2`。第四次按向上箭头将显示最后一个从以前的jshell会话输入命令/代码段。 如果要执行以前输入的代码段/命令，请使用向上箭头，直到显示所需的命令/代码段，然后按Enter执行。 按向下箭头将导航到列表中的下一个命令或代码段。 假设按向上箭头五次导航到第五个最后一个片断或命令。 现在按向下箭头将导航到第四个最后一个代码段或命令。 当处于第一个和最后一个片段或命令时，按向上箭头或向下箭头不起作用。

## 十八. 读取JShell堆栈跟踪

在jshell上输入的片段是合成类的一部分。 例如，Java不允许声明顶级方法。 方法声明必须是类型的一部分。 当Java程序中抛出异常时，堆栈跟踪将打印类型名称和行号。 在jshell中，可能会从代码段中抛出异常。 在这种情况下打印合成类名称和行号将会产生误导，对开发者来说是没有意义的。 堆栈跟踪中代码段中代码位置的格式将为：

```
at <snippet-name> (#<snippet-id>:<line-number-in-snippet>)
```

请注意，某些代码段可能没有名称。 例如，输入一个代码段`2 + 2`不会给它一个名字。 一些片段有一个名字，例如一个代码段，声明变量被赋予与变量名称相同的名称; 方法和类型声明也一样。 有时，可能有两个名称相同的片段，例如通过声明变量和具有相同名称的方法/类型。 jshell为所有片段分配唯一的片段ID。 可以使用`/list -all`命令查找代码段的ID。

以下jshell会话声明了一个`divide()`方法，并使用运算符`ArithmeticException`异常打印异常堆栈跟踪，该异常在整数除以零时抛出：

```
C:\Java9Revealed>jshell
|  Welcome to JShell -- Version 9-ea
|  For an introduction type: /help intro
jshell> int divide(int x, int y) {
   ...> return x/y;
   ...> }
|  created method divide(int,int)
jshell> divide(10, 2)
$2 ==> 5
jshell> divide(10, 0)
|  java.lang.ArithmeticException thrown: / by zero
|        at divide (#1:2)
|        at (#3:1)
jshell> /list -all
  s1 : import java.io.*;
  s2 : import java.math.*;
  s3 : import java.net.*;
  s4 : import java.nio.file.*;
  s5 : import java.util.*;
  s6 : import java.util.concurrent.*;
  s7 : import java.util.function.*;
  s8 : import java.util.prefs.*;
  s9 : import java.util.regex.*;
 s10 : import java.util.stream.*;
   1 : int divide(int x, int y) {
       return x/y;
       }
   2 : divide(10, 2)
   3 : divide(10, 0)
jshell>
```

我们尝试读取堆栈跟踪。 `(#3:1)`的最后一行表示异常是在代码段3的第1行引起的。注意在`/list -all`命令的输出中，代码段3是表达式的`divide(10, 0)`导致异常。 第二行，`divide (#1:2)`，表示堆栈跟踪中的第二级位于代码段的第2行，名称为divide代码段ID是1。

## 十九. 重用JShell会话（Session）

可以在jshell会话中输入许多片段和命令，并可能希望在其他会话中重用它们。 可以使用/save命令将命令和片段保存到文件中，并使用/open命令加载先前保存的命令和片段。 `/save`命令的语法如下：

```
/save <option> <file-path>
```

这里，<option>可以是以下选项之一：`-al`，`-history`和`-start`。 `<file-path>`是将保存片段/命令的文件路径。

`/save`命令没有选项将所有活动的片段保存在当前会话中。 请注意，它不保存任何命令或失败的代码段。

带有`-all`选项的`/save`命令将当前会话的所有片段保存到指定的文件，包括失败的和启动片段。 请注意，它不保存任何命令。

使用`-history`选项的`/save`命令保存自启动以来在jshell中键入的所有内容。

使用`-start`选项的`/save`命令将默认启动定义保存到指定的文件。

可以使用`/open`命令从文件重新加载片段。 该命令将文件名作为参数。

以下jshell会话声明一个Counter类，创建其对象，并调用对象上的方法。 最后，它将所有活动的片段保存到名为jshell.jsh的文件中。 请注意，文件扩展名.jsh是jshell文件的习惯。 你可以使用你想要的任何其他扩展。

```
C:\Java9Revealed>jshell
|  Welcome to JShell -- Version 9-ea
|  For an introduction type: /help intro
jshell> class Counter {
   ...>    private int count;
   ...>    public synchronized int next() {
   ...>      return ++count;
   ...>    }
   ...>    public int current() {
   ...>      return count;
   ...>    }
   ...> }
|  created class Counter
jshell> Counter counter = new Counter()
counter ==> Counter@5bbe1b6
jshell> counter.current()
$3 ==> 0
jshell> counter.next()
$4 ==> 1
jshell> counter.next()
$5 ==> 2
jshell> counter.current()
$6 ==> 2
jshell> /save jshell.jsh
jshell> /exit
|  Goodbye
```

此时，应该在当前目录中有一个名为jshell.jsh的文件，内容如下所示：

```
class Counter {
   private int count;
   public synchronized int next() {
     return ++count;
   }
   public int current() {
     return count;
   }
}
Counter counter = new Counter();
counter.current()
counter.next()
counter.next()
counter.current()
```

以下jshell会话将打开**jshell.jsh**文件，该文件将回放上一个会话中保存的所有片段。 打开文件后，可以开始调用counter变量的方法。

```
C:\Java9Revealed>jshell
|  Welcome to JShell -- Version 9-ea
|  For an introduction type: /help intro
jshell> /open jshell.jsh
jshell> counter.current()
$7 ==> 2
jshell> counter.next()
$8 ==> 3
jshell>
```

## 二十. 重置JShell状态

可以使用`/reset`命令重置JShell的执行状态。 执行此命令具有以下效果： 

* 在当前会话中输入的所有片段都将丢失，因此在执行此命令之前请小心。 
* 启动片段被重新执行。 
* 重新启动工具的执行状态。 
* 使用/set命令设置的jshell配置被保留。 
* 使用/env`命令设置的执行环境被保留。

以下jshell会话声明一个变量，重置会话，并尝试打印变量的值。 请注意，在重置会话时，所有声明的变量都将丢失，因此找不到先前声明的变量：

```
jshell> int x = 987
x ==> 987
jshell> /reset
|  Resetting state.
jshell> x
|  Error:
|  cannot find symbol
|    symbol:   variable x
|  x
|  ^
jshell>
```

## 二十一. 重新加载JShell状态

假设在jshell会话中回放了许多片段，并退出会话。 现在想回去并回放这些片段。 一种方法是启动一个新的jshell会话并重新输入这些片段。 在jshell中重新输入几个片段是一个麻烦。 有一个简单的方法来实现这一点 —— 通过使用`/reload`命令。 `/reload`命令重置jshell状态，并以与之前输入的序列相同的顺序回放所有有效的片段。 可以使用-restore和-quiet选项来自定义其行为。

没有任何选项的/reload命令会重置jshell状态，并从以下先前的操作/事件中回放有效的历史记录，具体取决于哪一个：

* 当前会话开始
* 当执行最后一个/reset命令时
* 当执行最后一个/reload命令时

可以使用`-restore`选项与`/reload`命令一起使用。 它将重置和回放以下两个操作/事件之间的历史记录，以最后两个为准：

* 启动jshell
* 执行/reset命令
* 执行/reload命令

使用`-restore`选项执行`/reload`命令的效果有点难以理解。 其主要目的是恢复以前的执行状态。 如果在每个jshell会话开始时执行此命令，从第二个会话开始，你的会话将包含在jshell会话中执行的所有代码段！ 这是一个强大的功能。 也就是说，可以对代码片段求值，关闭jshell，重新启动jshell，并执行`/reload -restore`命令作为第一个命令，并且不会丢失以前输入的任何代码段。 有时，将在会话中执行/reset命令两次，并希望恢复这两个复位之间存在的状态。 可以使用此命令来实现此结果。

以下jshell会话在每个会话中创建一个变量，并通过在每个会话执行`/reload -restore`命令来恢复上一个会话。 该示例显示第四个会话使用在第一个会话中声明的x1的变量。

```
C:\Java9Revealed>jshell
|  Welcome to JShell -- Version 9-ea
|  For an introduction type: /help intro
jshell> int x1 = 10
x1 ==> 10
jshell> /exit
|  Goodbye
C:\Java9Revealed>jshell
|  Welcome to JShell -- Version 9-ea
|  For an introduction type: /help intro
jshell> /reload -restore
|  Restarting and restoring from previous state.
-: int x1 = 10;
jshell> int x2 = 20
x2 ==> 20
jshell> /exit
|  Goodbye
C:\Java9Revealed>jshell
|  Welcome to JShell -- Version 9-ea
|  For an introduction type: /help intro
jshell> /reload -restore
|  Restarting and restoring from previous state.
-: int x1 = 10;
-: int x2 = 20;
jshell> int x3 = 30
x3 ==> 30
jshell> /exit
|  Goodbye
C:\Java9Revealed>jshell
|  Welcome to JShell -- Version 9-ea
|  For an introduction type: /help intro
jshell> /reload -restore
|  Restarting and restoring from previous state.
-: int x1 = 10;
-: int x2 = 20;
-: int x3 = 30;
jshell> System.out.println("x1 is " + x1)
x1 is 10
jshell>
```

`/reload`命令显示其回放的历史记录。 可以使用`-quiet`选项来抑制重放显示。 `-quiet`选项不会抑制回放历史记录时可能会生成的错误消息。 以下示例使用两个jshell会话。 第一个会话声明一个x1的变量。 第二个会话使用`-quiet`选项与`/reload`命令。 请注意，此时，由于使用了-quiet选项，因此在第二个会话中没有看到回放显示变量x1被重新加载。

```
C:\Java9Revealed>jshell
|  Welcome to JShell -- Version 9-ea
|  For an introduction type: /help intro
jshell> int x1 = 10
x1 ==> 10
jshell> /exit
|  Goodbye
C:\Java9Revealed>jshell
|  Welcome to JShell -- Version 9-ea
|  For an introduction type: /help intro
jshell> /reload -restore -quiet
|  Restarting and restoring from previous state.
jshell> x1
x1 ==> 10
jshell>
```


## 二十二. 配置JShell

使用`/set`命令，可以自定义jshell会话，从启动片段和命令到设置平台特定的片段编辑器。

### 1. 设置代码编辑器

JShell工具附带一个默认的代码编辑器。 在jshell中，可以使用/edit命令来编辑所有的片段或特定的片段。 `/edit`命令在编辑器中打开该片段。 代码编辑器是一个特定于平台的程序，如Windows上的notepad.exe，将被调用来编辑代码段。 可以使用/set命令与编辑器作为参数来设置或删除编辑器设置。 命令的有效形式如下：

```
/set editor [-retain] [-wait] <command>
/set editor [-retain] -default
/set editor [-retain] -delete
```

如果使用`-retain`选项，该设置将在jshell会话中持续生效。

如果指定了一个命令，则该命令必须是平台特定的。 也就是说，需要在Windows上指定Windows命令，UNIX上指定UNIX命令等。 该命令可能包含标志。 JShell工具会将要编辑的片段保存在临时文件中，并将临时文件的名称附加到命令中。 编辑器打开时，无法使用jshell。 如果编辑器立即退出，应该指定-wait选项，这将使jshell等到编辑器关闭。 以下命令将记事本设置为Windows上的编辑器：

```
jshell> /set editor -retain notepad.exe
```

`-default`选项将编辑器设置为默认编辑器。 `-delete`选项删除当前编辑器设置。 如果`-retain`选项与`-delete`选项一起使用，则保留的编辑器设置将被删除：

```
jshell> /set editor -retain -delete
|  Editor set to: -default
jshell>
```

设置在以下环境变量中的编辑器——`JSHELLEDITOR`，`VISUAL`或`EDITOR`，优先于默认编辑器。 这些环境变量按顺序查找编辑器。 如果没有设置这些环境变量，则使用默认编辑器。 所有这些规则背后的意图是一直有一个编辑器，然后使用默认编辑器作为后备。 没有任何参数和选项的 /set编辑器命令打印有关当前编辑器设置的信息。

以下jshell会话将记事本设置为Windows上的编辑器。 请注意，此示例将不适用于Windows以外的平台，需要在平台特定的程序中指定编辑器。

```
C:\Java9Revealed>jshell
|  Welcome to JShell -- Version 9-ea
|  For an introduction type: /help intro
jshell> /set editor
|  /set editor -default
jshell> /set editor -retain notepad.exe
|  Editor set to: notepad.exe
|  Editor setting retained: notepad.exe
jshell> /exit
|  Goodbye
C:\Java9Revealed>jshell
|  Welcome to JShell -- Version 9-ea
|  For an introduction type: /help intro
jshell> /set editor
|  /set editor -retain notepad.exe
jshell> 2 + 2
$1 ==> 4
jshell> /edit
jshell> /set editor -retain -delete
|  Editor set to: -default
jshell> /exit
|  Goodbye
C:\Java9Revealed>SET JSHELLEDITOR=notepad.exe
C:\Java9Revealed>jshell
|  Welcome to JShell -- Version 9-ea
|  For an introduction type: /help intro
jshell> /set editor
|  /set editor notepad.exe
jshell>
```

### 2. 设置反馈模式

执行代码段或命令时，jshell会打印反馈。 反馈的数量和格式取决于反馈模式。 可以使用四种预定义的反馈模式之一或自定义反馈模式：

* silent模式根本不给任何反馈
* concise模式给出与normal模式相同的反馈
* normal
* verbose模式提供最多的反馈

设置反馈模式的命令如下：

```
/set feedback [-retain] <mode>
```

这里，`<mode>`是四种反馈模式之一。 如果要在jshell会话中保留反馈模式，请使用`-retain`选项。

也可以在特定的反馈模式中启动jshell：

```
jshell --feedback <mode>
```

以下命令以verbose反馈模式启动jshell：

```
C:\Java9Revealed>jshell --feedback verbose
```

以下示例说明如何设置不同的反馈模式：


```
C:\Java9Revealed>jshell
|  Welcome to JShell -- Version 9-ea
|  For an introduction type: /help intro
jshell> 2 + 2
$1 ==> 4
jshell> /set feedback verbose
|  Feedback mode: verbose
jshell> 2 + 2
$2 ==> 4
|  created scratch variable $2 : int
jshell> /set feedback concise
jshell> 2 + 2
$3 ==> 4
jshell> /set feedback silent
-> 2 + 2
-> System.out.println("Hello")
Hello
-> /set feedback verbose
|  Feedback mode: verbose
jshell> 2 + 2
$6 ==> 4
|  created scratch variable $6 : int
```

jshell中设置的反馈模式是临时的。 它只对当前会话设置。 要在jshell会话中持续反馈模式，使用以下命令：

```
jshell> /set feedback -retain
```

此命令将持续当前的反馈模式。 当再次启动jshell时，它将配置在执行此命令之前设置的反馈模式。 仍然可以在会话中临时更改反馈模式。 如果要永久设置新的反馈模式，则需要使用/set feedback <mode>命令，再次执行该命令以保持新的设置。

还可以设置一个新的反馈模式，并且同时通过使用-retain选项来保留以后的会话。 以下命令将反馈模式设置为verbose，并将其保留在以后的会话中：

```
jshell> /set feedback -retain verbose
```

要确定当前的反馈模式，只需使用反馈参数执行`/se命令。 它打印用于在第一行设置当前反馈模式的命令，然后是所有可用的反馈模式，如下所示：

```
jshell> /set feedback
|  /set feedback normal
|
|  Available feedback modes:
|     concise
|     normal
|     silent
|     verbose
jshell>
```

> Tips
> 当学习jshell时，建议以verbose反馈模式启动它，因此可以获得有关命令和代码段执行状态的详细信息。 这将有助于更快地了解该工具。

