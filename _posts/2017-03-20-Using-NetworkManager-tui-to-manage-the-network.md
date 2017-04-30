---
title: Using NetworkManager-tui To Manage The Network From Text User Interface
abstract: Sometimes it's more convenient to manage the network from text user interface. In this article I'd like to share a curses-based tool named NetworkManager-tui.
---

{{ page.abstract }}

This package is provided by Fedora Linux[^fedora] distributions, and I'm using Fedora Version 24 in my local machine, so I can check it with the `dnf` command. Here is the info of this package:

[^fedora]: [https://getfedora.org.](https://getfedora.org/)

```
$ dnf info NetworkManager-tui
Name        : NetworkManager-tui
Arch        : x86_64
Epoch       : 1
Version     : 1.2.6
Release     : 1.fc24
Size        : 197 k
Repo        : updates
Summary     : NetworkManager curses-based UI
URL         : http://www.gnome.org/projects/NetworkManager/
License     : GPLv2+
Description : This adds a curses-based "TUI" (Text User Interface) to
            : NetworkManager, to allow performing some of the operations supported
            : by nm-connection-editor and nm-applet in a non-graphical environment.
```

And we can use `dnf` command to download and install it:

```
$ sudo dnf install NetworkManager-tui
```

The above command will install the `NetworkManager-tui` and its dependencies. After the packages are installed, we can use the `nmtui` command to open the manager in the text interface like this:

![2017-03-20-016.png]({{ site.url }}/assets/2017-03-20-016.png)

From the above screenshot, we can see the manager supports us to edit the connections, or to open or close a connection. We can select the `Activate a connection` in the menu, and then we will enter this page:

![2017-03-20-019.png]({{ site.url }}/assets/2017-03-20-019.png)

As the screenshot shown above, it entered into the connection selection page. I selected my VPN connection and hit enter, then it asked me to enter my password to VPN:

![2017-03-20-017.png]({{ site.url }}/assets/2017-03-20-017.png)

After I entered my password, the connection is activated like this:

![2017-03-20-020.png]({{ site.url }}/assets/2017-03-20-020.png)

From the above screenshot, we can see there is a `*` before the activated connection to show its active status. Until now, we have seen the basic usages of `nmtui` tool. Actually this curses-based[^curses] tool is a wrapper of a command line tool called `nmcli`. All your operations in `nmtui` interface will be converted to the command calls to `nmcli`. For example, here is the command to show all the active connections by using `nmcli` command:

```
$ nmcli connection show --active
NAME                    UUID                                  TYPE            DEVICE  
Beijing PEK2 (OpenVPN)  13bdb983-e5b4-4951-9e69-7ba42d6edc49  vpn             enp0s5  
docker0                 969fc191-391e-42a1-aa70-34b6199a8fbd  bridge          docker0
enp0s5                  417ac8e9-b2de-3466-bc5e-5bdcb76c0b87  802-3-ethernet  enp0s5  
tun0                    cc15051d-83ad-4f72-9142-ddf51fc80087  tun             tun0
```

I won't explain much about the usage of `nmcli` in this article. If you need to manage the network via command line, please check the Fedora document for `nmcli`[^nmcli].

[^curses]: [https://en.wikipedia.org.](https://en.wikipedia.org/wiki/Curses_(programming_library))

[^nmcli]:[https://fedoraproject.org.](https://fedoraproject.org/wiki/Networking/CLI)

### _References_

---
