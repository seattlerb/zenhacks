#!/usr/local/bin/ruby -w

require 'time'

class Time
  def self.zones
    class << Time; ZoneOffset; end
  end
end

p Time.zones
