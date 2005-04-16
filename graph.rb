#!/usr/local/bin/ruby -w

class Graph < Hash

  attr_reader :attribs
  attr_reader :prefix
  attr_reader :order
  def initialize(name="a_graph")
    super() { |h,k| h[k] = [] }
    @name = name
    @prefix = []
    @attribs = Hash.new { |h,k| h[k] = [] }
    @order = []
  end

  def []=(key, val)
    @order << key unless self.has_key? key
    super(key, val)
  end

  def each_pair
    @order.each do |from|
      self[from].each do |to|
        yield(from, to)
      end
    end
  end

  def invert
    result = self.class.new
    each_pair do |from, to|
      result[to] << from
    end
    result
  end

  def counts
    result = Hash.new(0)
    each_pair do |from, to|
      result[from] += 1
    end
    result
  end

  def keys_by_count
    counts.sort_by { |x,y| y }.map {|x| x.first }
  end

  def to_s
    result = []
    result << "digraph #{@name}"
    result << "  {"
    @prefix.each do |line|
      result << line
    end
    @attribs.sort.each do |node, attribs|
      result << "    #{node.inspect} [ #{attribs.join(',')} ]"
    end
    each_pair do |from, to|
      result << "    #{from.inspect} -> #{to.inspect};"
    end
    result << "  }"
    result.join("\n")
  end

end
