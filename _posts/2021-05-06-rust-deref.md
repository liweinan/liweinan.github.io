---
title: Rust Deref Example
---

Here is an example showing the `Deref` usage:

```rust
struct Foo {
    pub val: String,
}

impl Deref for Foo {
    type Target = String;

    fn deref(&self) -> &Self::Target {
        &self.val
    }
}

fn ref_val(f: &Foo) {
    println!("{}", **f);
}

#[test]
pub fn test_deref() {
    let f = Foo { val: "foo".to_string() };
    println!("{}", *f);
    ref_val(&f);
}
```

Please note in above inside the `ref_val(f: &Foo)` function, it needs `**f` to deref the `f` object correctly.

Here is the code output:

![](https://raw.githubusercontent.com/liweinan/blogpic2021i/master/may06/WechatIMG103.png)






