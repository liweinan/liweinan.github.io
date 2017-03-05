---
title: Using Papers And Manuscripts To Add Academic Citations in Github Pages
---

In this article I'd like to share with you how to use _Papers 3_ and _Manuscripts_ under _MacOS_ to add academic citations in your github pages blog.

Unfortunately, the _Github Pages_ does not support `jekyll-scholar` by default[^versions], which means you can not use the graceful _BibTex_ support provided by `jekyll-scholar` plugin. This is painful, but this is reality.

[^versions]: _[Github Pages Dependency versions](https://pages.github.com/versions/)_

There are several ways we can overcome it. For example, we can fully discard the built-in support of _Jekyll_ provided by _Github_ and generate our blog site locally. In this way, we can take full control of our own website. But this is even more painful, because _Github_ has eased our maintenance work a lot by generating _HTML_ files on-the-fly from our _Markdown_ files. So I don't want to discard the _Github_ built-in support for _Jekyll_ just for academic citation support.

The next solution is to convert the _BibTex_ file to _Markdown_ file locally, and add it to our posts. There is a tool that can do it actually[^bibtextomd].

[^bibtextomd]: _[
Convert BibTeX entries to formatted Markdown for use with the kramdown processor](https://github.com/bryanwweber/bibtextomd)_
