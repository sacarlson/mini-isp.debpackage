#!/usr/bin/ruby
# update ip trafic usage in ip_links table in mysql
Dir.chdir(File.dirname($PROGRAM_NAME))
require './freenet_lib.rb'
puts get_bytes_tx_ip(ARGV[0])
