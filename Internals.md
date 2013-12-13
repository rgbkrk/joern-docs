
tools.index:

SourceFileWalker walks files and calls OutputModule on events.

Neo4JOutputModule -> OutputModule

- Output module has a ModuleParser
- Neo4jASTWalker is registered as listener of ModuleParser

Walkthrough of the code importer
=================================

Code to Parse Tree to Abstract Syntax Tree
===

- Two parsers were generated from grammar definition files for the
  ANTLRv4 parser generator (see .g4-files in src/antlr):
  - The module-level parser (Module.g4) parses source files at the
    module level to identify type and function definitions etc.
  - The function-level parser (Function.g4) parses the content of
    functions.

- The generated parsers are also located in src/antlr. These parsers
  are operated using the two ANTLRModuleParserDriver and
  ANTLRFunctionParserDriver.

- We begin by invoking the module level parser (from the output
  module) to generate parse trees and subsequently walk them.
- The ModuleParseTreeListener defines callback functions invoked when
  walking the module-level parse-tree.
  - Its job is to convert the parse-tree (ANTLR data structure) into an
    abstract syntax tree (joern data structure).
  - In particular, it invokes the function parser (see
    parsing/ModuleFunctionParserInterface)
	- The function parser parses the function contents and
    subsequently walks the parse tree invoking the callbacks of the
    FunctionParseTreeListener. The listener forwards to appropriate
    builders.

- Parsing function contents is a little more evolved because in
  several cases, we deliberately passed on formulating nested grammar
  productions because this kills performance when doing robust
  parsing as in the worst case, we traverse up to the end of the file
  several times without finding a matching rule. For this reason, in
  particular the FunctionContentBuilder needs to introduce the
  nested structure based on the parse tree. This is by far the ugliest
  part of the joern code and it is located in
  astnodes.builders.FunctionContentBuilder.


Abstract Syntax Tree to Control Flow Graph
===

