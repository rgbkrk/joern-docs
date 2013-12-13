
joern is a tool for robust analysis of C/C++ code. It generates
intermediate representations of code such as abstract syntax trees
(ASTs), control flow graphs (CFGs) and data dependency graphs (DDG)
from source code without the need for a working build
environment. These representations are stored in a Neo4J graph
database, allowing code bases to be searched using complex queries
formulated in graph traversal languages such as Gremlin and Cypher.

# High Level Overview


## Graph Databases

Using joern effectively, requires a good understanding of the
following two relatively new technologies:

* [The neo4j graph database.](http://www.neo4j.org/) Neo4j is an
  open-source graph database. If you have never heard of graph
  databases, take a look at the book by
  [Robinson et al.](http://info.neotechnology.com/rs/neotechnology/images/GraphDatabases_EarlyRelease.pdf).

* [The Gremlin query language.](https://github.com/tinkerpop/gremlin/wiki)
  Gremlin is an imperative language written by Marco Rodriguez. It
  allows graph traversals to be formulated for a number of different
  graph database systems including Neo4j. Gremlin was chosen as a
  graph traversal language because it can be easiely extended to
  create a domain specific traversal language.
