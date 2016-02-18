#!/usr/bin/env ruby -w
# ----------------------------------------------------------------------------- #
#         File: best_foreign_film.rb
#  Description: prints foreign films nominees and winners
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2016-01-05 - 12:09
#      License: MIT
#  Last update: 2016-01-05 15:29
# ----------------------------------------------------------------------------- #
#  best_foreign_film.rb  Copyright (C) 2012-2016 j kepler
# ----------------------------------------------------------------------------- #
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
  start = 1947
  tmpfile = Tempfile.new('filmsXXXXX')

  #%x{ sed -n '/<table class="wikitable"/,/<.table>/p' #{file} | tee t.t |  grep -E 'href="|^</tr|^</table' | tee t.t1 > #{tmpfile.path} }
  %x{ sed -n '/#{start} in film/,/^<h2>/p' #{file} > #{tmpfile.path} }
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
# -----------------------------------------------
#
#  Columns (separated by </td>)
#  1 - year : a href="1947_in_film"
#  2 - academy award number - ignore this
#  2 - title - a href=" "
#  3 - original title  - <i><b> or just  <i>
#  4 - country : a href=""
#  5 - director : a href=""
#  6 - language
#
#  Row/movie separated by </tr>
# -----------------------------------------------
def read_file_in_loop filename
  winner = "N"
  ctr = 0
  newline = true
  printing = false
  year = []
  title = []
      array = []
      original_title = []
  delim="\t"
  col = 0
  File.open(filename).each { |line|
    line = line.chomp
    if line =~ /^<i><b>(.*?)<\/b>/ or line =~ /^<i>(.*?)<\/i>/
      if col > 3
        # we are in the array but data was on next line
        array[col-4] = $1
      elsif col == 3
        #if original_title[0] = "NOT FOUND"
          #original_title[0] = $1
        #else
          original_title << $1
        #end
      else
        $stderr.puts "FOUND SOME DATA (#{$1}) for col #{col}"
      end
    elsif line =~ /^<\/table/
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
      
      if original_title[0] == "NOT FOUND" and original_title.size > 1
        original_title.shift
      end

      original_titles = original_title.join(",")
      country = array.first
      director = array[1]
      language = array[2]
      print "#{y}#{delim}#{titles}#{delim}#{winner}#{delim}#{original_titles}#{delim}#{country}#{delim}#{director}#{delim}#{language}\n"
      newline = true
      title = []
      array = []
      original_title = []
      ctr = 0
      col = 0
      winner = "N"
    elsif line =~ /^<td/
      col += 1
      if line =~ /href="(\d{4})_in_film/
        col = 1
        puts "found a link year #{$1}" if $verbose
        year = [] if newline
        title = [] if newline
        newline = false
        printing = false # don't print unless movie found
        year << $1
        #winner = "W"
        next
      elsif line =~ /Academy_Awards.html/
        col = 1
        next
      end
      case col
      when 2
        # ther is another exception in 1969 second film
        if line =~ /<i><b><a href="(.*?)"/
          winner = "W"
        elsif line =~ /<i><a href="(.*?)"/ 
          winner = "N"
        elsif line =~ /<i>.*?<a href="(.*?)"/ 
          winner = "N"
        end
        puts "found a title #{$1}" if $verbose
        if $1
          printing = true
          title << fix_title($1)
        else
          # ths is for that case of no award given
          printing = true
          title << "No award"
        end
      when 3
        # original title
        if line =~ /<i><b><span .*?>(.*?)<\/span>/ or line =~ /<i><span .*?>(.*?)<\/span>/ or line =~ /<i><b>(.*?)<\/b>/ or line =~ /<i>(.*?)<\/i>/
          original_title << $1
        else
          original_title << "NOT FOUND"
        end
      when 4, 5, 6
        # country, director, language
        if line =~ /<a href="(.*?)"/
          array << $1
        else
          array << "NOT FOUND"
        end
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
    file = ARGV[0] || "../List_of_Academy_Award_winners_and_nominees_for_Best_Foreign_Language_Film.html"
    do_stuff file

  ensure
  end
end

