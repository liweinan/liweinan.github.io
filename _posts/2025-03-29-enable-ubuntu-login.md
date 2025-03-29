---
title: Enable SSH login on Ubuntu
---

![](https://raw.githubusercontent.com/liweinan/blogpics2025/main/0329/01.jpg)

I followed DeepSeek’s instruction to enable SSH login on Ubuntu:

- [Enable SSH login on Ubuntu](https://github.com/liweinan/deepseek-answers/blob/main/enable-ssh-login-in-ubuntu.md)

There are several notes about the SSH daemon configuration on Ubuntu. Firstly, better to disable the `ufw` firewall for testing environment. In addition, better to disable the `gcr-ssh-agent` like this:

- [What is gcr-ssh-agent?](https://github.com/liweinan/deepseek-answers/blob/main/what-is-gcr-ssh-agent.md)

And if I need to debug the `sshd`, here is the reference:

- [How to Run sshd in Debug Mode](https://github.com/liweinan/deepseek-answers/blob/main/ssh-in-debug-mode.md)

Most importantly, the configurations are required in `/etc/ssh/sshd_config`:

```
PubkeyAuthentication yes
AllowUsers anan
```

Some more troubleshooting info:

- [What Does "receive packet: type 51" Mean in SSH?](https://github.com/liweinan/deepseek-answers/blob/main/what-does-type-51-mean-in-ssh.md)
- [How to Fix "Missing Privilege Separation Directory: /run/sshd" Error in SSH](https://github.com/liweinan/deepseek-answers/blob/main/fix-ssd-dir-error.md)
- [Disable SELinux On Ubuntu](https://github.com/liweinan/deepseek-answers/blob/main/disable-selinux.md)