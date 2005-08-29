#!/usr/local/bin/ruby -w

$: << "lib"
$: << "../../ruby_to_c/dev"

require 'rubygems'
require 'ruby2ruby'

class Module
  def _(sexp)
    self.module_eval RubyToRuby.new.process(sexp)
  end
end

class Foo
  _ [:defn, :example, [:args], [:call, [:lit, 1], :+, [:array, [:lit, 1]]]]
end

p Foo.new.example
