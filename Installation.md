Installation
============

Joern currently consists of the following components:

-   **[joern(-core)](https://github.com/fabsx00/joern/)** parses source
    code using a robust parser, creates code property graphs and
    finally, imports these graphs into a Neo4j graph database.

-   **[python-joern](https://github.com/fabsx00/python-joern/)** is a
    (minimal) python interface to the Joern database. It offers a
    variety of utility traversals (so called *steps*) for common
    operations on the code property graph (think of these are stored
    procedures).

-   **[joern-tools](https://github.com/fabsx00/joern-tools/)** is a
    collection of command line tools employing python-joern to allow
    simple analysis tasks to be performed directly on the shell.

Both python-joern and joern-tools are optional, however, installing
python-joern is highly recommended for easy access to the database.
While it is possible to access Neo4J from many other languages, you will
need to write some extra code to do so and therefore, it is currently
not recommended.

System Requirements and Dependencies
------------------------------------

Joern is a Java Application and should work on systems offering a Java
virtual machine, e.g., Microsoft Windows, Mac OS X or GNU/Linux. We have
tested Joern on Arch Linux as well as Mac OS X Lion. If you plan to work
with large code bases such as the Linux Kernel, you should have at least
30GB of free disk space to store the database and 8GB of RAM to
experience acceptable performance. In addition, the following software
should be installed:

-   **[A Java Virtual Machine 1.7.](http://www.java.com/)** Joern is
    written in Java 7 and does not build with Java 6. It has been tested
    with OpenJDK-7 but should also work fine with Oracle’s JVM.

-   **[Neo4J 1.9.\* Community
    Edition.](http://www.neo4j.org/download/other_versions)** The graph
    database Neo4J provides access to the imported code. Note, that
    Joern has not been tested with the 2.0 branch of Neo4J.

**Build Dependencies.** A tarball containing all necessary
build-dependencies is available for download
[here](http://mlsec.org/joern/lib/lib.tar.gz). This contains files from
the following projects.

-   [The ANTLRv4 Parser Generator](http://www.antlr.org/)

-   [Apache Commons CLI Command Line Parser
    1.2](http://commons.apache.org/proper/commons-cli/)

-   [Neo4J 1.9.\* Community
    Edition](http://www.neo4j.org/download/other_versions)

-   [The Apache Ant build tool](http://ant.apache.org/) (tested with
    version 1.9.2)

The following sections offer a step-by-step guide to the installation of
Joern, including all of its dependencies.

Building the Code
-----------------

1.  Begin by downloading the latest stable version of joern at

    <http://mlsec.org/joern/download.shtml>. This will create the
    directory `joern` in your current working directory.

        $ wget https://github.com/fabsx00/joern/archive/v0.2.tar.gz
        $ tar xfzv v0.2.tar.gz

2.  Change to the directory `joern/`. Next, download build dependencies
    at <http://mlsec.org/joern/lib/lib.tar.gz> and extract the tarball.
    The JAR-files necessary to build Kern should now be located in
    `joern/lib/`.

        $ cd joern
        $ wget http://mlsec.org/joern/lib/lib.tar.gz
        $ tar xfzv lib.tar.gz

3.  Build the project by issuing the following command.

        $ ant

4.  **Create symlinks (optional).** The executable JAR file will be
    located in `joern/bin/joern.jar`. Simply place this JAR file
    somewhere on your disk and you are done. If you are using bash, you
    can optionally create the following alias in your `.bashrc`:

        alias joern='java -jar $JOERN/bin/joern.jar'

    where `$JOERN` is the directory you installed Joern into.

5.  **Build additional tools (optional).** Tools such as the
    `argumentTainter` can be built by issuing the following command.

        $ ant tools

    Upon successfully building the code, you can start importing C/C++
    code you would like to analyze as outlined the next section.
