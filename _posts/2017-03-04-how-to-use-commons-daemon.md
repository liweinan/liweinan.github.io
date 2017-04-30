---
title: How To Use Apache Commons Daemon
abstract: Apache Commons Daemon is a tool provided by Apache community which can help you to manage your Java application as a standard system daemon. In this article I'd like to show you the basic usage of it.
---

{{ page.abstract }}

The Apache Commons Daemon consists of two parts: One part is written in Java called `commons-daemon`, the other part is called `jsvc` which is written in C.

The `commons-daemon` part gives you some Java interfaces that you should follow to wrap your server program. The most important interface you need to implement is `Daemon.java`:

```java
public interface Daemon
{

    /**
     * Initializes this <code>Daemon</code> instance.
     * <p>
     *   This method gets called once the JVM process is created and the
     *   <code>Daemon</code> instance is created thru its empty public
     *   constructor.
     * </p>
     * <p>
     *   Under certain operating systems (typically Unix based operating
     *   systems) and if the native invocation framework is configured to do
     *   so, this method might be called with <i>super-user</i> privileges.
     * </p>
     * <p>
     *   For example, it might be wise to create <code>ServerSocket</code>
     *   instances within the scope of this method, and perform all operations
     *   requiring <i>super-user</i> privileges in the underlying operating
     *   system.
     * </p>
     * <p>
     *   Apart from set up and allocation of native resources, this method
     *   must not start the actual operation of the <code>Daemon</code> (such
     *   as starting threads calling the <code>ServerSocket.accept()</code>
     *   method) as this would impose some serious security hazards. The
     *   start of operation must be performed in the <code>start()</code>
     *   method.
     * </p>
     *
     * @param context A <code>DaemonContext</code> object used to
     * communicate with the container.
     * @exception DaemonInitException An exception that prevented
     * initialization where you want to display a nice message to the user,
     * rather than a stack trace.
     * @exception Exception Any exception preventing a successful
     *                      initialization.
     */
    public void init(DaemonContext context)
        throws DaemonInitException, Exception;

    /**
     * Starts the operation of this <code>Daemon</code> instance. This
     * method is to be invoked by the environment after the init()
     * method has been successfully invoked and possibly the security
     * level of the JVM has been dropped. Implementors of this
     * method are free to start any number of threads, but need to
     * return control after having done that to enable invocation of
     * the stop()-method.
     */
    public void start()
        throws Exception;

    /**
     * Stops the operation of this <code>Daemon</code> instance. Note
     * that the proper place to free any allocated resources such as
     * sockets or file descriptors is in the destroy method, as the
     * container may restart the Daemon by calling start() after
     * stop().
     */
    public void stop()
        throws Exception;

    /**
     * Frees any resources allocated by this daemon such as file
     * descriptors or sockets. This method gets called by the container
     * after stop() has been called, before the JVM exits. The Daemon
     * can not be restarted after this method has been called without a
     * new call to the init() method.
     */
    public void destroy();
}
```

From the above interface we can see there are several methods related with a server cycle you should implement. How does `commons-daemon` uses the above interface to manage your Java application? The answers lies in `jsvc` part. `jsvc` is written in C, and it provides you three processes[^1], which are called the `Launcher Process`, the `Controller Process`, and the `Controlled Process`.

[^1]: [Jsvc](https://commons.apache.org/proper/commons-daemon/jsvc.html)

The purpose of the launcher process is very straight-forward, which will launch a child process. The child process will be a Java instance and it's called the `controller process`.

The controller process will start JVM and start your Java application by properly calling the `init` and `start` methods defined in above interface. Then it will wait for standard Linux/UNIX process signals. So afterthen you can send standard Linux/UNIX signals to stop your Java application, and this process will call `stop` and `destroy` methods according to the signal you send to this process.

The started Java application process is called the `controlled process`, it's your Java application that is running. This process is downgraded to normal user privileges by using system capabilities like `setuid` and `setgid` or so.

How can `jsvc` start JVM? It uses `JNI` to interact with Java Virtual Machine. The fullname of `JNI` is called `Java Native Interface`[^2], and it is a stanard framework to enables Java code running in a Java Virtual Machine (JVM) to call and be called by native applications. You don't have to understand the details of `jsvc`, but if you are interested in the implementation, you can see the usage of `JNI_CreateJavaVM()` method provided by Java in `jsvc` source code as a start point to learn about `jsvc`. In general, the purpose of the `jsvc` is to manage the lifecycle of your Java application by interacting with `Daemon` interface on Java side, and you get the ability to start/stop your Java application by using standard system signals scheme.

[^2]: [Java Native Interface](https://en.wikipedia.org/wiki/Java_Native_Interface)

Now let's start to learn how to use `commons-daemon` and `jsvc` to manage the lifecycle of our Java application. There is an article that roughly describes the steps to integrate your Java application with `commons-daemon`[^3] you can check. In this article I'll provide a more detailed explaination.

[^3]: [How to convert a java program to daemon with jsvc?](http://stackoverflow.com/questions/7687159/how-to-convert-a-java-program-to-daemon-with-jsvc)

### Integrate your Java application with commons-daemon

Firstly, write a Java class that implements the `Daemon` interface:

```java
import org.apache.commons.daemon.Daemon;
import org.apache.commons.daemon.DaemonContext;

public class MyDaemon implements Daemon {

    @Override
    public void init(DaemonContext context) throws Exception {
        System.out.println("MyDaemon init...");
    }

    @Override
    public void start() throws Exception {
        System.out.println("MyDaemon start...");
    }

    @Override
    public void stop() throws Exception {
        System.out.println("MyDaemon stop...");
    }

    @Override
    public void destroy() {
        System.out.println("MyDaemon destroy...");
    }
}
```

From the above code, we can see the Daemon interfaces defines four methods that controls you application cycle, which are `init`, `start`, `stop` and `destroy`. And `jsvc` will call these methods to start/stop your application properly. So it's your responsibility to implement the above methods properly.

Then we need to compile our Java project properly. I have put above `MyDaemon` into a Gradle project[^4], so you can directly check it out and build a jar from it. You can go to the directory of the project, and then run `./gradlew fatJar`. It will download the `gradle` and build the project for you.

[^4]: [DaemonDemo](https://github.com/liweinan/jboss-webserver-and-eap-high-availability/tree/master/DaemonDemo)

After building it successfully, you can get the jar `build/libs/DaemonDemo-all-1.0.jar`. This jar contains the above `MyDaemon` class, and `commons-daemon` jar as dependency.

For the next step, we need to install `jsvc` into our system. I use `Fedora Linux`, so I use `dnf` command to install the package provided by default:

```bash
apache-commons-daemon-jsvc.x86_64 : Java daemon launcher
```

After installing it, we can see the files provided by above package:

```bash
$ rpm -ql apache-commons-daemon-jsvc-1.0.15-10.fc23.x86_64
/usr/bin/jsvc
/usr/share/doc/apache-commons-daemon-jsvc
/usr/share/doc/apache-commons-daemon-jsvc/LICENSE.txt
/usr/share/doc/apache-commons-daemon-jsvc/NOTICE.txt
/usr/share/man/man1/jsvc.1.gz
```

As the file list shown above, the core file provided by the package is the binary file  `/usr/bin/jsvc`. We will use this `jsvc` to start our `MyDaemon`.

Before starting `jsvc`, we need to make sure the Java side, `apache-commons-daemon`, is installed. You can download the jar from the Apache commons website directly[^5]. I will use the one provided by Fedora directly:

[^5]: [Download Commons Daemon](http://commons.apache.org/proper/commons-daemon/download_daemon.cgi)

```bash
apache-commons-daemon.noarch : Defines API to support an alternative invocation mechanism
```

The above package will provide the commons-daemon jar:

```bash
[weli@localhost projs]$ rpm -ql apache-commons-daemon-1.0.15-1.redhat_1.ep6.el6.noarch
/usr/share/java/apache-commons-daemon-1.0.15-redhat-1.jar
/usr/share/java/apache-commons-daemon.jar
/usr/share/java/commons-daemon-1.0.15-redhat-1.jar
/usr/share/java/commons-daemon.jar
/usr/share/java/jakarta-commons-daemon-1.0.15-redhat-1.jar
/usr/share/java/jakarta-commons-daemon.jar
```

Above jars are acutally the same, most of them are symbolic links to the same actual jar file, so referring to anyone is the same. Now I can use `jsvc` and `commons-daemon.jar` to start our `MyDaemon`. The command is like the following:

```bash
$ sudo /usr/bin/jsvc \
-debug \
-nodetach \
-cp /home/weli/projs/jboss-webserver-and-eap-high-availability/DaemonDemo/build/libs:/usr/share/java/commons-daemon-1.0.15-redhat-1.jar MyDaemon
```

As the command shown above, we have used `nodetach` option to make the program a daemon, and we use `cp` option to tell `jsvc` to find our jar and `commons-daemon` jar. Finally we have told `jsvc` our class that implements the `Daemon` interface. Because we have used `debug` option, so the output of above command is very long. Here is the whole output:

```bash
+-- DUMPING PARSED COMMAND LINE ARGUMENTS --------------
| Detach:          False
| Show Version:    No
| Show Help:       No
| Check Only:      Disabled
| Stop:            False
| Wait:            0
| Run as service:  No
| Install service: No
| Remove service:  No
| JVM Name:        "null"
| Java Home:       "null"
| PID File:        "/var/run/jsvc.pid"
| User Name:       "null"
| Extra Options:   1
|   "-Djava.class.path=/home/weli/projs/jboss-webserver-and-eap-high-availability/DaemonDemo/build/libs:/usr/share/java/commons-daemon-1.0.15-redhat-1.jar"
| Class Invoked:   "MyDaemon"
| Class Arguments: 0
+-------------------------------------------------------
Home not specified on command line, using environment
Home not on command line or in environment, searching
Attempting to locate Java Home in /usr/java/default
Path /usr/java/default is not a directory
Attempting to locate Java Home in /usr/java
Path /usr/java is not a directory
Attempting to locate Java Home in /usr/local/java
Path /usr/local/java is not a directory
Attempting to locate Java Home in /usr/lib/jvm/default-java
Path /usr/lib/jvm/default-java is not a directory
Attempting to locate Java Home in /usr/lib/jvm/java
Attempting to locate VM configuration file /usr/lib/jvm/java/jre/lib/jvm.cfg
Attempting to locate VM configuration file /usr/lib/jvm/java/lib/jvm.cfg
Attempting to locate VM configuration file /usr/lib/jvm/java/jre/lib/amd64/jvm.cfg
Found VM configuration file at /usr/lib/jvm/java/jre/lib/amd64/jvm.cfg
Found VM server definition in configuration
Checking library /usr/lib/jvm/java/jre/lib/amd64/server/libjvm.so
Found VM client definition in configuration
Checking library /usr/lib/jvm/java/jre/lib/amd64/client/libjvm.so
Checking library /usr/lib/jvm/java/lib/amd64/client/libjvm.so
Cannot locate library for VM client (skipping)
Java Home located in /usr/lib/jvm/java
+-- DUMPING JAVA HOME STRUCTURE ------------------------
| Java Home:       "/usr/lib/jvm/java"
| Java VM Config.: "/usr/lib/jvm/java/jre/lib/amd64/jvm.cfg"
| Found JVMs:      1
| JVM Name:        "server"
|                  "/usr/lib/jvm/java/jre/lib/amd64/server/libjvm.so"
+-------------------------------------------------------
Using default JVM in /usr/lib/jvm/java/jre/lib/amd64/server/libjvm.so
Invoking w/ LD_LIBRARY_PATH=/usr/lib/jvm/java/jre/lib/amd64/server:/usr/lib/jvm/java/jre/lib/amd64
+-- DUMPING PARSED COMMAND LINE ARGUMENTS --------------
| Detach:          False
| Show Version:    No
| Show Help:       No
| Check Only:      Disabled
| Stop:            False
| Wait:            0
| Run as service:  No
| Install service: No
| Remove service:  No
| JVM Name:        "null"
| Java Home:       "null"
| PID File:        "/var/run/jsvc.pid"
| User Name:       "null"
| Extra Options:   1
|   "-Djava.class.path=/home/weli/projs/jboss-webserver-and-eap-high-availability/DaemonDemo/build/libs:/usr/share/java/commons-daemon-1.0.15-redhat-1.jar"
| Class Invoked:   "MyDaemon"
| Class Arguments: 0
+-------------------------------------------------------
Home not specified on command line, using environment
Home not on command line or in environment, searching
Attempting to locate Java Home in /usr/java/default
Path /usr/java/default is not a directory
Attempting to locate Java Home in /usr/java
Path /usr/java is not a directory
Attempting to locate Java Home in /usr/local/java
Path /usr/local/java is not a directory
Attempting to locate Java Home in /usr/lib/jvm/default-java
Path /usr/lib/jvm/default-java is not a directory
Attempting to locate Java Home in /usr/lib/jvm/java
Attempting to locate VM configuration file /usr/lib/jvm/java/jre/lib/jvm.cfg
Attempting to locate VM configuration file /usr/lib/jvm/java/lib/jvm.cfg
Attempting to locate VM configuration file /usr/lib/jvm/java/jre/lib/amd64/jvm.cfg
Found VM configuration file at /usr/lib/jvm/java/jre/lib/amd64/jvm.cfg
Found VM server definition in configuration
Checking library /usr/lib/jvm/java/jre/lib/amd64/server/libjvm.so
Found VM client definition in configuration
Checking library /usr/lib/jvm/java/jre/lib/amd64/client/libjvm.so
Checking library /usr/lib/jvm/java/lib/amd64/client/libjvm.so
Cannot locate library for VM client (skipping)
Java Home located in /usr/lib/jvm/java
+-- DUMPING JAVA HOME STRUCTURE ------------------------
| Java Home:       "/usr/lib/jvm/java"
| Java VM Config.: "/usr/lib/jvm/java/jre/lib/amd64/jvm.cfg"
| Found JVMs:      1
| JVM Name:        "server"
|                  "/usr/lib/jvm/java/jre/lib/amd64/server/libjvm.so"
+-------------------------------------------------------
Running w/ LD_LIBRARY_PATH=/usr/lib/jvm/java/jre/lib/amd64/server:/usr/lib/jvm/java/jre/lib/amd64
redirecting stdout to /dev/null and stderr to /dev/null
Switching umask back to 022 from 077
Using default JVM in /usr/lib/jvm/java/jre/lib/amd64/server/libjvm.so
Attemtping to load library /usr/lib/jvm/java/jre/lib/amd64/server/libjvm.so
JVM library /usr/lib/jvm/java/jre/lib/amd64/server/libjvm.so loaded
JVM library entry point found (0x924610A0)
+-- DUMPING JAVA VM CREATION ARGUMENTS -----------------
| Version:                       0x010004
| Ignore Unrecognized Arguments: False
| Extra options:                 1
|   "-Djava.class.path=/home/weli/projs/jboss-webserver-and-eap-high-availability/DaemonDemo/build/libs:/usr/share/java/commons-daemon-1.0.15-redhat-1.jar" (0x00000000)
+-------------------------------------------------------
| Internal options:              4
|   "-Dcommons.daemon.process.id=31380" (0x00000000)
|   "-Dcommons.daemon.process.parent=31379" (0x00000000)
|   "-Dcommons.daemon.version=1.0.15-dev" (0x00000000)
|   "abort" (0xf9b3e0a0)
+-------------------------------------------------------
Java VM created successfully
Class org/apache/commons/daemon/support/DaemonLoader found
Native methods registered
java_init done
Daemon loading...
MyDaemon init...
Daemon loaded successfully
java_load done
MyDaemon start...
Daemon started successfully
java_start done
Waiting for a signal to be delivered
create_tmp_file: /tmp/31380.jsvc_up
```

From above log we can see all the details of the process. We can see `jsvc` tried to find `java` from several predefined locations, and finally it found the `java` provided by Fedora, and it shows how it uses `DaemonLoader` and start our `MyDaemon`.

Now let's analyze the processes created by `jsvc`. As we have learned, `jsvc` itself is a `Launcher Process`, it will start a JVM instance called `Controller Process`, which will interact with launcher to listen to standard system signals. The controller will start our Daemon program as a standalone process as the `Controlled Process`, the controlled process will accept the management of controller, because controller process can control the child(controlled) process by using the implemented `Daemon` interface.

We can use `ps` command to verify this:

```bash
[weli@localhost projs]$ ps -ef | grep jsvc
root      2376   316  0 18:12 pts/5    00:00:00 sudo /usr/bin/jsvc -debug -nodetach -cp /home/weli/projs/jboss-webserver-and-eap-high-availability/DaemonDemo/build/libs:/usr/share/java/commons-daemon-1.0.15-redhat-1.jar MyDaemon
root      2385  2376  0 18:12 pts/5    00:00:00 jsvc.exec -debug -nodetach -cp /home/weli/projs/jboss-webserver-and-eap-high-availability/DaemonDemo/build/libs:/usr/share/java/commons-daemon-1.0.15-redhat-1.jar MyDaemon
root      2386  2385  0 18:12 pts/5    00:00:00 jsvc.exec -debug -nodetach -cp /home/weli/projs/jboss-webserver-and-eap-high-availability/DaemonDemo/build/libs:/usr/share/java/commons-daemon-1.0.15-redhat-1.jar MyDaemon
```

From above we can see three processes. The `jsvc` itself is obviously the launcher. For the other to processes, we can refer to `jsvc` debug output to understand it:

```bash
+-------------------------------------------------------
| Internal options:              4
|   "-Dcommons.daemon.process.id=2386" (0x00000000)
|   "-Dcommons.daemon.process.parent=2385" (0x00000000)
|   "-Dcommons.daemon.version=1.0.15-dev" (0x00000000)
|   "abort" (0xfc2fc0a0)
+-------------------------------------------------------
Java VM created successfully
```

So the parent is the controller, and the other one is the worker. After the `jsvc` is started as a daemon, we can now pressing `CTRL-C` to send a `SIGINT` signal to the process, and we can see the following output:

```bash
^CCaught SIGINT: Scheduling a shutdown
remove_tmp_file: /tmp/2386.jsvc_up
Shutdown or reload requested: exiting
MyDaemon stop...
Forwarding signal 2 to process 2386
Caught SIGINT: Scheduling a shutdown
Shutdown or reload already scheduled
Daemon stopped successfully
MyDaemon destroy...
Daemon destroyed successfully
Calling System.exit(0)
Service shut down
```

As the log shown above, we can see how `jsvc` handles the signal properly and gracefully shutdown our `MyDaemon`. So it's our responsibility to implement `Daemon` interface correctly, so `jsvc` can use our implementation properly.

### What's the difference between systemd and jsvc

Currently the `systemd` can achieve most parts of  the process control function provided by `jsvc`, but `jsvc` can let the server to bind to privileged port and then drop the root access properly. To see more differences between `systemd` and `jsvc`, you can check this page[^6].

[^6]: [What benefit do I get from JSVC over just using systemd?](http://stackoverflow.com/questions/28894008/what-benefit-do-i-get-from-jsvc-over-just-using-systemd)

### _References_

---
