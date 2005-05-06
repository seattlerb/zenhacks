#require 'rubygems'
#require_gem 'ParseTree'
require 'parse_tree'
require 'sexp_processor'
require 'ruby_to_c'
require 'ruby2ruby'

class Method
  def with_class_and_method_name
    if self.inspect =~ /<Method: (.*)\#(.*)>/ then
      klass = eval $1
      method  = $2.intern
      return yield(klass, method)
    else
      raise "Can't parse signature: #{self.inspect}"
    end
  end

  def to_sexp
    with_class_and_method_name do |klass, method|
      ParseTree.new.parse_tree_for_method(klass, method)
    end
  end

  def to_c
    with_class_and_method_name do |klass, method|
      RubyToC.translate(klass, method)
    end
  end

  def to_ruby
    with_class_and_method_name do |klass, method|
      RubyToRuby.translate(klass, method)
    end
  end
end