
require 'r2c_hacks'

require 'test/unit' unless defined? $ZENTEST and $ZENTEST

class TestMethod < Test::Unit::TestCase
  
  def setup
    @method = self.method(:setup)
  end

  def test_to_c
    # TODO: :setup -> rb_intern("setup") -- or something
    assert_equal("void\nsetup() {\nself->method = method(self, :setup);\n}",
                 @method.to_c)
  end

  def test_to_ruby
    assert_equal("def setup()\n  @method = self.method(:setup)\nend",
                 @method.to_ruby)
  end

  def test_to_sexp
    assert_equal([:defn, :setup, 
                   [:scope,
                     [:block,
                       [:args],
                       [:iasgn, :@method,
                         [:call, [:self], :method,
                           [:array, [:lit, :setup]]]]]]],
                 @method.to_sexp)
  end
end

class TestProc < Test::Unit::TestCase
  def test_to_ruby_args
    assert_equal "proc { |x|\n  (x + 1)\n}", proc { |x| x + 1 }.to_ruby
  end

  def test_to_ruby_no_args
    assert_equal "proc { ||\n  (1 + 1)\n}", proc { 1 + 1 }.to_ruby
  end
end
