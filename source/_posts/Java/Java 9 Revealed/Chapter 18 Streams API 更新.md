---
title: Streams API 更新
date: 2018-4-19 13:10:00
tags:	[Java9,stream]
category: Java 9 Revealed
toc: true
comments: false
---

[原文地址](http://www.cnblogs.com/IcanFixIt/p/7253559.html)

在本章中，主要介绍以下内容：

* 在Stream接口中添加了更加便利的方法来处理流
* 在Collectors类中添加了新的收集器（collectors）

JDK 9中，在Streams API中添加了一些便利的方法，根据类型主要添加在：

* Stream接口
* Collectors类

`Stream`接口中的方法定义了新的流操作，而`Collectors`类中的方法定义了新的收集器。


本章的源代码位于名为com.jdojo.streams的模块中，其声明如下所示。

```java
// module-info.java
module com.jdojo.streams {
    exports com.jdojo.streams;
}
```

## 一. 新的流操作

在JDK 9中，Stream接口具有以下新方法：

```java
default Stream<T> dropWhile(Predicate<? super T> predicate)
default Stream<T> takeWhile(Predicate<? super T> predicate)
static <T> Stream<T> ofNullable(T t)
static <T> Stream<T> iterate(T seed, Predicate<? super T> hasNext, UnaryOperator<T> next)
```

在JDK 8中，Stream接口有两种方法：`skip(long count)`和`limit(long count)`。`skip()`方法从头开始跳过指定的数量元素后返回流的元素。 `limit()`方法从流的开始返回等于或小于指定数量的元素。第一个方法从一开始就删除元素，另一个从头开始删除剩余的元素。两者都基于元素的数量。 `dropWhile()`和`takeWhile()`相应地分别与`skip()`和`limit()`方法很像；然而，新方法适用于Predicate而不是元素的数量。

可以将这些方法想象是具有异常的`filter()`方法。 `filter()`方法评估所有元素上的predicate，而`dropWhile()`和`takeWhile()`方法则从流的起始处对元素进行predicate评估，直到predicate失败。

对于有序流，`dropWhile()`方法返回流的元素，从指定predicate为true的起始处丢弃元素。考虑以下有序的整数流：

```
1, 2, 3, 4, 5, 6, 7
```
如果在dropWhile()方法中使用一个predicate，该方法对小于5的整数返回true，则该方法将删除前四个元素并返回其余部分：

```
5, 6, 7
```

**对于无序流，dropWhile()方法的行为是非确定性的**。 它可以选择删除匹配predicate的任何元素子集。 当前的实现从匹配元素开始丢弃匹配元素，直到找到不匹配的元素。

`dropWhile()`方法有两种极端情况。 如果第一个元素与predicate不匹配，则该方法返回原始流。 如果所有元素与predicate匹配，则该方法返回一个空流。

`takeWhile()`方法的工作方式与dropWhile()方法相同，只不过它从流的起始处返回匹配的元素，而丢弃其余的。

> Tips
>
> 使用dropWhile()和takeWhile()方法处理有序和并行流时要非常小心，因为可能对性能有影响。 在有序的并行流中，元素必须是有序的，在这些方法返回之前从所有线程返回。 这些方法处理顺序流效果最佳。

如果元素为非空，则`Nullable(T t)`方法返回包含指定元素的单个元素的流。 如果指定的元素为空，则返回一个空的流。 在流处理中使用flatMap()方法时，此方法非常有用。 考虑以下map ，其值可能为null：

```java
Map<Integer, String> map = new HashMap<>();
map.put(1, "One");
map.put(2, "Two");
map.put(3, null);
map.put(4, "four");
```

如何在此map中获取一组排除null的值？ 也就是说，如何从这map中获得一个包含“One”，“Two”和“Four”的集合？ 以下是JDK 8中的内容：

```java
// In JDK 8
Set<String> nonNullvalues = map.entrySet()
           .stream()          
           .flatMap(e ->  e.getValue() == null ? Stream.empty() : Stream.of(e.getValue()))
           .collect(toSet());
```

注意在flatMap()方法中的Lambda表达式内使用三元运算符。 可以使用ofNullable()方法在JDK 9中使此表达式更简单：

```java
// In JDK 9
Set<String> nonNullvalues = map.entrySet()
           .stream()          
           .flatMap(e ->  Stream.ofNullable(e.getValue()))
           .collect(toSet());
```

新的`iterate(T seed, Predicate<? super T> hasNext, UnaryOperator<T> next)`方法允许使用初始种子值创建顺序（可能是无限）流，并迭代应用指定的下一个方法。 当指定的hasNext的predicate返回false时，迭代停止。 调用此方法与使用for循环相同：

```java
for (T n = seed; hasNext.test(n); n = next.apply(n)) {
    // n is the element added to the stream
}
```
以下代码片段会生成包含1到10之间的所有整数的流：

Stream.iterate(1, n -> n <= 10, n -> n + 1)
下面包含一个完整的程序，演示如何在Stream接口中使用新的方法。

```java
// StreamTest.java
package com.jdojo.streams;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import static java.util.stream.Collectors.toList;
import static java.util.stream.Collectors.toSet;
import java.util.stream.Stream;
public class StreamTest {
     public static void main(String[] args) {
        System.out.println("Using Stream.dropWhile() and Stream.takeWhile():");
        testDropWhileAndTakeWhile();
        System.out.println("\nUsing Stream.ofNullable():");
        testOfNullable();
        System.out.println("\nUsing Stream.iterator():");
        testIterator();
    }
    public static void testDropWhileAndTakeWhile() {
        List<Integer> list = List.of(1, 3, 5, 4, 6, 7, 8, 9);
        System.out.println("Original Stream: " + list);
        List<Integer> list2 = list.stream()
                                  .dropWhile(n -> n % 2 == 1)
                                  .collect(toList());
        System.out.println("After using dropWhile(n -> n % 2 == 1): " + list2);
        List<Integer> list3 = list.stream()
                                  .takeWhile(n -> n % 2 == 1)
                                  .collect(toList());
        System.out.println("After using takeWhile(n -> n % 2 == 1): " + list3);
    }
    public static void testOfNullable() {
        Map<Integer, String> map = new HashMap<>();
        map.put(1, "One");
        map.put(2, "Two");
        map.put(3, null);
        map.put(4, "Four");
        Set<String> nonNullValues = map.entrySet()
                                       .stream()          
                                       .flatMap(e ->  Stream.ofNullable(e.getValue()))
                                       .collect(toSet());        
        System.out.println("Map: " + map);
        System.out.println("Non-null Values in Map: " + nonNullValues);
    }
    public static void testIterator() {        
        List<Integer> list = Stream.iterate(1, n -> n <= 10, n -> n + 1)
                                   .collect(toList());
        System.out.println("Integers from 1 to 10: " + list);
    }
}
```
输出结果为：

```
Using Stream.dropWhile() and Stream.takeWhile():
Original Stream: [1, 3, 5, 4, 6, 7, 8, 9]
After using dropWhile(n -> n % 2 == 1): [4, 6, 7, 8, 9]
After using takeWhile(n -> n % 2 == 1): [1, 3, 5]
Using Stream.ofNullable():
Map: {1=One, 2=Two, 3=null, 4=Four}
Non-null Values in Map: [One, Four, Two]
Using Stream.iterator():
Integers from 1 to 10: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
```

## 新的收集器

`Collectors`类有以下两个返回Collector新的静态方法：

```java
<T,A,R> Collector<T,?,R> filtering(Predicate<? super T> predicate, Collector<? super T,A,R> downstream)
<T,U,A,R> Collector<T,?,R> flatMapping(Function<? super T,? extends Stream<? extends U>> mapper, Collector<? super U,A,R> downstream)
```

`filtering()`方法返回在收集元素之前应用过滤器的收集器。 如果指定的predicate对于元素返回true，则会收集元素; 否则，元素未被收集。

`flatMapping()`方法返回在收集元素之前应用扁平映射方法的收集器。 指定的扁平映射方法被应用到流的每个元素，并且从扁平映射器（flat mapper）返回的流的元素的累积。

这两种方法都会返回一个最为有用的收集器，这种收集器用于多级别的递减，例如downstream处理分组（groupingBy ）或分区（partitioningBy）。

下面使用Employee类来演示这些方法的使用。

```java
// Employee.java
package com.jdojo.streams;
import java.util.List;
public class Employee {
    private String name;
    private String department;
    private double salary;
    private List<String> spokenLanguages;
    public Employee(String name, String department, double salary,
                    List<String> spokenLanguages) {
        this.name = name;
        this.department = department;
        this.salary = salary;
        this.spokenLanguages = spokenLanguages;
    }
    public String getName() {
        return name;
    }
    public void setName(String name) {
        this.name = name;
    }
    public String getDepartment() {
        return department;
    }
    public void setDepartment(String department) {
        this.department = department;
    }
    public double getSalary() {
        return salary;
    }
    public void setSalary(double salary) {
        this.salary = salary;
    }
    public List<String> getSpokenLanguages() {
        return spokenLanguages;
    }
    public void setSpokenLanguages(List<String> spokenLanguages) {
        this.spokenLanguages = spokenLanguages;
    }
    @Override
    public String toString() {
        return "[" + name + ", " + department + ", " + salary + ", " + spokenLanguages +
               "]";
    }
    public static List<Employee> employees() {
        return List.of(
                new Employee("John", "Sales", 1000.89, List.of("English", "French")),
                new Employee("Wally", "Sales", 900.89, List.of("Spanish", "Wu")),
                new Employee("Ken", "Sales", 1900.00, List.of("English", "French")),
                new Employee("Li", "HR", 1950.89, List.of("Wu", "Lao")),
                new Employee("Manuel", "IT", 2001.99, List.of("English", "German")),
                new Employee("Tony", "IT", 1700.89, List.of("English"))
        );
    }
}
```

一个员工具有姓名，部门，工资以及他或她所说的语言等属性。 toString()方法返回一个表示所有这些属性的字符串。 static employees()方法返回员工们的列表，如表下所示。

|Name|Department|Salary|Spoken|Languages|
|----|----------|------|------|---------|
|John	|Sales	|1000.89	|English, French|
|Wally	|Sales	|900.89	|Spanish, Wu|
|Ken	|Sales	|1900.00	|English, French|
|Li	|HR	|1950.89	|Wu, Lao|
|Manuel	|IT	|2001.99	|English, German|
|Tony	|IT	|1700.89	|English|


可以按照以下方式获取按部门分组的员工列表：

```java
Map<String,List<Employee>> empGroupedByDept = Employee.employees()
                .stream()
                .collect(groupingBy(Employee::getDepartment, toList()));                
System.out.println(empGroupedByDept);
```

输出结果为：

```
{Sales=[[John, Sales, 1000.89, [English, French]], [Wally, Sales, 900.89, [Spanish, Wu]], [Ken, Sales, 1900.0, [English, French]]], HR=[[Li, HR, 1950.89, [Wu, Lao]]], IT=[[Manuel, IT, 2001.99, [English, German]], [Tony, IT, 1700.89, [English]]]}
```

此功能自JDK 8以来一直在Streams API中。现在，假设想获取按部门分组的员工列表，员工的工资必须大于1900才能包含在列表中。 第一个尝试是使用过滤器，如下所示：
```
Map<String, List<Employee>> empSalaryGt1900GroupedByDept = Employee.employees()
                .stream()
                .filter(e -> e.getSalary() > 1900)
                .collect(groupingBy(Employee::getDepartment, toList()));                
System.out.println(empSalaryGt1900GroupedByDept);
```

输出结果为：

```
{HR=[[Li, HR, 1950.89, [Wu, Lao]]], IT=[[Manuel, IT, 2001.99, [English, German]]]}
```

从某种意义上说，已经达到了目标。 但是，结果不包括任何员工工资没有大于1900的部门。这是因为在开始收集结果之前过滤了所有这些部门。 可以使用新的filtering()方法返回的收集器来实现此目的。 这个时候，如果收入1900以上的部门没有员工，该部门将被列入最终结果，并附上一份空的员工列表。

```java
Map<String, List<Employee>> empGroupedByDeptWithSalaryGt1900 = Employee.employees()
                   .stream()
                   .collect(groupingBy(Employee::getDepartment,
                                       filtering(e -> e.getSalary() > 1900.00, toList())));                
System.out.println(empGroupedByDeptWithSalaryGt1900);
```

输出结果为：

```
{Sales=[], HR=[[Li, HR, 1950.89, [Wu, Lao]]], IT=[[Manuel, IT, 2001.99, [English, German]]]}
```

这一次，结果包含Sales部门，即使没有此部门有没有工资在1900以上的员工。

让我们尝试一下按部门分组的员工所说的语言属性的集合。 以下代码片段尝试使用Collectors类的mapping()方法返回的Collector：

```java
Map<String,Set<List<String>>> langByDept = Employee.employees()
                .stream()
                .collect(groupingBy(Employee::getDepartment,
                         mapping(Employee::getSpokenLanguages, toSet())));                
System.out.println(langByDept);
```

输出的结果为：
```
{Sales=[[English, French], [Spanish, Wu]], HR=[[Wu, Lao]], IT=[[English, German], [English]]}
```

如输出所示，使用mapping()方法接收到的是Set<List<String>>而不是Set<String>。 在将字符串收集到一个集合中之前，需要对List <String>进行扁平化以获取字符串流。 使用新的flatMapping()方法返回的收集器来做这项任务：

```java
Map<String,Set<String>> langByDept2 = Employee.employees()
                .stream()
                .collect(groupingBy(Employee::getDepartment,
                         flatMapping(e -> e.getSpokenLanguages().stream(), toSet())));                
System.out.println(langByDept2);
```

输出结果为：

```
{Sales=[English, French, Spanish, Wu], HR=[Lao, Wu], IT=[English, German]}
```

这次得到了正确的结果。 下面包含一个完整的程序，演示如何在收集数据时使用过滤和扁平映射（flat mapping）。

```java
// StreamCollectorsTest.java
package com.jdojo. streams;
import java.util.List;
import java.util.Map;
import java.util.Set;
import static java.util.stream.Collectors.filtering;
import static java.util.stream.Collectors.flatMapping;
import static java.util.stream.Collectors.groupingBy;
import static java.util.stream.Collectors.mapping;
import static java.util.stream.Collectors.toList;
import static java.util.stream.Collectors.toSet;
public class StreamCollectorsTest {
    public static void main(String[] args) {
        System.out.println("Testing Collectors.filtering():");
        testFiltering();
        System.out.println("\nTesting Collectors.flatMapping():");
        testFlatMapping();
    }
    public static void testFiltering() {
        Map<String, List<Employee>> empGroupedByDept = Employee.employees()
                .stream()
                .collect(groupingBy(Employee::getDepartment, toList()));                
        System.out.println("Employees grouped by department:");
        System.out.println(empGroupedByDept);
        // Employees having salary > 1900 grouped by department:
        Map<String, List<Employee>> empSalaryGt1900GroupedByDept = Employee.employees()
                .stream()
                .filter(e -> e.getSalary() > 1900)
                .collect(groupingBy(Employee::getDepartment, toList()));                
        System.out.println("\nEmployees having salary > 1900 grouped by department:");
        System.out.println(empSalaryGt1900GroupedByDept);
        // Group employees by department who have salary > 1900
        Map<String, List<Employee>> empGroupedByDeptWithSalaryGt1900 = Employee.employees()
                .stream()
                .collect(groupingBy(Employee::getDepartment,
                         filtering(e -> e.getSalary() > 1900.00, toList())));                
        System.out.println("\nEmployees grouped by department having salary > 1900:");
        System.out.println(empGroupedByDeptWithSalaryGt1900);
        // Group employees by department who speak at least 2 languages
        // and 1 of them is English
        Map<String, List<Employee>> empByDeptWith2LangWithEn = Employee.employees()
                .stream()
                .collect(groupingBy(Employee::getDepartment,
                        filtering(e -> e.getSpokenLanguages().size() >= 2
                                  &&
                                  e.getSpokenLanguages().contains("English"),
                                  toList())));                        
        System.out.println("\nEmployees grouped by department speaking min. 2" +
                 " languages of which one is English:");
        System.out.println(empByDeptWith2LangWithEn);
    }
    public static void testFlatMapping(){
        Map<String,Set<List<String>>> langByDept = Employee.employees()
                .stream()
                .collect(groupingBy(Employee::getDepartment,
                                mapping(Employee::getSpokenLanguages, toSet())));                
        System.out.println("Languages spoken by department using mapping():");
        System.out.println(langByDept);
        Map<String,Set<String>> langByDept2 = Employee.employees()
                .stream()
                .collect(groupingBy(Employee::getDepartment,
                                flatMapping(e -> e.getSpokenLanguages().stream(), toSet())));  
        System.out.println("\nLanguages spoken by department using flapMapping():");
        System.out.println(langByDept2) ;      
    }        
}
```

输出的结果为：

```
Testing Collectors.filtering():
Employees grouped by department:
{Sales=[[John, Sales, 1000.89, [English, French]], [Wally, Sales, 900.89, [Spanish, Wu]], [Ken, Sales, 1900.0, [English, French]]], HR=[[Li, HR, 1950.89, [Wu, Lao]]], IT=[[Manuel, IT, 2001.99, [English, German]], [Tony, IT, 1700.89, [English]]]}
Employees having salary > 1900 grouped by department:
{HR=[[Li, HR, 1950.89, [Wu, Lao]]], IT=[[Manuel, IT, 2001.99, [English, German]]]}
Employees grouped by department having salary > 1900:
{Sales=[], HR=[[Li, HR, 1950.89, [Wu, Lao]]], IT=[[Manuel, IT, 2001.99, [English, German]]]}
Employees grouped by department speaking min. 2 languages of which one is English:
{Sales=[[John, Sales, 1000.89, [English, French]], [Ken, Sales, 1900.0, [English, French]]], HR=[], IT=[[Manuel, IT, 2001.99, [English, German]]]}
Testing Collectors.flatMapping():
Languages spoken by department using mapping():
{Sales=[[English, French], [Spanish, Wu]], HR=[[Wu, Lao]], IT=[[English, German], [English]]}
Languages spoken by department using flapMapping():
{Sales=[English, French, Spanish, Wu], HR=[Lao, Wu], IT=[English, German]}
```

## 三. 总结

JDK 9向Streams API添加了一些便利的方法，使流处理更容易，并使用收集器编写复杂的查询。

Stream接口有四种新方法：`dropWhile()`，`takeWhile()`，`ofNullable()`和`iterate()`。对于有序流，`dropWhile()`方法返回流的元素，从指定predicate为true的起始处丢弃元素。对于无序流，`dropWhile()`方法的行为是非确定性的。它可以选择删除匹配predicate的任何元素子集。当前的实现从匹配元素开始丢弃匹配元素，直到找到不匹配的元素。 `takeWhile()`方法的工作方式与`dropWhile()`方法相同，只不过它从流的起始处返回匹配的元素，而丢弃其余的。如果元素为非空，则`Nullable(T t)`方法返回包含指定元素的单个元素的流。如果指定的元素为空，则返回一个空的流。新的`iterate(T seed, Predicate<? super T> hasNext, UnaryOperator<T> next)`方法允许使用初始种子值创建顺序（可能是无限）流，并迭代应用指定的下一个方法。当指定的hasNext的predicate返回false时，迭代停止。

Collectors类在JDK 9中有两种新方法：`filtering()`和`flatMapping()`。 `filtering()`方法返回在收集元素之前应用过滤器的收集器。如果指定的predicate对于元素返回true，则会收集元素；否则，元素未被收集。 `flatMapping()`方法返回在收集元素之前应用扁平映射方法的收集器。指定的扁平映射方法被应用到流的每个元素，并且从扁平映射器返回的流的元素的累积。
