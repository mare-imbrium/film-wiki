#!/usr/bin/env ruby -w
# ----------------------------------------------------------------------------- #
#         File: best_actor.rb
#  Description: 
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2016-01-02 - 13:14
#      License: MIT
#  Last update: 2016-03-03 17:57
# ----------------------------------------------------------------------------- #
#  best_actor.rb  Copyright (C) 2012-2016 j kepler
#  BUG - this misses last entry in file since it processes on a new <tr>
#  2016-03-02 - 12:45 fixed in both sed/grep and if loop, print on end of tr 
#
require 'tempfile'
def do_stuff file, start=1927
  tmpfile = Tempfile.new('filmsXXXXX')
  #tmpfile.write(str)

  #%x{ sed -n '/1927 in film/,/^<h2>/p' Academy_Award_for_Best_Actor.html | grep -oE 'href="[^"]*|^<tr>' | sed 's/href="//' | grep -v '^#' | grep -v '^/w/index.php' > #{tmpfile.path} }
  %x{ sed -n '/#{start} in film/,/^<h2>/p' #{file} | grep -E 'href="[^"]*|^</tr>' | grep -v '/w/index.php' > #{tmpfile.path} }
  read_file_in_loop tmpfile.path

  tmpfile.close
end
# fix title from file system link to wikipedia link since that is our key in the table, esp for film
def fix_title t
  # remove .html
  t1 = t.sub(/\.html$/,'')
  # add /wiki/ unless it exists
  if t1.index("/wiki/")
    return t1
  end
  return "/wiki/" + t.sub(/\.html$/,'')
end
def read_file_in_loop filename
  winner = "N"
    ctr = 0
    newline = true
    year = []
    title = []
    actor = character = nil
    delim="\t"
File.open(filename).each { |line|
  line = line.chomp
  #if line =~ /^<tr>/
  if line =~ /^<\/tr/
    # new year
    y = "XXX"
    y = year.join("/") unless year.empty?
    titles = title.join(",")
    print "#{y}#{delim}#{actor}#{delim}#{winner}#{delim}#{titles}#{delim}#{character}\n"
    newline = true
    title = []
    actor = nil
    character = nil
    ctr = 0
    winner = "N"
  elsif line =~ /href="(\d{4})_in_film/
    year = [] if newline
    title = [] if newline
    newline = false
    year << $1
    winner = "W"
  elsif line =~ /Academy_Awards.html/
    next
  elsif line =~ /<i><a href="(.*?)"/
    title << fix_title($1)
  elsif line =~ /<a href="(.*?)"/
    if $1.index("#") == 0
      next
    end
    case ctr
    when 0
      actor = fix_title($1)
      ctr += 1
    when 1
      character = fix_title($1)
      ctr += 1
    end
  end
}
end


if __FILE__ == $0
  begin
    # http://www.ruby-doc.org/stdlib/libdoc/optparse/rdoc/classes/OptionParser.html
    require 'optparse'
    options = {}
    start = 1927
    OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options]"

      opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        options[:verbose] = v
      end
      opts.on("--start INT", "Year to start") do |v|
        start = v
      end
    end.parse!

    #p options
    #p ARGV
    file = ARGV[0] || "Academy_Award_for_Best_Actor.html"
    # start is the year the award started on, since we start looking from that line.
    if file.index("Supporting")
      start = 1936
    end
    puts "start year is #{start} "
    do_stuff file, start

  ensure
  end
end

