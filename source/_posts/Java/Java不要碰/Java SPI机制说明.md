---
title: Java spi
description: 这个系列是我的“java不要碰系列的第一篇文章，是我希望梳理整个Java职业生涯的各种问题的记录。希望能给立志于做java的工程师们一个技术上的支持”
date: 2018-3-5 19:00:00
tags:	[java不要碰]
toc: true
finished: true
comments: true
---


## Java SPI 说明

SPI的全名为Service Provider Interface.普通开发人员可能不熟悉，因为这个是针对厂商或者插件的,是JDK内置的一种服务提供发现机制。在`java.util.ServiceLoader`的文档里有比较详细的介绍.



#### service

一组编程接口和类，可以访问某些特定的应用程序功能或特性。该服务可以定义功能的接口和检索实现的方法。它依赖于服务提供者来实现该功能。

#### Service provider interface (SPI)

服务定义的一组公共接口和抽象类。 SPI定义了可用于您的应用程序的类和方法。

#### Service Provider

实现SPI。具有可扩展服务的应用程序使您，供应商和客户能够在不修改原始应用程序的情况下添加服务提供商。


我们已为例，来说明下具体如何在工程中使用Java SPI

首先，我们需要有一个明确的interface，来提供给


注意点

* 实现类必须有一个无参构造方法
* META-INF/services下的文件格式是无BOM的UTF8
* META-INF/services中每一行代表一个实现，可以使用“#”进行注释


ServiceLoader的接口说明

```
public Iterator<S> iterator()
public static <S> ServiceLoader<S> load(Class<S> service, ClassLoader loader)
public static <S> ServiceLoader<S> load(Class<S> service)
public static <S> ServiceLoader<S> loadInstalled(Class<S> service)
```

关于使用自定
```
ServiceLoader<DemoService> serviceLoader = ServiceLoader.load(DemoService.class);
Iterator<DemoService> it = serviceLoader.iterator();
while (it!=null && it.hasNext()) {
  DemoService demoService = it.next();
  System.out.println("class:"+demoService.getClass().getName()+"***"+demoService.sayHi("World"));
}
```

## Java SPI解决什么问题

> Java SPI是java自带了一个依赖倒转原则的解决方案：要针对接口编程，而不是针对实现编程。[依赖倒转原则][1]

## Java SPI 工程实践

### java 的jdbc

在JDBC4.0之前，我们开发有连接数据库的时候，通常会用`Class.forName("com.mysql.jdbc.Driver")`这句先加载数据库相关的驱动，然后再进行获取连接等的操作。而JDBC4.0之后不需要用`Class.forName("com.mysql.jdbc.Driver")`来加载驱动，直接获取连接就可以了，现在这种方式就是使用了Java的SPI扩展机制来实现。

首先在java中定义了接口`java.sql.Driver`，并没有具体的实现，具体的实现都是由不同厂商来提供的。

我们举例mysql(mysql-connector-java-6.0.5.jar)和h2(h2-1.4.193.jar)

#### mysql实现

在mysql的jar包`mysql-connector-java-6.0.6.jar`中，可以找到`META-INF/services`目录，该目录下会有一个名字为`java.sql.Driver`的文件，文件内容是`com.mysql.cj.jdbc.Driver`，这里面的内容就是针对Java中定义的接口的实现。

#### h2 实现

在h2的`h2-1.4.193.jar`中，可以找到`META-INF/services`目录，该目录下会有一个名字为`java.sql.Driver`的文件，文件内容是`org.h2.Driver`，这里面的内容就是针对Java中定义的接口的实现。

#### 机制说明

DriverManager
```
static {
    loadInitialDrivers();
    println("JDBC DriverManager initialized");
}
```

```
private static void loadInitialDrivers() {
        String drivers;
        try {
            drivers = AccessController.doPrivileged(new PrivilegedAction<String>() {
                public String run() {
                    return System.getProperty("jdbc.drivers");
                }
            });
        } catch (Exception ex) {
            drivers = null;
        }
        // If the driver is packaged as a Service Provider, load it.
        // Get all the drivers through the classloader
        // exposed as a java.sql.Driver.class service.
        // ServiceLoader.load() replaces the sun.misc.Providers()

        AccessController.doPrivileged(new PrivilegedAction<Void>() {
            public Void run() {

                ServiceLoader<Driver> loadedDrivers = ServiceLoader.load(Driver.class);
                Iterator<Driver> driversIterator = loadedDrivers.iterator();

                /* Load these drivers, so that they can be instantiated.
                 * It may be the case that the driver class may not be there
                 * i.e. there may be a packaged driver with the service class
                 * as implementation of java.sql.Driver but the actual class
                 * may be missing. In that case a java.util.ServiceConfigurationError
                 * will be thrown at runtime by the VM trying to locate
                 * and load the service.
                 *
                 * Adding a try catch block to catch those runtime errors
                 * if driver not available in classpath but it's
                 * packaged as service and that service is there in classpath.
                 */
                try{
                    while(driversIterator.hasNext()) {
                        driversIterator.next();
                    }
                } catch(Throwable t) {
                // Do nothing
                }
                return null;
            }
        });

        println("DriverManager.initialize: jdbc.drivers = " + drivers);

        if (drivers == null || drivers.equals("")) {
            return;
        }
        String[] driversList = drivers.split(":");
        println("number of Drivers:" + driversList.length);
        for (String aDriver : driversList) {
            try {
                println("DriverManager.Initialize: loading " + aDriver);
                Class.forName(aDriver, true,
                        ClassLoader.getSystemClassLoader());
            } catch (Exception ex) {
                println("DriverManager.Initialize: load failed: " + ex);
            }
        }
    }
```

### common-logging & sflog

`common-logging`中提供对于logfactory的实现。为了让框架本身支持其他的日志系统，提供了SPI的接口。这样`sflog`这样的后来者，就可以提供对应的service provider来实现自己的log框架，而不用配合修改common-logging
具体实现代码如下

common-logging中的`logfactory.getFactory()``

sflog(jcl-over-slf4j-1.7.21.jar)中的`META-INF/service/org.apache.commons.logging.LogFactory`

```
org.apache.commons.logging.impl.SLF4JLogFactory
```

### spring-web
spring-web使用j2ee的扩展机制提供了`META-INF/service/javax.servlet.ServletContainerInitializer`
具体大家可以查看下 ServletContainerInitializer 的 [doc文档](https://docs.oracle.com/javaee/6/api/index.html?javax/servlet/ServletContainerInitializer.html)

### javax.validation & hibernate-validator

hibernate-validator也是扩展了javax.validation.spi的相关接口 具体查看查看ValidationProviderResolver的 [doc文档](https://docs.oracle.com/javaee/6/api/index.html?javax/validation/package-summary.html)

## 其他 java支持的各种service provider

### J2EE&J2SE

相关的信息都在java doc中有说明，我就不意义展开了，有兴趣的同学可以通过下面两个搜索条件看看相关的系统框架中支持哪些service provider的扩展

* **J2SE（JDK8）** "service provider" site:https://docs.oracle.com/javase/8/docs/api/
* **Java EE（6）** "service provider" site:https://docs.oracle.com/javaee/6/api/index.html

## Java SPI 优缺点和使用场景

### Java SPI 优点

* JDK系统自带，只要你的java版本在1.6之上，就支持SPI功能
* 简单，轻量。给系统的可扩展性做了补充
* 提供了系统级的依赖反转功能（IOC）

### Java SPI 缺点

* 使用SPI查找具体的实现的时候，需要遍历所有的实现，并实例化，然后我们在循环中才能找到我们需要实现。这应该也是最大的缺点，需要把所有的实现都实例化了，即便我们不需要，也都给实例化了。
* 可以实现建议的IOC功能，但是如果需要实现复杂的AOP，服务动态刷新等机制，就力不从心了。


## 使用场景

* JDK中有些组建自带了service provider矿建（如 javax.validation），如果你需要扩展，应该优先使用。
* 当系统需要实现IOC功能，但是又不希望使用复杂、臃肿的第三方包（如spring、guice）可以使用简单的service provider来实现


相关链接

* [JAR File Specification#Service Provider](https://docs.oracle.com/javase/8/docs/technotes/guides/jar/jar.html#Service_Provider)
* [Introduction to the Service Provider Interfaces](https://docs.oracle.com/javase/tutorial/sound/SPI-intro.html)

[1]: https://gof.quanke.name/%E9%9D%A2%E5%90%91%E5%AF%B9%E8%B1%A1%E8%AE%BE%E8%AE%A1%E5%8E%9F%E5%88%99%E4%B9%8B%E4%BE%9D%E8%B5%96%E5%80%92%E8%BD%AC%E5%8E%9F%E5%88%99.html
