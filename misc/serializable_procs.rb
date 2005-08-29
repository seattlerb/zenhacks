#!/usr/local/bin/ruby -w

$: << "lib"
$: << "../../RubyInline/dev"
$: << "../../ParseTree/dev/lib"
$: << "../../ruby_to_c/dev"

require 'r2c_hacks'

require "pstore"
require "yaml"

class ProcStore # We have to have this because yaml calls allocate on Proc
  def initialize(&proc)
    @p = proc.to_ruby
  end

  def call(*args)
    eval(@p).call(*args)
  end
end

code = ProcStore.new { |x| return x+1 }

p code

File.open("proc.marshalled", "w") { |file| Marshal.dump(code, file) }
code = File.open("proc.marshalled") { |file| Marshal.load(file) }
p code
p code.call(1)

store = PStore.new("proc.pstore")
store.transaction do
  store["proc"] = code
end
store.transaction do
  code = store["proc"]
end

p code.call(1)

File.open("proc.yaml", "w") { |file| YAML.dump(code, file) }
code = File.open("proc.yaml") { |file| YAML.load(file) }

p code.call(1)
