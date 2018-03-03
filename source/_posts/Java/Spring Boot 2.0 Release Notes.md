

[英文地址](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-2.0-Release-Notes)

## 从Spring Boot 1.5升级

由于这是Spring Boot的主要版本，升级现有的应用程序可能会比平常更复杂一点。我们制定了专门的[迁移指南](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-2.0-Migration-Guide)来帮助您升级现有的Spring Boot 1.5应用程序。

如果你运行更早期的spring boot版本，我们强烈建议您在迁移到Spring Boot 2.0之前[升级到Spring Boot 1.5](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-1.5-Release-Notes)。

## 新特性和值得关注的点

### Java 8 和 Java 9的支持

Spring Boot 2.0要求Java 8作为最低版本.一些存在的API已经升级成使用Java8的新特性，例如：interface中的默认方法，函数回调以及类似`javax.time`的新的API 接口。如果您目前正在使用Java 7或更早版本，那么在开发Spring Boot 2.0应用程序之前，您需要升级您的JDK。

### Third-party Library更新

Spring Boot 2.0建立在Spring Framework 5之上。你可以查看[Spring Framework 5的新特性](https://github.com/spring-projects/spring-framework/wiki/What%27s-New-in-Spring-Framework-5.x)，并在继续后面的行动前查看[spring framework 5升级指南](https://github.com/spring-projects/spring-framework/wiki/Upgrading-to-Spring-Framework-5.x)

我们已尽可能升级到其他第三方jar的最新稳定版本.这个版本中比较重要的升级包括

* Tomcat 8.5
* Flyway 5
* Hibernate 5.2
* Thymeleaf 3

### Reactive Spring

Spring的产品中许多项目为reactive 提供了一流的支持。Reactive应用是完全异步，也是非堵塞的。它们使用事件驱动模型（event-loop），而不是更加传统的一个请求，一个线程的模型。spring framework 参考文档中“Web on reactive stack”章节为这个主题提供了一个很好的入门。

#### Spring WebFlux & WebFlux.fn

Spring WebFlux是Spring MVC的完全非阻塞反应式替代方案。Spring boot为基于annotation的Spring WebFlux和WebFlux.fn提供了自动化的配置。WebFlux.fn提供了过多的函数式风格API

首先，可以使用spring-boot-starter-webflux组建，它提供了由嵌入式netty服务器支持的Spring WebFlue。查阅[boot-features-developing-web-applications](https://docs.spring.io/spring-boot/docs/2.0.x-SNAPSHOT/reference/htmlsingle/#boot-features-developing-web-applications)可以获取更多信息

#### Reactive Spring Data

在底层技术的支持下，spring data也为reactive 应用提供了支持。当前Cassandra、MongoDB、Couchbase、redis已经有reactive API支持了

Spring Boot包含针对这些技术的特殊 starter-POM，可为您提供启动所需的一切。例如 spring-boot-starter-data-mongodb-reactive 包含了reactive 的mongoDB驱动和项目的reactor。

#### Reactive Spring Security

Spring boot2.0 可以使用spring security5.0 来保护你的reactive应用。当Spring security在classpath中时，Spring boot2.0未WebFlux应用题提供了自动化的Spring security配置。

WebFlux的Spring Security的访问规则可以通过SecurityWebFilterChain进行配置。如果你之前在Spring MVC中使用过Spring security，该感到非常熟悉。查阅[Spring Boot reference documentation](https://docs.spring.io/spring-boot/docs/2.0.x-SNAPSHOT/reference/htmlsingle/#boot-features-security-webflux)和[Spring Security documentation](https://docs.spring.io/spring-security/site/docs/5.0.0.RELEASE/reference/htmlsingle/#jc-webflux)可以了解更多的细节。

#### Embedded Netty Server

由于WebFlux不依赖于Servlet API，我们现在可以首次为Netty作为嵌入式服务器提供支持。spring-boot-starter-webflux将引入 Netty 4.1和[Ractor Netty](https://github.com/reactor/reactor-netty).

> 你只能讲netty作为reative服务器，不提供堵塞的Servlet API的支持。

### HTTP/2 Support

Tomcat、undertow和jetty已经提供支持http/2的。支持取决于所选的Web服务器和应用程序环境（因为JDK 8不支持该协议）。查阅[howto-configure-http2](https://docs.spring.io/spring-boot/docs/2.0.x-SNAPSHOT/reference/htmlsingle/#howto-configure-http2)了解更多。

### Configuration Property Binding

在Spring Boot 2.0中，用于将环境属性绑定到@ConfigurationProperties的机制已经彻底改进。我们借此机会收紧管理宽松绑定的规则，并修复了Spring Boot 1.x中的许多不一致之处。

新的`Binder` API也可以在你自己的代码中直接在@ConfigurationProperties之外使用。例如，下面的代码会绑定到一个List<Person>对象
  
```
List<PersonName> people = Binder.get(environment)
    .bind("my.property", Bindable.listOf(PersonName.class))
    .orElseThrow(IllegalStateException::new);
```

配置源可以像这样在YAML中表示

```
my:
  property:
  - first-name: Jane
    last-name: Doe
  - first-name: John
    last-name: Doe
```

更多关于绑定规则的更新信息可以查看[Relaxed-Binding-2.0](https://github.com/spring-projects/spring-boot/wiki/Relaxed-Binding-2.0)

#### Property Origins

由spring boot2.0通过YAML文件和properites文件的配置项现在包含有origin信息，可以帮助你跟踪它是从何处加载的。几个spring boot特性利用这个信息，并在适当的时候展示。

例如，绑定失败时抛出的BindException类是一个OriginProvider。这意味着起源信息可以很好地从故障分析器中显示出来。

另一个例子是`ENV`actuator endpoint ，当它可用时包含origin信息。下面的代码片段展示`spring.security.user.name`来自jar包中`application.properties` 文件的第1行第27字节。

```

{
  "name": "applicationConfig: [classpath:/application.properties]",
  "properties": {
    "spring.security.user.name": {
      "value": "user",
      "origin": "class path resource [application.properties]:1:27"
    }
  }
}
```

#### Converter Support

Binding中使用了一个新的ApplicationConversionService类，它提供了一些对属性绑定特别有用的额外转换器。最值得注意的是持续**duration类型**和**分隔字符串**的转换器。

duration转换器允许以ISO-8601格式或简单字符串（例如10m为10分钟）的转换。现有的属性已更改为始终使用Duration。

The @DurationUnit annotation ensures back-compatibility by setting the unit that is used if not is specified. For example, a property that expected seconds in Spring Boot 1.5 now has @DurationUnit(ChronoUnit.SECONDS) to ensure a simple value such as 10 actually uses 10s.

分割字符串转换器允许你将简单的spring转成collection、Array而不必需要以逗号分割。例如，LDAP 的base-dn使用@Delimiter(Delimiter.NONE)，这样LDAP DNs就不会有歧义了。

### Gradle Plugin

Spring boot的Gradle插件已经大量重写，以实现许多重大改进。你可以通过[reference](https://docs.spring.io/spring-boot/docs/2.0.x-SNAPSHOT/gradle-plugin/reference/)和[API](https://docs.spring.io/spring-boot/docs/2.0.0.BUILD-SNAPSHOT/gradle-plugin/api/)文档来了解过多的插件功能

### 







