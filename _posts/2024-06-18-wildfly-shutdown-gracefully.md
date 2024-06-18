---
title: Restart the WildFly server gracefully
---

To restart the WildFly server gracefully, use the following CLI command:

```bash
[standalone@localhost:9990 /] :shutdown(timeout=10, restart=true)
{
    "outcome" => "success",
    "result" => undefined
}
```

Here is the screenshot of the server log output:

![](https://raw.githubusercontent.com/liweinan/blogpics2024/main/0618/01.png)

Fomr the above screenshot we can see how the server is shutdown graceully and restarted by the CLI command.