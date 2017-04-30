---
title: Write An Apache HTTPD Module
abstract: In this article I'd like to show you how to write a module for Apache HTTPD.
---

{{ page.abstract }}

I'm using _Fedora Linux_, So I can use the _httpd_ and _httpd-devel_ provided by system:

![img]({{ site.url }}/assets/httpd_module_01.jpg)

The reason to install _httpd-devel_ is that we need the header files relative to module development provided by it[^1]. Now let's write a simple module:

```c
// foo_module.c
#include <stdio.h>
#include "apr_hash.h"
#include "ap_config.h"
#include "ap_provider.h"
#include "httpd.h"
#include "http_core.h"
#include "http_config.h"
#include "http_log.h"
#include "http_protocol.h"
#include "http_request.h"

static int foo_handler(request_rec *r) {
  if (!r->handler || strcmp(r->handler, "foo_handler")) return (DECLINED);

  ap_set_content_type(r, "text/html");
  ap_rprintf(r, "Hello, martian!");

  return OK;
}

static void foo_hooks(apr_pool_t *pool) {
  ap_hook_handler(foo_handler, NULL, NULL, APR_HOOK_MIDDLE);
}

module AP_MODULE_DECLARE_DATA foo_module = {
  STANDARD20_MODULE_STUFF,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  foo_hooks
};
```

This module will use `AP_MODULE_DECLARE_DATA` to register a `foo_module`：

```c
module AP_MODULE_DECLARE_DATA foo_module = ...
```

And it will use `foo_hooks` to call `ap_hook_handler`, and `ap_hook_handler` will load our `foo_handler` into _httpd_：

```c
static void foo_hooks(apr_pool_t *pool) {
  ap_hook_handler(foo_handler, NULL, NULL, APR_HOOK_MIDDLE);
}
```

Our main function `foo_handler` is very simple. You can see it doesn't deal with `request_rec`. It will just output some HTML data：

```c
ap_set_content_type(r, "text/html");
ap_rprintf(r, "Hello, martian!");
```

As we have understood the meaning of this simple module, now we can compile it. _Apache HTTPD_ has provided a module compiling and installing tool for us called `apxs`:

![img]({{ site.url }}/assets/httpd_module_02.jpg)

We can use it to compile our `foo_module`:

![img]({{ site.url }}/assets/httpd_module_03.jpg)

As the snapshot shown above，we have used `apxs` to compile _foo_module.c_:

```
$ apxs -a -c foo_module.c
```

The output of compling process is like this:

```
/usr/lib64/apr-1/build/libtool --silent --mode=compile gcc -prefer-pic -O2 -g -pipe -Wall -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -specs=/usr/lib/rpm/redhat/redhat-hardened-cc1 -m64 -mtune=generic  -DLINUX -D_REENTRANT -D_GNU_SOURCE -pthread -I/usr/include/httpd  -I/usr/include/apr-1   -I/usr/include/apr-1   -c -o foo_module.lo foo_module.c && touch foo_module.slo
/usr/lib64/apr-1/build/libtool --silent --mode=link gcc -Wl,-z,relro,-z,now   -o foo_module.la  -rpath /usr/lib64/httpd/modules -module -avoid-version    foo_module.lo
```

As the output shown above, we can see `apxs` used _libtool_ to compile our module, and generated many files:

```
$ ls
foo_module.c  foo_module.la  foo_module.lo  foo_module.o  foo_module.slo
```

There are also generated files in _.libs_ directory：

```
$ ls -l ./.libs/
total 104
-rw-rw-r--. 1 weli weli 35580 Jan 27 02:55 foo_module.a
lrwxrwxrwx. 1 weli weli    16 Jan 27 02:55 foo_module.la -> ../foo_module.la
-rw-rw-r--. 1 weli weli   938 Jan 27 02:55 foo_module.lai
-rw-rw-r--. 1 weli weli 35432 Jan 27 02:55 foo_module.o
-rwxrwxr-x. 1 weli weli 25560 Jan 27 02:55 foo_module.so
```

Most of the files on above are intermediate libraries genereated during compile process, what we care is the shared library, which is _.so_ file. This is the module file that can be loaded by Apache HTTPD.

Nevertheless, we don't have to install the module manually, we can also use the `apxs` utility to install it to default _httpd_ installation location. Here is the command to install the module:


```
$ sudo apxs -i foo_module.la
```

Please note we have used `sudo` to invoke `apxs`, because the module will be installed to system provided _httpd_, and its directories need root permission to modify. In addition, the `foo_module.la` is a _libtool_ description file that describes the libraries it generated, and it is a pure text file if you'd like to check. Here is the output of above command:

```
/usr/lib64/httpd/build/instdso.sh SH_LIBTOOL='/usr/lib64/apr-1/build/libtool' foo_module.la /usr/lib64/httpd/modules
/usr/lib64/apr-1/build/libtool --mode=install install foo_module.la /usr/lib64/httpd/modules/
libtool: install: install .libs/foo_module.so /usr/lib64/httpd/modules/foo_module.so
libtool: install: install .libs/foo_module.lai /usr/lib64/httpd/modules/foo_module.la
libtool: install: install .libs/foo_module.a /usr/lib64/httpd/modules/foo_module.a
libtool: install: chmod 644 /usr/lib64/httpd/modules/foo_module.a
libtool: install: ranlib /usr/lib64/httpd/modules/foo_module.a
libtool: finish: PATH="/sbin:/bin:/usr/sbin:/usr/bin:/sbin" ldconfig -n /usr/lib64/httpd/modules
----------------------------------------------------------------------
Libraries have been installed in:
   /usr/lib64/httpd/modules

If you ever happen to want to link against installed libraries
in a given directory, LIBDIR, you must either use libtool, and
specify the full pathname of the library, or use the '-LLIBDIR'
flag during linking and do at least one of the following:
   - add LIBDIR to the 'LD_LIBRARY_PATH' environment variable
     during execution
   - add LIBDIR to the 'LD_RUN_PATH' environment variable
     during linking
   - use the '-Wl,-rpath -Wl,LIBDIR' linker flag
   - have your system administrator add LIBDIR to '/etc/ld.so.conf'

See any operating system documentation about shared libraries for
more information, such as the ld(1) and ld.so(8) manual pages.
----------------------------------------------------------------------
chmod 755 /usr/lib64/httpd/modules/foo_module.so
```

The important line is at the bottom of above log, from which we can see _foo_module.so_ is installed to the default installation location of Fedora Linux provided _httpd_.

The above `apxs` command will just install the _.so_ file into httpd module directory, but it won't load it in _httpd_ config file for you. If you'd like to activate your module by adding it into _httpd_ config file, you can use the following command:

```
$ sudo apxs -ia foo_module.la
```

And this time there is an additional line in the output:

```
chmod 755 /usr/lib64/httpd/modules/foo_module.so
[activating module 'foo' in /etc/httpd/conf/httpd.conf]
```

As the log shown above, we can see `foo` module is added into `/etc/httpd/conf/httpd.conf`, and we can check it:

```conf
$ grep foo /etc/httpd/conf/httpd.conf
# LoadModule foo_module modules/mod_foo.so
LoadModule foo_module         /usr/lib64/httpd/modules/foo_module.so
```

Now we should configure the module in httpd. From the source code of the module we saw:

```c
static int foo_handler(request_rec *r) {
  if (!r->handler || strcmp(r->handler, "foo_handler")) return (DECLINED);
  ap_set_content_type(r, "text/html");
  ap_rprintf(r, "Hello, martian!");
```

So if the handler name is set to `foo_handler`, it will accept the request and return a simple text to the client. We can add following lines into `httpd.conf`:

```
<Location /foo>
SetHandler foo_handler
</Location>
```

With the above configuraton, we set the `foo_handler` to serve the location `/foo`, and our module will be used to deal with this location. Now we can start the httpd server:

```
$ sudo service httpd start
Redirecting to /bin/systemctl start  httpd.service
```

If the service started correctly, we can see from the log like this:

```
$ systemctl status httpd.service
● httpd.service - The Apache HTTP Server
   Loaded: loaded (/usr/lib/systemd/system/httpd.service; disabled; vendor preset: disabled)
   Active: active (running) since Thu 2017-04-13 18:04:46 CST; 20s ago
 Main PID: 16184 (httpd)
   Status: "Total requests: 0; Idle/Busy workers 100/0;Requests/sec: 0; Bytes served/sec:   0 B/sec"
    Tasks: 32 (limit: 512)
   Memory: 3.9M
      CPU: 133ms
   CGroup: /system.slice/httpd.service
           ├─16184 /usr/sbin/httpd -DFOREGROUND
           ├─16211 /usr/sbin/httpd -DFOREGROUND
           ├─16212 /usr/sbin/httpd -DFOREGROUND
           ├─16213 /usr/sbin/httpd -DFOREGROUND
           ├─16214 /usr/sbin/httpd -DFOREGROUND
           └─16215 /usr/sbin/httpd -DFOREGROUND

Apr 13 18:04:37 fedora.shared systemd[1]: Starting The Apache HTTP Server...
Apr 13 18:04:46 fedora.shared systemd[1]: Started The Apache HTTP Server.
```

Now we can access the location `/foo` to see if our module works properly:

```
$  curl http://localhost/foo
Hello, martian!
```

As the command output shown above, our module works as expected.

### _References_

---

[^1]: Kew, Nick. The Apache modules book: application development with Apache. Prentice Hall Professional, 2007.
