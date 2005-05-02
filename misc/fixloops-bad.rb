#!/usr/local/bin/ruby -w

# Refax automatic refactoring system by Rudi Cilibrasi (cilibrar@gmail.com)
# A simple example test of the new ParseTree library.
#
# This program is meant to suggest possible refactoring opportunities
#
# to convert loops of the form
# stmt A
# stmt B
# stmt C
# while cond
#   stmt A
#   stmt B
#   stmt C
# end
#
# to
#
# begin
#   stmt A
#   stmt B
#   stmt C
# end while cond
#
# to use this system, just put
#
# require 'fixloops'
# at the bottom of your ruby source file after requiring all classes to check
#
# ParseTree notes:
# 1) How can you distinguish while loops with preconditions
# versus those with postconditional guards?  It looks like the parse tree
# is showing them the same at this moment.
# 2) Trying to parse_tree(Object) throws a nil ptr


# And here is an example hastily.rb that can be refactored using it:
# Example Ruby program to test automatic refactoring engine based on ParseTree
# by Rudi Cilibrasi (cilibrar@gmail.com)

class HastilyWritten
  def keepgoing() rand(2) == 0 end
  def doSomethingWeird() puts "zzzzz" end
  def weirdfunc
    puts "This is a weird loop"
    doSomethingWeird()
    while keepgoing
      puts "This is a weird loop"
      doSomethingWeird()
    end
  end
  def finefunc
    begin
      puts "This is a weird loop"
      doSomethingWeird()
    end while keepgoing
  end
end

# Here is the line you need to use Refax automatic refactoring system
require 'fixloops'
