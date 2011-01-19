#!/usr/bin/ruby 
require 'las2witsml'

 l2w = Las2Witsml.new
 infile = File.new 'asphulto.las', 'r'
 outfile = File.new "asphaulto.witsml", "w"
 l2w.run infile, outfile, 't1', 'b1', 'l1', 'test log'

# 
#  infile = File.new 'md.las', 'r'
#  outfile = File.new 'md.witsml', 'w'
#  l2w.run infile, outfile, 't1', 'b1', 'l1', 'test log'
# 
# 
# infile = File.new 'dt.las', 'r'
# outfile = File.new 'dt.witsml', 'w'
# l2w.run infile, outfile, 't1', 'b1', 'l1', 'test log'


