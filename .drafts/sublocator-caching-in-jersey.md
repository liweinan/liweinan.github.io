---
title: "The sub-locator caching in Jersey"
abstract: "In this article, I'd like to share my investigation on the Jersey sub-locator caching support."
---

# {{ page.title }}

{{ page.abstract }}

Jersey supports this kind of sub-locator:

```java
@Path("sub")
public Class<SubResource> getSubResourceLocator2() {
    return SubResource.class;
}
```

As the code shown above, we can see that the sub-

 
 ### _References_
 
 ---

^[1]: [Performance Improvements of Sub-Resource Locators in Jersey](https://blog.dejavu.sk/2015/02/12/performance-improvements-of-sub-resource-locators-in-jersey/)
