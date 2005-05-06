#!/usr/local/bin/ruby -w

ENV['GEM_SKIP'] = 'ParseTree:RubyInline'
$:.push 'lib', '../../ParseTree/dev/lib', '../../RubyInline/dev', '../../ruby_to_c/dev'

require 'r2c_hacks'

class Example
  def example(arg1)
    return "Blah: " + arg1.to_s
  end
end

e = Example.new
puts "Code (via cat):"
puts `cat #{$0}`
puts "sexp:"
p e.method(:example).to_sexp
puts "C:"
puts e.method(:example).to_c
puts "Ruby:"
puts e.method(:example).to_ruby

