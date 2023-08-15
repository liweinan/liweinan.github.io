---
title: 代码中的side effect
abstract: 学习side effect的概念，并通过理解side effect，明白无状态的重要性。
---



所谓side effect[^def]，就是指代码中一处功能，除了返回它的值以外，还修改了公共数据的状态，或者影响了系统的整体行为。比如下面这段代码：

[^def]: http://en.wikipedia.org/wiki/Side_effect_(computer_science)

```c
#include <stdio.h>

char a = 'a';
char b = 'b';
char *ptr_a;
char *ptr_b;

void inc(char* ptr) {
	++*ptr;
	++*ptr_b;
}

int main() {
	ptr_a = &a;
	ptr_b = &b;
	
	inc(ptr_a);
	
	printf("%c %c\n", *ptr_a, *ptr_b);
}
```

我们把上面的代码编译并运行：

```c
$ cc foo.c
$ ./a.out
b c
$
```

可以看到，在这面的这段代码中，`inc(char *ptr)`这个方法是产生了side effect的。在main函数中调用`int(ptr_a)`的时候，期望的结果是把`ptr_a`指向的内容加1，但实际上在inc内部，它还把`ptr_b`中的内容悄悄地加了1，这样当我们调用完inc函数后，不光是`ptr_a`的内容被加1，`ptr_b`的内容也被修改了。

在实战过程中，这种side effect往往藏得很深，并不容易被发现，比如我最近在调一个RESTEasy的Bug[^1]。有关这个BUG的细节容并不重要，我们主要拿这个来做为样例。首先，下面是我针对这个bug提供的patch：

[^1]: https://issues.jboss.org/browse/RESTEASY-795

```java
public ResteasyJacksonProvider() {    
  super();
  Annotations[] ANNOTATIONS = {Annotations.JACKSON, Annotations.JAXB};
  _mapperConfig.setAnnotationsToUse(ANNOTATIONS);
}
```

但Bill认为我的patch有问题，最终的patch如下：

```java
public class ResteasyJacksonProvider extends JacksonJsonProvider
{
	public ResteasyJacksonProvider() {
		super(Annotations.JACKSON, Annotations.JAXB);
	}
}
```

两者的区别在于，我的patch是在调用了JacksonJsonProvider的constructor方法后，设置了所需参数：

```java
super();
_mapperConfig.setAnnotationsToUse(ANNOTATIONS);
```

而Bill的方法则是直接调用constructor并传入了初始参数：

```java
super(Annotations.JACKSON, Annotations.JAXB);
```

这两者有什么区别呢？主要的问题存在于_mapperConfig.setAnnotationsToUse这个方法具有side effect：

```java
_mapperConfig.setAnnotationsToUse(ANNOTATIONS);
```

打开这个`_mapperConfig`对应的class并查看`setAnnotationsToUse`：

```java
package org.codehaus.jackson.jaxrs;
public class MapperConfigurator
{
	public synchronized void setAnnotationsToUse(Annotations[] annotationsToUse) {
		_setAnnotations(mapper(), annotationsToUse);
	}
}
```

在上面的setAnnotationsToUse方法中，调用了`mapper()`方法，而这个方法会创建一个公用数据：

```java
protected ObjectMapper mapper()
{
	if (_mapper == null) {
		_mapper = new ObjectMapper();
		_setAnnotations(_mapper, _defaultAnnotationsToUse);
	}
	return _mapper;
}
```

在`mapper()`方法中，我们看到新创建了一个`_mapper`：

```java
_mapper = new ObjectMapper();
```

而这个新创建的数据会影响另外一个Class当中的代码逻辑：

```java
package org.codehaus.jackson.jaxrs;
public class JacksonJsonProvider

	public ObjectMapper locateMapper(Class<?> type, MediaType mediaType)
	{
		// First: were we configured with a specific instance?
		ObjectMapper m = _mapperConfig.getConfiguredMapper();
		if (m == null) {
			...
		}

	}
}
```

可以从上面的代码看到，当`_mapperConfig.getConfiguredMapper()`返回值不同时，`locateMapper(...)`方法的逻辑是不同的。于是我的patch就会造成既有代码执行结果的不同。

从上面的分析当中，我们也可以理解函数式语言的优势：每一个函数内部不具备状态，给定输入，可以期待相同的输出，同时不会带来内部状态的改变。

当然，并不是所有的系统都是无状态的，因为很多系统的目标就是管理状态，但在系统内部把有状态的部分和无状态的部分拆开，会使得整个系统更易于维护。 
