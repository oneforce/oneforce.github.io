---
title: 响应式流
date: 2018-4-19 10:10:00
tags:	[Java9,stream]
category: Java 9 Revealed
toc: true
comments: false
---


[原文地址](http://www.cnblogs.com/IcanFixIt/p/7245377.html)

在本章中，主要介绍以下内容：

* 什么是流（stream）
* 响应式流（Reactive Streams）的倡议是什么，以及规范和Java API
* 响应式流在JDK 中的API以及如何使用它们
* 如何使用JDK 9中的响应式流的Java API来创建发布者，订阅者和处理者

## 一. 什么是流

流是由生产者生产并由一个或多个消费者消费的元素（item）的序列。 这种生产者——消费者模型也被称为source/sink模型或发布者——订阅者（publisher-subscriber ）模型。 在本章中，将其称为发布者订阅者模型。

有几种流处理机制，其中pull模型和push模型是最常见的。 在push模型中，发布者将元素推送给订阅者。 在pull模式中，订阅者将元素推送给发布者。 发布者和订阅者都以同样的速率工作，这是一个理想的情况，这些模式非常有效。 我们会考虑一些情况，如果他们不按同样的速率工作，这种情况下涉及的问题以及对应的解决办法。

当发布者比订阅者快的时候，后者必须有一个无边界缓冲区来保存快速传入的元素，或者它必须丢弃它无法处理的元素。 另一个解决方案是使用一种称为背压（backpressure ）的策略，其中订阅者告诉发布者减慢速率并保持元素，直到订阅者准备好处理更多的元素。 使用背压可确保更快的发布者不会压制较慢的订阅者。 使用背压可能要求发布者拥有无限制的缓冲区，如果它要一直生成和保存元素。 发布者可以实现有界缓冲区来保存有限数量的元素，如果缓冲区已满，可以选择放弃它们。 可以使用另一策略，其中发布者将发布元素重新发送到订阅者，这些元素发布时订阅者不能接受。

订阅者在请求发布者的元素并且元素不可用时，该做什么？ 在同步请求中订阅者户必须等待，无限期地，直到有元素可用。 如果发布者同步地向订阅者发送元素，并且订阅者同步处理它们，则发布者必须阻塞直到数据处理完成。 解决方案是在两端进行异步处理，订阅者可以在从发布者请求元素之后继续处理其他任务。 当更多的元素准备就绪时，发布者将它们异步发送给订阅者。

## 二. 什么是响应式流（Reactive Streams）

响应式流从2013年开始，作为提供非阻塞背压的异步流处理标准的倡议。 它旨在解决处理元素流的问题——如何将元素流从发布者传递到订阅者，而不需要发布者阻塞，或订阅者有无限制的缓冲区或丢弃。

响应式流模型非常简单——订阅者向发布者发送多个元素的异步请求。 发布者向订阅者异步发送多个或稍少的元素。

> Tips
>
> 响应式流在pull模型和push模型流处理机制之间动态切换。 当订阅者较慢时，它使用pull模型，当订阅者更快时使用push模型。

在2015年，出版了用于处理响应式流的规范和Java API。 有关响应式流的更多信息，请访问 http://www.reactive-streams.org/ 。 Java API 的响应式流只包含四个接口：

```java
Publisher<T>
Subscriber<T>
Subscription
Processor<T,R>
```

发布者（publisher）是潜在无限数量的有序元素的生产者。 它根据收到的要求向当前订阅者发布（或发送）元素。

订阅者（subscriber）从发布者那里订阅并接收元素。 发布者向订阅者发送订阅令牌（subscription token）。 使用订阅令牌，订阅者从发布者哪里请求多个元素。 当元素准备就绪时，发布者向订阅者发送多个或更少的元素。 订阅者可以请求更多的元素。 发布者可能有多个来自订阅者的元素待处理请求。

订阅（subscription）表示订阅者订阅的一个发布者的令牌。 当订阅请求成功时，发布者将其传递给订阅者。 订阅者使用订阅令牌与发布者进行交互，例如请求更多的元素或取消订阅。

下图显示了发布者和订阅者之间的典型交互顺序。 订阅令牌未显示在图表中。 该图没有显示错误和取消事件。


![](http://blog.oneforce.cn/images/20180419/pub_sub.png)

处理者（processor）充当订阅者和发布者的处理阶段。 `Processor`接口继承了`Publisher`和`Subscriber`接口。 它用于转换发布者——订阅者管道中的元素。 `Processor<T,R>`订阅类型T的数据元素，接收并转换为类型R的数据，并发布变换后的数据。 下图显示了处理者在发布者——订阅和管道中作为转换器的作用。 可以拥有多个处理者。


![](http://blog.oneforce.cn/images/20180419/pub_sub2.png)

下面显示了响应式流倡导所提供的Java API。所有方法的返回类型为void。 这是因为这些方法表示异步请求或异步事件通知。

```java
public interface Publisher<T> {
    public void subscribe(Subscriber<? super T> s);
}
public interface Subscriber<T> {
    public void onSubscribe(Subscription s);
    public void onNext(T t);
    public void onError(Throwable t);
    public void onComplete();
}
public interface Subscription {
    public void request(long n);
    public void cancel();
}
public interface Processor<T,R> extends Subscriber<T>, Publisher<R> {
}
```

用于响应式流的Java API似乎很容易理解。 但是，实现起来并不简单。 发布者和订阅者之间的所有交互的异步性质以及处理背压使得实现变得复杂。 作为应用程序开发人员，会发现实现这些接口很复杂。 类库应该提供实现来支持广泛的用例。 JDK 9提供了Publisher接口的简单实现，可以将其用于简单的用例或扩展以满足自己的需求。 [RxJava](https://github.com/ReactiveX/RxJava)是响应式流的Java实现之一。

## 三. JDK 9 中响应式流的API

JDK 9在java.util.concurrent包中提供了一个与响应式流兼容的API，它在java.base模块中。 API由两个类组成：

```java
Flow
SubmissionPublisher<T>
```

`Flow`类是final的。 它封装了响应式流Java API和静态方法。 由响应式流Java API指定的四个接口作为嵌套静态接口包含在Flow类中：

```java
Flow.Processor<T,R>
Flow.Publisher<T>
Flow.Subscriber<T>
Flow.Subscription
```

这四个接口包含与上面代码所示的相同的方法。 Flow类包含`defaultBufferSize()`静态方法，它返回发布者和订阅者使用的缓冲区的默认大小。 目前，它返回**256**。

`SubmissionPublisher<T>`类是`Flow.Publisher<T>`接口的实现类。 该类实现了`AutoCloseable`接口，因此可以使用try-with-resources块来管理其实例。 JDK 9不提供`Flow.Subscriber<T>`接口的实现类; 需要自己实现。 但是，`SubmissionPublisher<T>`类包含可用于处理此发布者发布的所有元素的`consume(Consumer<? super T> consumer)`方法。

### 发布者——订阅者交互

在开始使用JDK API之前，了解使用响应式流的典型发布者——订阅者会话中发生的事件顺序很重要。 包括在每个事件中使用的方法。 发布者可以拥有零个或多个订阅者。 这里只使用一个订阅者。

* 创建发布者和订阅者，它们分别是`Flow.Publisher`和`Flow.Subscriber`接口的实例。
* 订阅者通过调用发布者的`subscribe()`方法来尝试订阅发布者。 如果订阅成功，发布者用`Flow.Subscription`异步调用订阅者的`onSubscribe()`方法。 如果尝试订阅失败，则使用调用订阅者的`onError()`方法，并抛出`IllegalStateException`异常，并且发布者——订阅者交互结束。
* 订阅者通过调用`Subscription`的`request(N)`方法向发布者发送多个元素的请求。 订阅者可以向发布者发送更多元素的多个请求，而不必等待其先前请求是否完成。
订阅者在所有先前的请求中调用订阅者的`onNext(T item)`方法，直到订阅者户请求的元素数量上限——在每次调用中向订阅者发送一个元素。 如果发布者没有更多的元素要发送给订阅者，则发布者调用订阅者的`onComplete()`方法来发信号通知流，从而结束发布者——订阅者交互。 如果订阅者请求`Long.MAX_VALUE`元素，则它实际上是无限制的请求，并且流实际上是推送流。
* 如果发布者随时遇到错误，它会调用订阅者的`onError()`方法。
* 订阅者可以通过调用其`Flow.Subscription的cancel()`方法来取消订阅。 一旦订阅被取消，发布者——订阅者交互结束。 然而，如果在请求取消之前存在未决请求，订阅者可以在取消订阅之后接收元素。

总结上述结束条件的步骤，一旦在订阅者上调用了`onComplete()`或`onError()`方法，订阅者就不再收到发布者的通知。

在发布者的`subscribe()`方法被调用之后，如果订阅者不取消其订阅，则保证以下订阅方法调用序列：

```
onSubscribe onNext* (onError | onComplete)?
```

这里，符号`*`和`?`在正则表达式中被用作关键字，一个*表示零个或多个出现， `?`意为零或一次。

在订阅者上的第一个方法调用是`onSubscribe()`方法，它是成功订阅发布者的通知。订阅者的`onNext()`方法可以被调用零次或多次，每次调用指示元素发布。`onComplete()`和`onError()`方法可以被调用为零或一次来指示终止状态; 只要订阅者不取消其订阅，就会调用这些方法。

### 创建发布者

创建发布者取决于`Flow.Publisher<T>`接口的实现类。该类包含以下构造函数：

```java
SubmissionPublisher()
SubmissionPublisher(Executor executor, int maxBufferCapacity)
SubmissionPublisher(Executor executor, int maxBufferCapacity, BiConsumer<? super Flow.Subscriber<? super T>,? super Throwable> handler)
```

`SubmissionPublisher`使用提供的`Executor`向其订阅者提供元素。 如果使用多个线程来生成要发布的元素并且可以估计订阅者数量，则可以使用具有固定线程池的`newFixedThreadPool(int nThread)`，这可以使用`Executors`类的`newFixedThreadPool(int nThread)`静态方法获取。 否则，使用默认的`Executor`，它使用`ForkJoinPool`类的`commonPool()`方法获取。

`SubmissionPublisher`类为每个订阅者使用一个独立的缓冲区。 缓冲区大小由构造函数中的`maxBufferCapacity`参数指定。 默认缓冲区大小是`Flow`类的`defaultBufferSize()`静态方法返回的值，该值为256。如果发布的元素数超过了订户的缓冲区大小，则额外的元素将被删除。 可以使用`SubmissionPublisher`类的`getMaxBufferCapacity()`方法获取每个订阅者的当前缓冲区大小。

当订阅者的方法抛出异常时，其订阅被取消。 当订阅者的`onNext()`方法抛出异常时，在其订阅被取消之前调用构造函数中指定的处理程序。 默认情况下，处理程序为null。

以下代码片段会创建一个SubmissionPublisher，它发布所有属性设置为默认值的Long类型的元素：

```java
// Create a publisher that can publish Long values
SubmissionPublisher<Long> pub = new SubmissionPublisher<>();
```

`SubmissionPublisher`类实现了`AutoCloseable`接口。 调用其`close()`方法调用其当前订阅者上的onComplete()方法。 调用`close()`方法后尝试发布元素会抛出`IllegalStateException`异常。

### 发布元素

`SubmissionPublisher<T>`类包含以下发布元素的方法：

```java
int offer(T item, long timeout, TimeUnit unit, BiPredicate<Flow.Subscriber<? super T>,? super T> onDrop)
int offer(T item, BiPredicate<Flow.Subscriber <? super T>,? super T> onDrop)
int submit(T item)
```

`submit()`方法阻塞，直到当前订阅者的资源可用于发布元素。 考虑每个订阅者的缓冲区容量为10的情况。 订阅者订阅了发布者并且不请求任何元素。 发布者发布了10个元素并全部缓冲所有元素。 尝试使用`submit()`方法发布另一个元素将阻塞，因为订阅者的缓冲区已满。

`offer()`方法是非阻塞的。 该方法的第一个版本允许指定超时，之后删除该项。 可以指定一个删除处理器，它是一个`BiPredicate`。 在删除订阅者的元素之前调用删除处理器的`test()`方法。 如果`test()`方法返回true，则再次重试该项。 如果`test()`方法返回false，则在不重试的情况下删除该项。 从`offer()`方法返回的负整数表示向订阅者发送元素失败的尝试次数；正整数表示在所有当前订阅者中提交但尚未消费的最大元素数量的估计。

应该使用哪种方法发布一个元素：`submit()`或`offer()`？ 这取决于你的要求。 如果每个已发布的元素必须发给所有订阅者，则`submit()`方法是最好选择。 如果要等待发布一段特定时间的元素进行重试，则可以使用`offer()`方法。

### 举个例子

来看一个使用`SubmissionPublisher`作为发布者的例子。 `SubmissionPublisher`可以使用其submit(T item)方法发布元素。 以下代码片段生成并发布五个整数（1,2,3,4和5），假设pub是对SubmissionPublisher对象的引用：

```java
// Generate and publish 10 integers
LongStream.range(1L, 6L)
          .forEach(pub::submit);
```

需要订阅者才能使用发布者发布的元素。 `SubmissionPublisher`类包含一个`consume(Consumer<? super T> consumer)`方法，它允许添加一个希望处理所有已发布元素的订阅者，并且对任何其他通知（如错误和完成通知）不感兴趣。 该方法返回一个CompletedFuture<Void>，当发布者调用订阅者的onComplete()方法时，表示完成。 以下代码片段将一个Consumer作为订阅者添加到发布者中：

```java
// Add a subscriber that prints the published items
CompletableFuture<Void> subTask = pub.consume(System.out::println);
```

本章中的代码是com.jdojo.stream的模块的一部分，其声明如下所示。

```java
// module-info.java
module com.jdojo.stream {
    exports com.jdojo.stream;
}
```

下面包含了NumberPrinter类的代码，它显示了如何使用`SubmissionPublisher`类来发布整数。 示例代码的详细说明遵循`NumberPrinter`类的输出。

```java

// NumberPrinter.java
package com.jdojo.stream;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.SubmissionPublisher;
import java.util.stream.LongStream;
public class NumberPrinter {
    public static void main(String[] args) {        
        CompletableFuture<Void> subTask = null;
        // The publisher is closed when the try block exits
        try (SubmissionPublisher<Long> pub = new SubmissionPublisher<>()) {
            // Print the buffer size used for each subscriber
            System.out.println("Subscriber Buffer Size: " + pub.getMaxBufferCapacity());
            // Add a subscriber to the publisher. The subscriber prints the published elements
            subTask = pub.consume(System.out::println);
            // Generate and publish five integers
            LongStream.range(1L, 6L)
                      .forEach(pub::submit);
        }

        if (subTask != null) {
            try {
                // Wait until the subscriber is complete
                subTask.get();
            } catch (InterruptedException | ExecutionException e) {
                e.printStackTrace();
            }
        }
    }
}

```

输出结果为：

```
Subscriber Buffer Size: 256
1
2
3
4
5
```

`main()`方法声明一个`subTask`的变量来保存订阅者任务的引用。 `subTask.get()`方法将阻塞，直到订阅者完成。

```java
CompletableFuture<Void> subTask = null;
```

发布类型为Long的元素发布者是在资源块中创建的。 发布者是SubmissionPublisher<Long>类的实例。 当try块退出时，发布者将自动关闭。

```java
try (SubmissionPublisher<Long> pub = new SubmissionPublisher<>()) {
  //...
}
```

该程序打印将订阅发布者的每个订阅者的缓冲区大小。

```
// Print the buffer size used for each subscriber
System.out.println("Subscriber Buffer Size: " + pub.getMaxBufferCapacity());
```

订阅者将使用consume()方法添加到发布者。 请注意，该方法允许指定一个Consumer，它在内部转换为Subscriber。 每个发布的元素会通知订阅者。 订阅者只需打印它接收的元素。

```java
// Add a subscriber to the publisher. The subscriber prints the published elements
subTask = pub.consume(System.out::println);
```

现在是发布整数的时候了。 该程序生成五个整数，1到5，并使用发布者的submit()方法发布它们。

```java
// Generate and publish five integers
LongStream.range(1L, 6L)
          .forEach(pub::submit);
```

已发布的整数以异步方式发送给订阅者。 当try块退出时，发布者关闭。 要保持程序运行，直到订阅者完成处理所有已发布的元素，必须调用`subTask.get()`。 如果不调用此方法，则可能不会在输出中看到五个整数。

### 创建订阅者

要有订阅者，需要创建一个实现`Flow.Subscriber<T>`接口的类。 实现接口方法的方式取决于具体的需求。 在本节中，将创建一个`SimpleSubscriber`类，该类实现`Flow.Subscriber<Long>`接口。 下面包含此类的代码。

```java
// SimpleSubscriber.java
package com.jdojo.stream;
import java.util.concurrent.Flow;
public class SimpleSubscriber implements Flow.Subscriber<Long> {    
    private Flow.Subscription subscription;
    // Subscriber name
    private String name = "Unknown";
    // Maximum number of items to be processed by this subscriber
    private final long maxCount;
    // keep track of number of items processed
    private long counter;
    public SimpleSubscriber(String name, long maxCount) {
        this.name = name;
        this.maxCount = maxCount <= 0 ? 1 : maxCount;
    }
    public String getName() {
        return name;
    }
    @Override
    public void onSubscribe(Flow.Subscription subscription) {
        this.subscription = subscription;
        System.out.printf("%s subscribed with max count %d.%n", name, maxCount);        
        // Request all items in one go
        subscription.request(maxCount);
    }
    @Override
    public void onNext(Long item) {
        counter++;
        System.out.printf("%s received %d.%n", name, item);
        if (counter >= maxCount) {
            System.out.printf("Cancelling %s. Processed item count: %d.%n", name, counter);            
            // Cancel the subscription
            subscription.cancel();
        }
    }
    @Override
    public void onError(Throwable t) {
        System.out.printf("An error occurred in %s: %s.%n", name, t.getMessage());
    }
    @Override
    public void onComplete() {
        System.out.printf("%s is complete.%n", name);
    }
}
```

`SimpleSubscriber`类的实例表示一个订阅者，它有一个名称和要处理的最大数量的items (maxCount)方法。 需要将其名称和maxCount传递给其构造函数。 如果maxCount小于1，则在构造函数中设置为1。

在`onSubscribe()`方法中，它保存发布者在名为subscription的实例变量中传递的`Flow.Subscription`。 它打印有关`Flow.Subscription`的消息，并请求一次可以处理的所有元素。 该订阅者有效地使用push模型，因为在该请求之后，不再向发布者发送更多的元素的请求。 发布着将推送maxCount或更少的元素数量给该订阅者。

在`onNext()`方法中，它将counter实例变量递增1。counter实例变量跟踪订阅者接收到的元素数量。 该方法打印详细说明接收到的元素消息。 如果它已经收到可以处理的最后一个元素，它将取消订阅。 取消订阅后，发布者不再收到任何元素。

在`onError()`和`onComplete()`方法中，它打印一个有关其状态的消息。

以下代码段创建一个SimpleSubscriber，其名称为S1，可以处理最多10个元素。

SimpleSubscriber sub1 = new SimpleSubscriber("S1", 10);
现在看一下具体使用SimpleSubscriber的例子。 下包含一个完整的程序。 它定期发布元素。 发布一个元素后，它等待1到3秒钟。 等待的持续时间是随机的。 以下详细说明本程序的输出。 该程序使用异步处理可能导致不同输出结果。

```java
// PeriodicPublisher.java
package com.jdojo.stream;
import java.util.Random;
import java.util.concurrent.Flow.Subscriber;
import java.util.concurrent.SubmissionPublisher;
import java.util.concurrent.TimeUnit;
public class PeriodicPublisher {
    final static int MAX_SLEEP_DURATION = 3;
    // Used to generate sleep time
    final static Random sleepTimeGenerator = new Random();
    public static void main(String[] args) {
        SubmissionPublisher<Long> pub = new SubmissionPublisher<>();
        // Create three subscribers
        SimpleSubscriber sub1 = new SimpleSubscriber("S1", 2);
        SimpleSubscriber sub2 = new SimpleSubscriber("S2", 5);
        SimpleSubscriber sub3 = new SimpleSubscriber("S3", 6);
        SimpleSubscriber sub4 = new SimpleSubscriber("S4", 10);
        // Subscriber to the publisher
        pub.subscribe(sub1);
        pub.subscribe(sub2);
        pub.subscribe(sub3);
        // Subscribe the 4th subscriber after 2 seconds
        subscribe(pub, sub4, 2);
        // Start publishing items
        Thread pubThread = publish(pub, 5);
        try {
            // Wait until the publisher is finished
            pubThread.join();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }
    public static Thread publish(SubmissionPublisher<Long> pub, long count) {
        Thread t = new Thread(() -> {
            for (long i = 1; i <= count; i++) {
                pub.submit(i);
                sleep(i);
            }
            // Close the publisher
            pub.close();
        });
        // Start the thread
        t.start();
        return t;
    }
    private static void sleep(Long item) {
        // Wait for 1 to 3 seconds
        int sleepTime = sleepTimeGenerator.nextInt(MAX_SLEEP_DURATION) + 1;
        try {
            System.out.printf("Published %d. Sleeping for %d sec.%n", item, sleepTime);
            TimeUnit.SECONDS.sleep(sleepTime);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }
    private static void subscribe(SubmissionPublisher<Long> pub, Subscriber<Long> sub,
                                  long delaySeconds) {
        new Thread(() -> {
            try {
                TimeUnit.SECONDS.sleep(delaySeconds);
                pub.subscribe(sub);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }            
        }).start();
    }
}
```

输出结果为：

```
S2 subscribed with max count 5.
Published 1. Sleeping for 1 sec.
S3 subscribed with max count 6.
S1 subscribed with max count 2.
S1 received 1.
S3 received 1.
S2 received 1.
Published 2. Sleeping for 1 sec.
S1 received 2.
S2 received 2.
S3 received 2.
Cancelling S1. Processed item count: 2.
S4 subscribed with max count 10.
Published 3. Sleeping for 1 sec.
S4 received 3.
S3 received 3.
S2 received 3.
Published 4. Sleeping for 2 sec.
S4 received 4.
S3 received 4.
S2 received 4.
Published 5. Sleeping for 2 sec.
S2 received 5.
Cancelling S2. Processed item count: 5.
S4 received 5.
S3 received 5.
S3 is complete.
S4 is complete.
```

`PeriodicPublisher`类使用两个静态变量。 `MAX_SLEEP_DURATION`静态变量保存发布这等待发布下一个元素最大秒数。 它设置为3。sleepTimeGenerator静态变量Random对象的引用，该对象在sleep()方法中用于生成下一个等待的随机持续时间。

`PeriodicPublisher`类的`main()`方法执行以下操作：

* 它创建作为SubmissionPublisher<Long>类的实例的发布者。
* 它创建了四个为S1，S2，S3和S4的订阅者。每个订阅者能够处理不同数量的元素。
* 三个订阅者立即订阅。
* S4的订阅者在两秒钟的最短延迟之后以单独的线程订阅。 `PeriodicPublisher`类的`subscribe()`方法负责处理此延迟订阅。注意到在两个元素（1和2）已经发布之后S4订阅的输出中，它将不会收到这两个元素。
* 它调用`publish()`方法，它启动一个新的线程来发布五个元素，它启动线程并返回线程引用。
* `main()`方法调用发布元素线程的`join()`方法，所以在所有元素发布之前程序不会终止。
* `publish()`方法负责发布五个元素。最后关闭发布者。它调用`sleep()`方法，使当前线程休眠一个和**MAX_SLEEP_DURATION**秒之间的随机选择的持续时间。
* 在输出中注意到，一些订阅者取消了订阅，因为他们从发布商那里收到指定数量的元素。

请注意，该程序保证所有元素将在终止之前发布，但不保证所有订阅者都将收到这些元素。 在输出中，会看到订阅者收到所有已发布的元素。 这是因为发布者在发布最后一个元素后等待至少一秒钟，这给了订阅者足够的时间，在这个小程序中接收和处理最后一个元素。

该程序没有表现出背压（backpressure） ，因为所有订阅者都通过一次性请求元素来使用push模型。 可以将SimpleSubscriber类修改为分配任务，以查看背压的效果：

* 在`onSubscribe()`方法中使用`subscription.request(1)`方法请求一个元素。
* 在`onNext()`方法中，延迟后请求更多的元素。 延迟应使订阅者的工作速度较慢，发布者发布元素的速度较慢。
* 需要发布超过256个元素，这是每个发布者向订阅者使用的默认缓冲区，或者使用`SubmissionPublisher`类的另一个构造函数使用较小的缓冲区大小。 这将迫使发布者发布比订阅者可以处理的更多的元素。
* 订阅者使用删除处理程序（ drop handler）订阅，以便可以看到发布者何时发现背压。
* 使用`SubmissionPublisher`类的`offer()`方法发布元素，因此当订阅者无法处理更多元素时，发布者不会无限期地等待。

### 使用处理者

处理者（Processor）同时是订阅者也是发布者。 要使用处理者，需要一个实现`Flow.Processor<T，R>`接口的类，其中T是订阅元素类型，R是已发布的元素类型。 在本节中，创建了一个基于`Predicate<T>`过滤元素的简单处理者。 处理者订阅发布六个整数——1,2,3,4,5和6的发布者。订阅者订阅处理者。 处理者从其发布者接收元素，如果它们通过了`Predicate<T>`指定的标准，则重新发布相同的元素。 下面包含其实例作为处理者的`FilterProcessor<T>`类的代码。

```java
// FilterProcessor.java
package com.jdojo.stream;
import java.util.concurrent.Flow;
import java.util.concurrent.Flow.Processor;
import java.util.concurrent.SubmissionPublisher;
import java.util.function.Predicate;
public class FilterProcessor<T> extends SubmissionPublisher<T> implements Processor<T,T>{
    private Predicate<? super T> filter;
    public FilterProcessor(Predicate<? super T> filter) {
        this.filter = filter;
    }
    @Override
    public void onSubscribe(Flow.Subscription subscription) {
        // Request an unbounded number of items
        subscription.request(Long.MAX_VALUE);
    }
    @Override
    public void onNext(T item) {
        // If the item passes the filter publish it. Otherwise, no action is needed.
        System.out.println("Filter received: " + item);
        if (filter.test(item)) {            
            this.submit(item);
        }
    }
    @Override
    public void onError(Throwable t) {
        // Pass the onError message to all subscribers asynchronously        
        this.getExecutor().execute(() -> this.getSubscribers()
                                             .forEach(s -> s.onError(t)));
    }
    @Override
    public void onComplete() {
        System.out.println("Filter is complete.");
        // Close this publisher, so all its subscribers will receive a onComplete message
        this.close();
    }
}
```

`FilterProcessor<T>`类继承自`SubmissionPublisher<T>`类，并实现了`Flow.Processor<T，T>`接口。 处理者必须是发布者以及订阅者。 从`SubmissionPublisher<T>`类继承了这个类，所以不必编写代码来使其成为发布者。 该类实现了`Processor<T,T>`接口的所有方法，因此它将接收和发布相同类型的元素。

构造函数接受`Predicate<? super T>` 参数并将其保存在实例变量filter中，将在`onNext()`方法中使用filter元素。

`onNext()`方法应用filter。 如果filter返回true，则会将该元素重新发布到其订阅者。 该类从其超类`SubmissionPublisher`继承了用于重新发布元素的`submit()`方法。

`onError()`方法异步地将错误重新发布给其订阅者。 它使用`SubmissionPublisher`类的`getExecutor()`和`getSubscribers()`方法，该方法返回Executor和当前订阅者的列表。 Executor用于异步地向当前订阅者发布消息。

`onComplete()`方法关闭处理者的发布者部分，它将向所有订阅者发送一个onComplete消息。

让我们看看这个处理者具体的例子。 下面包含ProcessorTest类的代码。 可能会得到一个不同的输出，因为这个程序涉及到几个异步步骤。 该程序的详细说明遵循程序的输出。

```java
// ProcessorTest.java
package com.jdojo.stream;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.SubmissionPublisher;
import java.util.concurrent.TimeUnit;
import java.util.stream.LongStream;
public class ProcessorTest {
    public static void main(String[] args) {
        CompletableFuture<Void> subTask = null;
        // The publisher is closed when the try block exits
        try (SubmissionPublisher<Long> pub = new SubmissionPublisher<>()) {
            // Create a Subscriber
            SimpleSubscriber sub = new SimpleSubscriber("S1", 10);
            // Create a processor
            FilterProcessor<Long> filter = new FilterProcessor<>(n -> n % 2 == 0);
            // Subscribe the filter to the publisher and a subscriber to the filter
            pub.subscribe(filter);            
            filter.subscribe(sub);
            // Generate and publish 6 integers
            LongStream.range(1L, 7L)
                      .forEach(pub::submit);
        }
        try {
            // Sleep for two seconds to let subscribers finish handling all items
            TimeUnit.SECONDS.sleep(2);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }
}
```

输出的结果为：

```
S1 subscribed with max count 10.
Filter received: 1
Filter received: 2
Filter received: 3
S1 received 2.
Filter received: 4
S1 received 4.
Filter received: 5
Filter received: 6
Filter is complete.
S1 received 6.
S1 is complete.
```

`ProcessorTest`类的`main()`方法创建一个发布者，它将发布六个整数——1,2,3,4,5和6。该方法做了很多事情：

* 它创建一个使用`try-with-resources`块的发布者，所以当try块退出时它将自动关闭。
* 它创建一个`SimpleSubscriber`类的实例的订阅者。订阅者名为S1，最多可处理10个元素。
* 它创建一个处理者，它是`FilterProcessor<Long>`类的实例。传递一个`Predicate<Long>`，让处理者重新发布整数并丢弃奇数。
* 处理者被订阅发布者，并且简单订阅者被订阅到处理者。这完成了发布者到订阅者的管道——发布者到处理者到订阅者。
* 在第一个try块的末尾，代码生成从1到6的整数，并使用发布者发布它们。
* 在`main()`方法结束时，程序等待两秒钟，以确保处理者和订阅者有机会处理其事件。如果删除此逻辑，程序可能无法打印任何内容。必须包含这个逻辑，因为所有事件都是异步处理的。当第一个try块退出时，发布者将完成向处理者发送所有通知。然而，处理者和订阅者需要一些时间来接收和处理这些通知。

## 总结

流是生产者生产并由一个或多个消费者消费的元素序列。 这种生产者——消费者模型也被称为source/sink模型或发行者——订阅者模型。

有几种流处理机制，pull模型和push模型是最常见的。 在push模型中，发布者将数据流推送到订阅者。 在pull模型中，定于这从发布者拉出数据。 当两端不以相同的速率工作的时，这些模型有问题。 解决方案是提供适应发布者和订阅者速率的流。 使用称为背压的策略，其中订阅者通知发布者它可以处理多少个元素，并且发布者仅向订阅者发送那些需要处理的元素。

响应式流从2013年开始，作为提供非阻塞背压的异步流处理标准的举措。 它旨在解决处理元素流的问题 ——如何将元素流从发布者传递到订阅者，而不需要发布者阻塞，或者订阅者有无限制的缓冲区或丢弃。 响应式流模型在pull模型和push模型流处理机制之间动态切换。 当订阅者处理较慢时，它使用pull模型，当订阅者处理更快时使用push模型。

在2015年，出版了一个用于处理响应式流的规范和Java API。 Java API 中的响应式流由四个接口组成：`Publisher<T>`，`Subscriber<T>`，`Subscription`和`Processor<T,R>`。

发布者根据收到的要求向订阅者发布元素。 用户订阅发布者接收元素。 发布者向订阅者发送订阅令牌。 使用订阅令牌，订阅者从发布者请求多个数据元素。 当数据元素准备就绪时，发布者向订阅者发送多个个或稍少的数据元素。 订阅者可以请求更多的数据元素。

JDK 9在java.util.concurrent包中提供了与响应式流兼容的API，它在java.base模块中。 API由两个类组成：`Flow`和`SubmissionPublisher<T>`。

`Flow`类封装了响应式流Java API。 由响应式流Java API指定的四个接口作为嵌套静态接口包含在Flow类中：`Flow.Processor<T,R>`，`Flow.Publisher<T>`，`Flow.Subscriber<T>`和`Flow.Subscription`。
