require 'parse_tree'
require 'support'
require 'sexp_processor'

class RubyToRuby < SexpProcessor

  def self.translate(klass, method=nil)
    unless method.nil? then
      self.new.process(ParseTree.new.parse_tree_for_method(klass, method))
    else
      self.new.process(ParseTree.new.parse_tree(klass).first) # huh? why is the :class node wrapped?
    end
  end

  def initialize
    super
    @env = Environment.new
    @indent = "  "
    self.auto_shift_type = true
    self.strict = true
    self.expected = String
  end
  
  def indent(s)
    s.to_s.map{|line| @indent + line}.join
  end
  
  def process_and(exp)
    "(#{process exp.shift} and #{process exp.shift})"
  end
  
  def process_args(exp)
    args = []

    until exp.empty? do
      arg = exp.shift
      if arg.is_a? Array
        args[-(arg.size-1)..-1] = arg[1..-1].map{|a| process a}
      else
        args << arg
      end
    end

    return "(#{args.join ', '})"
  end
  
  def process_array(exp)
    code = []
    until exp.empty? do
      code << process(exp.shift)
    end
    return "[" + code.join(", ") + "]"
  end

  def process_attrasgn(exp)
    process_call(exp)
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
    args_exp = exp.shift
    if args_exp && args_exp.first == :array
      args = "#{process(args_exp)[1..-2]}"
    else
      args = process args_exp
    end

    case name
    when :<=>, :==, :<, :>, :<=, :>=, :-, :+, :*, :/, :% then #
      "(#{receiver} #{name} #{args})"
    when :[] then
      "#{receiver}[#{args}]"
    else
      "#{receiver}.#{name}#{args ? "(#{args})" : args}"
    end
  end
  
  def process_case(exp)
    s = "case #{process exp.shift}\n"
    until exp.empty?
      pt = exp.shift
      if pt.first == :when
        s << "#{process(pt)}\n"
      else
        s << "else\n#{indent(process(pt))}\n"
      end
    end
    s + "\nend"
  end
  
  def process_class(exp)
    s = "class #{exp.shift} < #{exp.shift}\n"
    body = ""
    body << "#{process exp.shift}\n\n" until exp.empty?
    s + indent(body) + "end"
  end

  def process_const(exp)
    exp.shift.to_s
  end
  
  def process_dasgn_curr(exp)
    exp.shift.to_s
  end
  
  def process_defn(exp)
    name = exp.shift
    args = process(exp.shift).to_a
    args[1..-1] = indent(args[1..-1])
    args.join
    body = indent(process(exp.shift))
    return "def #{name}#{args}#{body}end".gsub(/\n\s*\n+/, "\n")
  end
  
  def process_dot2(exp)
    "(#{process exp.shift}..#{process exp.shift})"
  end

  def process_dot3(exp)
    "(#{process exp.shift}...#{process exp.shift})"
  end
  
  def process_dstr(exp)
    s = exp.shift.dump[0..-2]
    until exp.empty?
      pt = exp.shift
      if pt.first == :str
        s << process(pt)[1..-2]
      else
        s << '#{' + process(pt) + '}'
      end
    end
    s + '"'
  end

  def process_dvar(exp)
    exp.shift.to_s
  end

  def process_false(exp)
    "false"
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
  
  def process_iasgn(exp)
    "#{exp.shift} = #{process exp.shift}"
  end
  
  def process_if(exp)
    s = ["if (#{process exp.shift})"]
    s << "#{indent(process(exp.shift))}"
    s << "else\n#{indent(process(exp.shift))}" until exp.empty?
    s << "end"
    s.join("\n")
  end
  
  def process_iter(exp)
    "#{process exp.shift} {|#{process exp.shift}|\n" +
    indent("#{process exp.shift}\n") +
    "}"
  end
  
  def process_ivar(exp)
    exp.shift.to_s
  end
  
  def process_lasgn(exp)
    return "#{exp.shift} = #{process exp.shift}"
  end
  
  def process_lit(exp)
    obj = exp.shift
    if obj.is_a? Range # to get around how parsed ranges turn into lits and lose parens
      "(" + obj.inspect + ")"
    else
      obj.inspect
    end
  end
  
  def process_lvar(exp)
    exp.shift.to_s
  end
  
  def process_masgn(exp)
    process(exp.shift)[1..-2]
  end

  def process_nil(exp)
    "nil"
  end
  
  def process_return(exp)
    return "return #{process exp.shift}"
  end

  def process_scope(exp)
    return process(exp.shift)
  end

  def process_self(exp)
    "self"
  end
  def process_str(exp)
    return exp.shift.dump
  end

  def process_super(exp)
    "super(#{process(exp.shift)})"
  end
  
  def process_true(exp)
    "true"
  end

  def process_until(exp)
    cond_loop(exp, 'until')
  end
  
  def process_vcall(exp)
    return exp.shift.to_s
  end
  
  def process_when(exp)
    "when #{process(exp.shift).to_s[1..-2]}\n#{indent(process(exp.shift))}"
  end

  def process_while(exp)
    cond_loop(exp, 'while')
  end
  
  def process_zarray(exp)
    "[]"
  end

  def process_zsuper(exp)
    "super"
  end
  
  def cond_loop(exp, name)
    cond = process(exp.shift)
    body = indent(process(exp.shift))
    head_controlled = exp.empty? ? false : exp.shift

    code = []
    if head_controlled then
      code << "#{name} #{cond} do"
      code << body
      code << "end"
    else
      code << "begin"
      code << body
      code << "end #{name} #{cond}"
    end
    code.join("\n")
  end
  
end

if __FILE__ == $0
  r2r2r = RubyToRuby.translate(RubyToRuby).sub("RubyToRuby","RubyToRubyToRuby")
  eval r2r2r

  class RubyToRubyToRuby
    class<<self
      eval RubyToRuby.translate(class<<RubyToRuby;self;end, :translate)
    end
    eval RubyToRuby.translate(RubyToRuby, :initialize)
  end
  
  r2r2r2 = RubyToRubyToRuby.translate(RubyToRuby).sub("RubyToRuby","RubyToRubyToRuby")
  r2r2r2r = RubyToRubyToRuby.translate(RubyToRubyToRuby)
  # File.open('1','w'){|f| f.write r2r2r}
  # File.open('2','w'){|f| f.write r2r2r2}
  # File.open('3','w'){|f| f.write r2r2r2r}
  raise "Translation failed!" if (r2r2r != r2r2r2) or (r2r2r != r2r2r2r)
  
  puts("RubyToRubyToRubyToRubyyyyy!!!")
end
