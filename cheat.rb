#!/usr/local/bin/ruby -w

require 'rubygems'
require_gem 'ParseTree'
require 'sexp_processor'
require 'ruby_to_c'

class RubyToRuby < SexpProcessor

  def self.translate(klass, method=nil)
    unless method.nil? then
      self.new.process(ParseTree.new.parse_tree_for_method(klass, method))
    else
      self.new.process(ParseTree.new.parse_tree(klass))
    end
  end

  def initialize
    super
    @env = Environment.new
    self.auto_shift_type = true
    self.strict = true
    self.expected = String
  end

  def process(exp)
    t = exp.first rescue "unknown"
    begin
      super(exp)
    rescue SyntaxError => e
      result = []
      result << "  def process_#{t}(exp)"
      result << "    # #{exp.inspect}"
      (exp.size-1).times do |n|
        result << "    arg#{n} = process exp.shift"
      end
      result << "  end"
      puts result.join("\n")
      raise e
    end
  end

  def process_args(exp)
    args = []

    until exp.empty? do
      args << exp.shift
    end

    return "(#{args.join ', '})"
  end

  def process_array(exp)
    code = []
    until exp.empty? do
      code << process(exp.shift)
    end
    return code.join(", ")
  end

  def process_block(exp)
    code = []
    until exp.empty? do
      code << process(exp.shift)
    end

    body = code.join("\n")
    body += "\n"

    return body
  end

  def process_call(exp)
    receiver = process exp.shift
    name = exp.shift
    args = process exp.shift

    case name
    when :<=>, :==, :<, :>, :<=, :>=, :-, :+, :*, :/, :% then #
      "#{receiver} #{name} #{args}"
    when :[] then
      "#{receiver}[#{args}]"
    else
      "#{receiver}.#{name}#{args}"
    end
  end

  def process_defn(exp)
    name = exp.shift
    args = process exp.shift
    body = process exp.shift
    "def #{name}#{args}#{body}end"
  end

  def process_lvar(exp)
    exp.shift.to_s
  end

  def process_return(exp)
    return "return #{process exp.shift}"
  end

  def process_scope(exp)
    return process(exp.shift)
  end

  def process_str(exp)
    return "\"#{exp.shift}\""
  end
end

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

class Example
  def example(arg1)
    return "Blah: " + arg1.to_s
  end
end

e = Example.new
p e.method(:example).to_sexp
p e.method(:example).to_c
p e.method(:example).to_ruby

