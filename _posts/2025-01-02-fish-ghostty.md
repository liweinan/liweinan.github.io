---
title: Fix the config of fish shell when using ghostty
---

I’m using fish shell[^fish_shell] and ghostty[^ghostty]  together. If I use the `ssh` command to connect to a remote machine, I got this warning:

```bash
weli@mini ~
❯ ssh weli@192.168.0.113
(weli@192.168.0.113) Password:
Last login: Fri Jan  3 01:25:29 2025 from fe80::18ee:f404:c997:b86d%en0
warning: Could not set up terminal.
warning: TERM environment variable set to 'xterm-ghostty'.
warning: Check that this terminal type is supported on this system.
warning: Using fallback terminal type 'xterm-256color'.
Welcome to fish, the friendly interactive shell
Type help for instructions on how to use fish
weli@arm13 ~
❯
```

To make things worse, the above warning will cause the `scp` command to fail:

```bash
❯ scp foo.txt weli@192.168.0.113:~/
(weli@192.168.0.113) Password:
scp: Received message too long 1500476704
scp: Ensure the remote shell produces no output for non-interactive sessions.
```

To fix this problem, I added this line into `~/.config/fish/config.fish`:

```
set TERM xterm-256color
```

After the above config is added, then the warnings when connecting to remote machine disappeared.

[^fish_shell]: [fish shell](https://fishshell.com/)

[^ghostty]: [ghostty-org/ghostty: 👻 Ghostty is a fast, feature-rich, and cross-platform terminal emulator that uses platform-native UI and GPU acceleration.](https://github.com/ghostty-org/ghostty)