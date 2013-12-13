Documentation of steps joern makes available.

## Selecting start nodes (Coarse node selection)

The names of utility functions for start node selection have the
following form:

```lang-none
get $NodeType by $Attribute (Regex)?
```

For example, to obtain function nodes by name using a regular
expression, you can call getFunctionByNameRegex. For exact matches,
it's simply getFunctionByName.

You can obtain a list of all start node selection functions
implemented to date by running the following command:

```lang-none
grep 'metaClass.get' $JOERN/libjoern/python/joernsteps.groovy

```

If none of these functions meet your needs, you can use *queryNodeIndex*
to run a custom Lucene query on the index, for example:

```lang-none
# Select all assignment expressions containing a '+='

queryNodeIndex('type:"AssignmentExpr" and code:*+=*')

```

Finally, you can select start nodes using an arbitrary number of start
node selectors using the *OR* utility function:

```lang-none

# Select a function if its name matches '.*foo.*' or it has a
#  parameter of type bar

OR(getFunctionsByNameRegex('.*foo.*'),  getParametersOfType('bar').astNodeToFunction() ).functionName

```

## Filtering using the AST (Fine-grained node selection)

At any point in a query and in particular after selecting start nodes,
you will want to perform a fine-grained selection of nodes. If
possible, you can simply use a regular expression, for example:

```lang-none

getCallsTo('foo').filter{ it.code.matches($regex) }.code

```

However, C/C++ is not a regular language, for example, expressions may
be nested. Fortunately, joern parses the entire code and you can make
use of the abstract syntax tree to perform exact filtering.

To achieve this, you can use two types of steps:

* **AST transformation steps.** These steps bring you from an AST node
  of a given type to one or more child nodes with a well-defined
  semantic meaning. For example, *assignmentToLval()* will navigate
  you to the left-value (lval) of an assignment node.



## Getting from one representation to another

## Data Flow Analysis

Once you have selected nodes of interest, it often becomes necessary
to analyze relationships to other nodes. In the most common case, it
is of interest whether data flow exists to the selected node from a
member of another set of nodes (sources).



