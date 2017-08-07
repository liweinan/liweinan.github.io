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
                .prop("overrideGrammars", true)
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

Then I use this command to get the `application.wadl`:

```bash
$ curl http://localhost:8080/extended-wadl-webapp/application.wadl
```
And here is the WADL output I got:

```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<application xmlns="http://wadl.dev.java.net/2009/02">
    <doc xmlns:jersey="http://jersey.java.net/" jersey:generatedBy="Jersey: 2.26-SNAPSHOT 2017-08-03 10:33:11"/>
    <doc xmlns:jersey="http://jersey.java.net/" jersey:hint="This is simplified WADL with user and core resources only. To get full WADL with extended resources use the query parameter detail. Link: http://localhost:8080/extended-wadl-webapp/application.wadl?detail=true"/>
    <grammars>
        <include href="schema.xsd"/>
    </grammars>
    <resources base="http://localhost:8080/extended-wadl-webapp/">
        <resource path="items">
            <method id="createItem" name="POST">
                <request>
                    <representation mediaType="application/xml"/>
                </request>
                <response>
                    <representation mediaType="*/*"/>
                </response>
            </method>
            <resource path="{id}">
                <param xmlns:xs="http://www.w3.org/2001/XMLSchema" name="id" style="template" type="xs:int"/>
                <method id="getItem" name="GET">
                    <response>
                        <representation mediaType="application/xml"/>
                        <representation mediaType="text/plain"/>
                    </response>
                </method>
                <method id="getItemAsJSON" name="GET">
                    <response>
                        <representation mediaType="application/json"/>
                    </response>
                </method>
                <resource path="try-hard">
                    <method id="getItem" name="GET">
                        <request>
                            <param xmlns:xs="http://www.w3.org/2001/XMLSchema" name="Try-Hard" style="header" type="xs:boolean"/>
                        </request>
                        <response>
                            <representation mediaType="application/xml"/>
                            <representation mediaType="text/plain"/>
                        </response>
                    </method>
                </resource>
                <resource path="value/{value}">
                    <param xmlns:xs="http://www.w3.org/2001/XMLSchema" name="value" style="template" type="xs:string"/>
                    <method id="updateItemValue" name="PUT"/>
                </resource>
            </resource>
        </resource>
    </resources>
</application>
```

In above is the complete WADL output, and what I'm concerning is the WADL output part:

```xml
<grammars>
    <include href="schema.xsd"/>
</grammars>
```

The `schema.xsd` is configured in `SampleWadlGeneratorConfig` class. The configuration code is like this:

```java
return generator(WadlGeneratorGrammarsSupport.class)
        .prop("grammarsStream", "application-grammars.xml")
        .prop("overrideGrammars", true)
```

By default, Jersey will generate a grammar file automatically, and in above configuration, it set `overrideGrammars` as `true`, so Jersey won't generate the grammars xsd file by itself and it will only use the file assigned by the user.

If we set the `overrideGrammars` to `true` and recompile the sample and restart the server, then the grammars section of WADL output will change to this:

```xml
<grammars>
    <include href="schema.xsd"/>
    <include href="application.wadl/xsd0.xsd">
        <doc title="Generated" xml:lang="en"/>
    </include>
</grammars>
```

From above, we can see a new include file appears in the `grammars` section, and the name is `application.wadl/xsd0.xsd`. This file is generated automatically by Jersey. In addition, we also have the `schema.xsd` as configured. We can also use the `curl` command to fetch the `xsd0.xsd`:

```bash
$ curl http://localhost:8080/extended-wadl-webapp/application.wadl/xsd0.xsd
```

And here is the content of the `xsd0.xsd`:

```xml
<?xml version="1.0" standalone="yes"?>
<xs:schema version="1.0" targetNamespace="http://www.example.com" xmlns:xs="http://www.w3.org/2001/XMLSchema">

  <xs:element name="item">
    <xs:simpleType>
      <xs:restriction base="xs:string"/>
    </xs:simpleType>
  </xs:element>
</xs:schema>
```

This is related with the JAXB class resource in the example, and we will check the detail later.




### _References_

---

[^jersey]: Jersey codebase Github mirror: [https://github.com/jersey/jersey](https://github.com/jersey/jersey)
