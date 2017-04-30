---
title: Using Papers And Manuscripts To Add Academic Citations into GitHub Pages
abstract: In this article I'd like to share with you how to use Papers 3 and Manuscripts under MacOS to add academic citations into your GitHub Pages.
---

{{ page.abstract }}

Unfortunately, _GitHub Pages_ does not support `jekyll-scholar` plugin by default[^versions], which means you can not use the graceful _BibTex_ support provided by the plugin. This is painful, but this is the reality.

[^versions]: [GitHub Pages Dependency versions](https://pages.github.com/versions/)

Nevertheless, there are several ways we can overcome it to some extent. For example, we can fully discard the built-in support of _Jekyll_ provided by _GitHub_ and generate our whole blog site locally and push it online. In this way, we can take full control of our own website, but this is even more painful, because _GitHub_ has eased our maintenance work a lot by generating _HTML_ files on-the-fly from our _Markdown_ files with its built-in _Jekyll_ engine. I don't want to discard the _GitHub_ built-in support for _Jekyll_ just for academic citation support.

The next solution is to convert the _BibTex_ file into _Markdown_ format locally, and then we can add the converted _Markdown_ text into our posts. There is a tool that can do it actually[^bibtextomd].

[^bibtextomd]: [Convert BibTeX entries to formatted Markdown for use with the kramdown processor](https://github.com/bryanwweber/bibtextomd)

The third solution is to use _javascript_ library that can convert _BibTex_ formatted text into _HTML_ format on-the-fly. There is a library that can do this[^bipub].

[^bipub]: [bib-publication-list to automatically generate an interactive HTML publication list from a BibTeX file](https://github.com/vkaravir/bib-publication-list)

However, I want a solution that can fully control the output I need and cite it manually in my article. There are a lot of free tools that can help us to convert `.bib` file to formal citation styles, but I'd like to use some professional tools that can ensure the correctness of the output and can support multiple citation styles like _APA_, _MLA_, _Chicago_, etc[^citestyle].

[^citestyle]: [Citation Styles: APA, MLA, Chicago, Turabian, IEEE: Home](http://pitt.libguides.com/citationhelp)

To achieve this goal, we can use several professional academic reference managers such as _Mendeley_ or _Papers_. My favorite tool on _MacOS_ is _Papers 3_. It can export paper reference as _BibTex_ library file like this:

![bibtexexport]({{ site.url }}/assets/bibtexexport.png)

I can fully control the exported citation style in _Papars 3_ with its help. After the export is done, we get the `.bib` file like this:

```
exported.bib
```

We can use free tools provided by _LaTex_ family to convert the above `.bib` file to _PDF_ format, and then copy the generated citation text from the _PDF_ file into our post page. For myself, I have a paper writing software called _Manuscripts_ that can do this. _Manuscripts_ has a feature to import `.bib` file and generate the bibliography for us:

![importbib]({{ site.url }}/assets/importbib.png)

The generated bibliography conforms to formal formats:

![bib]({{ site.url }}/assets/bib.png)

We can copy the citation text into our post. Here is the example how I can use it in this post:

```markdown
(E & Huang 2001)[^Huang2001]

[^Huang2001]: E, W. & Huang, Z., 2001. Matching Conditions in Atomistic-Continuum Modeling of Materials. _arXiv.org_, (13), p.135501. Available at: [http://arxiv.org/abs/cond-mat/0106615v1](http://arxiv.org/abs/cond-mat/0106615v1).
```

Here's the output demo:

(E & Huang 2001)[^Huang2001]

[^Huang2001]: E, W. & Huang, Z., 2001. Matching Conditions in Atomistic-Continuum Modeling of Materials. _arXiv.org_, (13), p.135501. Available at: [http://arxiv.org/abs/cond-mat/0106615v1](http://arxiv.org/abs/cond-mat/0106615v1).

In this way, we have added academic citations into this post manually.

### _References_

---
