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

This is related with the JAXB class resource in the example, and we will check the detail later. Now we can check the server output in detail. Here is the part I'm interested in:

```
Aug 07, 2017 4:51:10 PM org.glassfish.jersey.server.wadl.config.WadlGeneratorLoader loadWadlGenerator
INFO: Loading wadlGenerator org.glassfish.jersey.server.wadl.internal.generators.WadlGeneratorGrammarsSupport
Aug 07, 2017 4:51:10 PM org.glassfish.jersey.server.wadl.config.WadlGeneratorLoader loadWadlGenerator
INFO: Loading wadlGenerator org.glassfish.jersey.server.wadl.internal.generators.WadlGeneratorGrammarsSupport
Aug 07, 2017 4:51:10 PM org.glassfish.jersey.server.wadl.internal.WadlApplicationContextImpl attachExternalGrammar
INFO: The wadl application already contains a grammars element, were adding elements of the provided grammars file.
Aug 07, 2017 4:53:08 PM org.glassfish.jersey.server.wadl.config.WadlGeneratorLoader loadWadlGenerator
INFO: Loading wadlGenerator org.glassfish.jersey.server.wadl.internal.generators.WadlGeneratorGrammarsSupport
Aug 07, 2017 4:53:08 PM org.glassfish.jersey.server.wadl.internal.WadlApplicationContextImpl attachExternalGrammar
INFO: The wadl application already contains a grammars element, were adding elements of the provided grammars file.
```

From the above debug log output, we can see the load process of `WadlGeneratorGrammarsSupport`. We can see a class named `WadlGeneratorLoader`, and there is a method named `loadWadlGenerator`. We will check this later. Then we can see a class `WadlApplicationContextImpl` and its method `attachExternalGrammar`. This should be the place that deals with the grammars, and we will check in detail later. At last, we can see some `INFO` like this:

```
INFO: The wadl application already contains a grammars element, were adding elements of the provided grammars file.
```

This is because we didn't override the default grammars generation by setting `overrideGrammars` to `false` in `WadlGeneratorGrammarsSupport`, and that's what we expected.

Now let's check `WadlApplicationContextImpl` in detail. In the class there is a `getApplication(...)` method:

```java
@Override
public ApplicationDescription getApplication(final UriInfo uriInfo, final boolean detailedWadl) {
    final ApplicationDescription applicationDescription = getWadlBuilder(detailedWadl, uriInfo)
            .generate(resourceContext.getResourceModel().getRootResources());
    final Application application = applicationDescription.getApplication();
    for (final Resources resources : application.getResources()) {
        if (resources.getBase() == null) {
            resources.setBase(uriInfo.getBaseUri().toString());
        }
    }
    attachExternalGrammar(application, applicationDescription, uriInfo.getRequestUri());
    return applicationDescription;
}
```

From the above code, we can see a method named `attachExternalGrammar(...)` is used to deal with the grammars section. Here is the code of the `attachExternalGrammar(...)` method:

```java
/**
 * Update the application object to include the generated grammar objects.
 */
private void attachExternalGrammar(
        final Application application,
        final ApplicationDescription applicationDescription,
        URI requestURI) {

    // Massage the application.wadl URI slightly to get the right effect
    //

    try {
        final String requestURIPath = requestURI.getPath();

        if (requestURIPath.endsWith("application.wadl")) {
            requestURI = UriBuilder.fromUri(requestURI)
                    .replacePath(
                            requestURIPath
                                    .substring(0, requestURIPath.lastIndexOf('/') + 1))
                    .build();
        }

        final String root = application.getResources().get(0).getBase();
        final UriBuilder extendedPath = root != null
                ? UriBuilder.fromPath(root).path("/application.wadl/") : UriBuilder.fromPath("./application.wadl/");
        final URI rootURI = root != null ? UriBuilder.fromPath(root).build() : null;

        // Add a reference to this grammar
        //

        final Grammars grammars;
        if (application.getGrammars() != null) {
            LOGGER.info(LocalizationMessages.ERROR_WADL_GRAMMAR_ALREADY_CONTAINS());
            grammars = application.getGrammars();
        } else {
            grammars = new Grammars();
            application.setGrammars(grammars);
        }

        // Create a reference back to the root WADL
        //

        for (final String path : applicationDescription.getExternalMetadataKeys()) {
            final URI schemaURI = extendedPath.clone().path(path).build();
            final String schemaPath = rootURI != null ? requestURI.relativize(schemaURI).toString() : schemaURI.toString();

            final Include include = new Include();
            include.setHref(schemaPath);
            final Doc doc = new Doc();
            doc.setLang("en");
            doc.setTitle("Generated");
            include.getDoc().add(doc);

            // Finally add to list
            grammars.getInclude().add(include);
        }
    } catch (final Exception e) {
        throw new ProcessingException(LocalizationMessages.ERROR_WADL_EXTERNAL_GRAMMAR(), e);
    }
}
```

In above code, I can see the generated `include` part is added into `grammars` section. Here is the relative code:

```java
for (final String path : applicationDescription.getExternalMetadataKeys()) {
    final URI schemaURI = extendedPath.clone().path(path).build();
    final String schemaPath = rootURI != null ? requestURI.relativize(schemaURI).toString() : schemaURI.toString();

    final Include include = new Include();
    include.setHref(schemaPath);
    final Doc doc = new Doc();
    doc.setLang("en");
    doc.setTitle("Generated");
    include.getDoc().add(doc);

    // Finally add to list
    grammars.getInclude().add(include);
}
```

I set a breakpoint to above logic, and set Maven to run in remote debug mode with this command:

```bash
export MAVEN_OPTS="-Xdebug -Xnoagent -Djava.compiler=NONE -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=8989"
```

And then I restart the server, and remote debug it in IntelliJ. Here is the callstack I got in IntelliJ:

![/assets/2017-08-08-grammar-callstack.png](/assets/2017-08-08-grammar-callstack.png)

### _References_

---

[^jersey]: Jersey codebase Github mirror: [https://github.com/jersey/jersey](https://github.com/jersey/jersey)
