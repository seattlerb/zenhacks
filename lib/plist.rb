require 'rexml/parsers/pullparser'
require 'time'
require 'pp'

class Plist
  def self.parse(path)
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
        when "key", "string" then
          stack.last.push data.join.strip
        when "date" then
          stack.last.push Time.parse(data.join)
        when "true" then
          stack.last.push true
        when "integer" then
          stack.last.push data.join.strip.to_i
        when "dict" then
          stack.last.push Hash[*last[1..-1]]
        when "array" then
          stack.last.push last[1..-1]
        when "plist" then
          return last.last
        else
          raise "unhandled type #{tag.inspect}"
        end

        data = []
      end
    end
  end
end
