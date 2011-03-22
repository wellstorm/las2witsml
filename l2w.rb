#!/usr/bin/ruby 


require "#{File.dirname(__FILE__)}/las_file"
require "#{File.dirname(__FILE__)}/witsml_file"
require "#{File.dirname(__FILE__)}/las2witsml"

ARGV.each do|a|
  l2w = Las2Witsml.new
  infile = File.new a, 'r'
  outfile = $stdout
  l2w.run infile, outfile, 't1', 'b1', 'l1', 'test log'
end



