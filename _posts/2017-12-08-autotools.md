---
title: 使用Autotools编译项目（上）
abstract: 这是一篇旧文，未来会不断把之前写过的文章放到这个博客里面。
---



{{ page.abstract }}

首先创建工作目录：

```bash
mkdir try-autotools
```

然后进入工作目录，创建helloworld.c：

```c
int main() {
  printf("Hello, world!");
}
```

然后，输入下面的命令：

```bash
% autoscan
```

获得configure.scan：

```bash
% ls
autoscan.log   configure.scan helloworld.c
```

然后将configure.scan重命名为configure.in：

```bash
% mv configure.scan configure.in
```

接下来执行aclocal：

```bash
% aclocal
```

执行结束后系统多出个autom4te.cache目录：

```bash
%  ls
autom4te.cache autoscan.log   configure.in   helloworld.c
```

此时执行autoheader：

```bash
% autoheader
```

生成config.h.in：

```bash
% ls
autom4te.cache config.h.in    configure.in
autoscan.log   configure      helloworld.c
```

创建Makefile.am，内容如下：

```bash
bin_PROGRAMS=helloworld
helloworld_SOURCES=helloworld.c
```

接下来打开configure.in，在AC_INIT后面添加：

```bash
AM_INIT_AUTOMAKE
AC_CONFIG_FILES([Makefile])
```

保存后退出。接下来使用touch命令创建如下文件：

```bash
% touch AUTHORS ChangeLog INSTALL NEWS README
```

然后执行：

```bash
% automake -a
```

会有一些告警日志，不管它。此时执行autoreconf，下面是执行结果及日志：

```bash
% autoreconf -vfi
autoreconf: Entering directory `.'
autoreconf: configure.in: not using Gettext
autoreconf: running: aclocal --force
autoreconf: configure.in: tracing
autoreconf: configure.in: not using Libtool
autoreconf: running: /usr/bin/autoconf --force
autoreconf: running: /usr/bin/autoheader --force
autoreconf: running: automake --add-missing --copy --force-missing
configure.in:6: installing `./missing'
configure.in:6: installing `./install-sh'
autoreconf: Leaving directory `.'
```

此时目录中内容如下：

```bash
% ls
AUTHORS        Makefile.am    aclocal.m4     config.h.in~   helloworld.c
COPYING        Makefile.in    autom4te.cache configure      install-sh
ChangeLog      NEWS           autoscan.log   configure.in   missing
INSTALL        README         config.h.in    depcomp
```

工作基本到此结束了。我们现在可以使用生成好的configure命令试试看：

```bash
% ./configure
```

可以看到目录中生成了Makefile，执行make：

```bash
% make
make  all-am
gcc -DHAVE_CONFIG_H -I.     -g -O2 -MT helloworld.o -MD -MP -MF .deps/helloworld.Tpo -c -o helloworld.o helloworld.c
helloworld.c: In function 'main':
helloworld.c:2: warning: incompatible implicit declaration of built-in function 'printf'
mv -f .deps/helloworld.Tpo .deps/helloworld.Po
gcc  -g -O2   -o helloworld helloworld.o  
```

此时helloworld已经被编译了：

```bash
% ./helloworld
Hello, world!
```

最后我们清除中间文件：

```bash
% make distclean
```

再删除autom4te的cache：

```bash
% rm -rf autom4te.cache
```

就得到了干净的工程目录：

```bash
% ls
AUTHORS      INSTALL      NEWS         config.h.in  depcomp      missing
COPYING      Makefile.am  README       configure    helloworld.c
ChangeLog    Makefile.in  aclocal.m4   configure.in install-sh
```

将目录打包，就可以进行软件分发了。
