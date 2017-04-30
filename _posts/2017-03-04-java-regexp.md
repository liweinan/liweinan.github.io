---
title: Using Java RegExp Engine
abstract: I'm playing Java RegExp Engine recently and I'd like to share some use experiences with you in this article.
---

{{ page.abstract }}

Here is the first example:

```java
Pattern p = Pattern.compile("(^[A-Za-z]+)( [0-9]+)( [A-Za-z]+)(.*)");
String text = "foo 42 bar xyz";
Matcher matcher = p.matcher(text);
matcher.find();
```

We have used parentheses to group our pattern into four parts:

```
(^[A-Za-z]+)( [0-9]+)( [A-Za-z]+)(.*)
```

The `matcher.find()` method will help to match the text using our `Pattern`:

```java
for (int i = 0; i <= matcher.groupCount(); i++) {
    System.out.println(i + ": " + matcher.group(i));
}
```

And the `matcher.group()` can help us to print the matched group defined in pattern string:

```
0: foo 42 bar xyz
1: foo
2:  42
3:  bar
4:  xyz
```

Please note the `group(0)` is the whole text matched by the pattern. The groups are defined by parentheses in pattern. For example, if we change our pattern from:

```java
Pattern p = Pattern.compile("(^[A-Za-z]+)( [0-9]+)( [A-Za-z]+)(.*)");
```

to:

```java
Pattern p = Pattern.compile("(^[A-Za-z]+)( [0-9]+)( [A-Za-z]+).*");
```

The difference is that this time we don't quote the last `.*` part into parentheses. And let's rerun the matching process:

```java
for (int i = 0; i <= matcher.groupCount(); i++) {
    System.out.println(i + ": " + matcher.group(i));
}
```

The result becomes:

```
0: foo 42 bar xyz
1: foo
2:  42
3:  bar
```

We can see this time `xyz` does not show，because the last `.*` does not belong to any `group`. Now let's see how to use `region` method. Here is the code example:

```java
Pattern p = Pattern.compile("(.* )(.* )");
String text = "foo 42 bar xyz";
Matcher matcher = p.matcher(text);
matcher.region(1, text.length());
matcher.find();
```

The `matcher.region(1, text.length())` is to set the start index and the end index of the text that the matcher will search for. As you can see, we have set the matcher to search from text index `1` till the end of the text, so the first character(which is index 0) of `text` will be ignored. Here's the search code:

```java
for (int i = 0; i <= matcher.groupCount(); i++) {
    System.out.println(i + ": " + matcher.group(i));
}
```

And here is the result:

```
0: oo 42 bar
1: oo 42
2: bar
```

We can see the first character in `text`, which is `f` of the `foo`, is bypassed. We can also see from the result that Java RegExp engine is greedy by default, because the group 1 returns `oo 42`, which matches maximum text of pattern `(.* )`. Now let's see the difference between `matches` and `find` methods of `Matcher` class.

The `matches` method will try to match the pattern with whole text. If the pattern doesn't match the whole text, the method fails. Otherwise, if there are contents in the text that can match the pattern, the `find` method will match it. Here is the code example:

```java
Pattern p = Pattern.compile("[a-z][a-z][a-z]");
String text = "foo 42 bar xyz";
Matcher matcher = p.matcher(text);
```

I have written a pattern that will match three consecutive alphabets. Now let's try to use 'matches()' method firstly:

```java
System.out.println(matcher.matches());
```

The result is `false`. Because the pattern can't match the whole `text`. Now let's try `find()` method:

```java
System.out.println(matcher.find());
```

The result is `true`, because the pattern can match partial contents in text, which could be `foo`. And each time we call `find()`, it will try to search the next partial text that can match the pattern. Let's see the code example:

```java
Pattern p = Pattern.compile("[a-z][a-z][a-z]");
String text = "foo 42 bar xyz";
Matcher matcher = p.matcher(text);

while (matcher.find()) {
    System.out.println(matcher.group());
}
```

As the example shown above, we will call `find()` method until it can't find anything more. Here's the result:

```
foo
bar
xyz
```

As the result shown above, we can see each time the `find()` method call match the pattern with partial text. We used `group()` method to return the whole matched text. Because our pattern has parentheses, so we can also use `group` method to get the substring we want. Here's the code example:

```java
Pattern p = Pattern.compile("([a-z])([a-z])([a-z])");
String text = "foo 42 bar xyz";
Matcher matcher = p.matcher(text);

while (matcher.find()) {
    System.out.println(matcher.group(1));
}
```

Because our pattern is `([a-z])([a-z])([a-z])`，so `group(1)` will be the first `[a-z]` in matched text. Here's the result:

```
f
b
x
```

The result is the first group in the pattern for each found text. Please note both `matches` and `find` will alter the internal state of the matcher. As we can see above, each `find` will search next part of the text. Let's see this code example:

```java
Pattern p = Pattern.compile("([a-z])([a-z])([a-z])");
String text = "foo";
Matcher matcher = p.matcher(text);

System.out.println(matcher.matches());

while (matcher.find()) {
    System.out.println(matcher.group(1));
}
```

We used `matches` method to match `text` will the pattern, and it will succeed. So the `find` method won't match anything at all, because the previous `matches` method already processed the text and matches the text successfully. The result of above code will be `true` and nothing else. If we remove the `matcher.matches()`, then the result will be `f`, which is the `matcher.group(1)` output.


Non-capturing group is a concept that supports you to group something in the pattern but don't count it in the result. Let's see this code example:

```java
Pattern p = Pattern.compile("([a-z])([a-z])([a-z])");
String text = "foo bar";
Matcher matcher = p.matcher(text);

while (matcher.find()) {
    System.out.println(matcher.group(1));
}
```

The pattern is to match three consecutive alphabets, so `foo` and `bar` will match for each `find()`. And group 1 is the first `[a-z]`, so it will match the first alphabet of `foo` and `bar`. The result of above code is:

```
f
b
```

Which is the same like we expected. Now let's modify the pattern a little bit:

```java
Pattern p = Pattern.compile("(?:[a-z])([a-z])([a-z])");
```

Please note we have added `?:` into first group, which means this group is a non-capturing group. The matcher will still match it, but this group will not be counted in the result.

So the `matcher.group(1)` this time will become the second `[a-z]`. Let's rerun the codes and here's the result:

```
o
a
```

Please note the first group, `f` in `foo` and `b` in `bar`, are bypassed. Because the first group has been marked as non-capturing group with `?:`.
