---
title: A Non-recursive Approach To The Fibonacci Sequence Generator
abstract: We usually know the Fibonacci sequence generator for learning the recursive algorithm. In this article, I'd like to introduce to you a non-recursive implementation.
---

## _{{ page.title }}_

{{ page.abstract }}

Here is the recursive version of the Fibonacci sequence generator we usually learn from the text book[^fibrec]:

```java
public static long fibonacci(int n) {
    if (n <= 1) return 1;
    else return fibonacci(n - 1) + fibonacci(n - 2);
}
```

The disadvantage of the above implementation is that the stack memory usage will increase exponentially as the argument `n` increases. In addition, this recursion is not a tail-recursion[^tail], so it can't be optimized easily by compiler.

Actually we can use loop instead of recursion to implement the fibonacci sequence more efficiently. Here is the one I wrote for example:

```java
public static long nonrecursiveFibonacci(int n) {
    if (n < 1) return 0;
    if (n == 1) return 1;
    if (n == 2) return 2;
    long a = 1;
    long b = 1;
    long sum = a + b; // for n == 2
    for (int i = 3; i <= n; i++) {
        a = sum; // using `a` for temporary storage
        sum = b + sum;
        b = a;
    }
    return sum;
}
```

As the codes shown above, I used a loop and some fine-grained boundary conditions to replace the recursion. In this way we totally eliminate the exponentially grown stack memory usages of the recursive version of the implementation. Now let's wrote some codes for benchmark:

```java
long start = System.currentTimeMillis();
long result = fibonacci(40);
long end = System.currentTimeMillis();
System.out.println("result: " + result);
System.out.println("Time consumed by `fibonacci` method:" + (end - start));
```

```java
start = System.currentTimeMillis();
result = nonrecursiveFibonacci(40);
end = System.currentTimeMillis();
System.out.println("result: " + result);
System.out.println("Time consumed by `nonrecursiveFibonacci` method:" + (end - start));
```

As the codes shown above, we used two different versions of implementations to calculate the 40th fibonacci number. And here's the running result:

```
result: 165580141
Time consumed by `fibonacci` method:756
```

```
result: 165580141
Time consumed by `nonrecursiveFibonacci` method:0
```

We can see the recursive version used 756 milliseconds to complete the calculation, and the time used by the non-recursive version can be neglected at millisecond level. The bigger the fibonacci number we want to calculate, the more performance difference between two implementations we'll get. More seriously, the recursive version will fail because it will throw stack memory overflow exception for its exponentially grown stack memory usage.

In conclusion, though the recursive implementation is clean in design, but sometimes it's not as efficient as the loop alternative. From the practical perspective, we should sometimes fine-tune our implementation to maximize the performance.

### _References_

---

[^fibrec]: [http://introcs.cs.princeton.edu/java/23recursion/Fibonacci.java.html](http://introcs.cs.princeton.edu/java/23recursion/Fibonacci.java.html)

[^tail]: [https://en.wikipedia.org/wiki/Tail_call](https://en.wikipedia.org/wiki/Tail_call)
