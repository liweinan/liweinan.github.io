---
title: The setup of WildFly in the jberet-tck-runner project
---

I have written a JBeret blog post describing the CI task setup of the `jberet-tck-runner`:

- [Adding rawhide TCK tests into the jberet-tck-runner project](https://jberet.org/jberet-tck-testings/) 

I'd like to add some notes here about the WildFly server setup in the CI in this blog post. Firstly the shared WildFly build is added in the rawhide CI:

- [https://github.com/jberet/jberet-tck-runner/blob/main/.github/workflows/rawhide-default.yml#L18](https://github.com/jberet/jberet-tck-runner/blob/main/.github/workflows/rawhide-default.yml#L18)

```yml
wildfly-build:
  uses: wildfly/wildfly/.github/workflows/shared-wildfly-build.yml@main
  with:
    wildfly-branch: "main"
    wildfly-repo: "wildfly/wildfly"
```

The above setup will build the WildFly main branch, and it will produce a zip file of the WildFly maven repo. The CI task will extract the zip:

```yml
- name: Extract WildFly Maven Repo
  shell: bash
  run: |
    tar xvzf wildfly-maven-repository.tar.gz -C ~
```

In the `pom.xml` of the project, the `wildfly-maven-plugin` can use the above extracted WildFly repo for provision:

- [https://github.com/jberet/jberet-tck-runner/blob/main/pom.xml#L67](https://github.com/jberet/jberet-tck-runner/blob/main/pom.xml#L67)

```xml
<plugin>
    <groupId>org.wildfly.plugins</groupId>
    <artifactId>wildfly-maven-plugin</artifactId>
    <version>${version.wildfly-maven-plugin}</version>
    ...
</plugin>
```

And the WildFly version is injected during the running process:

- [https://github.com/jberet/jberet-tck-runner/blob/main/run-tck-rawhide.sh#L78](https://github.com/jberet/jberet-tck-runner/blob/main/run-tck-rawhide.sh#L78)

```bash
USE_PROFILE="${USE_PROFILE}" \
WFLY_VER="${WFLY_VER}" \
JBERET_VER="${jberet_ver}" \
BATCH_TCK_DIR="${BATCH_TCK_DIR}" \
./run-wildfly-ci.sh
```

The above `WFLY_VER` is fetched and injected in the CI task:

- [https://github.com/jberet/jberet-tck-runner/blob/main/.github/workflows/rawhide-default.yml#L50](https://github.com/jberet/jberet-tck-runner/blob/main/.github/workflows/rawhide-default.yml#L50)

```yml
- name: Run Rawhide Tests With Default WildFly
  run: WFLY_VER=$\{\{needs.wildfly-build.outputs.wildfly-version\}\} USE_BRANCH=$\{\{ matrix.use_branch \}\} ./run-tck-rawhide.sh
```

The variable `needs.wildfly-build.outputs.wildfly-version` is produced by the `wildfly/wildfly/.github/workflows/shared-wildfly-build.yml`.


