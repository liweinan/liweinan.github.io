---
title: "Lambda is a linking scheme"
abstract: "The lambda expression is implemented by the invokedynamic JVM instruction, and in this article let's see why the invokedynamic instruction is actually a way for method linkage."
---

{% include mathjax.html %}

# {{ page.title }}

{{ page.abstract }}

Firstly let's define a interface and a class to be called by lambda expression:

```java
/**
 * Created by weinanli on 11/06/2017.
 */
public class Calculator {
    interface IntegerMath {
        int operation(int a, int b);
    }

    public int operateBinary(int a, int b, IntegerMath op) {
        return op.operation(a, b);
    }
}
```

From the above code, we can see the `Calculator` class has a `operateBinary(...)` method. The method accepts two integers and a `IntegerMath` interface for calculation. The `IntegerMath` interface defines an `operation(...)` method for the actual calculation process.

Before JDK7, we need to implement the `IntegerMath` interface by creating a class. With lambda expression, we can reduce the amount of code. Here is the example:

```java
/**
 * Created by weinanli on 11/06/2017.
 */
public class PlayWithLambda {
    public static void main(String[] args) throws Exception {
        Calculator myApp = new Calculator();
        Calculator.IntegerMath addition = (a, b) -> a + b;
        Calculator.IntegerMath subtraction = (a, b) -> a - b;

        myApp.operateBinary(40, 2, addition);
        myApp.operateBinary(20, 10, subtraction);
    }
}
```

From the above code, we have created two `IntegerMath` instances with lambda expressions: one is `addition`, and the other is `subtraction`.

The lambda expression let us define two anonymous class instances that implements the `IntegerMath` interface. We just need to write the implemented code of the `operation(...)` method in lambda expression, and this greatly reduce the amount of the code we need to write.

This works because in the `IntegerMath` interface, it just contain one method, so the lambda expression won't have ambiguous meaning: it just implement the sole method defined in the interface.

In the IntelliJ IDE environment, it can detect the lambda expressions and display the link between the expression and the interface method. Here is the screenshot:

![https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/lambda/link.png](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/lambda/link.png)

From the above screenshot, we can see the $\lambda$ symbol displayed at the left of the two lines of lambda expression symbols. If we click the symbol, it will navigate the code to the interface definition. Here is the screenshot:

![https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/lambda/interface.png](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/lambda/interface.png)

After clicking the $\lambda$ symbol in `PlayWithLambda` class, it navigates to the `IntegerMath` interface method as shown above.

Now we can check the bytecode to see how this link works in the underlying level. Here is the decompiled byte code of the `PlayWithLambda` class:

```
$ javap -c -v PlayWithLambda.class
Classfile /Users/weinanli/Desktop/java/PlayWithLambda.class
  Last modified Jun 11, 2017; size 1161 bytes
  MD5 checksum 54fe2e615e51b6eea59f94252110b2c9
  Compiled from "PlayWithLambda.java"
public class PlayWithLambda
  minor version: 0
  major version: 52
  flags: ACC_PUBLIC, ACC_SUPER
Constant pool:
   #1 = Methodref          #8.#22         // java/lang/Object."<init>":()V
   #2 = Class              #23            // Calculator
   #3 = Methodref          #2.#22         // Calculator."<init>":()V
   #4 = InvokeDynamic      #0:#28         // #0:operation:()LCalculator$IntegerMath;
   #5 = InvokeDynamic      #1:#28         // #1:operation:()LCalculator$IntegerMath;
   #6 = Methodref          #2.#30         // Calculator.operateBinary:(IILCalculator$IntegerMath;)I
   #7 = Class              #31            // PlayWithLambda
   #8 = Class              #32            // java/lang/Object
   #9 = Utf8               <init>
  #10 = Utf8               ()V
  #11 = Utf8               Code
  #12 = Utf8               LineNumberTable
  #13 = Utf8               main
  #14 = Utf8               ([Ljava/lang/String;)V
  #15 = Utf8               Exceptions
  #16 = Class              #33            // java/lang/Exception
  #17 = Utf8               lambda$main$1
  #18 = Utf8               (II)I
  #19 = Utf8               lambda$main$0
  #20 = Utf8               SourceFile
  #21 = Utf8               PlayWithLambda.java
  #22 = NameAndType        #9:#10         // "<init>":()V
  #23 = Utf8               Calculator
  #24 = Utf8               BootstrapMethods
  #25 = MethodHandle       #6:#34         // invokestatic java/lang/invoke/LambdaMetafactory.metafactory:(Ljava/lang/invoke/MethodHandles$Lookup;Ljava/lang/String;Ljava/lang/invoke/MethodType;Ljava/lang/invoke/MethodType;Ljava/lang/invoke/MethodHandle;Ljava/lang/invoke/MethodType;)Ljava/lang/invoke/CallSite;
  #26 = MethodType         #18            //  (II)I
  #27 = MethodHandle       #6:#35         // invokestatic PlayWithLambda.lambda$main$0:(II)I
  #28 = NameAndType        #36:#40        // operation:()LCalculator$IntegerMath;
  #29 = MethodHandle       #6:#41         // invokestatic PlayWithLambda.lambda$main$1:(II)I
  #30 = NameAndType        #42:#43        // operateBinary:(IILCalculator$IntegerMath;)I
  #31 = Utf8               PlayWithLambda
  #32 = Utf8               java/lang/Object
  #33 = Utf8               java/lang/Exception
  #34 = Methodref          #44.#45        // java/lang/invoke/LambdaMetafactory.metafactory:(Ljava/lang/invoke/MethodHandles$Lookup;Ljava/lang/String;Ljava/lang/invoke/MethodType;Ljava/lang/invoke/MethodType;Ljava/lang/invoke/MethodHandle;Ljava/lang/invoke/MethodType;)Ljava/lang/invoke/CallSite;
  #35 = Methodref          #7.#46         // PlayWithLambda.lambda$main$0:(II)I
  #36 = Utf8               operation
  #37 = Class              #47            // Calculator$IntegerMath
  #38 = Utf8               IntegerMath
  #39 = Utf8               InnerClasses
  #40 = Utf8               ()LCalculator$IntegerMath;
  #41 = Methodref          #7.#48         // PlayWithLambda.lambda$main$1:(II)I
  #42 = Utf8               operateBinary
  #43 = Utf8               (IILCalculator$IntegerMath;)I
  #44 = Class              #49            // java/lang/invoke/LambdaMetafactory
  #45 = NameAndType        #50:#53        // metafactory:(Ljava/lang/invoke/MethodHandles$Lookup;Ljava/lang/String;Ljava/lang/invoke/MethodType;Ljava/lang/invoke/MethodType;Ljava/lang/invoke/MethodHandle;Ljava/lang/invoke/MethodType;)Ljava/lang/invoke/CallSite;
  #46 = NameAndType        #19:#18        // lambda$main$0:(II)I
  #47 = Utf8               Calculator$IntegerMath
  #48 = NameAndType        #17:#18        // lambda$main$1:(II)I
  #49 = Utf8               java/lang/invoke/LambdaMetafactory
  #50 = Utf8               metafactory
  #51 = Class              #55            // java/lang/invoke/MethodHandles$Lookup
  #52 = Utf8               Lookup
  #53 = Utf8               (Ljava/lang/invoke/MethodHandles$Lookup;Ljava/lang/String;Ljava/lang/invoke/MethodType;Ljava/lang/invoke/MethodType;Ljava/lang/invoke/MethodHandle;Ljava/lang/invoke/MethodType;)Ljava/lang/invoke/CallSite;
  #54 = Class              #56            // java/lang/invoke/MethodHandles
  #55 = Utf8               java/lang/invoke/MethodHandles$Lookup
  #56 = Utf8               java/lang/invoke/MethodHandles
{
  public PlayWithLambda();
    descriptor: ()V
    flags: ACC_PUBLIC
    Code:
      stack=1, locals=1, args_size=1
         0: aload_0
         1: invokespecial #1                  // Method java/lang/Object."<init>":()V
         4: return
      LineNumberTable:
        line 1: 0

  public static void main(java.lang.String[]) throws java.lang.Exception;
    descriptor: ([Ljava/lang/String;)V
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
      stack=4, locals=4, args_size=1
         0: new           #2                  // class Calculator
         3: dup
         4: invokespecial #3                  // Method Calculator."<init>":()V
         7: astore_1
         8: invokedynamic #4,  0              // InvokeDynamic #0:operation:()LCalculator$IntegerMath;
        13: astore_2
        14: invokedynamic #5,  0              // InvokeDynamic #1:operation:()LCalculator$IntegerMath;
        19: astore_3
        20: aload_1
        21: bipush        40
        23: iconst_2
        24: aload_2
        25: invokevirtual #6                  // Method Calculator.operateBinary:(IILCalculator$IntegerMath;)I
        28: pop
        29: aload_1
        30: bipush        20
        32: bipush        10
        34: aload_3
        35: invokevirtual #6                  // Method Calculator.operateBinary:(IILCalculator$IntegerMath;)I
        38: pop
        39: return
      LineNumberTable:
        line 3: 0
        line 4: 8
        line 5: 14
        line 7: 20
        line 8: 29
        line 9: 39
    Exceptions:
      throws java.lang.Exception
}
SourceFile: "PlayWithLambda.java"
InnerClasses:
     static #38= #37 of #2; //IntegerMath=class Calculator$IntegerMath of class Calculator
     public static final #52= #51 of #54; //Lookup=class java/lang/invoke/MethodHandles$Lookup of class java/lang/invoke/MethodHandles
BootstrapMethods:
  0: #25 invokestatic java/lang/invoke/LambdaMetafactory.metafactory:(Ljava/lang/invoke/MethodHandles$Lookup;Ljava/lang/String;Ljava/lang/invoke/MethodType;Ljava/lang/invoke/MethodType;Ljava/lang/invoke/MethodHandle;Ljava/lang/invoke/MethodType;)Ljava/lang/invoke/CallSite;
    Method arguments:
      #26 (II)I
      #27 invokestatic PlayWithLambda.lambda$main$0:(II)I
      #26 (II)I
  1: #25 invokestatic java/lang/invoke/LambdaMetafactory.metafactory:(Ljava/lang/invoke/MethodHandles$Lookup;Ljava/lang/String;Ljava/lang/invoke/MethodType;Ljava/lang/invoke/MethodType;Ljava/lang/invoke/MethodHandle;Ljava/lang/invoke/MethodType;)Ljava/lang/invoke/CallSite;
    Method arguments:
      #26 (II)I
      #29 invokestatic PlayWithLambda.lambda$main$1:(II)I
      #26 (II)I
```

From the above decompiled code, we can see the two lines `invokedynamic` instructions:

```
$ javap -c -v PlayWithLambda.class | grep invokedynamic
         8: invokedynamic #4,  0              // InvokeDynamic #0:operation:()LCalculator$IntegerMath;
        14: invokedynamic #5,  0              // InvokeDynamic #1:operation:()LCalculator$IntegerMath;
```

We know the above two lines of instructions are corresponding to the two lines of lambda expressions in the Java code. In above code, the `#4`, and `#5` parameters are the indexes to the constant pool of the code. In the comments of the above code, it has already translated the real contents of the indexes to us, and they are two `InvokeDynamic` instances. We can also see the table in above decompiled code like this:

```
Constant pool:
   #4 = InvokeDynamic      #0:#28         // #0:operation:()LCalculator$IntegerMath;
   #5 = InvokeDynamic      #1:#28         // #1:operation:()LCalculator$IntegerMath;
```

The `InvokeDynmaic` instances also receives two parameters. The first one is an index to the bootstrap method table, and they are `#0` and `#1`. The second parameter is an index to the constant pool, and in the comment is has translated the index into the content of the index. Here is the relative info in the constant pool:

```
Constant pool:
  #28 = NameAndType        #36:#40        // operation:()LCalculator$IntegerMath;
```

From the above output, we can see the parameter is an instance of `NameAndType` class, and it refers to the interface method to be invoked. 

Now let's see the bootstrap methods table:

```
BootstrapMethods:
  0: #25 invokestatic java/lang/invoke/LambdaMetafactory.metafactory:(Ljava/lang/invoke/MethodHandles$Lookup;Ljava/lang/String;Ljava/lang/invoke/MethodType;Ljava/lang/invoke/MethodType;Ljava/lang/invoke/MethodHandle;Ljava/lang/invoke/MethodType;)Ljava/lang/invoke/CallSite;
    Method arguments:
      #26 (II)I
      #27 invokestatic PlayWithLambda.lambda$main$0:(II)I
      #26 (II)I
  1: #25 invokestatic java/lang/invoke/LambdaMetafactory.metafactory:(Ljava/lang/invoke/MethodHandles$Lookup;Ljava/lang/String;Ljava/lang/invoke/MethodType;Ljava/lang/invoke/MethodType;Ljava/lang/invoke/MethodHandle;Ljava/lang/invoke/MethodType;)Ljava/lang/invoke/CallSite;
    Method arguments:
      #26 (II)I
      #29 invokestatic PlayWithLambda.lambda$main$1:(II)I
      #26 (II)I
```

The above two `LambdaMetafactory.metafactory(...)` methods are invoked by the two lambda expressions, and they will link the lambda expressions with the two anonymous class instances that implements the `IntegerMath` interface.

The final result returned by `LambdaMetafactory.metafactory(...)` is a `CallSite` class instance, and it contains the `MethodHandle` class instance to be invoked.

From the above process, we can see the lambda expression helps us to create anonymous class and the Java compiler will generate the `invokedynamic` instruction for the lambda expression. At last, the bootstrap method like `LambdaMetafactory.metafactory(...)` will be put into the bootstrap methods table, and they are used to do the real linking job.  









