---
title: Spring Boot 2 Release Notes
description: 这个文章是我翻译的第一篇文章，累死我了。但是翻译完成后还是满满的自豪感。下次在为大家翻译spring boot2.0 吧
date: 2018-3-5 19:00:00
tags:	[spring,spring boot]
toc: true
finished: true
comments: true
---

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

### Kotlin

此处不翻译了，用不到：）

Spring Boot 2.0 now includes support for Kotlin 1.2.x and offers a runApplication function which provides a way to run a Spring Boot application using idiomatic Kotlin. We also expose and leverage the Kotlin support that other Spring projects such as Spring Framework, Spring Data, and Reactor have added to their recent releases.

For more information, refer to the [Kotlin support section of the reference documentation](https://docs.spring.io/spring-boot/docs/2.0.x-SNAPSHOT/reference/htmlsingle/#boot-features-kotlin).

### Actuator Improvements

Spring boot2.0 中有许多对actuator endpoints的增强和改进。所有的http actuator endpoints都曝露在`/actuator`，而且结果JSON被改进了。

我们不再默认曝露需要actuator endpoint。如果你正在升级spring boot1.5，请查看升级指南并需要特别关注`management.endpoints.web.exposure.include`属性。

#### Jersey and WebFlux Support

除了Spring MVC和JMX支持，在开发Jersey或者reactivet时你可以访问actuator endpoint。Jersey通过jersey `Resource`提供，WebFlux通过自定义`HandlerMapping`。

#### Hypermedia links

`/actuator`提供了HAL格式的response来访问所有激活的endpoints（即便在classpath中没有spring HATEOAS）。

#### Actuator @Endpoints

为了支持 Spring MVC, JMX, WebFlux and Jersey，我们开发了一个新的actautor endpoint程序模型。**The @Endpoint annotation can be used in combination with @ReadOperation, @WriteOperation and @DeleteOperation to develop endpoints in a technology agnostic way.**

你也可以用` @EndpointWebExtension`或者`@EndpointJmxExtension`来写特定的endpoints。

#### Micrometer

spring boot2.0 不在附带自己的metricx API了。我们依靠[micrometer.io](https://micrometer.io/)来提供所有的应用监控支持。

Micrometer提供标准的metrics

在spring boot2.0中，开箱即用的可以将Metrics导入到各个其他系统，如： Atlas, Datadog, Ganglia, Graphite, Influx, JMX, New Relic, Prometheus, SignalFx, StatsD和Wavefront。另外还可以使用简单的内存中metrics。

JVM metrics(GC/cpu/thread/memory),logback,tomcat,spring mvc,`RestTemplate`提供了集成支持。

### 数据支持

除了上面提到的`reactive spring data`，在数据领域已经做了其他一些更新和改进。

#### HikariCP

在Spring boot2.0 中，默认的数据库连接池已经用HikariCP提换了tomcat pool。我们发现HikariCP提供了更好的性能，而且你们更喜欢用它。

#### Initialization

数据库初始化逻辑在Spring Boot 2.0中已经rationalized。Spring Batch/Spring Integration/Spring Session/Quartz仅在使用内置数据库时启动初始化。`enable`属性被enum替代了。例如，你想总是执行Spring batch的初始化，你可以设置`spring.batch.initialize-schema=always`

如果你使用flyway或者Liquibase，你来管理你的数据库，而且你正在使用内存数据库，spring boot2.0 会自动切换到Hibernate的自动DDL。

#### JOOQ

不使用，不翻译了

Spring Boot 2.0 now detects the jOOQ dialect automatically based on the DataSource (similarly to what is done for the JPA dialect). A new @JooqTest annotation has also been introduced to ease testing where only jOOQ has to be used.

#### JdbcTemplate

Spring Boot自动配置的JdbcTemplate现在可以通过`spring.jdbc.template`属性进行自定义。此外，`NamedParameterJdbcTemplate`背后也重用了JdbcTemplate。

#### Spring Data Web Configuration

Spring boot提供了新的配置组`spring.data.web`来控制自定义的分页和排序

#### Influx DB

Spring Boot now auto-configures the open-source time series database InfluxDB. To enable InfluxDB support you need to set a spring.influx.url property, and include influxdb-java on your classpath.

#### Flyway/Liquibase Flexible Configuration

如果提供了`url`或者`user`配置，flyway和Liquibase的自动化配置管理将重新使用数据而不是无视它，这使您可以创建一个自定义的数据源，仅用于所需信息的迁移。

#### Hibernate

现在支持自定义Hibernate命名策略。对于高级场景，您现在可以定义ImplicitNamingStrategy或PhysicalNamingStrategy以在上下文中用作常规bean。

现在也可以通过公开HibernatePropertiesCustomizer bean，以更精细的方式定制Hibernate使用的属性。

#### MongoDB Client Customization

现在可以通过定义MongoClientSettingsBuilderCustomizer类型的bean来将高级定制应用于Spring Boot自动配置的Mongo客户端。

#### Redis

可以通过`spring.cache.redis.*`来配置 redis cache的默认属性.

### Web

#### Context Path Logging

当使用内置服务器时，content path 将和http port一起输出到日志中。

#### Web Filter Initialization

WEB filter 将在支持的容器上尽早的初始化。

#### Thymeleaf

`Thymeleaf starter`现在包括提供对javax.time类型支持的thymeleaf-extras-java8time。

#### JSON Support

新的`spring-boot-starter-json`收集了必要JSON读写工具。它不仅提供`jackson-databind`,也提供一些在Java8 下工作的模块：`jackson-datatype-jdk8`, `jackson-datatype-jsr310` and `jackson-module-parameter-names`.这个新的启动器现在被用在jackson-databind之前定义的地方。

如果你更喜欢Jackson以外的东西,我们在spring boot2.0 中也提供GSON.我们还引入了对JSON-B的支持(包含JSON-B测试的支持)

### Quartz

Quartz Scheduler现在提供了自动化配置。我们也增加了`spring-boot-starter-quartz`

你可以使用内存的JobStores，也使用使用基于数据库的JobStores。Spring应用程序中的所有JobDetail，Calendar和Trigger bean将自动注册到Scheduler中。

### Testing

对Spring Boot 2.0中提供的测试支持进行了一些补充和调整：

* 已添加新的@WebFluxTest注释以支持WebFlux应用程序的“切片”测试。
* 现在使用@WebMvcTest和@WebFluxTest自动扫描Converter和GenericConverter bean。
* @AutoConfigureWebTestClient注解以提供WebTestClient bean以供测试使用
* 新增了一个ApplicationContextRunner测试实用程序，这使得测试自动配置变得非常简单。我们已将大部分内部测试套件移至此新模型。

### Miscellaneous

* 当确定条件是否满足时，@ConditionalOnBean现在使用逻辑AND而不是逻辑OR。
* 无条件类现在包含在自动配置报告中
* spring CLI应用程序现在包含一个可用于创建Spring Security兼容哈希密码的encodepassword命令。
* 计划任务（即@EnableScheduling）可以使用actuator endpoint进行审查。
* Loggers endpoints现在允许您将日志级别重置为默认值。
* Spring Session用户现在可以通过actuator endpoints查找和删除会话。
* 使用spring-boot-starter-parent的基于Maven的应用程序现在默认使用-parameters标志

### Animated ASCII Art

![](https://github.com/spring-projects/spring-boot/wiki/images/animated-ascii-art.gif)



