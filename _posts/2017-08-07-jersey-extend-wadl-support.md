---
title: "Analysing the Jersey extended WADL support"
abstract: "In this article, I'd like to record my self-learning process on Jersey extended WADL support. It will be updated as I make progresses."
---

# {{ page.title }}

{{ page.abstract }}

Jersey provides extended WADL support out of box, and it provides an example in its codebase to show the usage of the feature[^jersey]. The name of the example is `extended-wadl-webapp`, and I'd like to use it to do the feature learning.

In the sample, it provides a `SampleWadlGeneratorConfig` to enable the extended WADL feature. Here is the code of the class:

```java
package org.glassfish.jersey.examples.extendedwadl;

import org.glassfish.jersey.server.wadl.config.WadlGeneratorConfig;
import org.glassfish.jersey.server.wadl.config.WadlGeneratorDescription;
import org.glassfish.jersey.server.wadl.internal.generators.WadlGeneratorApplicationDoc;
import org.glassfish.jersey.server.wadl.internal.generators.WadlGeneratorGrammarsSupport;
import org.glassfish.jersey.server.wadl.internal.generators.resourcedoc.WadlGeneratorResourceDocSupport;

import java.util.List;

/**
 * This subclass of {@link WadlGeneratorConfig} defines/configures {@link org.glassfish.jersey.server.wadl.WadlGenerator}s
 * to be used for generating WADL.
 *
 * @author Martin Grotzke (martin.grotzke@freiheit.com)
 */
public class SampleWadlGeneratorConfig extends WadlGeneratorConfig {

    @Override
    public List<WadlGeneratorDescription> configure() {
        return generator(WadlGeneratorGrammarsSupport.class)
                .prop("grammarsStream", "application-grammars.xml")
                .prop("overrideGrammars", false)
                .generator(WadlGeneratorApplicationDoc.class)
                .prop("applicationDocsStream", "application-doc.xml")
                .generator(WadlGeneratorResourceDocSupport.class)
                .prop("resourceDocStream", "resourcedoc.xml")
                .descriptions();
    }

}
```

From above code we can see Jersey supports several extended WADL documents by different classes. For example, there are `WadlGeneratorGrammarsSupport`, `WadlGeneratorApplicationDoc` and `WadlGeneratorResourceDocSupport`, etc. They are all conforms to `WadlGenerator` interface. Here is the relative diagram:

![/assets/2017-08-07-wadl-generator.png](/assets/2017-08-07-wadl-generator.png)

From the above diagram, we can see the relationship of the `WadlGenerator` interface and its implementation classes. I want to focus on `WadlGeneratorGrammarsSupport` in this article, so I will check the `grammars` part of the WADL output in detail. I comment out other two parts in `SampleWadlGeneratorConfig`:

```java
public class SampleWadlGeneratorConfig extends WadlGeneratorConfig {

    @Override
    public List<WadlGeneratorDescription> configure() {
        return generator(WadlGeneratorGrammarsSupport.class)
                .prop("grammarsStream", "application-grammars.xml")
                .prop("overrideGrammars", true)
//                .generator(WadlGeneratorApplicationDoc.class)
//                .prop("applicationDocsStream", "application-doc.xml")
//                .generator(WadlGeneratorResourceDocSupport.class)
//                .prop("resourceDocStream", "resourcedoc.xml")
                .descriptions();
    }

}
```

And I run the sample server with following command:

```bash
$ mvn clean package exec:java -Dmaven.test.skip=true
```

And the server started like this:

![/assets/2017-08-07-server-start.png](/assets/2017-08-07-server-start.png)





### _References_

---

[^jersey]: Jersey codebase Github mirror: [https://github.com/jersey/jersey](https://github.com/jersey/jersey)
