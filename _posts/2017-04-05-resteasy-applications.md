---
title: RESTEasy Applications Support
abstract: In this article I'd like to give you a brief introduction on RESTEasy Application Support.
---

## _{{ page.title }}_

{{ page.abstract }}

Application is an JAX-RS spec defined feature that support users to register restful resources into containers. Here are the descriptions to the Application in section `2.3.2 Servlet` of the `jsr339-jaxrs-2.0-final-spec`:

![2016-04-05-spec1.png]({{ site.url }}/assets/2016-04-05-spec1.png)

![2016-04-05-spec2.png]({{ site.url }}/assets/2016-04-05-spec2.png)

![2016-04-05-spec3.png]({{ site.url }}/assets/2016-04-05-spec3.png)

![2016-04-05-spec4.png]({{ site.url }}/assets/2016-04-05-spec4.png)

Please note Application is used with Servlet container, that means, not all the containers need to follow this Application workflow to register resources. For example, `resteasy-netty4` container doesn't need Application to work. Here is an example to use `resteasy-netty4`:

```java
ResteasyDeployment deployment = new ResteasyDeployment();

netty = new NettyJaxrsServer();
netty.setDeployment(deployment);
netty.setPort(port);
netty.setRootResourcePath("");
netty.setSecurityDomain(null);
netty.start();

deployment.getRegistry().addPerRequestResource(BasicResource.class);
```

As the example shown above, we can see that the `BasicResource` is added into `Registry` directly, and `Registry` is contained in `ResteasyDeployment`. We can see the whole process doesn't involve Application.
