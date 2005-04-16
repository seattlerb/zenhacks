#!/usr/local/bin/ruby -w

# the ultimate "rapper"
module MuffDaddy
  def self.__rap_method__(c, m)
    return if m =~ /^__/
    c = class << c; self; end unless c.class == Class
    return if c.instance_methods(false).include? "__#{m}"
    rapped_method = c.const_get("RAP_METHOD_NAME")
    c.class_eval "alias __#{m} #{m}"
    c.class_eval "def #{m}(*args); #{rapped_method} { __#{m}(*args) }; end"
  end

  def self.__rap_class__(c)
    c.instance_methods(false).each { |m| __rap_method__(c, m) }
    c.class_eval "def self.method_added(m); MuffDaddy.__rap_method__(self, m.to_s); end"
  end

  def self.__rap_object__(o)
    o.public_methods(false).each { |m| __rap_method__(o, m) }
  end

  def self.extend_object(o)
    super(o)
    MuffDaddy.__rap_object__(o)
  end

  def self.included(c)
    super(c)
    if c.class == Module then
      c.module_eval "def self.included(c); super(c); MuffDaddy.included(c); end"
      c.module_eval "def self.extend_object(c); super(c); MuffDaddy.extend_object(c); end"
    end
    MuffDaddy.__rap_class__(c)
  end
end

module CheapoTracer

  include MuffDaddy

  RAP_METHOD_NAME = :__trace__

  def __trace__
    @__trace = 0 unless defined? @__trace
    print "  " * @__trace
    print "#{@__trace}: "
    @__trace += 1
    yield
    @__trace -= 1
  end

end

class Untraced
  def something
    puts "Miiiiisery!"
    something_else
  end

  def something_else
    puts "Decay!"
  end
end

class Traced
  include CheapoTracer

  def method1
    puts "I'm dead too!"
  end
end

w1 = Untraced.new
w1.something

w1.extend CheapoTracer
w1.something

w2 = Untraced.new
w2.something

w3 = Traced.new
w3.method1
