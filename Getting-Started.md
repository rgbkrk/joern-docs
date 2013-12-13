This guide will walk you through the steps of installing joern, importing code and accessing the database using Python scripts.

# Installation

Make sure the following dependencies are installed:

- A Java Virtual Machine 1.7 such as OpenJDK-7's or Oracle's JVM.
- Neo4J 1.9 community edition: http://www.neo4j.org/download
- py2neo - a Python library for neo4: http://py2neo.org (Version 1.5. Note that version 1.6 no longer contains the Gremlin module)
- Apache Ant build tool (tested with version 1.9.2)

**Please note that joern currently does not build with Java 1.6, e.g.,
  OpenJDK-6.**

## Building

To get the most recent version of
joern, you can clone the git repository and build from source. To do
so, please install the Apache Ant build tool and a Java 7 SDK first
and then perform the following steps:

Clone the git repository and enter the joern directory ($JOERN):

      $ git clone https://github.com/fabsx00/joern.git
      $ cd joern

Download and extract dependencies in the joern directory:

      $ wget http://user.informatik.uni-goettingen.de/~fyamagu/lib.tar.gz
      $ tar xfz lib.tar.gz

You should now have a directory named "lib" in your $JOERN directory,
which contains all necessary jars.

Build the indexer (joern.jar) using ant:

    $ ant
      
The jar file will be located in $JOERN/bin/joern.jar. Simply place
this JAR file somewhere on your disk and you are done. If you are
using bash, you can optionally create the following alias in  your
~/.bashrc:

    alias joern='java -jar $JOERN/bin/joern.jar'

where $JOERN is the directory where you extracted joern.


Optionally build auxiliary tools for data flow and interprocedural
analysis:

    $ ant tools


# Importing and Accessing Code

Once joern has been installed either from source or binary, you can
begin to import code into the database by simply pointing joern.jar to
the directory containing the source code:

    $ java -jar $JOERN/bin/joern.jar $CodeDirectory

This will create a neo4j database directory (".joernIndex") in your
current working directory. Note that if the directory already exists
and contains a neo4j database, joern.jar will add the code to the
existing database. You can thus import additional code at any time. If
however, you want to create a new database, make sure to delete
'.joernIndex' prior to running joern.jar.

Additionally, for interprocedural analysis, run the following tool

      $ java -jar $JOERN/bin/icfg.jar

and for data flow analysis, the following two tools:
      
      $ java -jar $JOERN/bin/udg.jar
      $ java -jar $JOERN/bin/ddg.jar
      
after importing code.

## Starting the database server

It is possible to access the graph database directly from your scripts
by loading the database into memory on script startup. However, it is
highly recommended to access data via the neo4j server instead. The
advantage of doing so is that the data is loaded only once for all
scripts you may want to execute. Furthermore, you can benefit from
neo4j's caching for increased speed.

To install the neo4j server, download version 1.9 from:

    http://www.neo4j.org/download

Once downloaded, unpack the archive into a directory of your choice,
which we will call $Neo4jDir in the following.

Next, specificy the location of the database created by joern in your
Neo4J server configuration file in
$Neo4jDir/conf/neo4j-server.properties:

    org.neo4j.server.database.location=/$path_to_joern_index/.joernIndex/

Second, start the database server by issuing the following command:

	$ $Neo4jDir/bin/neo4j console

To check if the server has successfully started, point your browser to
http://localhost:7474/ . 

## Performance Tuning (Optional)

Please read the [neo4j performance
guide](http://docs.neo4j.org/chunked/stable/performance-guide.html) to
tune your installation. In particular, it may be necessary to [raise
the maximum number of open file
descriptors](http://docs.neo4j.org/chunked/stable/configuration-linux-notes.html)
for the user running the neo4j server. 

## Interacting with the database using Python

Once code has been imported into a Neo4j database, it can be accessed
using a number of different interfaces and programming languages. One
of the simplest possibilities is to create a standalone Neo4J server
instance as described in the previous section and connect to this
server using the Python library py2neo.

To do so, install py2neo as described here: http://book.py2neo.org/en/latest/ 

If you are using Python's pip, the following command will be all you need to execute:

    $ pip install neo4j

Finally, run the following sample Python script, which prints all
assignments using a gremlin traversal:

```
from py2neo import neo4j, gremlin
graph_db = neo4j.GraphDatabaseService("http://localhost:7474/db/data/")
	 for assign in gremlin.execute('g.idx("nodeIndex")[[type:"AssignmentExpr"]].code',graph_db):
	     	    print assign
```
