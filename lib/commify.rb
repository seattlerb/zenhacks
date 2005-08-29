#!/usr/local/bin/ruby -w

class Numeric
  def commify
    to_s.reverse.gsub(/(\d\d\d)(?=\d)(?!\d*\.)/, '\1,').reverse
  end
end
