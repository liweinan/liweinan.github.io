---
title: A Servlet Example Showing The Jakarta Spec Implementation in Apache Tomcat.
---

Recently I have built a Servlet example here:

- [https://github.com/liweinan/servlet-example](https://github.com/liweinan/servlet-example)

The example is quite self-explanatory here is the `FileUploadServlet` in the project:

```java
@WebServlet(name = "FileUploadServlet", urlPatterns = {"/upload"})
@MultipartConfig(
        fileSizeThreshold = 1024 * 1024 * 1, // 1 MB
        maxFileSize = 1024 * 1024 * 10,      // 10 MB
        maxRequestSize = 1024 * 1024 * 100   // 100 MB
)
public class FileUploadServlet extends HttpServlet {

    public void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

        /* Receive file uploaded to the Servlet from the HTML5 form */
        Part filePart = request.getPart("file");
        String fileName = filePart.getSubmittedFileName();
        String filePath = "/tmp/" + fileName;
        for (Part part : request.getParts()) {
            part.write(filePath);
        }
        response.getWriter().print("The file uploaded sucessfully: " + filePath);
    }

}
```

The project can be built into WAR file with `mvn install`, and it can be deployed into  containers like Apache Tomcat or WildFly. In the example some `jakarta servlet` annotations are used like `jakarta.servlet.annotation.WebServlet` or `jakarta.servlet.annotation.MultipartConfig`.

These annotations are coming from the `jakarta` specs itself:

- [jakartaee / Jakarta Servlet](https://github.com/jakartaee/servlet)

These annotations are implemented by the containers. For example, the Apache Tomcat will be responsible to support the `@MultipartConfig` annotation. Here is the source code repo of the Tomcat:

- [github / Apache Tomcat](https://github.com/apache/tomcat)

Here is the relative part related with the `@MultiplartConfig` annotation in the Tomcat code base:

```bash
➤ grep -rn 'MultipartConfig' *                                                                                                                                                                                                                                          23:11:34
java/org/apache/catalina/Wrapper.java:20:import jakarta.servlet.MultipartConfigElement;
java/org/apache/catalina/Wrapper.java:320:    MultipartConfigElement getMultipartConfigElement();
java/org/apache/catalina/Wrapper.java:329:    void setMultipartConfigElement(
java/org/apache/catalina/Wrapper.java:330:            MultipartConfigElement multipartConfig);
java/org/apache/catalina/core/StandardContext.java:170:     * Allow multipart/form-data requests to be parsed even when the target servlet doesn't specify @MultipartConfig or
java/org/apache/catalina/core/StandardContext.java:1222:     * Set to <code>true</code> to allow requests mapped to servlets that do not explicitly declare @MultipartConfig or
java/org/apache/catalina/core/StandardWrapper.java:39:import jakarta.servlet.MultipartConfigElement;
java/org/apache/catalina/core/StandardWrapper.java:45:import jakarta.servlet.annotation.MultipartConfig;
java/org/apache/catalina/core/StandardWrapper.java:208:    protected MultipartConfigElement multipartConfigElement = null;
java/org/apache/catalina/core/StandardWrapper.java:879:                MultipartConfig annotation = servlet.getClass().getAnnotation(MultipartConfig.class);
java/org/apache/catalina/core/StandardWrapper.java:881:                    multipartConfigElement = new MultipartConfigElement(annotation);
java/org/apache/catalina/core/StandardWrapper.java:1197:    public MultipartConfigElement getMultipartConfigElement() {
java/org/apache/catalina/core/StandardWrapper.java:1202:    public void setMultipartConfigElement(MultipartConfigElement multipartConfigElement) {
java/org/apache/catalina/core/ApplicationServletRegistration.java:26:import jakarta.servlet.MultipartConfigElement;
java/org/apache/catalina/core/ApplicationServletRegistration.java:135:    public void setMultipartConfig(MultipartConfigElement multipartConfig) {
java/org/apache/catalina/core/ApplicationServletRegistration.java:136:        wrapper.setMultipartConfigElement(multipartConfig);
java/org/apache/catalina/Context.java:113:     * do not explicitly declare @MultipartConfig or have
java/org/apache/catalina/connector/LocalStrings_ja.properties:61:coyoteRequest.noMultipartConfig=multi-part 構成が提供されていないため、partを処理できません
java/org/apache/catalina/connector/LocalStrings_zh_CN.properties:59:coyoteRequest.noMultipartConfig=由于没有提供multi-part配置，无法处理parts
java/org/apache/catalina/connector/LocalStrings_fr.properties:61:coyoteRequest.noMultipartConfig=Impossible de traiter des parties, parce qu'aucune configuration multi-parties n'a été fournie
java/org/apache/catalina/connector/LocalStrings_ko.properties:56:coyoteRequest.noMultipartConfig=어떤 multi-part 설정도 제공되지 않았기 때문에, part들을 처리할 수 없습니다.
java/org/apache/catalina/connector/LocalStrings.properties:61:coyoteRequest.noMultipartConfig=Unable to process parts as no multi-part configuration has been provided
java/org/apache/catalina/connector/LocalStrings_cs.properties:27:coyoteRequest.noMultipartConfig=Nelze zpracovat části, protože nebyla poskytnuta žádná multi-part konfigurace
java/org/apache/catalina/connector/LocalStrings_pt_BR.properties:16:coyoteRequest.noMultipartConfig=Impossível processar partes já que não há configuração de multi-part
java/org/apache/catalina/connector/LocalStrings_es.properties:42:coyoteRequest.noMultipartConfig=Imposible procesar partes debido a que se ha proveído una configuración no multipartes
java/org/apache/catalina/connector/Request.java:49:import jakarta.servlet.MultipartConfigElement;
java/org/apache/catalina/connector/Request.java:2419:        MultipartConfigElement mce = getWrapper().getMultipartConfigElement();
java/org/apache/catalina/connector/Request.java:2423:                mce = new MultipartConfigElement(null, connector.getMaxPostSize(), connector.getMaxPostSize(),
java/org/apache/catalina/connector/Request.java:2426:                partsParseException = new IllegalStateException(sm.getString("coyoteRequest.noMultipartConfig"));
java/org/apache/catalina/startup/ContextConfig.java:46:import jakarta.servlet.MultipartConfigElement;
java/org/apache/catalina/startup/ContextConfig.java:1490:                wrapper.setMultipartConfigElement(new MultipartConfigElement(multipartdef.getLocation(), maxFileSize,
java/jakarta/servlet/ServletRegistration.java:90:        void setMultipartConfig(MultipartConfigElement multipartConfig);
java/jakarta/servlet/MultipartConfigElement.java:19:import jakarta.servlet.annotation.MultipartConfig;
java/jakarta/servlet/MultipartConfigElement.java:22: * The programmatic equivalent of {@link jakarta.servlet.annotation.MultipartConfig} used to configure multi-part
java/jakarta/servlet/MultipartConfigElement.java:27:public class MultipartConfigElement {
java/jakarta/servlet/MultipartConfigElement.java:40:    public MultipartConfigElement(String location) {
java/jakarta/servlet/MultipartConfigElement.java:61:    public MultipartConfigElement(String location, long maxFileSize, long maxRequestSize, int fileSizeThreshold) {
java/jakarta/servlet/MultipartConfigElement.java:84:    public MultipartConfigElement(MultipartConfig annotation) {
java/jakarta/servlet/annotation/MultipartConfig.java:30: * multipart/form-data} request are retrieved by a Servlet annotated with {@code MultipartConfig} by calling
java/jakarta/servlet/annotation/MultipartConfig.java:35: * <code>@MultipartConfig()</code> <code>public class UploadServlet extends
java/jakarta/servlet/annotation/MultipartConfig.java:42:public @interface MultipartConfig {
java/jakarta/servlet/http/Part.java:79:     *                     {@link jakarta.servlet.MultipartConfigElement#getLocation()}
java/jakarta/servlet/ServletRequest.java:169:     * {@link jakarta.servlet.annotation.MultipartConfig} annotation or a <code>multipart-config</code> element in the
java/jakarta/servlet/ServletRequest.java:196:     * {@link jakarta.servlet.annotation.MultipartConfig} annotation or a <code>multipart-config</code> element in the
java/jakarta/servlet/ServletRequest.java:221:     * {@link jakarta.servlet.annotation.MultipartConfig} annotation or a <code>multipart-config</code> element in the
java/jakarta/servlet/ServletRequest.java:247:     * {@link jakarta.servlet.annotation.MultipartConfig} annotation or a <code>multipart-config</code> element in the
java/jakarta/el/ImportHandler.java:72:        servletClassNames.add("MultipartConfigElement");
test/org/apache/catalina/core/TestSwallowAbortedUploads.java:30:import jakarta.servlet.MultipartConfigElement;
test/org/apache/catalina/core/TestSwallowAbortedUploads.java:32:import jakarta.servlet.annotation.MultipartConfig;
test/org/apache/catalina/core/TestSwallowAbortedUploads.java:185:    @MultipartConfig
test/org/apache/catalina/core/TestSwallowAbortedUploads.java:248:            // to set our own MultipartConfigElement.
test/org/apache/catalina/core/TestSwallowAbortedUploads.java:251:                w.setMultipartConfigElement(new MultipartConfigElement("",
test/org/apache/catalina/core/TestSwallowAbortedUploads.java:254:                w.setMultipartConfigElement(new MultipartConfigElement(""));
test/org/apache/catalina/core/TestStandardContext.java:31:import jakarta.servlet.MultipartConfigElement;
test/org/apache/catalina/core/TestStandardContext.java:42:import jakarta.servlet.annotation.MultipartConfig;
test/org/apache/catalina/core/TestStandardContext.java:685:        // there is no @MultipartConfig
test/org/apache/catalina/core/TestStandardContext.java:713:    @MultipartConfig
test/org/apache/catalina/core/TestStandardContext.java:737:            // to set our own MultipartConfigElement.
test/org/apache/catalina/core/TestStandardContext.java:738:            w.setMultipartConfigElement(new MultipartConfigElement(""));
test/org/apache/catalina/startup/TestMultipartConfig.java:21:import jakarta.servlet.MultipartConfigElement;
test/org/apache/catalina/startup/TestMultipartConfig.java:39:public class TestMultipartConfig {
test/org/apache/catalina/startup/TestMultipartConfig.java:41:    public void testNoMultipartConfig() throws Exception {
test/org/apache/catalina/startup/TestMultipartConfig.java:44:        MultipartConfigElement mce = servlet.getMultipartConfigElement();
test/org/apache/catalina/startup/TestMultipartConfig.java:50:    public void testDefaultMultipartConfig() throws Exception {
test/org/apache/catalina/startup/TestMultipartConfig.java:55:        MultipartConfigElement mce = servlet.getMultipartConfigElement();
test/org/apache/catalina/startup/TestMultipartConfig.java:65:    public void testPartialMultipartConfigMaxFileSize() throws Exception {
test/org/apache/catalina/startup/TestMultipartConfig.java:70:        MultipartConfigElement mce = servlet.getMultipartConfigElement();
test/org/apache/catalina/startup/TestMultipartConfig.java:80:    public void testPartialMultipartConfigMaxRequestSize() throws Exception {
test/org/apache/catalina/startup/TestMultipartConfig.java:85:        MultipartConfigElement mce = servlet.getMultipartConfigElement();
test/org/apache/catalina/startup/TestMultipartConfig.java:95:    public void testPartialMultipartConfigFileSizeThreshold() throws Exception {
test/org/apache/catalina/startup/TestMultipartConfig.java:100:        MultipartConfigElement mce = servlet.getMultipartConfigElement();
test/org/apache/catalina/startup/TestMultipartConfig.java:110:    public void testCompleteMultipartConfig() throws Exception {
test/org/apache/catalina/startup/TestMultipartConfig.java:119:        MultipartConfigElement mce = servlet.getMultipartConfigElement();
webapps/docs/config/context.xml:270:        target servlet isn't marked with the @MultipartConfig annotation
webapps/docs/config/context.xml:363:        temporary upload location specified in the <code>MultipartConfig</code>
```

As the command output shown above, the Tomcat contains the parts that implements the Jakarta Servlet annotations. Here is the relative class diagram:

- ![](https://raw.githubusercontent.com/liweinan/blogpics2024/main/0415/servlet.jpg)

From above diagram we can see the relationships between the Tomcat classes and the Jakarta Servlet interfaces.