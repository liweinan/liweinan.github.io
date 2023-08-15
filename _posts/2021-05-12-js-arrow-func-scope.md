---
title: Javascript Arrow Function `this` Scope
---

Here is an example showing the difference of `this` in ordinary function and arrow function:

```javascript
o1 = {
    f1: function () {
        console.log(this);
    },
    f2: () => {
        console.log(this);
    }
}
```

Here is the output:

```javascript
> o1.f1()
{ f1: [Function: f1], f2: [Function: f2] }
undefined
```

From above we can see the `this` in `f1()` refers to `o1` itself. Here is the result of `f2()`:

```javascript
> o1.f2()
<ref *1> Object [global] {
  global: [Circular *1],
  clearInterval: [Function: clearInterval],
  clearTimeout: [Function: clearTimeout],
  setInterval: [Function: setInterval],
  setTimeout: [Function: setTimeout] {
    [Symbol(nodejs.util.promisify.custom)]: [Getter]
  },
  queueMicrotask: [Function: queueMicrotask],
  performance: [Getter/Setter],
  clearImmediate: [Function: clearImmediate],
  setImmediate: [Function: setImmediate] {
    [Symbol(nodejs.util.promisify.custom)]: [Getter]
  },
  foo: [Function: foo],
  foo2: [Function: foo2],
  obj: { num: 42 },
  num: 2020,
  l: [Function: l],
  l2: [Function: l2],
  o1: { f1: [Function: f1], f2: [Function: f2] }
}
undefined
>
```

From above we can see with the arrow function, `this` refers to the parent global object in nodejs(in browser, it refers to the global `window` object).

## Reference

- [JavaScript Functions](https://www.w3schools.com/js/js_functions.asp)

