---
title: An Introduction to Visual Paradigm
abstract: There are many UML modeling tools on the market. In this article, I'd like to introduce the one I used in my daily work called Visual Paradigm.
---

## _{{ page.title }}_

{{ page.abstract }}

I have used many UML and modeling tools in my career, some are open-sourced and some are commercial softwares. There are many options in this field you can choose from, such as _ArgoUML_[^argo], StarUML[^star], OmniGraffle[^omni], or etc. You can check the links of these tools I've provided to you to see if they can fit your requirements.

[^argo]: [ArgoUML](http://argouml.tigris.org/)
[^star]: [StarUML 2](http://staruml.io/)
[^omni]: [OmniGraffle 7 for Mac](https://www.omnigroup.com/omnigraffle)

The tool I used in my daily work is called  _Visual Paradigm_[^vpuml](abbviated as _VP_). Here is a brief introduction of this tool[^vpintro]:

> This software is a UML CASE Tool supporting UML 2, SysML and Business Process Modeling Notation (BPMN)

[^vpuml]: [Visual Paradigm](https://www.visual-paradigm.com)
[^vpintro]: [https://en.wikipedia.org/wiki/Visual_Paradigm_for_UML](https://en.wikipedia.org/wiki/Visual_Paradigm_for_UML)

There are many features provided by _VP_, not limited to _UML_ diagrams:

![VP Features]({{ site.url }}/assets/2017-03-06-vp-features.png)

As the diagram shown above, you can see there are a lot of features provided by the tool. I use this tool mainly for its reversing engineering capabilities to generate _UML Class Diagram_ and _Sequence Diagram_ from _Java_ or _C++_ codes. As you can see in the following diagram, _VP_ can generate _UML 2 Class Diagram_ directly from _Java Class File_:

![VP Reverse Class]({{ site.url }}/assets/2017-03-06-vp-reverse-class.png)

The generated class diagram is like this:

![VP Generated Class]({{ site.url }}/assets/2017-03-06-vp-generated-class.png)

And I can also generate class diagram for multiple classes to analyze their relationships:

![VP Generated Classes]({{ site.url }}/assets/2017-03-06-vp-generated-multiple-classes.png)

_VP_ can also generate sequence diagram directly from class methods:

![VP Reverse Sequence]({{ site.url }}/assets/2017-03-06-vp-reverse-sequence.png)

Here is the generated sequence diagram that can be helpful to analyze the program logic:

![VP Reverse Sequence]({{ site.url }}/assets/2017-03-06-vp-generated-sequence.png)

In this article, I have shown the basic usages of _Visual Paradigm_ from a programmer's perspecitve. For project managers and designers, I believe these customers can explore more values from the tool.

_References_

---
