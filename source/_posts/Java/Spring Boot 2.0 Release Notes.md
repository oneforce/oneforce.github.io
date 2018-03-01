
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

