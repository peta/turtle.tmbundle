# turtle.tmbundle
---------------------------------------------------------------------

Totally awesome bundle for Turtle – the terse RDF triple language.

It consists of:

+ Language grammar
+ Some snippets (prefixes and document skeleton)
+ Basic auto-completion (only URIrefs from RDF/S graphs)
+ Commands for instant graph visualization of a knowledge base (requires Graphviz and Raptor)

#### Roadmap

+ Extend language grammar
	+ matching the official parser spec
	+ support for object lists (S P {O1,O...,On} )
	+ ~~@base directive~~
	+ support full IRIs (not only URIrefs) as SPOs
	+ multiline literals
+ Toggle/fold for whole triple blocks and multiline literals
+ Autocomplete (with dropdown list?)
	+ for literal datatypes (for now only XSD)
	+ for literal language tags
	+ for prefixes and their according IRI (automagically fed by prefix.cc)
	+ for resource IRIs/QNames
+ Quick documentation lookup for selected resource IRIs/QNames 

## Language grammar 

For now it contains only a provisionally language grammar that has the following limits:

+ only supports prefix notation for URIrefs
+ supports comments
+ supports complete SPO statements
+ supports predicate lists, object lists
+ supports URI expressions, literals, typed literals, bnodes

## Graph visualization

In order to use this functionality you must have a working installation of [Graphviz](http://graphviz.org) (especially the dot command) and the [Raptor RDF syntax library](http://librdf.org/raptor/). When properly installed (locatable through PATHs) everything should work fine ootb. However, in some cases you must explicitly tell Textmate where to find them. You can do this by introducing two configuration variables (Textmate -> Preferences -> Variables):

`TM_DOT` absolute path to the dot binary (part of Graphviz)
`TM_RAPPER` absoluter path to the rapper binary (part of Raptor)

By hitting `CMD + R` the active TTL document will be visualized on-the-fly in a Textmate HTML preview window. Because these preview windows are driven by Safari's WebKit rendering engine, PDF documents will be rendered right in-line. That way your "edit knowledge base --> visualize" workflow will be super intuitive and wont get interrupted by switching to separate PDF viewer app for viewing the visualization.

By hitting `SHIFT + ALT + CMD + S` the active TTL document will be visualized and saved to a PDF document.

## Installation

Just download/clone this repository, and assert that the "parent" directory (which contains all folders/files of this repo) is named "turtle.tmbundle". Double click it and Textmate should know what to do. Alternatively just open the `turtle.tmbundle` package with Textmate. 

## Meta

Turtle.tmbundle was created by [Peter Geil](http://github.com/peta). Feedback is highly welcome – if you find a bug, have a feature request or simply want to contribute something, please visit the official GitHub repository at [https://github.com/peta/turtle.tmbundle](https://github.com/peta/turtle.tmbundle)
