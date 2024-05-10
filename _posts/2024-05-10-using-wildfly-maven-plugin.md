---
title: Using the wildfly-maven-plugin and the shared WildFly build to do the testing.
---

I have set up a sample project showing the usage of `wildfly-maven-plugin` and the shared WildFly build in Github CI:

- https://github.com/liweinan/wildfly-preview-ci-experiment

In the project it has the `wildfly-maven-plugin` added to generate the provisioned WildFly server:

```xml
<plugin>
    <groupId>org.wildfly.plugins</groupId>
    <artifactId>wildfly-maven-plugin</artifactId>
    <version>${version.wildfly-maven-plugin}</version>
...
```

With the configuration, the `jboss-home` should be defined in the `provision` goal, and used in the top level of the plugin for it to work properly:

```xml
<plugin>
    <groupId>org.wildfly.plugins</groupId>
    <artifactId>wildfly-maven-plugin</artifactId>
    <version>${version.wildfly-maven-plugin}</version>
    <configuration>
        <jboss-home>${jboss.home}</jboss-home> <-- put it here so the provisioned WildFly server could be used.
    </configuration>
    <executions>
        <execution>
            <id>server-provisioning</id>
            <phase>generate-test-resources</phase>
            <goals>
                <goal>provision</goal>
            </goals>
            <configuration>
                <provisioning-dir>${jboss.home}</provisioning-dir> <-- tell the plugin to genereate the provisioned server in the position.
                <galleon-options>
                    <jboss-fork-embedded>${galleon.fork.embedded}</jboss-fork-embedded>
                </galleon-options>
...
```

The feature pack can be configured like this so different feature packs can be used:

```xml
<feature-pack>
    <groupId>${server.test.feature.pack.groupId}</groupId>
    <artifactId>${server.test.feature.pack.artifactId}</artifactId>
    <version>${version.org.wildfly}</version>
...
```

Here is the default setting of the above properties:

```xml
<properties>
    <server.test.feature.pack.groupId>org.wildfly</server.test.feature.pack.groupId>
    <server.test.feature.pack.artifactId>wildfly-ee-galleon-pack</server.test.feature.pack.artifactId>
</properties>
```

Here are the properties defined in the `provision-preview`  profile:

```xml
<profile>
            <id>provision-preview</id>
            <properties>
                <server.test.feature.pack.groupId>org.wildfly</server.test.feature.pack.groupId>
                <server.test.feature.pack.artifactId>wildfly-preview-feature-pack</server.test.feature.pack.artifactId>
            </properties>
</profile>
```

In the [`main.yml`](https://github.com/liweinan/wildfly-preview-ci-experiment/blob/main/.github/workflows/main.yml), the Github CI task `shared-wildfly-build.yml` is used to build the WildFly main branch and put into the local Maven repo during the CI testing process:

```yml
jobs:
  wildfly-build:
    uses: wildfly/wildfly/.github/workflows/shared-wildfly-build.yml@main
    with:
      wildfly-branch: "main"
      wildfly-repo: "wildfly/wildfly"
...
```

The above file is defined in the WildFly repo:

- [wildfly/.github/workflows/shared-wildfly-build.yml at main · wildfly/wildfly](https://github.com/wildfly/wildfly/blob/main/.github/workflows/shared-wildfly-build.yml)

It will build the main branch of the WildFly and archive it into Maven repo, so the other project(like this sample project) can refer to it and use it during testing. And the built version of WildFly can be referred by the variable `needs.wildfly-build.outputs.wildfly-version`. Here is the usage in the `main.yml`:

```yaml
- name: Build With Provisioned WildFly
        run: |
          mvn clean install '-Dversion.org.wildfly=${{needs.wildfly-build.outputs.wildfly-version}}' '-Dversion.wildfly-maven-plugin=5.0.0.Final' '-Pprovision-preview'
```

Here is the relative PR that make the configuration:

- [Preview profile by liweinan · Pull Request \#1 · liweinan/wildfly-preview-ci-experiment](https://github.com/liweinan/wildfly-preview-ci-experiment/pull/1)

In the README of the project there are information on using the project.


