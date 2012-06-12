#!/usr/bin/env ruby -w
# Copyright 2012 Wellstorm Development LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


require 'optparse'

require "#{File.dirname(__FILE__)}/las_file"
require "#{File.dirname(__FILE__)}/witsml_file"
require "#{File.dirname(__FILE__)}/las2witsml"


options = {:defs => {}}

opts =OptionParser.new do |o|
  o.banner = "Usage: l2w [-nl name] [-uw uid] [-uwb uid] [-ul uid] [-h] lasfile"

  o.on("-n", "--namelog name", "Name to give the WITSML log; default 'Untitled'") do |v|
    options[:name] = v
  end

  o.on("-u", "--uidwell uid", "WITSML uid of the containing well") do |v|
    options[:uw] = v
  end
  o.on("-b", "--uidwellbore uid", "WITSML uid of the containing wellbore") do |v|
    options[:uwb] = v
  end
  o.on("-l", "--uidlog  uid", "WITSML uid to assign the log") do |v|
    options[:ul] = v
  end

  o.on_tail("-h", "--help", "Show this message") do
    puts o
    exit
  end
end



opts.parse!
if ( !options[:url] )
  puts(opts.help)
  exit 1
end


ARGV.each do|a|
  l2w = Las2Witsml.new
  infile = File.new a, 'r'
  outfile = $stdout
  l2w.run infile, outfile, options[:uw] || "",  options[:uwb] || "",  options[:ul] || "", options[:name] || 'Untitled'
end



