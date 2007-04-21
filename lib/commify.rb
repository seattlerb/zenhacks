#!/usr/local/bin/ruby -w

class Numeric
  def commify(dec='.', sep=',')
    num = to_s.sub(/\./, dec)
    dec = Regexp.escape
    num.reverse.gsub(/(\d\d\d)(?=\d)(?!\d*#{dec})/, "\\1#{sep}").reverse
  end
end
