---
title: Using Java RegExp Engine (01) - Group
---

I'm playing Java RegExp Engine recently and I'd like to share some use experiences with you.

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

We can see this time `xyz` does not show，because the last `.*` does not belong to any `group`.
