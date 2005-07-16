begin require 'rubygems' rescue LoadError end
require 'parse_tree'
require 'sexp_processor'
require 'ruby_to_c'
require 'ruby2ruby'

class Method
  def with_class_and_method_name
    if self.inspect =~ /<Method: (.*)\#(.*)>/ then
      klass = eval $1
      method  = $2.intern
      raise "Couldn't determine class from #{self.inspect}" if klass.nil?
      return yield(klass, method)
    else
      raise "Can't parse signature: #{self.inspect}"
    end
  end

  def to_sexp
    with_class_and_method_name do |klass, method|
      ParseTree.new(false).parse_tree_for_method(klass, method)
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

class Proc
  ProcStoreTmp = Class.new unless defined? ProcStoreTmp
  def to_ruby
    ProcStoreTmp.send(:define_method, :myproc, self)
    m = ProcStoreTmp.new.method(:myproc)
    result = m.to_ruby.sub(/def myproc\(([^\)]*)\)/,
                           'proc { |\1|').sub(/end\Z/, '}')
    return result
  end
end
