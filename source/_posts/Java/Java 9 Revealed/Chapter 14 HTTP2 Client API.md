---
title: http/2 client API
date: 2018-3-5 19:10:00
tags:	[Java9,http/2]
category: Java 9 Revealed
toc: true
comments: false
---

[原文地址](http://www.cnblogs.com/IcanFixIt/p/7229611.html)

在此章中，主要介绍以下内容：

* 什么是HTTP/2 Client API
* 如何创建HTTP客户端
* 如何使HTTP请求
* 如何接收HTTP响应
* 如何创建WebSocket的endpoints
* 如何将未经请求的数据从服务器推送到客户端

JDK 9将`HTTP/2 Client API`作为名为`jdk.incubator.httpclient`的孵化器模块。 该模块导出包含所有公共API的`jdk.incubator.http`包。 孵化器模块不是Java SE的一部分。 在Java SE 10中，它将被标准化，并成为Java SE 10的一部分，否则将被删除。 请参阅 http://openjdk.java.net/jeps/11上的网页，以了解有关JDK中孵化器模块的更多信息。

孵化器模块在编译时或运行时未被默认解析，因此需要使用`--add-modules`选项将`jdk.incubator.httpclient`模块添加到默认的根模块中，如下所示：

```bah
<javac|java|jmod...> -add-modules jdk.incubator.httpclient ...
```

如果另一个模块读取并解析了第二个模块，则也相应解析了孵化器模块。 在本章中，将创建一个读取`jdk.incubator.httpclient`模块的模块，不必使用-add-modules选项来解析。

因为孵化器模块提供的API还不是最终的，当在编译时或运行时使用孵化器模块时，会在标准错误上打印警告。 警告信息如下所示：

```
WARNING: Using incubator modules: jdk.incubator.httpclient
```

孵化器模块的名称和包含孵化器API的软件包以`jdk.incubator`开始。 一旦它们被标准化并包含在Java SE中，它们的名称将被更改为使用标准的Java命名约定。 例如，模块名称`jdk.incubator.httpclient`可能会在Java SE 10中成为`java.httpclient`。

因为`jdk.incubator.httpclient`模块不在Java SE中，所以将不会为此模块找到Javadoc。 为了生成此模块的Javadoc，并将其包含在本书的源代码中。 可以使用下载的源代码中的Java9Revealed/jdk.incubator.httpclient/dist/javadoc/index.html文件访问Javadoc。 使用JDK 9早期访问构建158的JDK版本来生成Javadoc。 API可能会改变，可能需要重新生成Javadoc。 以下是具体的步骤：

* 源代码包含与项目名称相同目录中的jdk.incubator.httpclient NetBeans项目。
* 安装JDK 9时，其源代码将作为src.zip文件复制到安装目录中。 将所有内容从src.zip文件中的jdk.incubator.httpclient目录复制到下载的源代码中的Java9revealed\jdk.incubator.httpclient\src目录中。
* 在NetBeans中打开jdk.incubator.httpclient项目。
* 右键单击NetBeans中的项目，然后选择“生成Javadoc”选项。 你会收到错误和警告，可以忽略。 它将在`Java9Revealed/jdk.incubator.httpclient/dist/javadoc`目录中生成Javadoc。 打开此目录中的index.html文件，查看`jdk.incubator.httpclient`模块的Javadoc。

## 一. 什么是HTTP/2 Client API？

自JDK 1.0以来，Java已经支持`HTTP/1.1`。 HTTP API由java.net包中的几种类型组成。 现有的API有以下问题：

* 它被设计为支持多个协议，如http，ftp，gopher等，其中许多协议不再被使用。
* 太抽象了，很难使用。
* 它包含许多未公开的行为。
* 它只支持一种模式，阻塞模式，这要求每个请求/响应有一个单独的线程。

2015年5月，IETF（Internet Engineering Task Force）发布了HTTP/2规范。 有关HTTP/2规范的完整文本，请访问https://tools.ietf.org/html/rfc7540。 HTTP/2不会修改应用程序级语义。 也就是说，对应用程序中的HTTP协议的了解和使用情况并没有改变。 它具有更有效的方式准备数据包，然后发送到客户端和服务器之间的电线。 所有之前知道的HTTP，如HTTP头，方法，状态码，URL等都保持不变。 HTTP/2尝试解决与HTTP/1连接所面临的许多性能相关的问题：

* HTTP/2支持二进制数据交换，来代替HTTP/1.1支持的文本数据。
* HTTP/2支持多路复用和并发，这意味着多个数据交换可以同时发生在TCP连接的两个方向上，而对请求的响应可以按顺序接收。 这消除了在对等体之间具有多个连接的开销，这在使用HTTP/1.1时通常是这种情况。 在HTTP/1.1中，必须按照发送请求的顺序接收响应，这称为head-of-line阻塞。 HTTP/2通过在同一TCP连接上进行复用来解决线路阻塞问题。
* 客户端可以建议请求的优先级，服务器可以在对响应进行优先级排序时予以遵守。
* HTTP首部（header）被压缩，这大大降低了首部大小，从而降低了延迟。
* 它允许从服务器到客户端的资源推送。

JDK 9不是更新现有的`HTTP/1.1 API`，而是提供了一个支持`HTTP/1.1`和`HTTP/2`的`HTTP/2 Client API`。 该API旨在最终取代旧的API。 新API还包含使用WebSocket协议开发客户端应用程序的类和接口。 有关完整的WebSocket协议规范，请访问https://tools.ietf.org/html/rfc6455。 新的HTTP/2客户端API与现有的API相比有以下几个好处：

* 在大多数常见情况下，学习和使用简单易用。
* 它提供基于事件的通知。 例如，当收到首部信息，收到正文并发生错误时，会生成通知。
* 它支持服务器推送，这允许服务器将资源推送到客户端，而客户端不需要明确的请求。 它使得与服务器的WebSocket通信设置变得简单。
* 它支持HTTP/2和HTTPS/TLS协议。
* 它同时工作在同步（阻塞模式）和异步（非阻塞模式）模式。

新的API由不到20种类型组成，其中有四种是主要类型。 当使用这四种类型时，会使用其他类型。 新API还使用旧API中的几种类型。 新的API位于jdk.incubator.httpclient模块中的jdk.incubator.http包中。 主要类型有三个抽象类和一个接口：

```java
HttpClient class
HttpRequest class
HttpResponse class
WebSocket interface
```

`HttpClient`类的实例是用于保存可用于多个HTTP请求的配置的容器，而不是为每个HTTP请求单独设置它们。 `HttpRequest`类的实例表示可以发送到服务器的HTTP请求。 `HttpResponse`类的实例表示HTTP响应。 `WebSocket`接口的实例表示一个WebSocket客户端。 可以使用Java EE 7 WebSocket API创建WebSocket服务器。

使用构建器创建`HttpClient`，`HttpRequest`和`WebSocket`的实例。 每个类型都包含一个名为`Builder`的嵌套类/接口，用于构建该类型的实例。 请注意，不用创建HttpResponse，它作为所做的HTTP请求的一部分返回。 新的HTTP/2 Client API非常简单，只需在一个语句中读取HTTP资源！ 以下代码段使用GET请求，以URL https://www.google.com/作为字符串读取内容：

```java
String responseBody = HttpClient.newHttpClient()
         .send(HttpRequest.newBuilder(new URI("https://www.google.com/"))
               .GET()
               .build(), BodyHandler.asString())
         .body();
```

处理HTTP请求的典型步骤如下：

* 创建HTTP客户端对象以保存HTTP配置信息。
* 创建HTTP请求对象并使用要发送到服务器的信息进行填充。
* 将HTTP请求发送到服务器。
* 接收来自服务器的HTTP响应对象作为响应。
* 处理HTTP响应。

## 二. 设置案例

在本章中使用了许多涉及与Web服务器交互的例子。 不是使用部署在Internet上的Web应用程序，而是在NetBeans中创建了一个可以在本地部署的Web应用程序项目。 如果更喜欢使用其他Web应用程序，则需要更改示例中使用的URL。

NetBeans Web应用程序位于源代码的webapp目录中。 通过在GlassFish服务器4.1.1和Tomcat 8/9上部署Web应用程序来测试示例。 可以从https://netbeans.org/下载带有GlassFish服务器的NetBeans IDE。 在8080端口的GlassFish服务器上运行HTTP监听器。如果在另一个端口上运行HTTP监听器，则需要更改示例URL中的端口号。

本章的所有HTTP客户端程序都位于`com.jdojo.http.client`模块中，其声明如下所示。

```java
// module-info.java
module com.jdojo.http.client {
    requires jdk.incubator.httpclient;
}
```

## 三. 创建HTTP客户端

HTTP请求需要将配置信息发送到服务器，以便服务器知道要使用的身份验证器，SSL配置详细信息，要使用的cookie管理器，代理信息，服务器重定向请求时的重定向策略等。 HttpClient类的实例保存这些特定于请求的配置，它们可以重用于多个请求。 可以根据每个请求覆盖其中的一些配置。 发送HTTP请求时，需要指定将提供请求的配置信息的HttpClient对象。 HttpClient包含用于所有HTTP请求的以下信息：验证器，cookie管理器，执行器，重定向策略，请求优先级，代理选择器，SSL上下文，SSL参数和HTTP版本。

* **认证者**是`java.net.Authenticator`类的实例。 它用于HTTP身份验证。 默认是不使用验证器。
* **Cookie管理器**用于管理`HTTP Cookie`。 它是`java.net.CookieManager`类的一个实例。 默认是不使用cookie管理器。
* **执行器**是`java.util.concurrent.Executor`接口的一个实例，用于发送和接收异步HTTP请求和响应。 如果未指定，则提供默认执行程序。
* **重定向策略**是`HttpClient.Redirect`枚举的常量，它指定如何处理服务器的重定向问题。 默认值NEVER，这意味着服务器发出的重定向不会被遵循。
* **请求优先级**是HTTP/2请求的默认优先级，可以在1到256（含）之间。 这是服务器优先处理请求的一个提示。 更高的值意味着更高的优先级。
* **代理选择器**是`java.net.ProxySelector`类的一个实例，用于选择要使用的代理服务器。 默认是不使用代理服务器。
* **SSL上下文**是提供安全套接字协议实现的`javax.net.ssl.SSLContext`类的实例。当不需要指定协议或不需要客户端身份验证时， 提供了一个默认的SSLContext，此选项将起作用。
* **SSL参数**是SSL/TLS/DTLS连接的参数。 它们保存在`javax.net.ssl.SSLParameters`类的实例中。
* **HTTP版本**是HTTP的版本，它是1.1或2.它被指定为`HttpClient.Version`枚举的常量：HTTP_1_1和HTTP_2。 它尽可能请求一个特定的HTTP协议版本。 默认值为HTTP_1_1。

> Tips
>
> HttpClient是不可变的。 当构建这样的请求时，存储在HttpClient中的一些配置可能会被HTTP请求覆盖。

HttpClient类是抽象的，不能直接创建它的对象。 有两种方法可以创建一个HttpClient对象：

* 使用HttpClient类的newHttpClient()静态方法
* 使用HttpClient.Builder类的build()方法

```
// Get the default HttpClient
HttpClient defaultClient = HttpClient.newHttpClient();
```

也可以使用`HttpClient.Builder`类创建HttpClient。 `HttpClient.newBuilder()`静态方法返回一个新的`HttpClient.Builder`类实例。 `HttpClient.Builder`类提供了设置每个配置值的方法。 配置的值被指定为方法的参数，该方法返回构建器对象本身的引用，因此可以链接多个方法。 最后，调用返回HttpClient对象的build()方法。 以下语句创建一个HttpClient，重定向策略设置为ALWAYS，HTTP版本设置为HTTP_2：

```java
// Create a custom HttpClient
HttpClient httpClient = HttpClient.newBuilder()
                      .followRedirects(HttpClient.Redirect.ALWAYS)
                      .version(HttpClient.Version.HTTP_2)
                      .build();
```

`HttpClient`类包含对应于每个配置设置的方法，该设置返回该配置的值。 这些方法如下：

```java
Optional<Authenticator> authenticator()
Optional<CookieManager> cookieManager()
Executor executor()
HttpClient.Redirect followRedirects()
Optional<ProxySelector> proxy()
SSLContext sslContext()
Optional<SSLParameters> sslParameters()
HttpClient.Version version()
```

请注意，`HttpClient`类中没有setter方法，因为它是不可变的。 不能使用HttpClient自己本身的对象。 在使用HttpClient对象向服务器发送请求之前，需要使用HttpRequest对象。HttpClient类包含以下三种向服务器发送请求的方法：

```java
<T> HttpResponse<T> send(HttpRequest req, HttpResponse.BodyHandler<T> responseBodyHandler)
<T> CompletableFuture<HttpResponse<T>> sendAsync(HttpRequest req, HttpResponse.BodyHandler<T> responseBodyHandler)
<U,T> CompletableFuture<U> sendAsync(HttpRequest req, HttpResponse.MultiProcessor<U,T> multiProcessor)
```

`send()`方法同步发送请求，而`sendAsync()`方法异步发送请求。

## 四. 处理HTTP请求
客户端应用程序使用HTTP请求与Web服务器进行通信。 它向服务器发送一个请求，服务器发回对应的HTTP响应。 HttpRequest类的实例表示HTTP请求。 以下是处理HTTP请求所需执行的步骤：

* 获取HTTP请求构建器（builder）
* 设置请求的参数
* 从构建器创建HTTP请求
* 将HTTP请求同步或异步发送到服务器
* 处理来自服务器的响应

### 1. 获取HTTP请求构建器

需要使用构建器对象，该对象是`HttpRequest.Builder`类的实例来创建一个HttpRequest。 可以使用HttpRequest类的以下静态方法获取HttpRequest.Builder：

```java
HttpRequest.Builder newBuilder()
HttpRequest.Builder newBuilder(URI uri)
```

以下代码片段显示了如何使用这些方法来获取HttpRequest.Builder实例：

```java
// A URI to point to google
URI googleUri = new URI("http://www.google.com");
// Get a builder for the google URI
HttpRequest.Builder builder1 = HttpRequest.newBuilder(googleUri);
// Get a builder without specifying a URI at this time
HttpRequest.Builder builder2 = HttpRequest.newBuilder();
```

### 2. 设置HTTP请求参数

拥有HTTP请求构建器后，可以使用构建器的方法为请求设置不同的参数。 所有方法返回构建器本身，因此可以链接它们。 这些方法如下：

```java
HttpRequest.Builder DELETE(HttpRequest.BodyProcessor body)
HttpRequest.Builder expectContinue(boolean enable)
HttpRequest.Builder GET()
HttpRequest.Builder header(String name, String value)
HttpRequest.Builder headers(String... headers)
HttpRequest.Builder method(String method, HttpRequest.BodyProcessor body)
HttpRequest.Builder POST(HttpRequest.BodyProcessor body)
HttpRequest.Builder PUT(HttpRequest.BodyProcessor body)
HttpRequest.Builder setHeader(String name, String value)
HttpRequest.Builder timeout(Duration duration)
HttpRequest.Builder uri(URI uri)
HttpRequest.Builder version(HttpClient.Version version)
```

使用`HttpClient`将`HttpRequest`发送到服务器。 当构建HTTP请求时，可以使用`version()`方法通过HttpRequest.Builder对象设置HTTP版本值，该方法将在发送此请求时覆盖HttpClient中设置的HTTP版本。 以下代码片段将HTTP版本设置为2.0，以覆盖默认HttpClient对象中的NEVER的默认值：

```java
// By default a client uses HTTP 1.1. All requests sent using this
// HttpClient will use HTTP 1.1 unless overridden by the request
HttpClient client = HttpClient.newHttpClient();
        
// A URI to point to google
URI googleUri = new URI("http://www.google.com");
// Get an HttpRequest that uses HTTP 2.0
HttpRequest request = HttpRequest.newBuilder(googleUri)
                                 .version(HttpClient.Version.HTTP_2)
                                 .build();
// The client object contains HTTP version as 1.1 and the request
// object contains HTTP version 2.0. The following statement will
// send the request using HTTP 2.0, which is in the request object.
HttpResponse<String> r = client.send(request, BodyHandler.asString());
```

`timeout()`方法指定请求的超时时间。 如果在指定的超时时间内未收到响应，则会抛出`HttpTimeoutException`异常。

HTTP请求可能包含名为expect的首部字段，其值为“100-Continue”。 如果设置了此首部字段，则客户端只会向服务器发送头文件，并且预计服务器将发回错误响应或100-Continue响应。 收到此响应后，客户端将请求主体发送到服务器。 在客户端发送实际请求体之前，客户端使用此技术来检查服务器是否可以基于请求的首部处理请求。 默认情况下，此首部字段未设置。 需要调用请求构建器的expectContinue(true)方法来启用此功能。 请注意，调用请求构建器的header("expect", "100-Continue")方法不会启用此功能。 必须使用expectContinue(true)方法启用它。

```
// Enable the expect=100-Continue header in the request
HttpRequest.Builder builder = HttpRequest.newBuilder()                                                               
                                         .expectContinue(true);
```

## 五. 设置请求首部

HTTP请求中的首部（header）是键值对的形式。 可以有多个首部字段。 可以使用`HttpRequest.Builder`类的`header()`，`headers()`和`setHeader()`方法向请求添加首部字段。 如果`header()`和`headers()`方法尚未存在，则会添加首部字段。 如果首部字段已经添加，这些方法什么都不做。 `setHeader()`方法如果存在，将替换首部字段； 否则，它会添加首部字段。

`header()`和`setHeader()`方法允许一次添加/设置一个首部字段，而`headers()`方法可以添加多个。`headers()`方法采用一个可变参数，它应该按顺序包含键值对。 以下代码片段显示了如何为HTTP请求设置首部字段：

```java
// Create a URI
URI calc = new URI("http://localhost:8080/webapp/Calculator");
// Use the header() method
HttpRequest.Builder builder1 = HttpRequest.newBuilder(calc)
    .header("Content-Type", "application/x-www-form-urlencoded")
    .header("Accept", "text/plain");
// Use the headers() method
HttpRequest.Builder builder2 = HttpRequest.newBuilder(calc)                
    .headers("Content-Type", "application/x-www-form-urlencoded",
             "Accept", "text/plain");
// Use the setHeader() method
HttpRequest.Builder builder3 = HttpRequest.newBuilder(calc)                
    .setHeader("Content-Type", "application/x-www-form-urlencoded")
    .setHeader("Accept", "text/plain");
```

## 六. 设置请求内容实体

一些HTTP请求的主体包含使用POST和PUT方法的请求等数据。 使用主体处理器设置HTTP请求的内容实体，该体处理器是HttpRequest.BodyProcessor的静态嵌套接口。


HttpRequest.BodyProcessor接口包含以下静态工厂方法，它们返回一个HTTP请求的处理器，请求特定类型的资源（例如String，byte []或File）：

```java
HttpRequest.BodyProcessor fromByteArray(byte[] buf)
HttpRequest.BodyProcessor fromByteArray(byte[] buf, int offset, int length)
HttpRequest.BodyProcessor fromByteArrays(Iterable<byte[]> iter)
HttpRequest.BodyProcessor fromFile(Path path)
HttpRequest.BodyProcessor fromInputStream(Supplier<? extends InputStream> streamSupplier)
HttpRequest.BodyProcessor fromString(String body)
HttpRequest.BodyProcessor fromString(String s, Charset charset)
```

这些方法的第一个参数表示请求的内容实体的数据源。 例如，如果String对象提供请求的内容实体，则使用fromString(String body)方法获取一个处理器。

> Tips
> 
> `HttpRequest`类包含`noBody()`静态方法，该方法返回一个`HttpRequest.BodyProcessor`，它不处理请求内容实体。 通常，当HTTP方法不接受正文时，此方法可以与`method()`方法一起使用，但是`method()`方法需要传递一个实体处理器。

一个请求是否可以拥有一个内容实体取决于用于发送请求的HTTP方法。 DELETE，POST和PUT方法都有一个实体，而GET方法则没有。`HttpRequest.Builder`类包含一个与HTTP方法名称相同的方法来设置请求的方法和实体。 例如，要使用POST方法与主体，构建器有`POST(HttpRequest.BodyProcessor body)`方法。

## 七. 创建HTTP请求

创建HTTP请求只需调用`HttpRequest.Builder`上的`build()`方法，该方法返回一个`HttpRequest`对象。 以下代码段创建了使用HTTP GET方法的HttpRequest：

```java
HttpRequest request = HttpRequest.newBuilder()
                                 .uri(new URI("http://www.google.com"))
                                 .GET()
                                 .build();
```

以下代码片段使用HTTP POST方法构建首部信息和内容实体的Http请求：
```java
// Build the URI and the form’s data
URI calc = new URI("http://localhost:8080/webapp/Calculator");               
String formData = "n1=" + URLEncoder.encode("10","UTF-8") +
                  "&n2=" + URLEncoder.encode("20","UTF-8") +
                  "&op=" + URLEncoder.encode("+","UTF-8");
// Build the HttpRequest object
HttpRequest request = HttpRequest.newBuilder(calc)   
   .header("Content-Type", "application/x-www-form-urlencoded")
   .header("Accept", "text/plain")   
   .POST(HttpRequest.BodyProcessor.fromString(formData))
   .build();
```

请注意，创建HttpRequest对象不会将请求发送到服务器。 需要调用HttpClient类的send()或sendAsync()方法将请求发送到服务器。

以下代码片段使用HTTP HEAD请求方法创建一个HttpRequest对象。 请注意，它使用HttpRequest.Builder类的method()方法来指定HTTP方法。

```java
HttpRequest request =
    HttpRequest.newBuilder(new URI("http://www.google.com"))   
               .method("HEAD", HttpRequest.noBody())
               .build();
```

还有许多其他HTTP方法，如HEAD和OPTIONS，它们没有HttpRequest.Builder类的相应方法。 该类包含一个可用于任何HTTP方法的method(String method, 

```java
HttpRequest.BodyProcessor body)。 当使用method()方法时，请确保以大写的方式指定方法名称，例如GET，POST，HEAD等。以下是这些方法的列表：

HttpRequest.Builder DELETE(HttpRequest.BodyProcessor body)
HttpRequest.Builder method(String method, HttpRequest.BodyProcessor body)
HttpRequest.Builder POST(HttpRequest.BodyProcessor body)
HttpRequest.Builder PUT(HttpRequest.BodyProcessor body)
```

以下代码片段从String中设置HTTP请求的内容实体，通常在将HTML表单发布到URL时完成。 表单数据由三个n1，n2和op字段组成。


```java
URI calc = new URI("http://localhost:8080/webapp/Calculator");
// Compose the form data with n1 = 10, n2 = 20. And op = +      
String formData = "n1=" + URLEncoder.encode("10","UTF-8") +
                  "&n2=" + URLEncoder.encode("20","UTF-8") +
                  "&op=" + URLEncoder.encode("+","UTF-8")  ;
HttpRequest.Builder builder = HttpRequest.newBuilder(calc)                
    .header("Content-Type", "application/x-www-form-urlencoded")
    .header("Accept", "text/plain")
    .POST(HttpRequest.BodyProcessor.fromString(formData));
```

## 八. 处理HTTP响应

一旦拥有`HttpRequest`对象，可以将请求发送到服务器并同步或异步地接收响应。 `HttpResponse<T>`类的实例表示从服务器接收到的响应，其中类型参数T表示响应内容实体的类型，例如String，byte []或Path。 可以使用HttpRequest类的以下方法发送HTTP请求并接收HTTP响应：

```java
<T> HttpResponse<T> send(HttpRequest req, HttpResponse.BodyHandler<T> responseBodyHandler)
<T> CompletableFuture<HttpResponse<T>> sendAsync(HttpRequest req, HttpResponse.BodyHandler<T> responseBodyHandler)
<U,T> CompletableFuture<U> sendAsync(HttpRequest req, HttpResponse.MultiProcessor<U,T> multiProcessor)
```

`send()`方法是同步的。 也就是说，它会一直阻塞，直到收到响应。 `sendAsync()`方法异步处理响应。 它立即返回一个`CompletableFuture<HttpResponse>`，当响应准备好进行处理时，它就会完成。

### 1. 处理响应状态和首部

HTTP响应包含状态代码，响应首部和响应内容实体。 一旦从服务器接收到状态代码和首部，但在接收到正文之前，`HttpResponse`对象就可使用。 `HttpResponse`类的`statusCode()`方法返回响应的状态代码，类型为int。 `HttpResponse`类的`headers()`方法返回响应的首部，作为`HttpHeaders`接口的实例。 HttpHeaders接口包含以下方法，通过名称或所有首部方便地检索首部的值作为`Map <String，List <String >>`类型：

```java
List<String> allValues(String name)
Optional<String> firstValue(String name)
Optional<Long> firstValueAsLong(String name)
Map<String,List<String>> map()
```

下面包含一个完整的程序，用于向google发送请求，并附上HEAD请求。 它打印接收到的响应的状态代码和首部。 你可能得到不同的输出。

```java
// GoogleHeadersTest.java
package com.jdojo.http.client;
import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import jdk.incubator.http.HttpClient;
import jdk.incubator.http.HttpRequest;
import jdk.incubator.http.HttpResponse;
public class GoogleHeadersTest {
    public static void main(String[] args) {
        try {
            URI googleUri = new URI("http://www.google.com");
            HttpClient client = HttpClient.newHttpClient();
            HttpRequest request =
                HttpRequest.newBuilder(googleUri)
                           .method("HEAD", HttpRequest.noBody())
                           .build();
            HttpResponse<?> response =
              client.send(request, HttpResponse.BodyHandler.discard(null));
            // Print the response status code and headers
            System.out.println("Response Status Code:" +
                               response.statusCode());
            System.out.println("Response Headers are:");
            response.headers()
                    .map()
                    .entrySet()
                    .forEach(System.out::println);
        } catch (URISyntaxException | InterruptedException |
                 IOException e) {
            e.printStackTrace();
        }
    }
}
```

输出的结果为：

```
WARNING: Using incubator modules: jdk.incubator.httpclient
Response Status Code:200
Response Headers are:
accept-ranges=[none]
cache-control=[private, max-age=0]
content-type=[text/html; charset=ISO-8859-1]
date=[Sun, 26 Feb 2017 16:39:36 GMT]
expires=[-1]
p3p=[CP="This is not a P3P policy! See https://www.google.com/support/accounts/answer/151657?hl=en for more info."]
server=[gws]
set-cookie=[NID=97=Kmz52m8Zdf4lsNDsnMyrJomx_2kD7lnWYcNEuwPWsFTFUZ7yli6DbCB98Wv-SlxOfKA0OoOBIBgysuZw3ALtgJjX67v7-mC5fPv88n8VpwxrNcjVGCfFrxVro6gRNIrye4dAWZvUVfY28eOM; expires=Mon, 28-Aug-2017 16:39:36 GMT; path=/; domain=.google.com; HttpOnly]
transfer-encoding=[chunked]
vary=[Accept-Encoding]
x-frame-options=[SAMEORIGIN]
x-xss-protection=[1; mode=block]
```

### 2. 处理响应内容实体

处理HTTP响应的内容实体是两步过程：

* 当使用HttpClient类的send()或sendAsync()方法发送请求时，需要指定响应主体处理程序，它是HttpResponse.BodyHandler<T>接口的实例。
* 当接收到响应状态代码和首部时，调用响应体处理程序的apply()方法。 响应状态代码和首部传递给apply()方法。 apply()方法返回HttpResponse.BodyProcessor接口的实例，它读取响应实体并将读取的数据转换为类型T。

不要担心处理响应实体的这些细节。 提供了`HttpResponse.BodyHandler<T>`的几个实现。 可以使用HttpResponse.BodyHandler接口的以下静态工厂方法获取其不同类型参数T的实例：

```java
HttpResponse.BodyHandler<byte[]> asByteArray()
HttpResponse.BodyHandler<Void> asByteArrayConsumer(Consumer<Optional<byte[]>> consumer)
HttpResponse.BodyHandler<Path> asFile(Path file)
HttpResponse.BodyHandler<Path> asFile(Path file, OpenOption... openOptions)
HttpResponse.BodyHandler<Path> asFileDownload(Path directory, OpenOption... openOptions)
HttpResponse.BodyHandler<String> asString()
HttpResponse.BodyHandler<String> asString(Charset charset)
<U> HttpResponse.BodyHandler<U> discard(U value)
```

这些方法的签名足够直观，可以告诉你他们处理什么类型的响应实体。 例如，如果要将响应实体作为String获取，请使用asString()方法获取一个实体处理程序。 discard(U value)方法返回一个实体处理程序，它丢弃响应实体并返回指定的值作为主体。

`HttpResponse<T>`类的`body()`方法返回类型为T的响应实体。

以下代码段向google发送GET请求，并以String形式检索响应实体。 这里忽略了了异常处理逻辑。

```java
import java.net.URI;
import jdk.incubator.http.HttpClient;
import jdk.incubator.http.HttpRequest;
import jdk.incubator.http.HttpResponse;
import static jdk.incubator.http.HttpResponse.BodyHandler.asString;
...
// Build the request
HttpRequest request = HttpRequest.newBuilder()
                .uri(new URI("http://google.com"))
                .GET()
                .build();
// Send the request and get a Response
HttpResponse<String> response = HttpClient.newHttpClient()
                                          .send(request, asString());
// Get the response body and print it
String body = response.body();
System.out.println(body);
```

输出结果为：

```
WARNING: Using incubator modules: jdk.incubator.httpclient
<HTML><HEAD><meta http-equiv="content-type" content="text/html;charset=utf-8">
<TITLE>301 Moved</TITLE></HEAD><BODY>
<H1>301 Moved</H1>
The document has moved
<A HREF="http://www.google.com/">here</A>.
</BODY></HTML>
```

该示例返回一个状态代码为301的响应正文，表示URL已经移动。 输出还包含移动的URL。 如果将HttpClient中的以下重定向策略设置为“ALWAYS”，则该请求将重新提交到已移动的URL。 以下代码片段可解决此问题：

```java
// The request will follow the redirects issues by the server       
HttpResponse<String> response = HttpClient.newBuilder()
    .followRedirects(HttpClient.Redirect.ALWAYS)
    .build()
    .send(request, asString());
```

下面包含一个完整的程序，它显示如何使用一个POST请求与内容实体，并异步处理响应。 源代码中的Web应用程序包含为Calculator的servlet。 Calculator servlet的源代码不会在这里显示。 servlet接受请求中的三个参数，命名为n1，n2和op，其中n1和n2是两个数字，op是一个运算符（+， - ，*或/）。 响应是一个纯文本，并包含了运算符及其结果。 程序中的URL假定你已在本机上部署了servlet，并且Web服务器正在端口8080上运行。如果这些假设不正确，请相应地修改程序。 如果servlet被成功调用，你将得到这里显示的输出。 否则，将获得不同的输出。

```java
// CalculatorTest.java
package com.jdojo.http.client;
import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.URLEncoder;
import jdk.incubator.http.HttpClient;
import jdk.incubator.http.HttpRequest;
import static jdk.incubator.http.HttpRequest.BodyProcessor.fromString;
import jdk.incubator.http.HttpResponse;
public class CalculatorTest {
    public static void main(String[] args) {
        try {
            URI calcUri =
                new URI("http://localhost:8080/webapp/Calculator");
            String formData = "n1=" + URLEncoder.encode("10","UTF-8") +
                              "&n2=" + URLEncoder.encode("20","UTF-8") +
                              "&op=" + URLEncoder.encode("+","UTF-8")  ;
            // Create a request
            HttpRequest request = HttpRequest.newBuilder()
                .uri(calcUri)
                .header("Content-Type", "application/x-www-form-urlencoded")
                .header("Accept", "text/plain")                
                .POST(fromString(formData))
                .build();
            // Process the response asynchronously. When the response
            // is ready, the processResponse() method of this class will
            // be called.
            HttpClient.newHttpClient()
                      .sendAsync(request,
                                 HttpResponse.BodyHandler.asString())
                      .whenComplete(CalculatorTest::processResponse);
            try {
                // Let the current thread sleep for 5 seconds,
                // so the async response processing is complete
                Thread.sleep(5000);
            } catch (InterruptedException ex) {
                ex.printStackTrace();
            }
        } catch (URISyntaxException | IOException e) {
            e.printStackTrace();
        }
    }
    private static void processResponse(HttpResponse<String> response,
                                       Throwable t) {
         if (t == null ) {
             System.out.println("Response Status Code: " +  
                                 response.statusCode());
             System.out.println("Response Body: " + response.body());
         } else {
            System.out.println("An exception occurred while " +
                "processing the HTTP request. Error: " +  t.getMessage());
         }
     }
}
```

输出结果为：

```
WARNING: Using incubator modules: jdk.incubator.httpclient
Response Status Code: 200
Response Body: 10 + 20 = 30.0
```

使用响应实体处理程序可以节省开发人员的大量工作。 在一个语句中，可以下载并将URL的内容保存在文件中。 以下代码片段将google的内容作为google.html的文件保存在当前目录中。 下载完成后，打印下载文件的路径。 如果发生错误，则会打印异常的堆栈跟踪。

```java
HttpClient.newBuilder()
          .followRedirects(HttpClient.Redirect.ALWAYS)
          .build()
          .sendAsync(HttpRequest.newBuilder()           
                                .uri(new URI("http://www.google.com"))
                                .GET()
                                .build(),
                                asFile(Paths.get("google.html")))
           .whenComplete((HttpResponse<Path> response,
                          Throwable exception) -> {
               if(exception == null) {
                  System.out.println("File saved to " +
                                     response.body().toAbsolutePath());
              } else {
                  exception.printStackTrace();
              }
            });
```

### 3. 处理响应的Trailer

HTTP Trailer是HTTP响应结束后由服务器发送的键值列表。 许多服务器通常不使用HTTP Trailer。 HttpResponse类包含一个trailers()方法，它作为CompletableFuture <HttpHeaders>的实例返回响应Trailer。 注意返回的对象类型的名称——HttpHeaders。 HTTP/2 Client API确实有一个名为HttpTrailers的类型。 需要检索响应实体，然后才能检索Trailer。 目前，HTTP/2 Client API不支持处理HTTP Trailer了。 以下代码片段显示了如何在API支持时打印所有响应Trailer：

```java
// Get an HTTP response
HttpResponse<String> response = HttpClient.newBuilder()
                  .followRedirects(HttpClient.Redirect.ALWAYS)
                  .build()
                  .send(HttpRequest.newBuilder()           
                                   .uri(new URI("http://www.google.com"))
                                   .GET()
                                   .build(),
                                   asString());
// Read the response body
String body = response.body();
// Process trailers
response.trailers()
        .whenComplete((HttpHeaders trailers, Throwable t) -> {
             if(t == null) {
                 trailers.map()
                         .entrySet()
                         .forEach(System.out::println);
             } else {
                  t.printStackTrace();
             }
         });
```

## 九. 设置请求重定向策略

一个HTTP请求对应的响应，Web服务器可以返回3XX响应状态码，其中X是0到9之间的数字。该状态码表示客户端需要执行附加操作才能完成请求。 例如，状态代码为301表示URL已被永久移动到新位置。 响应实体包含替代位置。 默认情况下，在收到3XX状态代码后，请求不会重新提交到新位置。 可以将HttpClient.Redirect枚举的以下常量设置为HttpClient执行的策略，以防返回的响应包含3XX响应状态代码：


* **ALWAYS**指示应始终遵循重定向。 也就是说，请求应该重新提交到新的位置。
* **NEVER**表示重定向不应该被遵循。 这是默认值。
* **SAME_PROTOCOL**表示如果旧位置和新位置使用相同的协议（例如HTTP到HTTP或HTTPS到HTTPS），则可能会发生重定向。
* **SECURE**表示重定向应始终发生，除非旧位置使用HTTPS，而新的位置使用了HTTP。

## 十. 使用WebSocket协议

WebSocket协议在两个endpoint（客户端endpoint和服务器endpoint）之间提供双向通信。 endpoint 是指使用WebSocket协议的连接的两侧中的任何一个。 客户端endpoint启动连接，服务器端点接受连接。 连接是双向的，这意味着服务器endpoint可以自己将消息推送到客户端端点。 在这种情况下，也会遇到另一个术语，称为对等体(peer)。 对等体只是连接的另一端。 例如，对于客户端endpoint，服务器endpoint是对等体，对于服务器endpoint，客户端endpoint是对等体。 WebSocket会话表示endpoint和单个对等体之间的一系列交互。

WebSocket协议可以分为三个部分：

* 打开握手
* 数据交换
* 关闭握手

客户端发起与与服务器的打开握手。 使用HTTP与WebSocket协议的升级请求进行握手。 服务器通过升级响应响应打开握手。 握手成功后，客户端和服务器交换消息。 消息交换可以由客户端或服务器发起。 最后，任一endpoint都可以发送关闭握手; 对方以关闭握手回应。 关闭握手成功后，WebSocket关闭。

JDK 9中的HTTP/2 Client API支持创建WebSocket客户端endpoint。 要拥有使用WebSocket协议的完整示例，需要具有服务器endpoint和客户端endpoint。 以下部分涵盖了创建两者。

### 1. 创建服务器端Endpoint

创建服务器Endpoint需要使用Java EE。 将简要介绍如何创建一个服务器Endpoint示例中使用。 使用Java EE 7注解创建一个WebSocket服务器Endpoint。

下面包含TimeServerEndPoint类的代码。 该类包含在源代码的webapp目录中的Web应用程序中。 将Web应用程序部署到Web服务器时，此类将部署为服务器Endpoint。

```java
// TimeServerEndPoint.java
package com.jdojo.ws;
import java.io.IOException;
import java.time.ZonedDateTime;
import java.util.concurrent.TimeUnit;
import javax.websocket.CloseReason;
import javax.websocket.OnMessage;
import javax.websocket.OnOpen;
import javax.websocket.OnClose;
import javax.websocket.OnError;
import javax.websocket.Session;
import javax.websocket.server.ServerEndpoint;
import static javax.websocket.CloseReason.CloseCodes.NORMAL_CLOSURE;
@ServerEndpoint("/servertime")
public class TimeServerEndPoint {
    @OnOpen
    public void onOpen(Session session) {                
        System.out.println("Client connected. ");
    }
    @OnClose
    public void onClose(Session session) {        
        System.out.println("Connection closed.");
    }
    @OnError
    public void onError(Session session, Throwable t) {
        System.out.println("Error occurred:" + t.getMessage());
    }
    @OnMessage
    public void onMessage(String message, Session session) {
        System.out.println("Client: " + message);                
        // Send messages to the client
        sendMessages(session);
    }
    private void sendMessages(Session session) {
        /* Start a new thread and send 3 messages to the
           client. Each message contains the current date and
           time with zone.
        */
        new Thread(() -> {
            for(int i = 0; i < 3; i++) {
                String currentTime =
                    ZonedDateTime.now().toString();
                try {
                    session.getBasicRemote()
                           .sendText(currentTime, true);
                    TimeUnit.SECONDS.sleep(5);
                } catch(InterruptedException | IOException e) {
                    e.printStackTrace();
                    break;
                }
            }
            try {
                // Let us close the WebSocket
                session.close(new CloseReason(NORMAL_CLOSURE,
                                              "Done"));
            } catch (IOException e) {
                e.printStackTrace();
            }
        })
        .start();
    }
}
```

在`TimeServerEndPoint`类上使用`@ServerEndpoint("/servertime")`注解使该类成为服务器Endpoint，当它部署到Web服务器时。注解value元素的值为`/servertime`，这将使Web服务器在此URL发布此Endpoint。

该类包含四个方法，它们已经添加了@onOpen，@onMessage，@onClose和@onError注解。 命名这些方法的名字与这些注解相同。 这些方法在服务器Endpoint的生命周期的不同点被调用。 他们以Session对象为参数。 Session对象表示此Endpoint与其对等体的交互，这将是客户端。

当与对等体进行握手成功时，将调用onOpen()方法。 该方法打印客户端连接的消息。

当从对等体接收到消息时，会调用onMessage()。 该方法打印它接收的消息，并调用一个名为sendMessages()的私有方法。 sendMessages()方法启动一个新线程，并向对等体发送三条消息。 线程在发送每条消息后休眠五秒钟。 该消息包含当前日期和时间与时区。 可以同步或异步地向对等体发送消息。 要发送消息，需要获得表示与对等体的会话的RemoteEndpoint接口的引用。 在Session实例上使用getBasicRemote()和getAsyncRemote()方法来获取可以分别同步和异步发送消息的RemoteEndpoint.Basic和RemoteEndpont.Async实例。 一旦得到了对等体（远程endpoint）的引用，可以调用其几个sendXxx()方法来向对等体发送不同类型的数据。

```java
// Send a synchronous text message to the peer
session.getBasicRemote()
       .sendText(currentTime, true);
sendText()
```

方法中的第二个参数指示是否是发送的部分消息的最后一部分。 如果消息完成，请使用true。

在所有消息发送到对等体后，使用sendClose()方法发送关闭消息。 该方法接收封闭了一个关闭代码和一个紧密原因的CloseReason类的对象。 当对等体收到一个关闭消息时，对等体需要响应一个关闭消息，之后WebSocket连接被关闭。

请注意，在发送关闭消息后，服务器endpoint不应该向对等体发送更多消息。

当出现错误而不是由WebSocket协议处理时，会调用onError()方法。

不能单独使用此endpoint。 需要创建一个客户端endpoint，将在下一节中详细介绍。

### 2. 创建客户端Endpoint

开发WebSocket客户端Endpoint涉及使用WebSocket接口，它是JDK 9中的HTTP/2 Client API的一部分。WebSocket接口包含以下嵌套类型：

* WebSocket.Builder
* WebSocket.Listener
* WebSocket.MessagePart

WebSocket接口的实例表示一个WebSocket客户端endpoint。 构建器，它是WebSocket.Builder接口的实例，用于创建WebSocket实例。 HttpClient类的`newWebSocketBuilder(URI uri, WebSocket.Listener listener)`方法返回一个WebSocket.Builder接口的实例。

当事件发生在客户端endpoint时，例如，完成开启握手，消息到达，关闭握手等，通知被发送到一个监听器，该监听器是WebSocket.Listener接口的实例。 该接口包含每种通知类型的默认方法。 需要创建一个实现此接口的类。 仅实现与接收通知的事件相对应的那些方法。 创建·WebSocket·实例时，需要指定监听器。

当向对等体发送关闭消息时，可以指定关闭状态代码。 WebSocket接口包含以下可以用作WebSocket关闭消息状态代码的int类型常量：

* **CLOSED_ABNORMALLY**：表示WebSocket关闭消息状态代码（1006），这意味着连接异常关闭，例如，没有发送或接收到关闭消息。
* **NORMAL_CLOSURE**：表示WebSocket关闭消息状态代码（1000），这意味着连接正常关闭。 这意味着建立连接的目的已经实现了。

服务器Endpoint可能会发送部分消息。 消息被标记为开始，部分，最后或全部，表示其位置。 WebSocket.MessagePart枚举定义了与消息的位置相对应的四个常量：FIRST，PART，LAST和WHOLE。 当监听器收到已收到消息的通知时，将这些值作为消息的一部分。

以下部分将详细介绍设置客户端Endpoint的各个步骤。

## 十一. 创建监听器

监听器是WebSocket.Listener接口的实例。 创建监听器涉及创建实现此接口的类。 该接口包含以下默认方法：

```java
CompletionStage<?> onBinary(WebSocket webSocket, ByteBuffer message, WebSocket.MessagePart part)
CompletionStage<?> onClose(WebSocket webSocket, int statusCode, String reason)
void onError(WebSocket webSocket, Throwable error)
void onOpen(WebSocket webSocket)
CompletionStage<?> onPing(WebSocket webSocket, ByteBuffer message)
CompletionStage<?> onPong(WebSocket webSocket, ByteBuffer message)
CompletionStage<?> onText(WebSocket webSocket, CharSequence message, WebSocket.MessagePart part)
```

当客户端Endpoint连接到引用传递给该方法的对等体作为第一个参数时，调用onOpen()方法。 默认实现请求一个消息，这意味着该侦听器可以再接收一条消息。 消息请求是使用WebSocket接口的request(long n)方法进行的：

```java
// Allow one more message to be received
webSocket.request(1);
```

如果服务器发送的消息多于请求消息，则消息在TCP连接上排队，最终可能强制发送方通过TCP流控制停止发送更多消息。 请在适当的时间调用request(long n)方法并使用适当的参数值，这样监听器就不会从服务器一直接收消息。 在监听器中重写onOpen()方法是一个常见的错误，而不是调用webSocket.request(1)方法，后者会阻止从服务器接收消息。

当endpoint收到来自对等体的关闭消息时，调用onClose()方法。 这是监听器的最后通知。 从此方法抛出的异常将被忽略。 默认的实现不会做任何事情。 通常，需要向对方发送一条关闭消息，以完成关闭握手。

当endpoint从对等体接收到Ping消息时，调用onPing()方法。 Ping消息可以由客户端和服务器endpoint发送。 默认实现将相同消息内容的Pong消息发送给对等体。

当endpoint从对等体接收到Pong消息时，调用onPong()方法。 通常作为对先前发送的Ping消息的响应来接收Pong消息。 endpoint也可以接收未经请求的Pong消息。 onPong()方法的默认实现在监听器上再请求一个消息，不执行其他操作。

当WebSocket上发生I/O或协议错误时，会调用onError()方法。 从此方法抛出的异常将被忽略。 调用此方法后，监听器不再收到通知。 默认实现什么都不做。

当从对等体接收到二进制消息和文本消息时，会调用onBinary()和onText()方法。 确保检查这些方法的最后一个参数，这表示消息的位置。 如果收到部分消息，需要组装它们以获取整个消息。 从这些方法返回null表示消息处理完成。 否则，返回CompletionStage<?>，并在消息处理完成后完成。

以下代码段创建一个可以接收信息的WebSocket监听器：

```java
WebSocket.Listener listener =  new WebSocket.Listener() {
    @Override
    public CompletionStage<?> onText(WebSocket webSocket,
                                     CharSequence message,
                                     WebSocket.MessagePart part) {
        // Allow one message to be received by the listener
        webSocket.request(1);
        // Print the message received from the server
        System.out.println("Server: " + message);
        // Return null indicating that we are done processing this message
        return null;
     }
};
```

## 十二. 构建Endpoint

需要构建充当客户端点的WebSocket接口的实例。 该实例用于与服务器Endpoint连接和交换消息。 WebSocket实例使用WebSocket.Builder构建。 可以使用HttpClient类的以下方法获取构建器：

```java
WebSocket.Builder newWebSocketBuilder(URI uri, WebSocket.Listener listener)
```

用于获取WebSocket构建器的HttpClient实例提供了WebSocket的连接配置。 指定的uri是服务器Endpoint的URI。 监听器是正在构建的Endpoint的监听器， 拥有构建器后，可以调用以下方法来配置endpoint：

```java
WebSocket.Builder connectTimeout(Duration timeout)
WebSocket.Builder header(String name, String value)
WebSocket.Builder subprotocols(String mostPreferred, String... lesserPreferred)
```

`connectTimeout()`方法允许指定开启握手的超时时间。 如果开放握手在指定的持续时间内未完成，则从`WebSocket.Builder`的`buildAsync()`方法完成后返回带有异常的`HttpTimeoutException`的`CompletableFuture`。 可以使用`header()`方法添加任何用于打开握手的自定义首部。 可以使用`subprotocols()`方法在打开握手期间指定给定子协议的请求 —— 只有其中一个将被服务器选择。 子协议由应用程序定义。 客户端和服务器需要同意处理特定的子协议及其细节。

最后，调用`WebSocket.Builder`接口的`buildAsync()`方法来构建`Endpoint`。 它返回`CompletableFuture <WebSocket>`，当该Endpoint连接到服务器Endpoint时，正常完成； 当有错误时，返回异常。 以下代码片段显示了如何构建和连接客户端Endpoint。 请注意，服务器的URI以ws开头，表示WebSocket协议。

```java
URI serverUri = new URI("ws://localhost:8080/webapp/servertime");
// Get a listener
WebSocket.Listener listener = ...;
// Build an endpoint using the default HttpClient
HttpClient.newHttpClient()
          .newWebSocketBuilder(serverUri, listener)
          .buildAsync()
          .whenComplete((WebSocket webSocket, Throwable t) -> {
               // More code goes here
           });
```

## 十三. 向对等体发送消息

一旦客户端Endpoint连接到对等体，则交换消息。 WebSocket接口的实例表示一个客户端Endpoint，该接口包含以下方法向对等体发送消息：

```java
CompletableFuture<WebSocket> sendBinary(ByteBuffer message, boolean isLast)
CompletableFuture<WebSocket> sendClose()
CompletableFuture<WebSocket> sendClose(int statusCode, String reason)
CompletableFuture<WebSocket> sendPing(ByteBuffer message)
CompletableFuture<WebSocket> sendPong(ByteBuffer message)
CompletableFuture<WebSocket> sendText(CharSequence message)
CompletableFuture<WebSocket> sendText(CharSequence message, boolean isLast)

```

* **sendText()**方法用于向对等体发送信息。 如果发送部分消息，请使用该方法的两个参数的版本。 如果第二个参数为false，则表示部分消息的一部分。 如果第二个参数为true，则表示部分消息的最后部分。 如果以前没有发送部分消息，则第二个参数中的true表示整个消息。
* **endText(CharSequence message)**是一种便捷的方法，它使用true作为第二个参数来调用该方法的第二个版本。
* **sendBinary()**方法向对等体发送二进制信息。
* **sendPing()**和**sendPong()**方法分别向对等体发送Ping和Pong消息。
* **sendClose()**方法向对等体发送Close消息。 可以发送关闭消息作为由对等方发起的关闭握手的一部分，或者可以发送它来发起与对等体的闭合握手。

> Tips
> 
> 如果想要突然关闭WebSocket，请使用WebSocket接口的`abort()`方法。

### 1. 运行WebSocket程序

现在是查看WebSocket客户端endpoint和WebSocket服务器endpoint交换消息的时候了。下面包含一个封装客户机endpoint的WebSocketClient类的代码。 其用途如下：

```java
// Create a client WebSocket
WebSocketClient wsClient = new WebSocketClient(new URI(“<server-uri>”));
// Connect to the server and exchange messages
wsClient.connect();
// WebSocketClient.java
package com.jdojo.http.client;
import java.net.URI;
import java.util.concurrent.CompletionStage;
import jdk.incubator.http.HttpClient;
import jdk.incubator.http.WebSocket;
public class WebSocketClient {
    private WebSocket webSocket;
    private final URI serverUri;
    private boolean inError = false;
    public WebSocketClient(URI serverUri) {
        this.serverUri = serverUri;
    }
    public boolean isClosed() {
        return (webSocket != null && webSocket.isClosed())
               ||
               this.inError;        
    }
    public void connect() {
        HttpClient.newHttpClient()
                  .newWebSocketBuilder(serverUri, this.getListener())
                  .buildAsync()
                  .whenComplete(this::statusChanged);
    }
    private void statusChanged(WebSocket webSocket, Throwable t) {
        this.webSocket = webSocket;
        if (t == null) {        
            this.talkToServer();
        } else {
            this.inError = true;
            System.out.println("Could not connect to the server." +
                               " Error: " + t.getMessage());
        }
    }
    private void talkToServer() {
        // Allow one message to be received by the listener
        webSocket.request(1);
        // Send the server a request for time
        webSocket.sendText("Hello");
    }
    private WebSocket.Listener getListener() {
        return new WebSocket.Listener() {
            @Override
            public void onOpen(WebSocket webSocket) {
                // Allow one more message to be received by the listener
                webSocket.request(1);
                // Notify the user that we are connected
                System.out.println("A WebSocket has been opened.");                
            }
            @Override
            public CompletionStage<?> onClose(WebSocket webSocket,
                             int statusCode, String reason) {
                // Server closed the web socket. Let us respond to
                // the close message from the server
                webSocket.sendClose();
                System.out.println("The WebSocket is closed." +
                                   " Close Code: " + statusCode +
                                   ", Close Reason: " + reason);
                // Return null indicating that this WebSocket
                // can be closed immediately
                return null;
            }
            @Override
            public void onError(WebSocket webSocket, Throwable t) {
                System.out.println("An error occurred: " + t.getMessage());
            }
            @Override
            public CompletionStage<?> onText(WebSocket WebSocket,
                CharSequence message, WebSocket.MessagePart part) {
                // Allow one more message to be received by the listener
                webSocket.request(1);
                // Print the message received from the server
                System.out.println("Server: " + message);
                // Return null indicating that we are done
                // processing this message
                return null;
            }
        };
    }
}
```

WebSocketClient类的工作原理如下：

* `webSocket`实例变量保存客户端endpoint的引用。
* `serverUri`实例变量保存服务器端endpoint的URI。
* `isError`实例变量保存一个指示符，无论该endpoint 是否出错。
* `isClosed()`方法检查endpoint 是否已经关闭或出错。
* 在开启握手成功之前，webSocket实例变量置为null。 它的值在statusChanged()方法中更新。
* `connect()`方法构建一个WebSocket并启动一个开始握手。 请注意，无论连接状态如何，它在开始握手完成后调用statusChanged()方法。
* 当开始握手成功时，tatusChanged()方法通过调用talkToServer()方法与服务器通信。 否则，它会打印一条错误消息，并将isError标志设置为true。
* `talkToServer()`方法允许监听器再接收一个消息，并向服务器endpoint发送一条信息。 请注意，服务器endpoint从客户端endpoint接收到信息时，会以五秒的间隔发送三个消息。 从talkToServer()方法发送此消息将启动两个endpoint之间的消息交换。
* `getListener()`方法创建并返回一个`WebSocket.Listener`实例。 服务器endpoint将发送三个消息，后跟一个关闭消息。 监听器中的onClose()方法通过发送一个空的关闭消息来响应来自服务器的关闭消息，这将结束客户端endpoint操作。

如下包含运行客户端endpoint的程序。 如果运行WebSocketClientTest类，请确保具有服务器endpoint的Web应用程序正在运行。 还需要修改SERVER_URI静态变量以匹配Web应用程序的服务器endpoint的URI。 输出将使用时区打印当前日期和时间，因此可能会得到不同的输出。

```java
// WebSocketClientTest.java
package com.jdojo.http.client;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.concurrent.TimeUnit;
public class WebSocketClientTest {    
    // Please change the URI to point to your server endpoint
    static final String SERVER_URI ="ws://localhost:8080/webapp/servertime";
    public static void main(String[] args)
       throws URISyntaxException, InterruptedException {
        // Create a client WebSocket
        WebSocketClient wsClient = new WebSocketClient(new URI(SERVER_URI));
        // Connect to the Server
        wsClient.connect();
        // Wait until the WebSocket is closed
        while(!wsClient.isClosed()) {            
            TimeUnit.SECONDS.sleep(1);
        }
        // Need to exit
        System.exit(0);
    }
}
```

输出结果为：

```
A WebSocket has been opened.
Server: 2016-12-15T14:19:53.311-06:00[America/Chicago]
Server: 2016-12-15T14:19:58.312-06:00[America/Chicago]
Server: 2016-12-15T14:20:03.313-06:00[America/Chicago]
The WebSocket is closed.  Close Code: 1000, Close Reason: Done
```

### 2. WebSocket应用程序疑难解答

当测试WebSocket应用程序时，会出现一些问题。 下表列出了一些这些问题及其解决方案。

|错误信息	|解决方案|
|--------|--------|
|Could not connect to the server. Error: java.net.ConnectException: Connection refused: no further information	|表示Web服务器未运行或服务器URI不正确。 尝试运行Web服务器并检查在WebSocketClientTest类中其SERVER_URI静态变量的指定的服务器URI。|
|Could not connect to the server. Error: java.net.http.WebSocketHandshakeException: 404: RFC 6455 1.3. Unable to complete handshake; HTTP response status code 404	|表示服务器URI未指向服务器上的正确endpoint 。 验证WebSocketClientTest类中SERVER_URI静态变量的值是否正确。|
|A WebSocket has been opened. Dec 15, 2016 2:58:03 PM java.net.http.WS$1 onError WARNING: Failing connection java.net.http.WS@162532d6[CONNECTED], reason: 'RFC 6455 7.2.1. Stream ended before a Close frame has been received' An error occurred: null	|表示开启握手后，服务器将自动关闭服务器endpoint。 这通常由计算机上运行的防病毒程序执行的。 需要配置防病毒程序以允许指定端口上的HTTP连接，或者在另一个未被防病毒程序阻止的端口上使用HTTP监听器运行Web服务器。|
|A WebSocket has been opened. Server: 2016-12-16T07:15:04.586-06:00[America/Chicago]	|在这种情况下，应用程序会打印一行或两行输出并一直等待。 当在客户端endpoint逻辑中没有webSocket.request(1)调用时，会发生这种情况。 服务器正在发送消息，因为不允许更多消息排队。 在onOpen，onText和其他事件中调用request(n)方法来解决这个问题。|

## 十四. 总结

JDK 9添加了一个`HTTP/2 Client API`，可以在Java应用程序中使用HTTP请求和响应。 API提供类和接口来开发具有身份验证和TLS的WebSocket客户端。 API位于jdk.incubator.http包中，该包位于`jdk.incubator.httpclient`模块中。

三个抽象类，`HttpClient`，`HttpRequest`和`HttpResponse`，`WebSocket`接口是HTTP/2 Client API的核心。这些类型的实例使用构建器创建。 HttpClient类是不可变的。HttpClient类的实例保存可以重复用于多个HTTP请求的HTTP连接配置。 HttpRequest类实例表示HTTP请求。 HttpResponse类的实例表示从服务器接收的HTTP响应。可以同步或异步地发送和接收HTTP请求和响应。

WebSocket接口的实例表示一个WebSocket客户端endpoint。与WebSocket服务器端endpoint的通信是异步完成的。 WebSocket API是基于事件的。需要为WebSocket客户端endpoint指定一个监听器，它是WebSocket.Listener接口的一个实例。监听器通过调用其适当的方法 —— 当事件发生在endpoint上时，例如，当通过调用监听器的onOpen()方法成功完成与对等体的打开握手时，通知监听器。 API支持与对等体交换文本以及二进制消息。消息可以部分交换。
