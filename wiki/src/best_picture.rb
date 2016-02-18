#!/usr/bin/env ruby -w
# ----------------------------------------------------------------------------- #
#         File: best_actor.rb
#  Description: prints out the best picture winners and nominees using 2014 file.
#    The format could change each year.
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2016-01-02 - 13:14
#      License: MIT
#  Last update: 2016-01-04 18:54
#  BUG : one should not rely on producer or company column since i only take href and sometimes
#     there are multiple, and mixed format. i am only concerned with film year and W/N.
# ----------------------------------------------------------------------------- #
#  best_actor.rb  Copyright (C) 2012-2016 j kepler
#
# currently these 2 can be used to filter out the relevant section.
# sed -n '/<td><i><a href="Wings_(1927_film).html/,/Notes/p' Academy_Award_for_Best_Picture.html | grep -E 'href="|^<tr|<table
# sed -n '/<table class="wikitable"/,/<\/table>/p' Academy_Award_for_Best_Picture.html
# movie links start with <i><a href="
# each year starts with <table "
# each movie is separated by <tr
# non-movie links can either have <a href or just <td>.*</td>. first is company , second is producer
#    some have a link inside a td !!!
#
require 'tempfile'
require 'fileutils'
def do_stuff file
  tmpfile = Tempfile.new('filmsXXXXX')

  %x{ sed -n '/<table class="wikitable"/,/<.table>/p' #{file} | tee t.t |  grep -E 'href="|^</tr|^</table' | tee t.t1 > #{tmpfile.path} }
  #%x{ sed -n '/#{start} in film/,/^<h2>/p' #{file} | grep -E 'href="[^"]*|^<tr>' | grep -v '/w/index.php' > #{tmpfile.path} }
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
    printing = false
    year = []
    title = []
    company = producer = nil
    delim="\t"
File.open(filename).each { |line|
  line = line.chomp
  if line =~ /^<\/table/
    puts "found end of table" if $verbose
    # new year
    # one year is over
    winner = "W"
  elsif line =~ /^<\/tr/
    next unless printing # only print after movie is found
    puts "found end of row tr - now we print ..." if $verbose
    # one row is over, print it
    y = "XXX"
    y = year.join("/") unless year.empty?
    titles = title.join(",")
    print "#{y}#{delim}#{titles}#{delim}#{winner}#{delim}#{company}#{delim}#{producer}\n"
    newline = true
    title = []
    company = producer = nil
    ctr = 0
    winner = "N"
  elsif line =~ /href="(\d{4})_in_film/
    puts "found a link year #{$1}" if $verbose
    year = [] if newline
    title = [] if newline
    newline = false
    printing = false # don't print unless movie found
    year << $1
    winner = "W"
  elsif line =~ /Academy_Awards.html/
    next
  elsif line =~ /<i><a href="(.*?)"/
    puts "found a title #{$1}" if $verbose
    printing = true
    title << fix_title($1)
  elsif line =~ /<a href="(.*?)"/ or line =~ /<td>(.*?)</
    if $1.index("#") == 0
      next
    end
    case ctr
    when 0
      company = fix_title($1)
      ctr += 1
    when 1
      producer = fix_title($1)
      ctr += 1
    end
  end
}
end

$verbose = false
if __FILE__ == $0
  begin
    # http://www.ruby-doc.org/stdlib/libdoc/optparse/rdoc/classes/OptionParser.html
    require 'optparse'
    options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options]"

      opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        options[:verbose] = v
        $verbose = v
      end
    end.parse!


    FileUtils.cd "/Volumes/Pacino/dziga_backup/rahul/Downloads/MOV/wiki/src"
    file = ARGV[0] || "../Academy_Award_for_Best_Picture.html"
    do_stuff file

  ensure
  end
end

