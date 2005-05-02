require 'parse_tree'
require 'ruby2ruby'

class Refax

  def couldPossiblyRefactor?(p, ind)
    return false unless p[ind].is_a?(Array)
    return false unless p[ind].first == :while
    return false if p[ind][-1] == :post
    return true unless p[ind][2].is_a?(Array)
    p[ind][2].first == :block
  end

  def howManyInsn(p)
    fail "Must be a while, not a #{p}" unless p.first == :while
    if p[2].is_a?(Array)
      fail unless p[2].first == :block
      p[2].size - 1
    else
      1
    end
  end

  def grabInsnArray(p)
    fail "Must be a while, not a #{p}" unless p[0] == :while
      if p[2].is_a?(Array)
        p[2][1..-1]
      else
        [p[2]]
      end
  end

  def isEquiv(a, b)
    a.to_s == b.to_s
  end

  def fixcode(p, ind)
    loopsize = howManyInsn(p[ind])
    goodcode = p.clone
    goodcode[ind][-1] = ! goodcode[ind][-1] #true # false
    goodcode.slice!(ind-loopsize..ind-1)
    goodcode # todo : make correcter
  end

  def recurseOn(p)
    if p.is_a?(Array)
      @lastclass = p[1] if p.first == :class
      @lastfunc = p[1] if p.first == :defn
      p.each { |i| recurseOn(i) }
      p.each_index do |ind|
        if couldPossiblyRefactor?(p,ind)
          loopsize = howManyInsn(p[ind])
          if loopsize < ind
            if isEquiv(p[ind-loopsize,loopsize], grabInsnArray(p[ind]))
              goodstuff = fixcode(p, ind)
              puts "Suggest refactoring #{@lastclass}##{@lastfunc} from:"
              puts 
              puts RubyToRuby.translate(eval(@lastclass.to_s), @lastfunc)
              print "\nto:\n\n"
              puts RubyToRuby.new.process(s(:defn, @lastfunc, s(:scope, goodstuff)))
            end
          end
        end
      end
    end
  end

  def refactor(c)
    fail "Must have class or module" unless c.is_a?(Module)
    p = ParseTree.new.parse_tree(c)
    recurseOn(p)
  end

  r = Refax.new
  ObjectSpace.each_object(Module) { |c|
    r.refactor(c)
  }

end
