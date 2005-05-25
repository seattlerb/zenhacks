#!/usr/local/bin/ruby -w

class Graph < Hash

  attr_reader :attribs
  attr_reader :prefix
  attr_reader :order
  attr_reader :edge

  def initialize
    super { |h,k| h[k] = [] }
    @prefix = []
    @attribs = Hash.new { |h,k| h[k] = [] }
    @edge = Hash.new { |h,k| h[k] = Hash.new { |h2,k2| h2[k2] = [] } }
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
    result << "digraph absent"
    result << "  {"
    @prefix.each do |line|
      result << line
    end
    @attribs.sort.each do |node, attribs|
      result << "    #{node.inspect} [ #{attribs.join(',')} ]"
    end
    each_pair do |from, to|
      edge = @edge[from][to].join(", ")
      edge = " [ #{edge} ]" unless edge.empty?
      result << "    #{from.inspect} -> #{to.inspect}#{edge};"
    end
    result << "  }"
    result.join("\n")
  end

  def save(path, type="png")
    File.open(path + ".dot", "w") do |f|
      f.puts self.to_s
      f.flush
      cmd = "/usr/local/bin/dot -T#{type} #{path}.dot > #{path}.#{type}"
      system cmd
    end
  end
end
