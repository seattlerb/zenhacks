#!/usr/local/bin/ruby -w

class Class
  def path
    result = []
    self.name.split(/::/).inject(Object) do |c, n|
      result << c.const_get(n)
      result.last
    end
    return result
  end
end

class Foo
  class Bar
  end
end

p Foo::Bar.path
# => [Foo, Foo::Bar]
