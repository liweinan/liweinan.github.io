---
title: The Analysis of `AutowiredAnnotationBeanPostProcessor` in Springframework
---

In Springframework, the `AutowiredAnnotationBeanPostProcessor` is used to deal with the `@Autowired` and the `@Inject` annotations and inject the beans. Here is the class diagram of `AutowiredAnnotationBeanPostProcessor`:

- AutowiredAnnotationBeanPostProcessor.jpg

This is part of the `javadoc` of the class:

```java
/**
 * {@link org.springframework.beans.factory.config.BeanPostProcessor BeanPostProcessor}
 * implementation that autowires annotated fields, setter methods, and arbitrary
 * config methods. Such members to be injected are detected through annotations:
 * by default, Spring's {@link Autowired @Autowired} and {@link Value @Value}
 * annotations.
 *
 * <p>Also supports the common {@link jakarta.inject.Inject @Inject} annotation,
 * if available, as a direct alternative to Spring's own {@code @Autowired}.
 * Additionally, it retains support for the {@code javax.inject.Inject} variant
 * dating back to the original JSR-330 specification (as known from Java EE 6-8).
 ...
```

It uses the `autowiredAnnotationTypes` internally to store the annotation types to process:


```java
private final Set<Class<? extends Annotation>> autowiredAnnotationTypes = CollectionUtils.newLinkedHashSet(4);

/**
 * Create a new {@code AutowiredAnnotationBeanPostProcessor} for Spring's
 * standard {@link Autowired @Autowired} and {@link Value @Value} annotations.
 * <p>Also supports the common {@link jakarta.inject.Inject @Inject} annotation,
 * if available, as well as the original {@code javax.inject.Inject} variant.
 */
@SuppressWarnings("unchecked")
public AutowiredAnnotationBeanPostProcessor() {
    this.autowiredAnnotationTypes.add(Autowired.class);
    this.autowiredAnnotationTypes.add(Value.class);

    ClassLoader classLoader = AutowiredAnnotationBeanPostProcessor.class.getClassLoader();
    try {
        this.autowiredAnnotationTypes.add((Class<? extends Annotation>)
                ClassUtils.forName("jakarta.inject.Inject", classLoader));
        logger.trace("'jakarta.inject.Inject' annotation found and supported for autowiring");
    }
    catch (ClassNotFoundException ex) {
        // jakarta.inject API not available - simply skip.
    }

    try {
        this.autowiredAnnotationTypes.add((Class<? extends Annotation>)
                ClassUtils.forName("javax.inject.Inject", classLoader));
        logger.trace("'javax.inject.Inject' annotation found and supported for autowiring");
    }
    catch (ClassNotFoundException ex) {
        // javax.inject API not available - simply skip.
    }
}
```

