In this section, you will learn how to write "static tainting" queries using joern. 

Begin by importing the code and running dataFlow.sh to create data dependency graphs.

```lang-none
$ cd $JOERN
$ time java -jar bin/joern.jar $CODEBASE
$ ./dataFlow.sh

```

Select a source of interest, for example, the libc function
*recv*. Tell joern that *recv* taints its second argument. The DDGs of
affected functions will be recalculated.

```lang-none
$ java -jar bin/argumentTainter.jar recv 1
```

Create the following sample dork, which will return all functions
where the first argument of recv taints the second argument of memcpy
and no statement matching 'sanitizerRegex' is encountered on the path.

```lang-none
import sys, os

sys.path.append(os.getcwd())
from libjoern import JoernSteps

j = JoernSteps()

query = """
// Starting from a sink

setSinkArgument('memcpy.*', '1', '.*')
.sideEffect{ sinkCallCode = sinkCode(it) ; argCode = sinkArgCode(it); }

.dataFlowFromRegex('recv')

// create the sanitizer description, an arbitrary closure (i.e.,
// anonymous function), which can refer to sinkCallCode and
// argCode

.isNotSanitizedBy{ it.filter{it.code.contains('memset')} }

// isNotSanitizedBy returns (sourceId, sinkId) pairs
.sideEffect{ (sinkId, sourceId) = it}

// output
.transform{ g.v(sinkId) }
.functionAndFilename().sideEffect{ (funcName, fileName) = it;}
.transform{[fileName, funcName, sinkCallCode, argCode]}
"""

for x in j.executeGremlinCmd(query):
    print x
```

Start the database server and run the query.
