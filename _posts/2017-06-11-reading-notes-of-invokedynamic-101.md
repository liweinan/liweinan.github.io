---
title: "Reading notes of the article 'Invokedynamic 101'"
abstract: "I'm reading the article 'Invokedynamic 101' recently, and I want to write some notes on the code provided in the article."
---

# {{ page.title }}

{{ page.abstract }}

Here is the address of the article:

- [http://www.javaworld.com/article/2860079/learn-java/invokedynamic-101.html](http://www.javaworld.com/article/2860079/learn-java/invokedynamic-101.html)

The article introduces the internal working scheme of the JVM `invokedynamic` instruction, and you need to read it before reading this article.

Here is the class diagram that shows the relationship of `MethodType`, `MethodHandle`, `MethodHandles`, `Lookup`, and `CallSite`:

![https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/jvm/relationship.png](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/jvm/relationship.png)

The above diagram shows the relationship of these classes. The following code shows the usages of `MethodHandles`, `Lookup`, `MethodHandle` and `MethodType`:  

```java
import java.lang.invoke.MethodHandle;
import java.lang.invoke.MethodHandles;
import java.lang.invoke.MethodType;

/**
 * Created by weinanli on 09/06/2017.
 */

public class InsertArguments {
    public static void main(String[] args) throws Throwable {
        MethodHandles.Lookup lookup = MethodHandles.lookup();
        MethodHandle handle = lookup.findStatic(Math.class, "pow",
                MethodType.methodType(double.class,
                        double.class,
                        double.class));
        System.out.printf("2^10 = %d%n", (int) (double) handle.invoke(2.0));
        handle = MethodHandles.insertArguments(handle, 1, 10);
    }
}
```

From the above code, we can see the `Lookup` class is an inner class of `MethodHandles` class, and the instance of `Lookup` class is fetched from `MethodHandles` class.

The `MethodType` class is used to represent the method signature: it includes the method parameters and the method return type. This is convenient because we can encapsulate the signature of a method into a single `MethodType` instance.

The `MethodType` instance is then passed to `Lookup` instance and we finally get an instance of `MethodHandle` class.

The `MethodHandle` class is finally used to invoke the method.

In the article 'Invokedynamic 101', it introduces the concept of `bootstrap` methods. The `bootstrap` methods will be called by the  `invokedynamic` instruction to prepare the `CallSite` for using, and the `CallSite` class will contain the `MethodHandle` for calling.

To clarify the above sequence, I have modified `IDDL` class (introduced in the `Invokedynamic 101`) a little bit and here is the source code:

```java
import java.lang.invoke.*;

/**
 * Created by weinanli on 09/06/2017.
 */
public class IDDL {
    private static MethodHandle handle;

    private static void helloWorld() {
        System.out.println("Hello, World!");
    }
    

    public static CallSite bootstrapDynamic(MethodHandles.Lookup caller,
                                            String name,
                                            MethodType type)
            throws IllegalAccessException, NoSuchMethodException {

        System.out.println("bootstrap method called!");
        System.out.println("name: " + name);
        
        MethodHandles.Lookup lookup = MethodHandles.lookup();
        Class thisClass = lookup.lookupClass();
        handle = lookup.findStatic(thisClass, "helloWorld",
                MethodType.methodType(void.class));
        if (!type.equals(handle.type()))
            handle = handle.asType(type);

        return new ConstantCallSite(handle);
    }
}
```

As the code shown above, I have added three lines of the log output simply by using the `System.out.println(...)` method. We will see the log in runtime later.

Now here is the disassembled bytecode of `IDD` class(it has been provided in the original article, and I put it here for noting):

```
$ javap -c -v IDD.class
Classfile /Users/weinanli/Desktop/java/IDD.class
  Last modified Jun 9, 2017; size 390 bytes
  MD5 checksum ee1ec44a736cc0d446337023ec1a8ba6
public class IDD
  minor version: 0
  major version: 51
  flags: ACC_PUBLIC, ACC_SUPER
Constant pool:
   #1 = Utf8               IDD
   #2 = Class              #1             // IDD
   #3 = Utf8               java/lang/Object
   #4 = Class              #3             // java/lang/Object
   #5 = Utf8               <init>
   #6 = Utf8               ()V
   #7 = NameAndType        #5:#6          // "<init>":()V
   #8 = Methodref          #4.#7          // java/lang/Object."<init>":()V
   #9 = Utf8               main
  #10 = Utf8               ([Ljava/lang/String;)V
  #11 = Utf8               IDDL
  #12 = Class              #11            // IDDL
  #13 = Utf8               bootstrapDynamic
  #14 = Utf8               (Ljava/lang/invoke/MethodHandles$Lookup;Ljava/lang/String;Ljava/lang/invoke/MethodType;)Ljava/lang/invoke/CallSite;
  #15 = NameAndType        #13:#14        // bootstrapDynamic:(Ljava/lang/invoke/MethodHandles$Lookup;Ljava/lang/String;Ljava/lang/invoke/MethodType;)Ljava/lang/invoke/CallSite;
  #16 = Methodref          #12.#15        // IDDL.bootstrapDynamic:(Ljava/lang/invoke/MethodHandles$Lookup;Ljava/lang/String;Ljava/lang/invoke/MethodType;)Ljava/lang/invoke/CallSite;
  #17 = MethodHandle       #6:#16         // invokestatic IDDL.bootstrapDynamic:(Ljava/lang/invoke/MethodHandles$Lookup;Ljava/lang/String;Ljava/lang/invoke/MethodType;)Ljava/lang/invoke/CallSite;
  #18 = Utf8               foo
  #19 = NameAndType        #18:#6         // foo:()V
  #20 = InvokeDynamic      #0:#19         // #0:foo:()V
  #21 = Utf8               Code
  #22 = Utf8               BootstrapMethods
{
  public IDD();
    descriptor: ()V
    flags: ACC_PUBLIC
    Code:
      stack=1, locals=1, args_size=1
         0: aload_0
         1: invokespecial #8                  // Method java/lang/Object."<init>":()V
         4: return

  public static void main(java.lang.String[]);
    descriptor: ([Ljava/lang/String;)V
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
      stack=0, locals=1, args_size=1
         0: invokedynamic #20,  0             // InvokeDynamic #0:foo:()V
         5: return
}
BootstrapMethods:
  0: #17 invokestatic IDDL.bootstrapDynamic:(Ljava/lang/invoke/MethodHandles$Lookup;Ljava/lang/String;Ljava/lang/invoke/MethodType;)Ljava/lang/invoke/CallSite;
```

From the above bytecode, we can see there is `BootstrapMethods` section at the bottom, and we can see the `IDDL.bootstrapDynamic(...)` method is marked as a bootstrap method. This means that the virtual machine will invoke this method when `invokedynamic` instruction is being called.

In addition, we can see the `invokedyanmic` related instructions are these two lines:

```
#19 = NameAndType        #18:#6         // foo:()V
#20 = InvokeDynamic      #0:#19         // #0:foo:()V
```

From the above code, we can see the `invokedynmaic` instruction calls a `foo()` method. However this `foo()` method does not exist actually. It doesn't matter, because in our `bootstrapDynamic(...)` method, it just override this information. Here is the relative code in the method:

```java
handle = lookup.findStatic(thisClass, "helloWorld",
        MethodType.methodType(void.class));
```

From the above code, we can see the method name is written explicitly as `helloWorld`, and the passed in `name` parameter is not used at all, which means the passed in name `foo` is not used.

Because we have the `helloWorld` method, so the whole `invokedynamic` sequence will run correctly. Now let's run the compile code. Here is my directory:

```bash
$ ls IDD*.class
IDD.class  IDDL.class
```

Now I can run the code and here is the output:

```bash
$ java IDD
bootstrap method called!
name: foo
Hello, World!
```

From the above output, we can see the bootstrap method `bootstrapDynamic(...)` is being activated by the `invokedynamic` instruction, and the parameter of the `invokedynamic` instruction, `foo` is being passed to the bootstrap method. But as we have fixed the method handle to represent `helloWorld()` method, so the passed in parameter value `foo` is ignored.

Finally we can see the `helloWorld()` method is called and it outputs 'Hello, World!' on the screen.

Now let's write a sample code uses the lambda expression:

```java
public class ThreadLambda {
    public static void main(String[] args) {
        Runnable r = () -> System.out.println("Hello");
        r.run();
    }
}
```

The above class contains a lambda expression which represents a `Runnable` instance. We know the lambda expression will use the `invokedynamic` instruction to do the underlying work, and it will create a inner class for the lambda. We can compile the above code and disassemble the class to bytecode.

Here is the result:

```
$ javap -c -v ThreadLambda.class
Classfile /Users/weinanli/Desktop/java/ThreadLambda.class
  Last modified Jun 9, 2017; size 1017 bytes
  MD5 checksum f11dcb317d0d1e01b6c2c59212e51d69
  Compiled from "ThreadLambda.java"
public class ThreadLambda
  minor version: 0
  major version: 52
  flags: ACC_PUBLIC, ACC_SUPER
Constant pool:
   #1 = Methodref          #8.#18         // java/lang/Object."<init>":()V
   #2 = InvokeDynamic      #0:#23         // #0:run:()Ljava/lang/Runnable;
   #3 = InterfaceMethodref #24.#25        // java/lang/Runnable.run:()V
   #4 = Fieldref           #26.#27        // java/lang/System.out:Ljava/io/PrintStream;
   #5 = String             #28            // Hello
   #6 = Methodref          #29.#30        // java/io/PrintStream.println:(Ljava/lang/String;)V
   #7 = Class              #31            // ThreadLambda
   #8 = Class              #32            // java/lang/Object
   #9 = Utf8               <init>
  #10 = Utf8               ()V
  #11 = Utf8               Code
  #12 = Utf8               LineNumberTable
  #13 = Utf8               main
  #14 = Utf8               ([Ljava/lang/String;)V
  #15 = Utf8               lambda$main$0
  #16 = Utf8               SourceFile
  #17 = Utf8               ThreadLambda.java
  #18 = NameAndType        #9:#10         // "<init>":()V
  #19 = Utf8               BootstrapMethods
  #20 = MethodHandle       #6:#33         // invokestatic java/lang/invoke/LambdaMetafactory.metafactory:(Ljava/lang/invoke/MethodHandles$Lookup;Ljava/lang/String;Ljava/lang/invoke/MethodType;Ljava/lang/invoke/MethodType;Ljava/lang/invoke/MethodHandle;Ljava/lang/invoke/MethodType;)Ljava/lang/invoke/CallSite;
  #21 = MethodType         #10            //  ()V
  #22 = MethodHandle       #6:#34         // invokestatic ThreadLambda.lambda$main$0:()V
  #23 = NameAndType        #35:#36        // run:()Ljava/lang/Runnable;
  #24 = Class              #37            // java/lang/Runnable
  #25 = NameAndType        #35:#10        // run:()V
  #26 = Class              #38            // java/lang/System
  #27 = NameAndType        #39:#40        // out:Ljava/io/PrintStream;
  #28 = Utf8               Hello
  #29 = Class              #41            // java/io/PrintStream
  #30 = NameAndType        #42:#43        // println:(Ljava/lang/String;)V
  #31 = Utf8               ThreadLambda
  #32 = Utf8               java/lang/Object
  #33 = Methodref          #44.#45        // java/lang/invoke/LambdaMetafactory.metafactory:(Ljava/lang/invoke/MethodHandles$Lookup;Ljava/lang/String;Ljava/lang/invoke/MethodType;Ljava/lang/invoke/MethodType;Ljava/lang/invoke/MethodHandle;Ljava/lang/invoke/MethodType;)Ljava/lang/invoke/CallSite;
  #34 = Methodref          #7.#46         // ThreadLambda.lambda$main$0:()V
  #35 = Utf8               run
  #36 = Utf8               ()Ljava/lang/Runnable;
  #37 = Utf8               java/lang/Runnable
  #38 = Utf8               java/lang/System
  #39 = Utf8               out
  #40 = Utf8               Ljava/io/PrintStream;
  #41 = Utf8               java/io/PrintStream
  #42 = Utf8               println
  #43 = Utf8               (Ljava/lang/String;)V
  #44 = Class              #47            // java/lang/invoke/LambdaMetafactory
  #45 = NameAndType        #48:#52        // metafactory:(Ljava/lang/invoke/MethodHandles$Lookup;Ljava/lang/String;Ljava/lang/invoke/MethodType;Ljava/lang/invoke/MethodType;Ljava/lang/invoke/MethodHandle;Ljava/lang/invoke/MethodType;)Ljava/lang/invoke/CallSite;
  #46 = NameAndType        #15:#10        // lambda$main$0:()V
  #47 = Utf8               java/lang/invoke/LambdaMetafactory
  #48 = Utf8               metafactory
  #49 = Class              #54            // java/lang/invoke/MethodHandles$Lookup
  #50 = Utf8               Lookup
  #51 = Utf8               InnerClasses
  #52 = Utf8               (Ljava/lang/invoke/MethodHandles$Lookup;Ljava/lang/String;Ljava/lang/invoke/MethodType;Ljava/lang/invoke/MethodType;Ljava/lang/invoke/MethodHandle;Ljava/lang/invoke/MethodType;)Ljava/lang/invoke/CallSite;
  #53 = Class              #55            // java/lang/invoke/MethodHandles
  #54 = Utf8               java/lang/invoke/MethodHandles$Lookup
  #55 = Utf8               java/lang/invoke/MethodHandles
{
  public ThreadLambda();
    descriptor: ()V
    flags: ACC_PUBLIC
    Code:
      stack=1, locals=1, args_size=1
         0: aload_0
         1: invokespecial #1                  // Method java/lang/Object."<init>":()V
         4: return
      LineNumberTable:
        line 1: 0

  public static void main(java.lang.String[]);
    descriptor: ([Ljava/lang/String;)V
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
      stack=1, locals=2, args_size=1
         0: invokedynamic #2,  0              // InvokeDynamic #0:run:()Ljava/lang/Runnable;
         5: astore_1
         6: aload_1
         7: invokeinterface #3,  1            // InterfaceMethod java/lang/Runnable.run:()V
        12: return
      LineNumberTable:
        line 3: 0
        line 4: 6
        line 5: 12
}
SourceFile: "ThreadLambda.java"
InnerClasses:
     public static final #50= #49 of #53; //Lookup=class java/lang/invoke/MethodHandles$Lookup of class java/lang/invoke/MethodHandles
BootstrapMethods:
  0: #20 invokestatic java/lang/invoke/LambdaMetafactory.metafactory:(Ljava/lang/invoke/MethodHandles$Lookup;Ljava/lang/String;Ljava/lang/invoke/MethodType;Ljava/lang/invoke/MethodType;Ljava/lang/invoke/MethodHandle;Ljava/lang/invoke/MethodType;)Ljava/lang/invoke/CallSite;
    Method arguments:
      #21 ()V
      #22 invokestatic ThreadLambda.lambda$main$0:()V
      #21 ()V
```

From the above output, we can see the `BootstrapMethods` section, and it marked the `java/lang/invoke/LambdaMetafactory.metafactory` method as the bootstrap method. I won't dive into details about this class in this article, but you can guess its purpose is similar to our handmade `bootstrapDynamic(...)` method in above. It will prepare the `CallSite` with suitable `MethodHandle` included, by using the passed in parameters correctly, such as the method name passed in `invokedynamic` instruction. Here is the relative code of `invokeydynamic` instruction we can see in above output:

```
0: invokedynamic #2,  0              // InvokeDynamic #0:run:()Ljava/lang/Runnable;
```

We can see the parameter is `#2,  0`, and the table has been already translated in comment, it represents the `run:()Ljava/lang/Runnable;` method. This is correct, because our lambda represents this method.

In addition, from the above output, we can see the inner class represents the lambda expression is being created:

```
$ javap -c -v ThreadLambda.class | grep main.*0
  #15 = Utf8               lambda$main$0
  #22 = MethodHandle       #6:#34         // invokestatic ThreadLambda.lambda$main$0:()V
  #34 = Methodref          #7.#46         // ThreadLambda.lambda$main$0:()V
  #46 = NameAndType        #15:#10        // lambda$main$0:()V
      #22 invokestatic ThreadLambda.lambda$main$0:()V
```

The inner class will also be used by the bootstrap class `java.lang.invoke.LambdaMetafactory` for processing.

In this article, I explained some details on `invokedynamic` instruction execution sequence and its internal design. I wish the information is useful to you. 