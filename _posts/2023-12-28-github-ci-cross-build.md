---
title: Github CI Cross Repo Build
---

I have created a demo project showing the usage of the cross repo build of Github CI:

- https://github.com/liweinan/cross-repo-ci-build

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

- https://github.com/wildfly/wildfly/blob/main/.github/workflows/shared-wildfly-build.yml

The build process of the WildFly repo will stay in the demo project side, and here is the build process:

- [merge workflow file · liweinan/cross-repo-ci-build@ab3dcfc](https://github.com/liweinan/cross-repo-ci-build/actions/runs/7349453968/job/20009407868)

You can see more usages of the feature here:

- [https://github.com/resteasy/resteasy/blob/main/.github/workflows/wildfly-build.yml](https://github.com/resteasy/resteasy/blob/main/.github/workflows/wildfly-build.yml)





