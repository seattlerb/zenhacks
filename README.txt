ZenHacks
    http://rubyforge.org/projects/zenhacks/
    ryand-ruby@zenspider.com

** DESCRIPTION:
  
ZenHacks is a semi-random collection of libs and scripts that just
don't belong in a package of their own. Many, if not most, have
dependencies on other packages and use, abuse, or extend them in
interesting ways.

This package is not supported in the same sense that my other packages
are, but since it is such a fun playground, I am very open to
contributions, suggestions, and bug fixes. I just can't put this
project at the top of my priority list the way I can/do the others, so
it may take me longer to get to than normal.

** INCLUDES

+ RubyInline Hacks
	+ zenprofile-demo.sh - demonstrates the use of zenprofile.
	+ lib/zenprofile.rb - a code profiler that is fairly readable yet fast.
+ ParseTree Hacks
	+ bin/parse_tree_graph - graphs parsetree for code fed to it.
	+ test/test_parse_tree_graph.rb - tests for parse_tree_graph.
+ RubyToRuby Hacks
	+ fixloops-demo.sh - demonstrates using parsetree to analyze source.
	+ lib/fixloops.rb - simple loop analyzer and refactoring tool.
	+ misc/fixloops-bad.rb - demo code for fixloops-demo.sh.
	+ lib/ruby2ruby.rb - converts ParseTree's sexp back into ruby.
+ RubyToC Hacks
	+ r2c_hacks-demo.rb - demonstrates r2c_hacks' methods.
	+ lib/r2c_hacks.rb - implements to_sexp, to_ruby, and to_c for methods.
	+ zenoptimize-demo.sh - demonstrates dynamic optimization of ruby.
	+ lib/zenoptimize.rb - implements a dynamic optimizer using ruby2c.
+ Testing Hacks
	+ bin/test_stats - shows ratio of assertions to methods
+ Misc Hacks
	+ misc/factorial.rb - not a hack, but a demo file for above toys.
	+ misc/find_c_methods - sniffs through ruby's C to find C methods.
	+ lib/class-path.rb - returns array of each level of a class' namespace.
	+ lib/discover.rb - requires files and returns classes introduced.
	+ lib/muffdaddy.rb - allows you to very easily wrap objects and classes.
	+ lib/graph.rb - very simple / clean api for building w/ graphviz.
	+ bin/macgraph - very stupid / ugly frontend for using graphviz on osx.
	+ lib/OrderedHash.rb - a simple Hash with ordered keys.
	+ test/TestOrderedHash.rb - (bad) tests for OrderedHash.
	+ OrderedHash.rb/TestOrderedHash.rb - Orderered keyed collection.
	+ lib/timezones.rb - fixes the fact that you can't get timezones from Time.

** REQUIREMENTS:

Lots... RubyInline, Ruby2C, ParseTree. Probably others. Not all
dependencies are required for all hacks. There may be some tweaking
needed to run the demo.sh files.

** INSTALL:

+ No install, this is mostly for playing and/or reading.

** LICENSE:

(The MIT License)

Copyright (c) 2001-2005 Ryan Davis, Zen Spider Software

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
