
## Database Nodes

In this section, we present the different types of database nodes
created by joern when importing code into the database. All traversals
begin by selecting a sub set of these nodes as starting points of the
analysis. This *start node selection* can be efficiently performed by
querying the *node index*, an neo4j index (see
[this page](http://docs.neo4j.org/chunked/stable/indexing.html)),
which allows nodes to be looked up by any of its attributes (e.g.,
type, id, code). See
[this page](https://github.com/fabsx00/joern/Examples.md#accessing-the-node-index)
for examples on using the node index. 

* **File and Directory Nodes (type:File/Directory).** The
  directory hierarchy is exposed by creating a node for each file and
  directory and connecting these nodes using IS_PARENT_DIR_OF and
  IS_FILE_OF edges. This "source tree" allows code to be located by
  its location in the filesystem directory hierachy, for example, this
  allows you to limit your analysis to functions contained in a
  specified sub-directory
  ([Examples on using the source tree](https://github.com/fabsx00/joern/blob/master/libjoern/python/examples/usingTheSourceTree.py)).

* **Function nodes (type: Function).** A node for each function
  (i.e. procedure) is created. The function-node itself only holds the
  function name and signature, however, it can be used to obtain the
  respective Abstract Syntax Tree and Control Flow Graph of the
  function.

* **Struct/Class declaration nodes (type: Class).** A Class-node is
  created for each structure/class identified and connected to
  file-nodes by IS_FILE_OF edges. The members of the class, i.e.,
  attribute and method declarations are connected to class-nodes by
  IS_CLASS_OF edges.

* **Abstract Syntax Tree Nodes (type:various).** Abstract syntax trees
  represent the syntactical structure of the code. They are the
  representation of choice when language constructs such as function
  calls, assignments or cast-expressions need to be located. Morever,
  this hierarchical representation exposes how language constructs are
  composed to form larger constructs. For example, a statement may
  consist of an assignment expression, which itself consists of a
  left- and right value where the right value may contain a
  multiplicative expression (see [the Wikipedia
  article](http://en.wikipedia.org/wiki/Abstract_syntax_tree) for more
  information). Abstract syntax trees are connected to their
  respective functions by IS_FUNCTION_OF_AST edges.

* **Statement Nodes (type:BasicBlock).** To analyze the control flow
  of programs, access to control flow graphs is vital. Classic control
  flow graphs consist of Basic Blocks (see
  [Wikipedia](http://en.wikipedia.org/wiki/Basic_block)) connected by
  directed edges. Joern's control flow graphs are slightly unorthodox:
  basic blocks are chopped up into their statements such that each
  statement can be placed in a separate statement-node. These
  statement-nodes are then connected using FLOWS_TO edges. This has
  shown to be a representation better suited to formulate database
  queries than control flow graphs consisting of basic blocks.

* **Symbol nodes (type:Symbol).** Data flow analysis is always
  performed with respect to a variable. Since our fuzzy parser needs
  to work even if declarations contained in header-files are missing,
  we will often encounter the situation where a "symbol" is used,
  which has not previously been declared. We approach this problem by
  creating "symbol" nodes for each identifier we encounter regardless
  of whether a declaration for this symbol is known or not. We also
  introduce symbols for postfix expressions such as 'a->b' to allow us
  to track the use of fields of structures. Symbol nodes are connected
  to all statement blocks using the symbol by USE edges and to all
  statement blocks assigning to the symbol ("definining the symbol")
  by DEF edges.

* **Variable declaration nodes (type: DeclStmt).** Finally,
  declarations of global variables are saved in declaration statement
  nodes and connected to the source file they are contained in using
  IS_FILE_OF edges.

To get a complete list of all node types and their properties,
checkout the
[output.neo4j.nodes package](https://github.com/fabsx00/joern/tree/master/src/output/neo4j/nodes).

## Database Edges

Nodes are connected by edges of the following types:

**Edges connecting the directory hierarchy to functions and declarations:**

* IS_PARENT_DIR_OF: connects directories to the files and
  sub-directories they contain

* IS_FILE_OF: connects files to the functions, variable declarations
  and statements they contain.

**Edges connecting functions to their ASTs and CFGs:**

* IS_FUNCTION_OF_AST: connects functions to their abstract syntax
  trees
* IS_FUNCTION_OF_CFG: connects functions to their CFGs

* IS_AST_OF_AST_ROOT: connects abstract syntax trees to their root
  nodes.

**AST/CFG edges**

* IS_AST_PARENT: connects parent AST nodes to their children

* IS_CFG_OF_CFG_ROOT: connects control flow graphs to the entry
  statement node

* FLOWS_TO: connects statement nodes to successors in the control flow
  graph, i.e. statements possibly executed right after the current
  statement.

* IS_BASIC_BLOCK_OF: connects statement nodes to their abstract syntax
  trees.

**Edges for Type analysis**

* IS_CLASS_OF: connects structures/classes to their members

* DECLARES: connects declaration statements to the declarations they
  contain, e.g., "int x, y" contains the two declarations "int x" and
  "int y".

**Edges for data flow analysis**

* DEF: connects symbol nodes to the AST nodes where the symbol is
  "defined", i.e., where it is first declared or assigned to.

* USE: connects symbol nodes to the AST nodes where the symbol is
  used.

* REACHES: connects statement nodes to the statements reached via
  data-flow. REACHES edges are labeled by variables.

Edges for interprocedural analysis

* IS_ARG: connects arguments to the parameters of the functions
  (possibly) called.

## Data Dependency Graphs

Joern keeps track of the symbols defined and used by statements. By
augmenting the control flow graph with this information, it is
possible to determine which statements are affected by assignments to
a variable (see
["Reaching Definitions"](http://en.wikipedia.org/wiki/Reaching_definition)). We
express this in a *data dependency graph*. The nodes of the data
dependency graph are shared with the control flow graph, i.e., there
is a node for each statement. Statement nodes assigning to a variable
are then connected to statement nodes affected by the assignment using
REACHES edges.
