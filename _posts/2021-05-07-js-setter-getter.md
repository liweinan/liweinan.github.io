---
title: Defining Javascript Getter And Setter Functions
---

Defining a function inside object:

```javascript
let o = {
    a() {
        return 42;
    }
};

console.log(o);
console.log(o.a);
console.log(o.a());
```

Output:

![](https://raw.githubusercontent.com/liweinan/blogpic2021i/master/may07/4651FA0A-BBD2-4600-BB38-28B7B519ABD1.png)

From above we can see `a()` is an ordinary function.

Now rewriting `a()` as a getter function:

```javascript
// -----------------------

let o2 = {
    get a() {
        return 42;
    }
};

console.log(o2);
console.log(o2.a);
// console.log(o2.a()); // Uncaught TypeError: o2.a is not a function
```

In above code the `a()` is defined with `get` so it’s a getter function. Here’s the output of the code:

![](https://raw.githubusercontent.com/liweinan/blogpic2021i/master/may07/24253504-3781-48C5-9204-7A638719C781.png)

Above is the getter function. To define a setter function, here is the example:

```javascript
let o3 = {
    v: 0,
    set a(x) {
        this.v = x;
    }
};

console.log(o3);
o3.a = 42;
console.log(o3.v);
```

In above we define a function `a()` and prefixed it with `set`, and then we can set the value of `v` by `o3.a = 42`.

Here is the output of the code:

![](https://raw.githubusercontent.com/liweinan/blogpic2021i/master/may07/F9BC463B-86DD-4884-82EA-903F21D0FE07.png)

Finally here is the code showing how to add getter and setter functions by the `Object.defineProperties()` function:

```javascript
// ------------------------

let o4 = {
    v: 0
};

Object.defineProperties(o4, {
    'g': {
        get: function () {
            return this.v;
        }
    },
    's': {
        set: function (x) {
            this.v = x;
        }
    }
});

console.log(o4.g);
o4.s = 42;
console.log(o4.g);
```

Here is the output of the above code:

![](https://raw.githubusercontent.com/liweinan/blogpic2021i/master/may07/81BC3FDB-6213-4B76-8A84-894EF19CC1E0.png)

## References

- [Object.defineProperty() - JavaScript MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/defineProperty)
- [Working with objects - JavaScript MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Working_with_Objects#defining_getters_and_setters)

