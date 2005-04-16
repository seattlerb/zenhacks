#require 'rubygems'
#require_gem 'ParseTree'
require 'parse_tree'
require 'support'
require 'sexp_processor'

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
    rescue UnknownNodeError => e
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
    return "def #{name}#{args}#{body}end".gsub(/\n\n+/, "\n")
  end

  def process_fcall(exp)
    exp_orig = exp.deep_clone
    # [:fcall, :puts, [:array, [:str, "This is a weird loop"]]]
    name = exp.shift.to_s
    args = exp.shift
    code = []
    unless args.nil? then
      assert_type args, :array
      args.shift # :array
      until args.empty? do
        code << process(args.shift)
      end
    end
    return "#{name}(#{code.join(', ')})"
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

  def process_vcall(exp)
    return exp.shift.to_s
  end

  def process_while(exp)
    cond = process(exp.shift)
    body = process(exp.shift)
    is_precondition = exp.shift

    code = []
    if is_precondition then
      code << "while #{cond} do"
      code << body
      code << "end"
    else
      code << "begin"
      code << body
      code << "end while #{cond}"
    end
    body = code.join("\n")
    return body
  end
end

