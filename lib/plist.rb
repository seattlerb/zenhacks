require 'rexml/parsers/pullparser'

def parse_plist(path)
  f = File.open(path)
  stack = []
  data = []
  parser = REXML::Parsers::PullParser.new(f)
  parser.each do |res|
    raise res[1] if res.error?
    tag = res[0]
    case res.event_type
    when :start_element
      stack.push [tag]
    when :text
      data.push tag
    when :end_element
      raise "Um. not the same #{stack.last} vs #{tag}" if
        stack.last.first != tag

      last = stack.pop

      case tag
      when "key", "string"
        stack.last.push(data.join.strip)
      when "integer"
        stack.last.push(data.join.strip.to_i)
      when "dict"
        stack.last.push(Hash[*last[1..-1]])
      when "array"
        a = last[1..-1]
        stack.last.push(a)
      when "plist"
        return last.last
      else
        raise "unhandled type #{tag.inspect}"
      end

      data = []
    end
  end
end

