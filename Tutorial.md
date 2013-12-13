Once you have installed joern and imported code, you are ready to work
with the database. In the following, a brief overview of the database
content will be given, you will see how to formulate a query to find
missing checks of pointers returned by malloc and learn some
rudimentary Gremlin while you are at it. However, I highly recommend
to also read the
[Gremlin documentation](https://github.com/tinkerpop/gremlin/wiki).

To begin, please import some source code as follows:
	
	$ cd $JOERN
	$ java -jar bin/joern.jar $CODE_DIR/

Next, start the database server in a second terminal

	$ NEO4J/bin/neo4j console

and change into libjoern/python:

    $ cd $JOERN/libjoern/python

## The REST API

The Neo4J server offers a web interface and a web-based API (REST API)
to explore and query the database. Once your database server has been
launched, point your browser to

    http://localhost:7474/db/data/node/0
    
This is the "reference node", which is the root node of the graph
database. Starting from this node, the entire database contents
can be accessed. In particular, you can get an overview of all
existing edge types as well as the properties attached to nodes and
edges.

Of course, in practice, you will not want to use your browser to query
the database. Instead, you can use py2neo to access the REST API using
Python as we will do in the following. 

## The Directory Hierarchy

**Inspecting node properties.** Let's begin by writing a small
python-script, which outputs all nodes directly connected to the root
node:

```lang-none
import sys, os
sys.path.append(os.getcwd())
from libjoern import JoernSteps
j = JoernSteps()

# Syntax:
# g: a reference to the neo4j graph
# g.v(id): retrieve node by id.
# g.v(id).out(): all nodes immediately
# connected to the node by an
# outgoing edge.

query = """ g.v(0).out() """
for x in j.executeGremlinCmd(query): print x['data']

```

Place this script in libjoern/python/examples/explore.py and run it:

      $ python2 ./examples/foo.py
      
      {u'type': u'Directory', u'filepath': u'$CODE_DIR'}


If this works, you have successfully injected a Gremlin script into
the neo4j database using the REST API. Congratulations, btw.

As you can see from the output, the reference node has a single child
node. This node has two 'attributes': 'type' and 'filepath'. In the
joern database, each node has a 'type', in this case
'Directory'. Directory nodes in particular have a second attribute,
'filepath', which stores the complete path to the directory
represented by this node.


**Inspecting Edge Types.** Let's see where we can get by expanding
outgoing edges:

```lang-none
import sys, os
sys.path.append(os.getcwd())
from libjoern import JoernSteps
j = JoernSteps()

# Syntax
# .outE(): outgoing Edges

query = """ g.v(0).out().outE() """
for x in j.executeGremlinCmd(query): print x['type']
```

	 $ python2 ./examples/explore.py | sort | uniq -c
	
	139 IS_PARENT_DIR_OF

This shows: the Directory node itsself merely stores a filepath,
however, it is connected to the rest of the directory hierarchy by
edges of type 'IS_PARENT_DIR_OF', and thus its position in the
directory hierarchy is encoded in the graph structure.

**Filtering.** Directory nodes are connected to two types of nodes:
other directory nodes and file nodes. Let's visit only those files
placed directly in the libpurple directory:

```lang-none
# Syntax
# .filter(closure): allows you to filter incoming objects using the
# supplied closure, e.g., the anonymous function { it.type ==
# 'File'}. 'it' is the incoming pipe, which means you can treat it
# just like you would treat the return-value of out().

query = """ g.v(0).out().out().filter{ it.type == 'File' } """
for x in j.executeGremlinCmd(query):  print x['data']
```

From here on, let's see where file nodes point us:

```lang-none
query = """ g.v(0).out().out().filter{ it.type == 'File' }.out().type """
for x in j.executeGremlinCmd(query): print x
```

File nodes are linked to all definitions they contain, i.e., type,
variable and function definitions and this is where things start to
become interesting.

## The Node Index

Before we discuss function definitions, let's quickly take a look at
the node index, which you will probably need to make use of in all but
the most basic scripts. Instead of walking the graph database from its
root node, you can make use of the node index to lookup nodes by their
properties. Under the hood, this index is implemented as an Apache
Lucene Index and thus you can make use of the full Lucene query
language to retrieve nodes. Let's see some examples.

**Lookups by a single attribute.** Lookups of nodes by a single
attribute can be expressed elegantly using Gremlin. As an example,
consider the following query to lookup all functions of the code base:

```lang-none
query = """ g.idx('nodeIndex')[[type:'Function']] """

for x in j.executeGremlinCmd(query): print x
```
**Arbitrary Lucene Queries** Since the node index is an Apache Lucene
index, you can use the Lucene query language to formulate more evolved
queries (see
http://lucene.apache.org/core/2_9_4/queryparsersyntax.html). Unfortunately,
using arbitrary lucene queries via Gremlin is rather clumsy. As an
example, consider the following query to retrieve the ids all
functions matching *alloc*.

```lang-none
query = """

luceneQuery = 'type:"Function" AND functionName:*alloc*'

new com.tinkerpop.blueprints.pgm.impls.neo4j.util.Neo4jVertexSequence(
  g.getRawGraph().index().forNodes("nodeIndex")
  .query(luceneQuery), g)._().id
"""

for x in j.executeGremlinCmd(query): print x
```

Fortunately, libjoern offers a shorthand to express queries of this
kind:

```lang-none
query = """ queryNodeIndex('type:"Function" AND functionName:*alloc*').id """

for x in j.executeGremlinCmd(query): print x
```

**Mid-query lookups.** In the previous example, the index was used to
obtain start nodes for a query. However, in many cases, it is
necessary to perform index-lookups in the middle of a query based on
attributes of the nodes traversed so far. libjoern defines a
'queryNodeIndex'-step for this as well, which takes a Lucene query as
input and returns all nodes matching the query. As an example, the
following query returns the code of all Assignment expressions in
functions matching *create*. Note that AssignmentExpr-nodes are
AST-nodes, which we will discuss in the next section.

```lang-none
query = """
  queryNodeIndex('type:"Function" AND functionName:*create*').id
  .transform{ 'functionId:' + it + ' AND type:AssignmentExpr' }
  .queryToNodes().code
"""

for x in j.executeGremlinCmd(query): print x
```

## Function Definitions

One of the core ideas of joern is to store different graph
representations of code, suited for different code analysis tasks, in
a single edge-labeled graph. This allows to switch between different
representations in a single database query, which enables us to
formulate very powerful queries as we will see in this section. For
functions, joern gives us access to the following graphs:

* Abstract Syntax Trees (AST)
* Control Flow Graphs (CFG)
* Interprocedural Control Flow Graphs (ICFG)
* USE/DEF Graphs (UDG)
* Data Dependency Graphs (DDG)

Let's see how we can leverage some of these by incrementally building
a simple sample query: Finding calls to malloc where the return value
is dereferenced but not checked for NULL.

By default joern only generates ASTs and CFGs, so please shutdown the
database and run the following tools from the $JOERN directory first:

	$ cd $JOERN
	$ java -jar bin/udg.jar
	$ java -jar bin/ddg.jar

Note that this query will be intraprocedural and thus we do not
generate interprocedural control flow graphs byt only USE/DEF Graphs
and Data Dependency Graphs.

**Retrieving AST nodes.** First, we retrieve all l-values of
  assignments from the AST where malloc is a direct right value: 

```lang-none
query = """
   queryNodeIndex('type:CallExpression AND code:malloc*')
   .in('IS_AST_PARENT').filter{ it.type == 'AssignmentExpr'}
   .assignmentToLval().code
"""
for x in j.executeGremlinCmd(query): print x
```

Note, that 'assignmentToLval' is simply a step defined in libjoern which
walks you to the l-value node from an assignment node. Since
retrieving calls by name is a common operation, a shorthand has been
defined in libjoern: getCallsTo:

```lang-none
query = """
   getCallsTo('malloc').in('IS_AST_PARENT')
   .filter{ it.type == 'AssignmentExpr'}
   .assignmentToLval().code
"""
for x in j.executeGremlinCmd(query): print x
```

**User-defined steps.** Defining shorthands, so called 'user defined
steps', allows you to reduce duplicate code in your queries and adapt
the query language to your needs. It also greatly increases
readability, so I would  highly recommend making use of this language
feature. For more information, see the Gremlin documentation [x] and
the steps pre-defined in libjoern [x].

**Filtering Calls in Conditions.** Next, we want to make sure that all
calls to malloc directly inside a condition are discarded, since these
are checked for NULL. To do this, we filter if the sub-tree of the AST
rooted at this basic block is a 'Condition' node. Before we do this,
however, we save the l-value in the variable 'lval' using a
side-effect. This allows us to make use of the l-val in subsequent
steps.

```lang-none
query = """
   getCallsTo('malloc').in('IS_AST_PARENT')
   .filter{ it.type == 'AssignmentExpr'}
   .assignmentToLval().sideEffect{lval = it.code}
   .astNodeToBasicBlockRoot().filter{ it.type != 'Condition'}.code

"""
for x in j.executeGremlinCmd(query): print x
```

**Transition into the DDG.** So far, we have only briefly touched the
basic block of this instruction and have only considered the
information in the AST. Now we do something interesting: We will jump
from the AST into the Data Dependency Graph (DDG) using the
'astNodeToBasicBlock' step. We do this because the DDG allows us to
easily inspect data flow.

**Data Flow Analysis.** The Data Dependency Graph makes explicit
which basic blocks are reached by the definitions of variables (see
"Reaching Definitions"), and by definition, compiler folks mean
"Assignment". It is thus very easy for us to see where the pointer
initialized by malloc is used before being reassigned. We do this by
following edges of type "REACHES" in the data-dependency graph:

```lang-none
query = """
   getCallsTo('malloc').in('IS_AST_PARENT')
   .filter{ it.type == 'AssignmentExpr'}
   .assignmentToLval().sideEffect{lval = it.code}
   .astNodeToBasicBlockRoot().filter{ it.type != 'Condition'}
   .astNodeToBasicBlock()
   .outE('REACHES').filter{it.var.equals(lval)}.inV()
"""
for x in j.executeGremlinCmd(query): print x
```

The last line deserves an explanation: We expand outgoing edges of
type 'REACHES' and keep only those, which are labeled by the value we
are tracing (lval). The step 'inV' then simply returns the node on the
other end of the 'REACHES' edge. To simplify future queries, we can
again place this code in a step: reachesUnaltered, however, notice
that the syntax becomes a bit clumsy when passing more than one
variable to steps (I'm pretty sure there is a better way).

```lang-none
query = """
   getCallsTo('malloc').in('IS_AST_PARENT')
   .filter{ it.type == 'AssignmentExpr'}
   .assignmentToLval().sideEffect{lval = it.code}
   .astNodeToBasicBlockRoot().filter{ it.type != 'Condition'}
   .astNodeToBasicBlock().transform{ [it,lval] }.reachesUnaltered()
"""
for x in j.executeGremlinCmd(query): print x
```

**Grouping by call.** We group by call id using the Gremlin step
'groupBy'. This is a so called side-effect step, which fills the
dictionary as a side effect but returns the element just processed. To
obtain the result of the last side-effect (i.e., the dictionary), the
Gremlin step 'cap' is used. As a result. we obtain a dictionary where
keys are call-ids and values are lists of basic blocks accessing the
l-value.

```lang-none
query = """
   getCallsTo('malloc').sideEffect{callId = it.id}.in('IS_AST_PARENT')
   .filter{ it.type == 'AssignmentExpr'}
   .assignmentToLval().sideEffect{lval = it.code}
   .astNodeToBasicBlockRoot().filter{ it.type != 'Condition'}
   .astNodeToBasicBlock().transform{ [it,lval] }.reachesUnaltered()
   .groupBy{callId}{ it.code }.cap
"""

for x in j.executeGremlinCmd(query):
    for (k,v) in x.iteritems():
        print v
```

**Adapting output.** Finally, we adapt the output so that we can
easiely locate the reported code fragments: Instead of just keeping
the code of each block reached, we also record the type of its AST
subtree, allowing us to spot conditions. In addition, we use the
pre-defined step 'functionToLocationRow' to obtain the functions
filename, name and position in the file.

```lang-none
query = """
   getCallsTo('g_malloc').sideEffect{callId=it.id;funcId=it.functionId}.in('IS_AST_PARENT')
   .filter{ it.type == 'AssignmentExpr'}
   .assignmentToLval().sideEffect{lval = it.code}
   .astNodeToBasicBlockRoot().filter{ it.type != 'Condition'}
   .astNodeToBasicBlock().transform{ [it,lval] }.reachesUnaltered()
   .sideEffect{blockType = it.basicBlockToAST().type;
   funcRow = g.v(it.functionId).functionToLocationRow() }
   .groupBy{callId}{ [blockType, it.code, funcRow] }.cap
"""
print 'Results'

for x in j.executeGremlinCmd(query):
    for (k,v) in x.iteritems():       
        nonConditions = [x for x in v if x[0][0] != 'Condition']
        conditions = [x for x in v if x[0][0] == 'Condition']
        if (len(conditions) == 0 and len(nonConditions) > 0):
            print '==='  + str(v[0][2])
```
