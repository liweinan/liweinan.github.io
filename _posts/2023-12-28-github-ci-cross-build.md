---
title: Github CI Cross Repo Build
---

I have created a demo project showing the usage of the cross repo build of Github CI:

- [https://github.com/liweinan/cross-repo-ci-build](https://github.com/liweinan/cross-repo-ci-build)

In its [workflow file](https://github.com/liweinan/cross-repo-ci-build/blob/main/.github/workflows/maven.yml), it contains the job like this:

```yaml
jobs:
  wildfly-build:
    uses: wildfly/wildfly/.github/workflows/shared-wildfly-build.yml@main
    with:
      wildfly-branch: "main"
      wildfly-repo: "wildfly/wildfly"
```

It will refer to the build file in:

- [https://github.com/wildfly/wildfly/blob/main/.github/workflows/shared-wildfly-build.yml](https://github.com/wildfly/wildfly/blob/main/.github/workflows/shared-wildfly-build.yml)

The above build process can produce a `wildfly-maven-repository.tar.gz` file:

```yaml
- name: Archive the repository
  run:  |
    cd ~
    find ./.m2/repository -type d -name "*SNAPSHOT" -print0 | xargs -0 tar -czf ~/wildfly-maven-repository.tar.gz
- uses: actions/upload-artifact@v4
  with:
    name: wildfly-maven-repository
    path: ~/wildfly-maven-repository.tar.gz
    retention-days: 5
```

The build process of the WildFly repo will stay in the demo project side, and here is the build process:

- [merge workflow file · liweinan/cross-repo-ci-build@ab3dcfc](https://github.com/liweinan/cross-repo-ci-build/actions/runs/7349453968/job/20009407868)

And in the demo project `build` job it needs the output of the `wildfly-build` job, which is `wildfly-maven-repository.tar.gz`, and then it will download and extract the `tar.gz` file:  

```yaml
build:
  runs-on: ubuntu-latest
  needs: wildfly-build
  steps:
    - uses: actions/checkout@v4
    - uses: actions/download-artifact@v4
      with:
        name: wildfly-maven-repository
        path: .
    - name: Extract Maven Repo
      shell: bash
      run: tar -xzf wildfly-maven-repository.tar.gz -C ~
```

You can see more usages of the feature here:

- [https://github.com/resteasy/resteasy/blob/main/.github/workflows/wildfly-build.yml](https://github.com/resteasy/resteasy/blob/main/.github/workflows/wildfly-build.yml)

Note: It needs `download-artifact` to be upgraded into `v4`:

- [https://github.com/liweinan/cross-repo-ci-build/commit/937518fe864edf9b0889a6e64e55a3fff9301381](https://github.com/liweinan/cross-repo-ci-build/commit/937518fe864edf9b0889a6e64e55a3fff9301381)



