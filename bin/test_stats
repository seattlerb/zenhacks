#!/usr/local/bin/ruby -w

assert_count = {}
def_count = {}
result = []

assert_count.default = 0
def_count.default = 0

current_class = "unknown"

ARGF.each_line do |l|

  current_class = $1 if l =~ /^\s*class\s+(\S+)/
  def_count[current_class]    += 1 if l =~ /^\s*def/
  assert_count[current_class] += 1 if l =~ /assert_|flunk|fail/

end

def_count.each_key do |classname|

  entry = {}

  next if classname =~ /^Test/
  testclassname = "Test#{classname}"
  a_count = assert_count[testclassname]
  d_count = def_count[classname]
  ratio = a_count.to_f / d_count.to_f * 100.0

  entry['n'] = classname
  entry['r'] = ratio
  entry['a'] = a_count
  entry['d'] = d_count

  result.push entry
end

sorted_results = result.sort { |a,b| b['r'] <=> a['r'] }

sorted_results.each do |e|
  printf "# %25s: %4d defs %4d = %6.2f%%\n", e['n'], e['d'], e['a'], e['r']
end
