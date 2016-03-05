#!/usr/bin/env ruby -w
# ----------------------------------------------------------------------------- #
#         File: oscar.rb
#  Description: 
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2016-02-26 - 20:06
#      License: MIT
#  Last update: 2016-03-01 15:01
# ----------------------------------------------------------------------------- #
#  YFF Copyright (C) 2012-2016 j kepler

require 'sqlite3'

dbname = "../movie.sqlite"
$db = SQLite3::Database.new(dbname)

def read_file_in_loop filename
  ctr = failctr = 0
  File.open(filename).each { |line|
    line = line.chomp
    next if line =~ /^$/
    cols = line.split("\t")
    url = cols.first
    won = cols[1].to_i
    nom = cols[2].to_i

    rowid, a, b = $db.get_first_row %Q[select rowid, won, nom from movie where url = "#{url}"; ] 
    if rowid.nil?
      puts "ERROR : #{url} not found in DB (#{line})"
      failctr += 1
      next
    end
    if won == a and nom == b
      puts " #{url} matches #{a} and #{b} " if $opt_verbose
      ctr += 1
    else
      puts ">>>>>>>>>>> #{url} NOT MATCH DB:#{a} and #{b}. FILE: != #{won} #{nom}  "
      failctr += 1
    end

  }
  puts "Failed: #{failctr} "
  puts "Succeed: #{ctr} "
end




if __FILE__ == $0
        $opt_verbose = false
  begin
    # http://www.ruby-doc.org/stdlib/libdoc/optparse/rdoc/classes/OptionParser.html
    require 'optparse'
    options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options]"

      opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        options[:verbose] = v
        $opt_verbose = v
      end
    end.parse!

    p options
    p ARGV

    filename=ARGV[0] || "o.t"
    # or 
    read_file_in_loop filename
  ensure
  end
end

