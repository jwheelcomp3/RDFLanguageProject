RDFLanguageProject
==================

Project for Programming Languages Paradigms course creating an interpreted language that generates a subset of RDF/XML.


Authors:
* Matt Walston
* Jared Wheeler


Introduction
RDF is a W3C standard for Linked Data on the Semantic Web.  Specifications for RDF/XML, the output of this language, are located at: http://www.w3.org/TR/REC-rdf-syntax/.

RDF is made of items and verbs which link the items.  Items are described within the RDF/XML with Description tags, with the verb tags nested, referring to other items.  The specifications above are a good guide to RDF/XML, there are also guides online and in print format to the theory of RDF and the construction fo RDF/XML.

However, XML is not easily human readable, so this declarative language seeks to provide a slightly more human readable format which automatically generates the RDF/XML.  This language provides a strong variety of RDF/XML tools, and therefore can have some results that are not true RDF/XML, and the results should therefore be checked with the W3C RDF Validator located at http://www.w3.org/RDF/Validator/.


Grammar

S ->	A				
A	-> N | D				
N	-> namespace id = U N	| empty			
D	-> U B D	| L B D	| G B D	| blank B D	| empty
U	-> ' literal '				
L	-> local id				
G	-> global id				
B	-> { IB }				
IB	-> NV DC IB	| empty	
NV	-> literal::literal	
DC	-> C	| D			
C	-> U TM	| T			
TM	-> T	| empty			
T	-> { VB }				
VB -> " CL "	| D			
CL -> literal CL	| empty			

S is the start state.
A encompases the entire program.
N is where all namespace declarations are going to take place.
D is the start of a definition, determining if it will be referencing a preexisting item, a local definition, a global definition, or an unnamed node.
U governs the URI references.
L defines local rdf:nodeType name.
G defines an rdf:ID name.
B indicates the body of the defined resource, surrounded by brackets.
IB is the basic set up for a predicate.
NV is the structure of the namespace and predicate for use.
DC determines if a resource or a sub-defined local item will be connected by the predicate.
C and TM allow the use of a URI for linking to external resource or for use as a rdf:dataType definition with literal data.
T allows a further nesting of items within the predicate, indicated by brackets.
VB will determine if the nested item is a literal or an unnamed node declaration.
CL processes the literal data within the literal of a predicate.


Language

local, global, and blank indicate the types of rdf:Description that should be generated.  Local corresponds to an rdf:nodeType; global to rdf:ID, and blank to an unnamed node.  namespace is a keyword to indicate the definition of a namespace.  The rdf namespace is provided by default.

literal indicates a string value; the literal within the U state is a valid URI, the literal in the CL state can be any data, the first literal in the NV state must be either rdf or correspond to a namespace which was defined at the start of the program; the second literal should be a predicate from that ontology.


Example inputs are located within the examples folder.



Runtime Requirements
Requires Ruby 1.9.3 or newer.


Execution Instructions


