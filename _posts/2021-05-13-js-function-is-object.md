---
title: Javascript / Function is an object
---

In JavaScript web page it says *functions are first-class objects*:

![](https://raw.githubusercontent.com/liweinan/blogpic2021i/master/may13/67281620827454_.pic_hd.jpg)

Here is the code to set a property `x` to the function:

```javascript
f = function ppp() {
    if (ppp.x === 42) {
        console.log("ok!");
        return;
    }
    console.log("1. ppp ->", ppp);
    ppp.x = 42;
    console.log("2. ppp ->", ppp);
    console.log("typeof ppp ->", typeof ppp);
    console.log("3. ppp.x -> ", ppp.x);
    ppp();
}
```

In above code we set a property `x` to `ppp` function itself, and call itself recursively. Here is the running result:

![](https://raw.githubusercontent.com/liweinan/blogpic2021i/master/may13/C182A997-CBE3-4649-A1CC-7582C294DA80.png)

From above we can see the property `x` is set, and function is called recursively.

In addition we can also set a function to a function itself:

![](https://raw.githubusercontent.com/liweinan/blogpic2021i/master/may13/67291620827551_.pic_hd.jpg)

In above code we can see a `f()` function is added to `ppp()` function itself. Running the above code will get the result in below:

![](https://raw.githubusercontent.com/liweinan/blogpic2021i/master/may13/67301620827559_.pic_hd.jpg)

From above we can see the `ppp.f()` function can be called properly.






