# turtle.tmbundle #
===============

Totally awesome bundle for Turtle – the terse RDF triple language.

It consists of:

+ Language grammar
+ Some snippets (prefixes and document skeleton)
+ Basic auto-completion (only URIrefs from RDF/S graphs)
+ Commands for instant graph visualization of a knowledge base (requires Graphviz and Raptor)

## Language grammar ## 

For now it contains only a provisionally language grammar that has the following limits:

+ only supports prefix notation for URIrefs
+ supports comments
+ supports complete SPO statements
+ supports shorthand notation for multiple PO-pairs
+ supports URI expressions, literals, typed literals, bnodes

## Graph visualization ##

In order to use this functionality you must have a working installation of [Graphviz](http://graphviz.org) (especially the dot command) and the [Raptor RDF syntax library](http://librdf.org/raptor/). When properly installed (locatable through PATHs) everything should work fine ootb. However, in some cases you must explicitly tell Textmate where to find them. You can do this by introducing two configuration variables (Textmate -> Preferences -> Variables):

`TM_DOT` absolute path to the dot binary (part of Graphviz)
`TM_RAPPER` absoluter path to the rapper binary (part of Raptor)

By hitting `CMD + R` the active TTL document will be visualized on-the-fly in a Textmate HTML preview window. Because these preview windows are driven by Safari's WebKit rendering engine, PDF documents will be rendered right in-line. That way your "edit knowledge base --> visualize" workflow will be super intuitive and wont get interrupted by switching to separate PDF viewer app for viewing the visualization.

By hitting `SHIFT + ALT + CMD + S` the active TTL document will be visualized and saved to a PDF document.





