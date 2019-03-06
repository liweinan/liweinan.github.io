---
title: 各种语言中的map和lambda
abstract: 本文横向比较7种语言的map函数。 
---

## {{ page.title }}

本文横向比较7种语言的map函数。

其实很多语言中都有map函数，而且功能也都差不多，比如ruby里面这样：

```ruby
irb(main):001:0> [1, 2, 3].map { |n| n*n }
=> [1, 4, 9]
```

上面是ruby的map方法。可以看到，数组`[1,2,3]`的`map`方法接收一个block，这个block接收数组里面的每一个元素，并将其乘方。

所以我们可以很清楚地看到map的功能：

1. 接收一组数据
2. 把这组数据的每一个元素x1, x2, x3等逐个传给函数f，执行f(x1)，f(x2)，f(x3)，等等，返回y1, y2, y3...
3. 返回由y1, y2, y3...组成的数组。

上面的ruby的这段代码完美符合这个定义：

1. `[1, 2, 3]`是一组输入数据
2. 数组中的"1", "2", "3"传递给函数`n*n`，执行`1*1`, `2*2`, `3*3`，返回"1", "4", "9"
3. 返回`[1, 4, 9]`这个数组。

支持map函数（ruby里面叫方法）语言的设计和实现，在概念上可能不同，但背后的逻辑不变。

接下来我们看看haskell里面的map函数，因为haskell有着严格的类型系统，所以我们更为直观地在haskell中查看map的类型定义如下：

```haskell
Prelude> :info map
map :: (a -> b) -> [a] -> [b] 	-- Defined in ‘GHC.Base’
```

上面的类型定义非常清楚，map函数接收两个参数：

1. `(a -> b)`
2. `[a]`

第一个参数是一个函数，这个函数接收类型为a的参数，返回类型为b的参数。第二个参数是`[a]`，是类型为a的数组。

所以这个定义和ruby的map方法一样，完美贴合map的定义：接收一个数组`[a]`，数组中的结果传递给一个函数处理`(a->b)`，返回结果`[b]`。

最后我们用用看haskell的map函数：

```haskell
Prelude> quadratic x = x * x
Prelude> map quadratic [1, 2, 3]
[1,4,9]
```

如上所示，我们首先定义了乘方函数quadratic，然后把这个函数作为第一个参数传递给了map，然后把`[1, 2, 3]`作为第二个参数。

于是`[1, 2, 3]`里面的元素分别作为参数传递给quadratic并执行，返回结果`[1, 4, 9]`。

这和ruby中我们写的代码效果一样：

```ruby
[1, 2, 3].map { |n| n*n }
```

但是我们仔细看看可以发现，在实现的理念上，ruby和haskell是完全不同的。

从上面的代码我们可以看到，ruby的map方法，是`[1, 2, 3]`这个数组类的一个方法：

```ruby
irb(main):003:0> [1, 2, 3].class
=> Array
```

ruby中的map方法是由上面这个Array class提供的。很多支持map方法的语言，在设计上都和ruby类似。

但是haskell可以完全算是一个另类，采用了完全不同的设计。最为本质的不同是，haskell的map本身就是一个函数：

```haskell
Prelude> :info map
map :: (a -> b) -> [a] -> [b] 	-- Defined in ‘GHC.Base’
```

因为haskell并不是面向对象的设计，haskell里面的class完全不是面向对象语言中class的概念。因此，map不属于任何所谓的"对象"和"类"，因为haskell中根本没有这种概念。

因为这个特性，haskell的map更为灵活，比如，可以接受高阶函数作为参数：

```haskell
Prelude> map (+1) [1, 2, 3]
[2,3,4]
```

这个在Haskell的设计中被称为first-class functions。

可以看到，函数式语言抽象的类型设计带来了一个很大的好处：一种统一的功能设计。体现在map上面，我们看到map和其它函数并没有不同，只是一个接受函数为参数的高阶函数而已（背后要靠haskell的typing system撑起来）。

这是函数式（functional）语言和宣告（imperative）式语言的区别之一。

接下来看看各种语言当中的map。

> .R.U.B.Y.

首先我们来看ruby，ruby中真正意义上的"lambda"应该是它的"block"的概念，下面是例子：

```ruby
irb(main):001:0> [1, 2, 3].map { |n| n*n }
=> [1, 4, 9]
```

如上所示，大括号里面的`n*n`就是一个匿名函数。但是ruby里面还有自己的"proc"和"lambda"这两种具体的东西，有ruby自己特有的定义和实现[^ruby]。

[^ruby]: http://awaxman11.github.io/blog/2013/08/05/what-is-the-difference-between-a-block/

ruby把匿名函数这块考虑的特别细致，所以在语言实现的时候细分成了好几个概念，其实这是ruby语言设计思想的一个具体体现：一切设计，为具体的使用价值来服务。

这也是个人喜欢ruby的一个核心价值：实用性。

那么ruby算是functional的语言，还是imperative的语言呢？

这里必须要说，很多计算机语言，都是一种"融合体"，吸收了很多种设计思想在里面。比如ruby，首先我们可以明确一点，它是面向对象（object oriented）的语言。

那么ruby是functional还是imperative呢？可以说，它是一种融合，以imperative为主，但吸收了很多functional的设计思想的语言。

> .L.I.S.P.

接下来我们看看lisp，lisp是实现lambda和map的祖师爷了，而且lisp中的这两个概念是原汁原味的。下面是例子：

```lisp
[6]> (mapcar (lambda (n) (* n n)) '(1 2 3))
(1 4 9)
```

lisp的lambda函数就用"lambda"定义，然后lisp里面的map概念的实际实现叫做`mapcar`（"map"则是另外一个函数）。

lisp的函数命名有点混乱，学习lisp的朋友相信都有体会。

lisp是纯正的functional语言了，但是它不是强类型定义的语言，这点要和haskell和scala区分开。

> .G.R.O.O.V.Y.

Groovy里面的lambda概念的实现就是closure，语法就是大括号包裹一个匿名函数：

```groovy
groovy:000> [1, 2, 3].collect { x -> x * x }
===> [1, 4, 9]
```

如上所示，groovy的collect方法实际就是map，而且我们发现，groovy的map实现和ruby的map实现类似：它们都是数组提供的一个方法。ruby里叫map，groovy里面叫做collect。一看就知道都是object oriented的语言。

Groovy实际上就是Java的一层糖衣了，各种设计思想都贴近Java本身。那么我们自然而然下一个语言讨论Java。

> .J.A.V.A.

从Java 8开始，Java开始实现了一些函数式语言的设计的设计了，核心的语言特性包括：lambda expression，functional interface。

下面是Java 8的代码例子[^code]：

[^code]: https://repl.it/@weinan/DarkslategreyBuzzingPilchard

```java
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

public class Main {
    public static void main(String[] args) {
        List results = Arrays.asList(1, 2, 3).stream().map(x -> x * x).collect(Collectors.toList());
        results.forEach(System.out::println);
    }
}
```

上面的代码，核心部分就是这句：

```java
List results = Arrays.asList(1, 2, 3).stream().map(x -> x * x).collect(Collectors.toList());
```

上面的代码中，我们创建了一个包含"1, 2, 3"的数组，然后通过"stream"方法将其转化成Steam类，这个类是Java 8中加入的，它提供map方法。

在map方法中，我们可以使用Java 8中的lambda表达式。

在这个例子里面，我们的lambda表达式是`x -> x * x`。

最后我们还调用了数组的`forEach`方法，传入`System.out::println`[^doc]，打印出运算结果。

[^doc]: [Java 8 里面的双冒号语法和lambda一样，也是通过invokedynamic来实现的](http://weinan.io/2017/12/10/java.html)

可以看到，Java的lambda表达式是一种匿名函数的书写方法，并且可以把函数作为参数进行传递了。可以说从Java 8开始，Java已经是一门函数式语言了。

> .C.L.O.J.U.R.E.

Clojure可以说是Lisp的近亲，但真正深入学习进取，可以发现这只是表面现象。clojure借用了lisp的语法，设计理念，但是背后还是有巨大差异。

我们看看Clojure中的lambda和map。我们可以使用clojure的这在线的repl来玩：

http://www.tryclj.com/

输入代码如下：
```clojure
(map (fn [x] (* x x)) '(1 2 3))
```

上面是clojure的map方法，它接受一个匿名函数（用fn定义）作为参数，并接受待处理的list（'1 2 3）作为第二参数。下面是运行结果：

```clojure
(1 4 9)
```

可以看到clojure和lisp的map和lambda差不多，只不过在clojure中，"lambda"叫"fn"，"mapcar"叫"map"。

> .H.A.S.K.E.L.L.

我们来看看Haskell中的map与lambda：

```haskell
Prelude> map (\x -> x * x) [1, 2, 3]
[1,4,9]
```

如上所示，我们在Haskell中，使用反斜杠"\"来表示一个匿名函数的开始部分。我们在map中传递了一个lambda：

```haskell
(\x -> x * x)
```

然后让它作用于数组：

```haskell
[1, 2, 3]
```

这个反斜杠的语法格式，大家记住就可以了。

> .S.C.A.L.A.

Scala可以算是最"杂糅"的一门语言了。首先，它是object-oriented语言，它的语法可能欺骗了很多初学者，觉得和Java差不多。

但深入学下去，会发现它和Haskell才是近亲。

看看Scala的lambda和map的实现：

```scala
scala> (1 to 3).map { x => x * x }
res1: scala.collection.immutable.IndexedSeq[Int] = Vector(1, 4, 9)
```

如上所示，Scala的lambda也是像groovy一样放在大括号里，然后map方法也是调用(1 to 3)这个数组的方法，怎么看都是和ruby，groovy，java8这种object-oriented语言一个派系的。

但是我们别被表面欺骗了，Scala可是和Haskell一样，有类型系统，支持函数式编程的。因此，Scala也可以像Haskell这样来定义函数：

```scala
scala> (x: Int) => x + 1
res2: Int => Int = <function1>
```

看上面这个匿名函数定义，是不是觉得和Haskell的语法都很像！

所以说Scala是一门杂糅的语言。

一口气为大家介绍了七种语言，整个过程是非常开心的！希望大家能从这个过程中，有所收获！

