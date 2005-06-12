# -*- ruby -*-

require 'rubygems'

spec = Gem::Specification.new do |s|

  s.name = 'ZenHacks'
  s.version = '1.0.0'
  s.summary = "Tools and toys of mine that don't have a better home."

  paragraphs = File.read("README.txt").split(/\n\n+/)
  s.description = paragraphs[3]
  puts s.description

  all_files = IO.readlines("Manifest.txt").map {|f| f.chomp }

  s.requirements << "Many. Depends on what you want to play with."
  s.files = all_files

  s.bindir = "bin"
  s.executables = all_files.grep(%r%bin/%).map { |f| File.basename(f) }
  puts "Executables = #{s.executables.join(", ")}"

  s.require_path = 'lib' 
#  s.autorequire = nil

  s.has_rdoc = false                            # I SUCK - TODO
#  s.test_suite_file = nil

  s.author = "Ryan Davis"
  s.email = "ryand-ruby@zenspider.com"
  s.homepage = "http://rubyforge.org/projects/zenhacks/"
  s.rubyforge_project = "zenhacks"
end

if $0 == __FILE__
  Gem.manage_gems
  Gem::Builder.new(spec).build
end
