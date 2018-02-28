---
title: Java Revealed Chapter 13 Collection API
description: 转载其他人对于Jshell的翻译
date: 2018-2-8 19:00:00
tags:	[Java9,collection, lambda]
category: Java Revealed
toc: true
comments: false
---

[原文地址](http://www.cnblogs.com/IcanFixIt/p/7217042.html)

在本章中，主要介绍以下内容：

* 在JDK 9之前如何创建了不可变的`list`，`set`和`map`以及使用它们的问题。
* 如何使用JDK 9中的`List`接口的`of()`静态工厂方法创建不可变的list。
* 如何使用JDK 9中的`Set`接口的`of()`静态工厂方法创建不可变的set。
* 如何使用JDK 9中的`Map`接口的`of()`，`ofEntries()`和`entry()`静态工厂方法创建不可变的map。

## 一. 背景

Collection API由类和接口组成，提供了一种保存和操作不同类型的对象集合的方法，例如list，set和map。 它在Java SE 1.2版本中添加进来。 Java编程语言不支持Collection Literals，这是一种简单易用的方式来声明和初始化集合。 Collection Literals允许通过在紧凑形式的表达式中指定集合的元素来创建特定类型的集合。 Collection Literals的一个示例是一个列表文字，能够创建一个列表，其中包含100和200的整数，如下所示：

```java
List<Integer> list = [100, 200];
```

Collection Literals紧凑，使用简单。 由于在创建时已知元素的数量，因此可以实现高效的内存使用。 它可以设计成不可变的，使其线程安全。

在Java编程语言中包含Collection Literals语法在JDK 9之前被考虑过几次。 Java设计师决定不将Collection Literals添加到Java语言中，至少不在JDK 9中。在这一点上将Collection Literals添加到Java将需要太多的努力来获得太少的收益。 他们决定通过在List，Set和Map接口中添加静态工厂方法来更新Collection API，从而可以轻松有效地创建小型的，不可变的集合来实现相同的目标。

现有的Collection API创建可变集合。 可以通过将可变集合包装在另一个对象中创建一个不可变的（或不可修改的）集合，该对象只是原始可变对象的包装器。 要在JDK 8或更早版本中创建两个整数的无法修改的列表，通常使用以下代码片段：

```java
// Create an empty, mutable list
List<Integer> list = new ArrayList<>();
// Add two elements to the mutable list
list.add(100);
list.add(200);
// Create an immutable list by wrapping the mutable list
List<Integer> list2 = Collections.unmodifiableList(list);
```

这种做法有严重的缺陷。 不可变的list只是可修改list的包装。 有意的是，将变量名为list。 不能使用list2变量修改列表。但是，仍然可以使用list变量来修改列表，并且在使用list2变量读取list时将会反映出修改。 下面包含一个完整的程序来创建一个不可变的list，并显示如何在以后更改其内容。

```java
// PreJDK9UnmodifiableList.java
package com.jdojo.collection;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
public class PreJDK9UnmodifiableList {
    public static void main(String[] args) {
       List<Integer> list = new ArrayList<>();
       list.add(100);
       list.add(200);
       System.out.println("list = " + list);
       // Create an unmodifiable list
       List<Integer> list2 = Collections.unmodifiableList(list);
       System.out.println("list2 = " + list2);
       // Let us add an element using list
       list.add(300);
       // Print the contents of the list using both
       // variables named list and list2
       System.out.println("list = " + list);
       System.out.println("list2 = " + list2);
    }  
}
```

输出结果为：

```java
list = [100, 200]
list2 = [100, 200]
list = [100, 200, 300]
list2 = [100, 200, 300]
```

输出显示，只要保留原始列表的引用，就可以更改其内容，并且不可变的list也不是真正不可变的！ 解决此问题的方法是使用新的不可变list引用来覆盖原始引用变量，如下所示：

```java
List<Integer> list = new ArrayList<>();
list.add(100);
list.add(200);
// Create an unmodifiable list and store it in list
list = Collections.unmodifiableList(list);
```

注意，此示例使用多个语句来创建和填入不可变的list。 如果需要在类中声明和初始化不可变的list作为实例或静态变量，则该方法不起作用，因为它涉及多个语句。 这样一个声明需要简单，紧凑，并且包含在一个声明中。 如果在类中使用以前的代码来实例变量，那么代码将类似于以下代码：

```java
public class Test {
    private List<Integer> list = new ArrayList<>();
    {
       list.add(100);
       list.add(200);
       list = Collections.unmodifiableList(list);
    }
    // ...
}
```

还有其他方式来声明和初始化一个不可变的list，例如使用数组并将其转换为list。 其中三种方式如下：

```java
public class Test {
    // Using an array and converting it to a list
    private List<Integer> list2 = Collections.unmodifiableList(new ArrayList<>( Arrays.asList(100, 200)));
    // Using an anonymous class
    private List<Integer> list3 = Collections.unmodifiableList(new ArrayList<>(){{add(100); add(200);}});
    // Using a stream
    private List<Integer> list4 = Collections.unmodifiableList(Stream.of(100, 200).collect(Collectors.toList()));
    // More code goes here
}
```

此示例证明可以在一个语句中具有不可变的list。 但是，语法是冗长的。 再是效率低下。 例如，只要在list中保存两个整数，则需要创建具有后备数组对象的多个对象来保存这些值。

JDK 9通过向List，Set和Map接口提供静态工厂方法来解决这些问题。 该方法命名为of()并且被重载。 在JDK 9中，可以声明和初始化两个元素的不可变列表，如下所示：

```java
// Create an unmodifiable list of two integers
List<Integer> list = List.of(100, 200);
```

## 二. 不可变的list

JDK 9将`of()`静态工厂方法重载到List接口。 它提供了一种简单而紧凑的方式来创建不可变的list。 以下是of()方法的所有版本：

```java
static <E> List<E> of()
static <E> List<E> of(E e1)
static <E> List<E> of(E e1, E e2)
static <E> List<E> of(E e1, E e2, E e3)
static <E> List<E> of(E e1, E e2, E e3, E e4)
static <E> List<E> of(E e1, E e2, E e3, E e4, E e5)
static <E> List<E> of(E e1, E e2, E e3, E e4, E e5, E e6)
static <E> List<E> of(E e1, E e2, E e3, E e4, E e5, E e6, E e7)
static <E> List<E> of(E e1, E e2, E e3, E e4, E e5, E e6, E e7, E e8)
static <E> List<E> of(E e1, E e2, E e3, E e4, E e5, E e6, E e7, E e8, E e9)
static <E> List<E> of(E e1, E e2, E e3, E e4, E e5, E e6, E e7, E e8, E e9, E e10)
static <E> List<E> of(E... elements)
```

`of()`方法有11个特定版本来创建零到十个元素的list。 另一个版本采用可变参数来允许创建任何数量的元素的不可变的list。 你可能会想知道当使用可变参数的版本可以创建具有任意数量的元素的列表时，为什么有这么多版本的方法。 它们存在为性能原因。 API设计人员希望能够有效地使用少量元素的列表。 使用数组实现可变参数。 存在具有非可变参数的方法，以避免将参数装入数组中，这使得它们更有效率。 这些方法使用List接口的特殊实现类用于较小的list。

of()方法返回的list具有以下特征：

* 结构上是不可变的。 尝试添加，替换或删除元素会抛出`UnsupportedOperationException`异常。
* 不允许null元素。 如果列表中的元素为null，则抛出`NullPointerException`异常。
* 如果所有元素是可序列化的，那么它们也是可序列化的。
* 元素的顺序与of()方法中指定的，与of(E… elements)方法的可变参数版本中使用的数组相同。
* 对返回的列表的实现类没有保证。 也就是说，不要指望返回的对象是ArrayList或任何其他实现List接口的类。 这些方法的实现是内部的，不应该假定他们的类名。 例如，`List.of()`和`List.of("A")`可能会返回两个不同类的对象。

`Collections`类包含一个EMPTY_LIST的静态属性，表示不可变的空list。 它还包含一个`emptyList()`的静态方法来获取不可变的空list。`singletonList(T object)`方法返回具有指定元素的不可变单例list。 以下代码片段显示了JDK 9和JDK 9之前创建不可变的空和单例list的方式。

```java
// Creating an empty, immutable List before JDK 9
List<Integer> emptyList1 = Collections.EMPTY_LIST;
List<Integer> emptyList2 = Collections.emptyList();
// Creating an empty list in JDK 9
List<Integer> emptyList = List.of();
// Creating a singleton, immutable List before JDK 9
List<Integer> singletonList1 = Collections.singletonList(100);
// Creating a singleton, immutable List in JDK 9
List<Integer> singletonList = List.of(100);
```

如何使用of()方法从数组中创建一个不可变的list？ 答案取决于你想要从数组的列表。 可能需要一个list，其元素与数组的元素相同，或者可能希望使用数组本身作为列表中唯一元素的list。 使用`List.of(array)`将调用`of(E... elements)`方法，返回的列表将其元素与数组中的元素相同。 如您希望数组本身是list中的唯一元素，则需要使用`List.<array-type>of(array)`方法，这将调用`of(E e1)`方法，返回的列表将具有一个 元素，它是数组本身。 以下代码使用Integer数组来演示：

```java
Integer[] nums = {100, 200};
// Create a list whose elements are the same as the elements
// in the array
List<Integer> list1 = List.of(nums);        
System.out.println("list1 = " + list1);
System.out.println("list1.size() = " + list1.size());
// Create a list whose sole element is the array itself
List<Integer[]> list2 = List.<Integer[]>of(nums);        
System.out.println("list2 = " + list2);
System.out.println("list2.size() = " + list2.size());
```
输出结果为：

```bash
list1 = [100, 200]
list1.size() = 2
list2 = [[Ljava.lang.Integer;@7efef64]
list2.size() = 1
```

下面包含一个完整的程序，显示如何使用List接口的of()静态工厂方法来创建不可变的list。

```java
// ListTest.java
package com.jdojo.collection;
import java.util.List;
public class ListTest {
    public static void main(String[] args) {
        // Create few unmodifiable lists
        List<Integer> emptyList = List.of();
        List<Integer> luckyNumber = List.of(19);
        List<String> vowels = List.of("A", "E", "I", "O", "U");
        System.out.println("emptyList = " + emptyList);
        System.out.println("singletonList = " + luckyNumber);
        System.out.println("vowels = " + vowels);
        try {
            // Try using a null element
            List<Integer> list = List.of(1, 2, null, 3);
        } catch(NullPointerException e) {
            System.out.println("Nulls not allowed in List.of().");
        }
        try {
            // Try adding an element
            luckyNumber.add(8);
        } catch(UnsupportedOperationException e) {
            System.out.println("Cannot add an element.");
        }
        try {
            // Try removing an element
            luckyNumber.remove(0);
        } catch(UnsupportedOperationException e) {
            System.out.println("Cannot remove an element.");
        }
    }
}
```

输出结果为：

```
emptyList = []
singletonList = [19]
vowels = [A, E, I, O, U]
Nulls not allowed in List.of().
Cannot add an element.
Cannot remove an element .
```

## 三. 不可变的set

JDK 9在Set接口中添加了`of()`静态工厂方法的重载。 它提供了一种简单而紧凑的方式来创建不可变的set。 以下是of()方法的所有版本：

```java
static <E> Set<E> of()
static <E> Set<E> of(E e1)
static <E> Set<E> of(E e1, E e2)
static <E> Set<E> of(E e1, E e2, E e3)
static <E> Set<E> of(E e1, E e2, E e3, E e4)
static <E> Set<E> of(E e1, E e2, E e3, E e4, E e5)
static <E> Set<E> of(E e1, E e2, E e3, E e4, E e5, E e6)
static <E> Set<E> of(E e1, E e2, E e3, E e4, E e5, E e6, E e7)
static <E> Set<E> of(E e1, E e2, E e3, E e4, E e5, E e6, E e7, E e8)
static <E> Set<E> of(E e1, E e2, E e3, E e4, E e5, E e6, E e7, E e8, E e9)
static <E> Set<E> of(E e1, E e2, E e3, E e4, E e5, E e6, E e7, E e8, E e9, E e10)
static <E> Set<E> of(E... elements)
```

`of()`方法的所有版本为性能都做了调整。 可以使用前11个版本来创建一个不可变的零到十个元素的set。 of方法的前11个版本与可变参数的版本一起存在的原因是为了避免将参数装入数组中，最多可设置10个元素。 可变参数的版本可用于创建一个包含任意数量元素的不可变set。

`of()`方法返回的set具有以下特征：

* 结构上是不可变的。 尝试添加，替换或删除元素会抛出UnsupportedOperationException异常。
* 不允许null元素。 如果set中的元素为null，则抛出NullPointerException异常。
* 如果所有元素是可序列化的，那么它们是可序列化的。
* 不允许重复元素。 指定重复的元素会引发一个IllegalArgumentException。
* 元素的迭代顺序是未指定的。
* 对于返回的集合的实现类不能保证。 也就是说，不要指望返回的对象是HashSet或任何其他实现Set接口的类。 这些方法的实现是内部的，不应该假定他们的类名。 例如，`Set.of()`和`Set.of(“A”)`可能返回两个不同类的对象。

Collections类包含一个EMPTY_SET的静态属性，表示不可变的空set。 它还包含emptySet()的静态方法来获取不可变的空set。 它的singleton(T object)方法返回具有指定元素的不可变单例set。 以下代码片段显示了JDK 9和JDK 9之前创建不可变的空和单例set的方法：

```java
// Creating an empty, immutable Set before JDK 9
Set<Integer> emptySet1 = Collections.EMPTY_SET;
Set<Integer> emptySet2 = Collections.emptySet();
// Creating an empty Set in JDK 9
Set<Integer> emptySet = Set.of();
// Creating a singleton, immutable Set before JDK 9
Set<Integer> singletonSet1 = Collections.singleton(100);
// Creating a singleton, immutable Set in JDK 9
Set<Integer> singletonSet = Set.of(100);
```

以下代码显示了如何从数组中创建一个不可变的set。 可以有一个set的元素与数组的元素相同，或者可以使用集合作为唯一元素的集合。 注意，当使用数组元素作为集合的元素时，该数组不能具有重复的元素。 否则，Set.of()方法将抛出IllegalArgumentException异常。

```java
Integer[] nums = {100, 200};
// Create a set whose elements are the same as the
// elements of the array
Set<Integer> set1 = Set.of(nums);
System.out.println("set1 = " + set1);
System.out.println("set1.size() = " + set1.size());
// Create a set whose sole element is the array itself
Set<Integer[]> set2 = Set.<Integer[]>of(nums);
System.out.println("set2 = " + set2);
System.out.println("set2.size() = " + set2.size());
// Create an array with duplicate elements
Integer[] nums2 = {101, 201, 101};
// Try creating a set with the array as its sole element
Set<Integer[]> set3 = Set.<Integer[]>of(nums2);
System.out.println("set3 = " + set3);
System.out.println("set3.size() = " + set3.size());
try {
    // Try creating a set whose elements are the elements of
    // the array. It will throw an IllegalArgumentException.
    Set<Integer> set4 = Set.of(nums2);
    System.out.println("set4 = " + set4);
} catch(IllegalArgumentException e) {
    System.out.println(e.getMessage());
}
```

输出结果为：

```bash
set1 = [100, 200]
set1.size() = 2
set2 = [[Ljava.lang.Integer;@47c62251]
set2.size() = 1
set3 = [[Ljava.lang.Integer;@3e6fa38a]
set3.size() = 1
duplicate element: 101
```

下面包含一个完整的程序，显示如何使用Set接口的`of()`静态工厂方法来创建不可变的set。 注意程序中包含元音元素的set的输出。 组合的元素可能不会以创建set时指定的相同顺序输出，因为set不保证其元素的顺序。

```java
// SetTest.java
package com.jdojo.collection;
import java.util.Set;
public class SetTest {
    public static void main(String[] args) {
        // Create few unmodifiable sets
        Set<Integer> emptySet = Set.of();
        Set<Integer> luckyNumber = Set.of(19);
        Set<String> vowels = Set.of("A", "E", "I", "O", "U");
        System.out.println("emptySet = " + emptySet);
        System.out.println("singletonSet = " + luckyNumber);
        System.out.println("vowels = " + vowels);
        try {
            // Try using a null element
            Set<Integer> set = Set.of(1, 2, null, 3);
        } catch(NullPointerException e) {
            System.out.println("Nulls not allowed in Set.of().");
        }
        try {
            // Try using duplicate elements
            Set<Integer> set = Set.of(1, 2, 3, 2);
        } catch(IllegalArgumentException e) {
            System.out.println(e.getMessage());
        }
        try {
            // Try adding an element
            luckyNumber.add(8);
        } catch(UnsupportedOperationException e) {
            System.out.println("Cannot add an element.");
        }
         try {
            // Try removing an element
            luckyNumber.remove(0);
        } catch(UnsupportedOperationException e) {
            System.out.println("Cannot remove an element.");
        }
    }
}
```

以下是输出结果：

```bash
emptySet = []
singletonSet = [19]
vowels = [E, O, A, U, I]
Nulls not allowed in Set.of().
duplicate element: 2
Cannot add an element.
Cannot remove an element.
```

## 四. 不可变的map

JDK 9将`of()`静态工厂方法重载添到Map接口中。 它提供了一种简单而紧凑的方式来创建不可变的map。 方法的实现为性能做了调整。 以下是`of()`方法的11个版本，可以创建一个不可变的零到十个键值条目的map：

```java
static <K,V> Map<K,V> of()
static <K,V> Map<K,V> of(K k1, V v1)
static <K,V> Map<K,V> of(K k1, V v1, K k2, V v2)
static <K,V> Map<K,V> of(K k1, V v1, K k2, V v2, K k3, V v3)
static <K,V> Map<K,V> of(K k1, V v1, K k2, V v2, K k3, V v3, K k4, V v4)
static <K,V> Map<K,V> of(K k1, V v1, K k2, V v2, K k3, V v3, K k4, V v4, K k5, V v5)
static <K,V> Map<K,V> of(K k1, V v1, K k2, V v2, K k3, V v3, K k4, V v4, K k5, V v5, K k6, V v6)
static <K,V> Map<K,V> of(K k1, V v1, K k2, V v2, K k3, V v3, K k4, V v4, K k5, V v5, K k6, V v6, K k7, V v7)
static <K,V> Map<K,V> of(K k1, V v1, K k2, V v2, K k3, V v3, K k4, V v4, K k5, V v5, K k6, V v6, K k7, V v7, K k8, V v8)
static <K,V> Map<K,V> of(K k1, V v1, K k2, V v2, K k3, V v3, K k4, V v4, K k5, V v5, K k6, V v6, K k7, V v7, K k8, V v8, K k9, V v9)
static <K,V> Map<K,V> of(K k1, V v1, K k2, V v2, K k3, V v3, K k4, V v4, K k5, V v5, K k6, V v6, K k7, V v7, K k8, V v8, K k9, V v9, K k10, V v10)
```
注意在`of()`方法中的参数的位置。 第一个和第二个参数分别是map中第一个键值对的键和值；第三个和第四个参数分别是map中第二个键值对的键和值。 注意，在Map中，没有像在List和Set中可变参数的`of()`方法。 这是因为Map条目包含两个值（键值和值），并且Java中的方法中只能有一个可变参数。 以下代码片段显示了如何使用`of()`方法创建map：

```java
// An empty, unmodifiable Map
Map<Integer, String> emptyMap = Map.of();
// A singleton, unmodifiable Map
Map<Integer, String> singletonMap = Map.of(1, "One");
// A unmodifiable Map with two entries
Map<Integer, String> luckyNumbers = Map.of(1, "One", 2, "Two");
```

要创建具有任意数量条目的不可修改的Map，JDK 9在Map接口中提供了一个`ofEntries()`的静态方法，它的签名如下：

```java
<K,V> Map<K,V> ofEntries(Map.Entry<? extends K,? extends V>... entries)
```

要使用`ofEntries()`方法，需要在`Map.Entry`实例中包含每个map键值对。 JDK 9在Map接口中提供了一个方便的`entry()`静态方法来创建`Map.Entry`的实例。 `entry()`方法的签名如下：

```java
<K,V> Map.Entry<K,V> entry(K k, V v)
```

为了保持表达式的可读性和紧凑性，需要为Map.entry方法使用静态导入，并使用如下所示的语句来创建一个具有任意数量条目的不可修改的map：

```java
import java.util.Map;
import static java.util.Map.entry;
// ...
// Use the Map.ofEntries() and Map.entry() methods to
// create an unmodifiable Map
Map<Integer, String> numberToWord =
          Map.ofEntries(entry(1, "One"),
                        entry(2, "Two"),
                        entry(3, "Three"));
```

Map接口的`of()`和`ofEntries()`方法返回的map具有以下特征：

* 在结构上是不可变的。 尝试添加，替换或删除条目会抛出`UnsupportedOperationException`异常。
* 不允许在键或值中为null。 如果map中的键或值为null，则抛出`NullPointerException`异常。
* 如果所有键和值都是可序列化的，它们是可序列化的。
* 不允许重复的键。 指定重复的键会引发`IllegalArgumentException`异常。
* 映射的迭代顺序是未指定的。
* 对于返回的Map的实现类不能保证。 也就是说，不要指望返回的对象是HashMap或实现Map接口的任何其他类。 这些方法的实现是内部的，不应该假定他们的类名。 例如，`Map.of()`和`Map.of(1, "One")`可能会返回两个不同类的对象。

Collections类包含EMPTY_MAP的静态字段，表示不可变的空map。 它还包含一个emptyMap()的静态方法来获取不可变的空map。 `singletonMap(K key, V value)`方法返回具有指定键和值的不可变的单例map。 以下代段显示了JDK 9和JDK 9之前创建不可变空map和单例map的方式：

```java
// Creating an empty, immutable Map before JDK 9
Map<Integer,String> emptyMap1 = Collections.EMPTY_MAP;
Map<Integer,String> emptyMap2 = Collections.emptyMap();
// Creating an empty Map in JDK 9
Map<Integer,String> emptyMap = Map.of();
// Creating a singleton, immutable Map before JDK 9
Map<Integer,String> singletonMap1 =
    Collections.singletonMap(1, "One");
// Creating a singleton, immutable Map in JDK 9
Map<Integer,String> singletonMap = Map.of(1, "One");
```

下面包含一个完整的程序，显示如何使用Map接口的of()，ofEntries()和entry() 静态方法来创建不可变的
map。 请注意map中指定日期的顺序以及输出中显示的顺序。 它们可能不匹配，因为map更像set，不能保证其条目的检索顺序。

```java
// MapTest.java
package com.jdojo.collection;
import java.util.Map;
import static java.util.Map.entry;
public class MapTest {
    public static void main(String[] args) {
        // Create few unmodifiable maps
        Map<Integer,String> emptyMap = Map.of();
        Map<Integer,String> luckyNumber = Map.of(19, "Nineteen");
        Map<Integer,String> numberToWord =
                Map.of(1, "One", 2, "Two", 3, "Three");
        Map<String,String> days = Map.ofEntries(
                entry("Mon", "Monday"),
                entry("Tue", "Tuesday"),
                entry("Wed", "Wednesday"),
                entry("Thu", "Thursday"),
                entry("Fri", "Friday"),
                entry("Sat", "Saturday"),
                entry("Sun", "Sunday"));
        System.out.println("emptyMap = " + emptyMap);
        System.out.println("singletonMap = " + luckyNumber);
        System.out.println("numberToWord = " + numberToWord);
        System.out.println("days = " + days);
        try {
            // Try using a null value
            Map<Integer,String> map = Map.of(1, null);
        } catch(NullPointerException e) {
            System.out.println("Nulls not allowed in Map.of().");
        }
        try {
            // Try using duplicate keys
            Map<Integer,String> map = Map.of(1, "One", 1, "On");
        } catch(IllegalArgumentException e) {
            System.out.println(e.getMessage());
        }
        try {
            // Try adding an entry
            luckyNumber.put(8, "Eight");
        } catch(UnsupportedOperationException e) {
            System.out.println("Cannot add an entry.");
        }
         try {
            // Try removing an entry
            luckyNumber.remove(0);
        } catch(UnsupportedOperationException e) {
            System.out.println("Cannot remove an entry.");
        }
    }
}
```

输出结果为：

```
emptyMap = {}
singletonMap = {19=Nineteen}
numberToWord = {1=One, 3=Three, 2=Two}
days = {Sat=Saturday, Tue=Tuesday, Thu=Thursday, Sun=Sunday, Wed=Wednesday, Fri=Friday, Mon=Monday}
Nulls not allowed in Map.of().
duplicate key: 1
Cannot add an entry.
Cannot remove an entry.
```

## 五. 总结

在Java语言中支持collection literals是非常需要的功能。 JDK 9替代了对collection literals的支持，更新了Collection API，而是在List，Set和Map接口中添加了`of()`静态工厂方法，分别返回一个不可变的List，Set和Map。该方法被重载，指定集合的零到十个元素。 List和Set接口提供了可变参数的`of()`方法，用于创建一个包含任意数量的元素的List和Set。 Map接口提供了`ofEntries()`静态工厂方法，用于创建一个不可变的任意数量条目的Map。 Map接口还包含一个静态的entry()方法，它接受一个键和一个值作为参数并返回一个`Map.Entry`实例。 `ofEntries()`和`entry()`方法一起使用来创建任意数量条目的不可变的Map。

这些接口中的新的静态工厂方法为性能做了调整。 `List.of()`和`Set.of()`方法不允许使用null元素。 `Set.of()`方法不允许重复的元素。 `Map.of()`和`Map.ofEntries()`方法不允许重复键，或者将null作为键或值。
