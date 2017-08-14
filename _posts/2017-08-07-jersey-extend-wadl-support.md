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

In above code, I can see the generated `include` part is added into `grammars` section. Please note the above code is used to generate the `grammars` section in `/application.wadl` data output. It's not the function that generate the content of `/application.wadl/xsd0.xsd`. Here is the sequence diagram of the above method:

![/assets/org.glassfish.jersey.server.wadl.internal.WadlApplicationContextImpl.attachExternalGrammar(Application, ApplicationDescription, URI).png](/assets/org.glassfish.jersey.server.wadl.internal.WadlApplicationContextImpl.attachExternalGrammar(Application, ApplicationDescription, URI).png)

Here is the relative code deals with the grammars section:

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

From above screenshot, we can see the `applicationDescription` has the `getExternalMetadataKeys()` method, and `path` is fetched from it. The default path value is `xsd0.xsd`. This is the automatically generated grammar file by Jersey. Here is the code of `getExternalMetadataKeys()` method inside `ApplicationDescription` class:

```java
/**
 * @return A set of all the external metadata keys
 */
public Set<String> getExternalMetadataKeys() {
    return _externalGrammarDefiniton.map.keySet();
}
```

We can see the method only return the key set of `_externalGrammarDefiniton`. Here is the definition of `_externalGrammarDefiniton` inside `ApplicationDescription`:

```java
private WadlGenerator.ExternalGrammarDefinition _externalGrammarDefiniton;
```

From above we can see the `ExternalGrammarDefinition` is an inner class of `WadlGenerator`, and here is the class diagram of it:

![/assets/2017-08-08-ExternalGrammarDefinition.png](/assets/2017-08-08-ExternalGrammarDefinition.png)

From above diagram we can see the `ExternalGrammarDefinition` class has a map of `ExternalGrammar` and a list of `Resolver`. Here is the class diagram of these classes:

![/assets/2017-08-08-ExternalGrammar.png](/assets/2017-08-08-ExternalGrammar.png)

From above diagram, we can see `ExternalGrammar` contains `_content` with type of `byte[]`. The `ExternalGrammar` is used in `WadlResource`. Here is the class diagram of the `WadlResource`:

![/assets/2017-08-09-WadlResource.png](/assets/2017-08-09-WadlResource.png)

This is a JAX-RS resource class created by Jeresy to provide the `/application.wadl` resource. I'd like to check the `getWadl(...)` and `getExternalGrammar(...)` methods in the class. Here is the full code of the `WadlResource`:

```java
/*
 * DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
 *
 * Copyright (c) 2010-2017 Oracle and/or its affiliates. All rights reserved.
 *
 * The contents of this file are subject to the terms of either the GNU
 * General Public License Version 2 only ("GPL") or the Common Development
 * and Distribution License("CDDL") (collectively, the "License").  You
 * may not use this file except in compliance with the License.  You can
 * obtain a copy of the License at
 * https://oss.oracle.com/licenses/CDDL+GPL-1.1
 * or LICENSE.txt.  See the License for the specific
 * language governing permissions and limitations under the License.
 *
 * When distributing the software, include this License Header Notice in each
 * file and include the License file at LICENSE.txt.
 *
 * GPL Classpath Exception:
 * Oracle designates this particular file as subject to the "Classpath"
 * exception as provided by Oracle in the GPL Version 2 section of the License
 * file that accompanied this code.
 *
 * Modifications:
 * If applicable, add the following below the License Header, with the fields
 * enclosed by brackets [] replaced by your own identifying information:
 * "Portions Copyright [year] [name of copyright owner]"
 *
 * Contributor(s):
 * If you wish your version of this file to be governed by only the CDDL or
 * only the GPL Version 2, indicate your decision by adding "[Contributor]
 * elects to include this software in this distribution under the [CDDL or GPL
 * Version 2] license."  If you don't indicate a single choice of license, a
 * recipient has the option to distribute your version of this file under
 * either the CDDL, the GPL Version 2 or to extend the choice of license to
 * its licensees as provided above.  However, if you add GPL Version 2 code
 * and therefore, elected the GPL Version 2 license, then the option applies
 * only if the new code is made subject to such option by the copyright
 * holder.
 */

package org.glassfish.jersey.server.wadl.internal;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.net.URI;
import java.text.SimpleDateFormat;
import java.util.Date;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.ProcessingException;
import javax.ws.rs.Produces;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.UriInfo;

import javax.inject.Singleton;
import javax.xml.bind.Marshaller;

import org.glassfish.jersey.server.internal.LocalizationMessages;
import org.glassfish.jersey.server.model.ExtendedResource;
import org.glassfish.jersey.server.wadl.WadlApplicationContext;

import com.sun.research.ws.wadl.Application;

/**
 *
 * @author Paul Sandoz
 */
@Singleton
@Path("application.wadl")
@ExtendedResource
public final class WadlResource {

    public static final String HTTPDATEFORMAT = "EEE, dd MMM yyyy HH:mm:ss zzz";

    private volatile URI lastBaseUri;
    private volatile boolean lastDetailedWadl;

    private byte[] wadlXmlRepresentation;
    private String lastModified;

    @Context
    private WadlApplicationContext wadlContext;


    public WadlResource() {
        this.lastModified = new SimpleDateFormat(HTTPDATEFORMAT).format(new Date());
    }

    private boolean isCached(UriInfo uriInfo, boolean detailedWadl) {
        return (lastBaseUri != null && lastBaseUri.equals(uriInfo.getBaseUri()) && lastDetailedWadl == detailedWadl);
    }

    @Produces({"application/vnd.sun.wadl+xml", "application/xml"})
    @GET
    public synchronized Response getWadl(@Context UriInfo uriInfo) {
        try {
            if (!wadlContext.isWadlGenerationEnabled()) {
                return Response.status(Response.Status.NOT_FOUND).build();
            }

            final boolean detailedWadl = WadlUtils.isDetailedWadlRequested(uriInfo);
            if ((wadlXmlRepresentation == null) || (!isCached(uriInfo, detailedWadl))) {
                this.lastBaseUri = uriInfo.getBaseUri();
                lastDetailedWadl = detailedWadl;
                this.lastModified = new SimpleDateFormat(HTTPDATEFORMAT).format(new Date());

                ApplicationDescription applicationDescription = wadlContext.getApplication(uriInfo,
                        detailedWadl);

                Application application = applicationDescription.getApplication();

                try {
                    final Marshaller marshaller = wadlContext.getJAXBContext().createMarshaller();
                    marshaller.setProperty(Marshaller.JAXB_FORMATTED_OUTPUT, true);
                    final ByteArrayOutputStream os = new ByteArrayOutputStream();
                    marshaller.marshal(application, os);
                    wadlXmlRepresentation = os.toByteArray();
                    os.close();
                } catch (Exception e) {
                    throw new ProcessingException("Could not marshal the wadl Application.", e);
                }
            }

            return Response.ok(new ByteArrayInputStream(wadlXmlRepresentation)).header("Last-modified", lastModified).build();
        } catch (Exception e) {
            throw new ProcessingException("Error generating /application.wadl.", e);
        }
    }


    @Produces({"application/xml"})
    @GET
    @Path("{path}")
    public synchronized Response getExternalGrammar(
            @Context UriInfo uriInfo,
            @PathParam("path") String path) {
        try {
            // Fail if wadl generation is disabled
            if (!wadlContext.isWadlGenerationEnabled()) {
                return Response.status(Response.Status.NOT_FOUND).build();
            }

            ApplicationDescription applicationDescription =
                    wadlContext.getApplication(uriInfo, WadlUtils.isDetailedWadlRequested(uriInfo));

            // Fail is we don't have any metadata for this path
            ApplicationDescription.ExternalGrammar externalMetadata = applicationDescription.getExternalGrammar(path);

            if (externalMetadata == null) {
                return Response.status(Response.Status.NOT_FOUND).build();
            }

            // Return the data
            return Response.ok().type(externalMetadata.getType())
                    .entity(externalMetadata.getContent())
                    .build();
        } catch (Exception e) {
            throw new ProcessingException(LocalizationMessages.ERROR_WADL_RESOURCE_EXTERNAL_GRAMMAR(), e);
        }
    }

}
```

Here is the sequence diagram of the `getWadl(...)` method in `WadlResource`:

![/assets/org.glassfish.jersey.server.wadl.internal.WadlResource.getWadl(UriInfo).png](/assets/org.glassfish.jersey.server.wadl.internal.WadlResource.getWadl(UriInfo).png)

From the above sequence diagram, we can see the method will get `ApplicationDescription` from `WadlApplicationContext`, and then from `WadlApplicationContext` it will get the `ApplicationDescription`. Finally the `Application` will be fetched from `WadlApplicationDescription`. Now let's check the sequence diagram of the `getExternalGrammar(...)` method:

![/assets/org.glassfish.jersey.server.wadl.internal.WadlResource.getExternalGrammar(UriInfo, String).png](/assets/org.glassfish.jersey.server.wadl.internal.WadlResource.getExternalGrammar(UriInfo, String).png)

From the above sequence diagram, we can see the method will finally call the `getExternalGrammar(...)` method in `ApplicationDescription`. Here is the sequence diagram:

![/assets/org.glassfish.jersey.server.wadl.internal.ApplicationDescription.getExternalGrammar(String).png)](/assets/org.glassfish.jersey.server.wadl.internal.ApplicationDescription.getExternalGrammar(String).png)

From above we can see the method will return the instance of `ExternalGrammar`. After learning the above WADL generation process, now let's check how does the default `xsd0.xsd` grammars get generated.

Firstly we should check the `getExternalGrammar(...)` method in `WadlResource`, because from the `@Path` configuration of this method, we can see it will serve the `/application.wadl/{path}` path, and so it will serve the generated `/application.wadl/xsd0.xsd` path. This is the core part of the `getExternalGrammar(...)` method:

```java
ApplicationDescription applicationDescription =
        wadlContext.getApplication(uriInfo, WadlUtils.isDetailedWadlRequested(uriInfo));

// Fail is we don't have any metadata for this path
ApplicationDescription.ExternalGrammar externalMetadata = applicationDescription.getExternalGrammar(path);
```

In above code, the `ApplicationDescription` is fetched from `WadlContenxt`, and in `ApplicationDescription` it contains `ExternalGrammar`. Finally, in `ExternalGrammar` it contains the generated WADL data. We can confirm this by setting a breakpoint in the `getApplication()` method of `WadlApplicationContextImpl` class, and here is the screenshot:

![/assets/WadlApplicationContextImpl.png](/assets/WadlApplicationContextImpl.png)

From the above screenshot, we can see the `_content` in `_externalGrammarDefiniton` of `WadlApplicationContextImpl` contains the generated WADL data related with `xsd0.xsd`, and this generation process happened in `getApplication()` method.

In `getApplication(...)` method of `WadlApplicationContextImpl`, the core part is here:

```java
final ApplicationDescription applicationDescription = getWadlBuilder(detailedWadl, uriInfo)
        .generate(resourceContext.getResourceModel().getRootResources());
```

We can see it will call its `getWadlBuilder(...)` method to get an instance of `WadlBuilder` and then use it to generate the WADL data.  In above code, it fetches the `WadlBuilder` and run its `generate(...)` method.

So the default grammars section is actually generated by `WadlBuilder` from resources. In below is the screenshot to see the running state of the `WadlBuilder.generate(...)` method called by `WadlApplicationContextImpl.getApplication(...)` method:

![/assets/2017-08-10-generate.png](/assets/2017-08-10-generate.png)

From the above screenshot, we can see the resources are passed into the method, and the builder will generate the WADL default grammars from it. So we can see the process to generate grammars is same with generating other parts of the WADL data, and it will just use WadlBuilder to do the job.

Here is the code of the `WadlBuilder.generate(...)` method:

```java
/**
   * Generate WADL for a set of resources.
   *
   * @param resources the set of resources.
   * @return the JAXB WADL application bean.
   */
  public ApplicationDescription generate(List<org.glassfish.jersey.server.model.Resource> resources) {
      Application wadlApplication = _wadlGenerator.createApplication();
      Resources wadlResources = _wadlGenerator.createResources();

      // for each resource
      for (org.glassfish.jersey.server.model.Resource r : resources) {
          Resource wadlResource = generateResource(r, r.getPath());
          if (wadlResource == null) {
              continue;
          }
          wadlResources.getResource().add(wadlResource);
      }
      wadlApplication.getResources().add(wadlResources);

      addVersion(wadlApplication);
      addHint(wadlApplication);

      // Build any external grammars

      WadlGenerator.ExternalGrammarDefinition external =
              _wadlGenerator.createExternalGrammar();
      //

      ApplicationDescription description = new ApplicationDescription(wadlApplication, external);

      // Attach the data to the parts of the model

      _wadlGenerator.attachTypes(description);

      // Return the description of the application

      return description;
  }

```

From the above code, we can see besides processing resources, it will call the `_wadlGenerator.createExternalGrammar()` method to deal with the grammars section.

I set a breakpoint here and found that the class that implements the `WadlBuilder` interface fetched here is `WadlGeneratorJAXBGrammarGenerator`. Here is the class diagram of `WadlGeneratorJAXBGrammarGenerator`:

![/assets/WadlGeneratorJAXBGrammarGenerator.png](/assets/WadlGeneratorJAXBGrammarGenerator.png)

The purpose of calling the `createExternalGrammar()` method in `WadlGeneratorJAXBGrammarGenerator` is to fill the `WadlGenerator.ExternalGrammarDefinition`. After the method is called inside `WadlBuilder.generator()`, we can see the `_content` inside `ExternalGrammarDefinition` is filled. Here is the screenshot:

![/assets/2017-08-10-content.png](/assets/2017-08-10-content.png)

After above internal grammars generation process is done, the main work is almost done. It will attach the rest of metadata to the grammars section, and finally the filled `ApplicationDescription.ExternalGrammar` will be returned to `WadlResource`. Here is the screenshot:

![/assets/2017-08-10-WadlResource.png](/assets/2017-08-10-WadlResource.png)

From the above screenshot, we can see the `ApplicationDescription.ExternalGrammar` is finally returned to `WadlResource.getExternalGrammar(...)` method, and it will be returned to the caller of `/application.wadl/xsd0.xsd`.

From the above learning, we can see the `getWadl(...)` method and the `getExternalGrammar(...)` method in `WadlResource` class are almost the same. They all rely on the underlying Jersey structures to generate WADL resources, but one return the whole WADL data and the other one just return the generated external grammar data. Here are is comparation result of the two methods:

![/assets/2017-08-11-diff.png](/assets/2017-08-11-diff.png)

In the next step, I'd like to analyze how the `xsd0.xsd` is related with the generated grammars. I set a breakpoint in the `WadlResource.getExternalGrammar(...)` method, and then I request with following command:

```bash
$ curl http://localhost:8080/extended-wadl-webapp/application.wadl/xsd1.xsd
```

In above command I used `xsd1.xsd` in request URL to see if Jersey generate the path dynamically and if it will serve it. Here is the breakpoint screenshot from server side:

![/assets/2017-08-11-xsd1.png](/assets/2017-08-11-xsd1.png)

From above screenshot we can see the `xsd1.xsd` is passed into the method as `path` parameter. However inside `_externamGrammarDefinition` the `key` is still `xsd0.xsd`. From this we can see Jersey doesn't generate the URL dynamically, and it serves the `xsd0.xsd` statically.

This process happens in `WadlGeneratorJAXBGrammarGenerator.buildModelAndSchemas(...)` method. Here is the screenshot inside the method:

![/assets/2017-08-11-generate-xsd1.png](/assets/2017-08-11-generate-xsd1.png)

From the above screenshot, we can see the filename generation process. Here is the full code of the `buildModelAndSchemas(...)` method:

```java
/**
 * Build the JAXB model and generate the schemas based on tha data
 *
 * @param extraFiles additional files.
 * @return class to {@link QName} resolver.
 */
private Resolver buildModelAndSchemas(final Map<String, ApplicationDescription.ExternalGrammar> extraFiles) {

    // Lets get all candidate classes so we can create the JAX-B context
    // include any @XmlSeeAlso references.

    final Set<Class> classSet = new HashSet<>(seeAlsoClasses);

    for (final TypeCallbackPair pair : nameCallbacks) {
        final GenericType genericType = pair.genericType;
        final Class<?> clazz = genericType.getRawType();

        // Is this class itself interesting?

        if (clazz.getAnnotation(XmlRootElement.class) != null) {
            classSet.add(clazz);
        } else if (SPECIAL_GENERIC_TYPES.contains(clazz)) {

            final Type type = genericType.getType();
            if (type instanceof ParameterizedType) {
                final Type parameterType = ((ParameterizedType) type).getActualTypeArguments()[0];
                if (parameterType instanceof Class) {
                    classSet.add((Class) parameterType);
                }
            }
        }
    }

    // Create a JAX-B context, and use this to generate us a bunch of
    // schema objects

    JAXBIntrospector introspector = null;

    try {
        final JAXBContext context = JAXBContext.newInstance(classSet.toArray(new Class[classSet.size()]));

        final List<StreamResult> results = new ArrayList<>();

        context.generateSchema(new SchemaOutputResolver() {

            int counter = 0;

            @Override
            public Result createOutput(final String namespaceUri, final String suggestedFileName) {
                final StreamResult result = new StreamResult(new CharArrayWriter());
                result.setSystemId("xsd" + (counter++) + ".xsd");
                results.add(result);
                return result;
            }
        });

        // Store the new files for later use
        //

        for (final StreamResult result : results) {
            final CharArrayWriter writer = (CharArrayWriter) result.getWriter();
            final byte[] contents = writer.toString().getBytes("UTF8");
            extraFiles.put(
                    result.getSystemId(),
                    new ApplicationDescription.ExternalGrammar(
                            MediaType.APPLICATION_XML_TYPE, // I don't think there is a specific media type for XML Schema
                            contents));
        }

        // Create an introspector
        //

        introspector = context.createJAXBIntrospector();

    } catch (final JAXBException e) {
        LOGGER.log(Level.SEVERE, "Failed to generate the schema for the JAX-B elements", e);
    } catch (final IOException e) {
        LOGGER.log(Level.SEVERE, "Failed to generate the schema for the JAX-B elements due to an IO error", e);
    }

    // Create introspector

    if (introspector != null) {
        final JAXBIntrospector copy = introspector;

        return new Resolver() {

            public QName resolve(final Class type) {

                Object parameterClassInstance = null;
                try {
                    final Constructor<?> defaultConstructor =
                            AccessController.doPrivileged(new PrivilegedExceptionAction<Constructor<?>>() {
                                @SuppressWarnings("unchecked")
                                @Override
                                public Constructor<?> run() throws NoSuchMethodException {
                                    final Constructor<?> constructor = type.getDeclaredConstructor();
                                    constructor.setAccessible(true);
                                    return constructor;
                                }
                            });
                    parameterClassInstance = defaultConstructor.newInstance();
                } catch (final InstantiationException | SecurityException | IllegalAccessException
                        | IllegalArgumentException | InvocationTargetException ex) {
                    LOGGER.log(Level.FINE, null, ex);
                } catch (final PrivilegedActionException ex) {
                    LOGGER.log(Level.FINE, null, ex.getCause());
                }

                if (parameterClassInstance == null) {
                    return null;
                }

                try {
                    return copy.getElementName(parameterClassInstance);
                } catch (final NullPointerException e) {
                    // EclipseLink throws an NPE if an object annotated with @XmlType and without the @XmlRootElement
                    // annotation is passed as a parameter of #getElementName method.
                    return null;
                }
            }
        };
    } else {
        return null; // No resolver created
    }
}
```

The above method is used to generate the default grammars file, and it is called by the `createExternalGrammar()` method in the same class. Here is the code of `createExternalGrammar()` method:

```java
public ExternalGrammarDefinition createExternalGrammar() {

     // Right now lets generate some external metadata

     final Map<String, ApplicationDescription.ExternalGrammar> extraFiles = new HashMap<>();

     // Build the model as required
     final Resolver resolver = buildModelAndSchemas(extraFiles);

     // Pass onto the next delegate
     final ExternalGrammarDefinition previous = wadlGeneratorDelegate.createExternalGrammar();
     previous.map.putAll(extraFiles);
     if (resolver != null) {
         previous.addResolver(resolver);
     }

     return previous;
}
```



### _References_

[^jersey]: Jersey codebase Github mirror: [https://github.com/jersey/jersey](https://github.com/jersey/jersey)
