---
title: Using Papers And Manuscripts To Add Academic Citations in Github Pages
---

In this article I'd like to share with you how to use _Papers 3_ and _Manuscripts_ under _MacOS_ to add academic citations into your github pages.

Unfortunately, the _Github Pages_ does not support `jekyll-scholar` plugin by default[^versions], which means you can not use the graceful _BibTex_ support provided by the plugin. This is painful, but this is reality.

[^versions]: _[Github Pages Dependency versions](https://pages.github.com/versions/)_

There are several ways we can overcome it. For example, we can fully discard the built-in support of _Jekyll_ provided by _Github_ and generate our blog site locally. In this way, we can take full control of our own website. But this is even more painful, because _Github_ has eased our maintenance work a lot by generating _HTML_ files on-the-fly from our _Markdown_ files. So I don't want to discard the _Github_ built-in support for _Jekyll_ just for academic citation support.

The next solution is to convert the _BibTex_ file to _Markdown_ file locally, and add it to our posts. There is a tool that can do it actually[^bibtextomd]. I don't like this solution personally because I don't like the output it generates.

[^bibtextomd]: [Convert BibTeX entries to formatted Markdown for use with the kramdown processor](https://github.com/bryanwweber/bibtextomd)

The third solution is to use _javascript_ library that can convert _BibTex_ formatted text into _HTML_ format on-the-fly. There is a library that can do this[^bipub]. I can't use this because I can't fully control the output.

[^bipub]: [bib-publication-list to automatically generate an interactive HTML publication list from a BibTeX file](https://github.com/vkaravir/bib-publication-list)

I want a solution that can fully control the output I need and cite it manually in my article. There are a lot of free tools that can help us to convert `.bib` file to formal citation styles, but I'd like to use some professional tools that can ensure the correctness of the output and can support multiple citation styles like _APA_, _MLA_, _Chicago_, etc[^citestyle].

[^citestyle]: [Citation Styles: APA, MLA, Chicago, Turabian, IEEE: Home](http://pitt.libguides.com/citationhelp)

To achieve this goal, we can use professional academic reference managers such as _Mendeley_ or _Papers_. My favorite tool on Mac is _Papers 3_. It can export paper reference as _BibTex_ library file like this:

![bibtexexport]({{ site.url }}/assets/bibtexexport.png)

And I can control the exported citation style in _Papars 3_. After the export is done, we have the exported `.bib` file:

```
exported.bib
```

We can use free tools provided by _LaTex_ family to convert above `.bib` file to `PDF` format, and then copy the generated citation text from the pdf. For myself, I have a paper writing software called _Manuscripts_ and feel happy to use it in my daily writing process.

_Manuscripts_ has a feature to import `.bib` file and generate the bibliography for us:

![importbib]({{ site.url }}/assets/importbib.png)

It's nice and clean:

![bib]({{ site.url }}/assets/bib.png)

We can copy the citation text into our blog post and everything is fully under our control. Here is the example how I can use it in this post:

```markdown
(E & Huang 2001)[^Huang2001]

[^Huang2001]: E, W. & Huang, Z., 2001. Matching Conditions in Atomistic-Continuum Modeling of Materials. _arXiv.org_, (13), p.135501. Available at: [http://arxiv.org/abs/cond-mat/0106615v1](http://arxiv.org/abs/cond-mat/0106615v1).
```

Here's the output demo:

(E & Huang 2001)[^Huang2001]

[^Huang2001]: E, W. & Huang, Z., 2001. Matching Conditions in Atomistic-Continuum Modeling of Materials. _arXiv.org_, (13), p.135501. Available at: [http://arxiv.org/abs/cond-mat/0106615v1](http://arxiv.org/abs/cond-mat/0106615v1).

In this way, we have added academic citations into this post in a manual, controllable way.
