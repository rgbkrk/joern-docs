
Guidelines to create joern queries

**Use the template below to begin with.** You can place this code
   anywhere you like. As a recommendation, place it in a sub-directory
   of $JOERN/libjoern/python as that will be the current working
   directory when running queries.

```lang-none
# query.py
from py2neo import neo4j, gremlin
import sys, os
sys.path.append(os.getcwd())

from libjoern import JoernSteps

j = JoernSteps()

query = """ """

for x in j.executeGremlinCmd(query):
    print x
```

 **Test the empty query.**: Enter the working directory and run the
   query to make sure everything is setup correctly.

```
$ cd $JOERN/libjoern/python/
$ python2 ./path/to/query.py
```

 **Choose start nodes.** Use one of the utility functions provided
   in
   [joernsteps.groovy](https://github.com/fabsx00/joern/blob/master/libjoern/python/joernsteps.groovy)
   such as *getFunctionByName*, *getFunctionByNameRegex* or
   *getParametersOfType* to select start nodes for your traversal. If
   many nodes are returned, it is highly recommended to select a
   number of samples instead of the complete set of nodes. That way,
   results will be returned instantly while developing the query. As
   an extreme example, you may begin with only a single sample
   function for the query you are attempting to build.
   

```lang-none
query = """
	getFunctionByName('function_matching_the_query').signature
	"""
```

 **Append to the query.** Successively add to the end of the query
   and observe output after each step by checking the 'code' and
   'type' attributes. This has two very important advantages over
   writing the query in one go: (1) You will see immediately when a
   pipe is simply incorrect (2) you will get a good feeling for the
   runtime of the pipes.

```lang-none

# Are the conditions returned?

query = """
	getFunctionByName('function_matching_the_query')
	.functionToConditions().code

"""
```

```lang-none

# Does my filter discard what I want to discard?

query = """
	getFunctionByName('function_matching_the_query')
	.functionToConditions().filter{ !it.code.contains('foo') }
	.code
"""
```

 **Examine nodes and edges.** You might not always know the
   attributes of the different node types by heart. In this case, you
   can have gremlin return the complete nodes as well as outgoing and
   incoming edges. **Warning!** Returning complete nodes/edges is only
   suited for debugging. You may run out of heap space if you return
   hundreds of thousands of complete nodes this way.

```lang-none

# Get complete nodes: exposes all attributes

query = """
	getFunctionByName('function_matching_the_query')
	.functionToConditions()
"""
```

```lang-none

# Get outgoing edges. Exposes types of edges and its attributes

query = """
	getFunctionByName('function_matching_the_query')
	.functionToConditions().outE()
"""
```

**Use debugging scripts if necessary** To debug queries, it might be useful to
   plot abstract syntax trees and control flow graphs of
   functions. Use the following sample scripts to plot ASTs and CFGs
   respectively.

AST-plotting
```lang-none
$ python2 ./examples/dotAST $functionName > foo.dot
$ dot -Tpng foo.dot > foo.png
```

CFG-plotting
```lang-none
$ python2 ./examples/dotCFG $functionName > foo.dot
$ dot -Tpng foo.dot > foo.png
```

Hints:

- Try your queries on single functions or small sub sets of the code
  you want to examine first. That way, you will be able to tell the
  difference between a slow query and one that runs wild completely.

- Filtering early in queries is important to gain good
  performance. Keep in mind that Gremlin is imperative. It will not
  re-order your filters to gain optimal performance.

- Before writing anything yourself, check if joernsteps.groovy
  implements the functionality you need.


