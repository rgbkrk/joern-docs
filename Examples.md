Some examples to give you an idea of how joern can be used in your work.

# Accessing the node index

To allow start nodes for traversals to be obtained quickly, joern keeps an index of all nodes, allowing you to look nodes up by their properties. Internally, this is an Apache Lucene index and thus, arbitrary Lucene queries can be used to specify nodes of interest.

To do so from Cypher, you can use queries of the following type:

    START c=node:nodeIndex($query) RETURN c    

where $query is a lucene query. For example,

    START c=node:nodeIndex('type:"CallExpression" AND functionId:"1000"') RETURN c

returns all call expressions in the the function with the id 1000.

The corresponding gremlin query is a bit clumsy because lookups of this kind are not officially supported:
    
    cmd = 'new com.tinkerpop.blueprints.pgm.impls.neo4j.util.Neo4jVertexSequence(g.getRawGraph().index().forNodes("astNodeIndex").query(\'type:"CallExpression" AND functionId:"1000"\'), g)._()'

However, when using the joernSteps library bundled with joern, this becomes:

    from libjoern import JoernSteps
    j = JoernSteps()
    cmd = """ queryNodeIndex('type:"CallExpression" AND functionId:"1000"') """
    y = j.executeGremlinCmd(cmd)

You can find more examples of how to use the node index [here](https://github.com/fabsx00/joern/blob/master/libjoern/python/examples/usingTheIndex.py).

# Search for functions by name

This complete example shows how to use gremlin from python to list all functions matching a Lucene query. As an example, when called with the argument "mai.*" it will return the filename containing the definition of "main".

     from py2neo import neo4j, gremlin

     import sys, os
     sys.path.append(os.getcwd())
     from libjoern import JoernSteps
     j = JoernSteps()

     # Get functions by name from index

     cmd = "g.idx('nodeIndex')[[functionName:'%%query%%' + '%s']]" % (sys.argv[1])
     cmd += ".sideEffect{ name = it.functionName; }.in('IS_FILE_OF').sideEffect{fname = it.filepath }";
     cmd += '.transform{ [name, fname] }.toList()'

     y = j.executeGremlinCmd(cmd)
     for x in y: print x

# Extrapolation

In this example, a similarity matrix suitable to identify functions employing similar API usage patterns is created. The example demonstrates that two cypher queries are sufficient to represent each function of the code base by the functions it calls and the types it references. With this information at hand, scikit-learn is used to create a sparse document by term matrix, apply the tf-idf weighting scheme and perform principal component analysis to extract common API usage patterns as proposed in the WOOT paper on [vulnerability extrapolation](http://user.informatik.uni-goettingen.de/~krieck/docs/2011-woot.pdf).
     
You can find the complete script here:
https://github.com/fabsx00/joern/blob/master/libjoern/python/examples/extrapolation.py