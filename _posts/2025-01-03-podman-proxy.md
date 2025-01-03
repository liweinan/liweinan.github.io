---
title: Override the proxy setting of podman in MacOS
---

I tried to use podman on MacOS so I installed it by using the `brew` command:

```bash
$ brew install podman
```

After `podman` is installed, I tried to init the podman machine:

```bash
❯ podman machine init
Looking up Podman Machine image at quay.io/podman/machine-os:5.3 to create VM
Getting image source signatures
Copying blob 047caa9c4100 done   |
Copying config 44136fa355 done   |
Writing manifest to image destination
047caa9c410038075055e1e41d520fc975a09797838541174fa3066e58ebd8ea
Extracting compressed file: podman-machine-default-amd64.raw: done
Machine init complete
To start your machine run:

        podman machine start
```

After podman machine is initialized, I start the podman machine by running the following command:

```bash
❯ podman machine start
Starting machine "podman-machine-default"

This machine is currently configured in rootless mode. If your containers
require root permissions (e.g. ports < 1024), or if you run into compatibility
issues with non-podman clients, you can switch using the following command:

        podman machine set --rootful

API forwarding listening on: /var/folders/0m/csp222ks3g17w_2qqrcw8ktm0000gn/T/podman/podman-machine-default-api.sock

The system helper service is not installed; the default Docker API socket
address can't be used by podman. If you would like to install it, run the following commands:

        sudo /usr/local/Cellar/podman/5.3.1/bin/podman-mac-helper install
        podman machine stop; podman machine start

You can still connect Docker API clients by setting DOCKER_HOST using the
following command in your terminal session:

        export DOCKER_HOST='unix:///var/folders/0m/csp222ks3g17w_2qqrcw8ktm0000gn/T/podman/podman-machine-default-api.sock'

Machine "podman-machine-default" started successfully
```

As podman machine is started, I tried to run an Alpine Linux container:

```bash
❯ podman run -it alpine sh
Resolved "alpine" as an alias (/etc/containers/registries.conf.d/000-shortnames.conf)
Trying to pull docker.io/library/alpine:latest...
Error: initializing source docker://alpine:latest: pinging container registry registry-1.docker.io: Get "https://registry-1.docker.io/v2/": EOF
```

It seems the `podman` has network connection problem. I tried to configure `http_proxy` and `https_proxy` properties in my shell environment, however it has no effect in my local environment. So I installed the `podman-desktop` in my local environment:

```bash
❯ brew install podman-desktop
==> Downloading https://github.com/containers/podman-desktop/releases/download/v1.15.0/podman-desktop-1.15.0-x64
==> Downloading from https://objects.githubusercontent.com/github-production-release-asset-2e65be/465844859/27f9
######################################################################################################### 100.0%
==> Installing Cask podman-desktop
==> Moving App 'Podman Desktop.app' to '/Applications/Podman Desktop.app'
🍺  podman-desktop was successfully installed!
```

After `podman-desktop` is installed, I opened the application and it has proxy setting page for `podman`:

![](https://raw.githubusercontent.com/liweinan/blogpics2025/main/0103/01.png)

So I used the `manual` proxy setting and configured my proxy address in this page and then clicked the `Update` button:

![](https://raw.githubusercontent.com/liweinan/blogpics2025/main/0103/02.png)

And the proxy settings is updated:

![](https://raw.githubusercontent.com/liweinan/blogpics2025/main/0103/03.png)

> Note: The setting is actually updated in the file `~/.config/containers/containers.conf`.

After the configuration is updated, I restart the podman machine by using the function provided the `podman-desktop`:

![](https://raw.githubusercontent.com/liweinan/blogpics2025/main/0103/04.png)

Or you can use the `podman` command to stop the machine and then start it:

```bash
$ podman machine stop
Machine "podman-machine-default" stopped successfully
```

```bash
$ podman machine start
...
Machine "podman-machine-default" started successfully
```

After the machine is restarted, I tried to run the container again:

```bash
❯ podman run -it alpine sh
Resolved "alpine" as an alias (/etc/containers/registries.conf.d/000-shortnames.conf)
Trying to pull docker.io/library/alpine:latest...
Getting image source signatures
Copying blob sha256:38a8310d387e375e0ec6fabe047a9149e8eb214073db9f461fee6251fd936a75
Copying config sha256:4048db5d36726e313ab8f7ffccf2362a34cba69e4cdd49119713483a68641fce
Writing manifest to image destination
/ #
```

And this time the image can be pulled correctly.

