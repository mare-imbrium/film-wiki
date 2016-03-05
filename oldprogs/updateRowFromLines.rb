#!/usr/bin/env ruby -w
# ----------------------------------------------------------------------------- #
#         File: updateRowFromLines.rb
#  Description: take a listing from sqlite -line and edit it and update it.
#     This is required due to dupes. I can vimdiff them, edit one and update it
#     and delete the other.
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2016-03-04 - 20:07
#      License: MIT
#  Last update: 2016-03-04 20:44
# ----------------------------------------------------------------------------- #
#  YFF Copyright (C) 2012-2016 j kepler
#

require 'sqlite3'

def getdb
  ofile="../movie.sqlite"
  unless File.exist? ofile
    $stderr.puts "File: does not exist #{ofile}. Aborting."
    exit 1
  end
  $db = SQLite3::Database.new(ofile)
end

def read_file_in_loop filename
  getdb
  ctr = 0
  str = "UPDATE movie set "
  where = nil
  arr = []
  vals = []
  rowid = nil
  flds = []
  File.open(filename).each { |line|
    line = line.chomp
    next if line =~ /^$/
    
    ix = line.index("=");
    fld = line[0,ix].strip
    puts fld
    value = line[ix + 1..-1].strip
    if fld == "rowid"
      where = " where rowid = #{value} ; "
      rowid = value
      next
    end
    if value == ""
      # need to take care of this
      value = nil
    end
    arr << " #{fld} = ? "
    flds << fld
    vals << value
    #cols = line.split("=")
    ctr += 1
    # puts line if line =~ /blue/
  }
  sarr = arr.join(",")
  statement = str + sarr + where;
  puts statement
  puts 
  puts vals.join(",")
  puts "Are you sure you want to update ?"
  ans = STDIN.gets
  ans = ans.chomp
  if ans == "y"
    $db.execute(statement, vals);
    puts "Update done !"
    selstr = flds.join(",")
    cols = $db.get_first_row("select #{selstr} from movie where rowid = #{rowid};")
    puts cols.join("\n");
  else
    puts "No update done !"
  end
end


if __FILE__ == $0
  begin
    # http://www.ruby-doc.org/stdlib/libdoc/optparse/rdoc/classes/OptionParser.html
    require 'optparse'
    options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options]"

      opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        options[:verbose] = v
      end
    end.parse!


    filename=ARGV[0] || "defaultname";
    unless File.exist? filename
      $stderr.puts "File: #{filename} does not exist. Aborting"
      exit 1
    end
    read_file_in_loop filename
  ensure
  end
end

