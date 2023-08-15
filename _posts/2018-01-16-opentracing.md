---
title: Opentracing：「ThreadLocalActiveSpanSource」和「ThreadLocalActiveSpan」
abstract: 分析「ThreadLocalActiveSpanSource」和「ThreadLocalActiveSpan」这两个Classes之间的关系。
author: 阿男
---



以下是ThreadLocalActiveSpanSource：

```java
/**
 * A simple {@link ActiveSpanSource} implementation built on top of Java's thread-local storage primitive.
 *
 * @see ThreadLocalActiveSpan
 * @see Tracer#activeSpan()
 */
public class ThreadLocalActiveSpanSource implements ActiveSpanSource {
	final ThreadLocal<ThreadLocalActiveSpan> tlsSnapshot = new ThreadLocal<ThreadLocalActiveSpan>();

	@Override
	public ThreadLocalActiveSpan activeSpan() {
		return tlsSnapshot.get();
	}

	@Override
	public ActiveSpan makeActive(Span span) {
		return new ThreadLocalActiveSpan(this, span, new AtomicInteger(1));
	}

}
```

注意上面的「makeActive(...)」方法是如何创建了一个「ThreadLocalActiveSpan」的实例：

```java
public class ThreadLocalActiveSpanSource implements ActiveSpanSource {
    @Override
    public ActiveSpan makeActive(Span span) {
        return new ThreadLocalActiveSpan(this, span, new AtomicInteger(1));
    }
}
```

可以看到「ThreadLocalActiveSpan」的Constructor接受的参数之一是「this」，因此「ThreadLocalActiveSpanSource」会在「ThreadLocalActiveSpan」的Constructor中被使用。可以看下「ThreadLocalActiveSpan」的Constructor代码：

```java
public class ThreadLocalActiveSpan implements ActiveSpan {
	private final ThreadLocalActiveSpanSource source;
	private final Span  wrapped;
	private final ThreadLocalActiveSpan toRestore;
	private final AtomicInteger refCount;

	ThreadLocalActiveSpan(ThreadLocalActiveSpanSource source, Span wrapped, AtomicInteger refCount) {
		this.source = source;
		this.refCount = refCount;
		this.wrapped = wrapped;
		this.toRestore = source.tlsSnapshot.get();
		source.tlsSnapshot.set(this);
	}
}
```

如上所示，「ThreadLocalActiveSpanSource」的实例被保存在「source」里面，然后「source.tlsSnapshot」被设置好了。



