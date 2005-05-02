
$TESTING = true
require 'test/unit' unless defined? $ZENTEST and $ZENTEST
require 'parse_tree_graph'

class TestSexpGrapher < Test::Unit::TestCase

  def setup
    @grapher = SexpGrapher.new
    @count = 0
  end

  def util_process_snippet(code)
    @count += 1
    klassname = "SGExample#{@count}"
    klass = "class #{klassname}; def example; #{code}; end; end"
    Object.class_eval klass
    klass = Object.const_get klassname
    result = ParseTree.new.parse_tree(klass)
    result = result[0][3][2][1][2..-1] # just the body of the method
    result = Sexp.from_array(result)
    grapher = SexpGrapher.new
    grapher.process(result)
    grapher.graphstr
  end

  def test_graph_basic
    expected = 'digraph a_graph
  {
   node [ shape = box, style = filled ];
    "n0001" [ label = ":call" ]
    "n0002" [ label = ":lit" ]
    "n0003" [ label = "1" ]
    "n0004" [ label = ":+" ]
    "n0005" [ label = ":array" ]
    "n0006" [ label = ":lit" ]
    "n0007" [ label = "1" ]
    "n0001" -> "n0002";
    "n0001" -> "n0004";
    "n0001" -> "n0005";
    "n0002" -> "n0003";
    "n0005" -> "n0006";
    "n0006" -> "n0007";
  }'
    assert_equal expected, util_process_snippet("1+1")
  end
end
