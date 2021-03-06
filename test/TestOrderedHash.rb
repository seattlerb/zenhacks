#!/usr/local/bin/ruby -w
# Code Generated by ZenTest v. 2.2.0
#                 classname: asrt / meth =  ratio%
#               OrderedHash:    1 /    6 =  16.67%
# Number of errors detected: 0

#require 'test/unit' unless defined? $ZENTEST and $ZENTEST
require 'test/unit/testcase'
require 'OrderedHash'

class TestOrderedHash < Test::Unit::TestCase

  def setup
    @k = %w(z y x)
    @h = OrderedHash.new

    @k.each_with_index do |key, val|
      @h[key] = val + 1
    end
  end

  def test_keys
    assert_equal @k, @h.keys
  end

  def test_each
    assert_equal 1, 2
  end

  def test_each_key
    raise NotImplementedError, 'Need to write test_each_key'
  end

  def test_each_value
    raise NotImplementedError, 'Need to write test_each_value'
  end

  def test_index_equals
    raise NotImplementedError, 'Need to write test_index_equals'
  end
end

# Number of errors detected: 1
