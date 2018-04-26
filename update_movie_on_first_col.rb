#!/usr/bin/env ruby
# ----------------------------------------------------------------------------- #
#         File: update_movie_on_first_col.rb
#  Description: Takes a TSV file with header names and updates given table with all fields, using first as key.
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2016-02-27 - 19:05
#      License: MIT
#  Last update: 2016-03-07 11:34
# ----------------------------------------------------------------------------- #
#  YFF Copyright (C) 2012-2016 j kepler
#
#  NOTE: XXX WE are using key to resolve but KEY is DUPLICATE for many films with multiple versions !!


require 'sqlite3'
#require 'tqdm'
def getdb
  unless File.exist? $opt_db
    $stderr.puts "File: #{$opt_db} does not exist. Aborting"
    exit 1
  end
  $db = SQLite3::Database.new($opt_db)
end
def _update str, cols
  unless $opt_dryrun
    ret = $db.execute(str, cols);
  end
end
def read_file_in_loop filename
  getdb
  ctr = 0
  header = nil
  str = nil
  selstr = nil
  uctr = 0
  File.open(filename).each { |line|
    line = line.chomp
    next if line =~ /^$/
    cols = line.split("\t")
    key = cols.shift
    ctr += 1
    if ctr == 1
      header = cols
      str = "UPDATE #{$opt_tablename} SET "
      str << header.map{ |s| " #{s} = ? " }.join(",")
      str << " WHERE #{key} = ? ;"
      selstr = "select count(1) from #{$opt_tablename} where #{key} = ? ;"
      puts str
      unless key == "url"
        puts "Please check header and column names"
        yn = STDIN.gets.chomp
        if yn == "n"
          exit 1
        end
      end
      next
    end
    ret = $db.get_first_value(selstr, [key]);
    #puts "select returned #{ret} "

    if ret == 0
      $stderr.puts "Table does not contain key:: #{key} "
      ckey = %x[ ./convert_url_to_key.rb "#{key}" ]
      ckey = ckey.chomp
      # XXX There are several urls with the same key, this will update wrong row !!!
      ret  = $db.get_first_value("select count(1) from #{$opt_tablename} where key = ? ;", [ckey])
      #ret  = $db.get_first_value("select url from #{$opt_tablename} where key = ? ;", [ckey])
      if ret == 1
        key  = $db.get_first_value("select url from #{$opt_tablename} where key = ? ;", [ckey])
        puts "Found correct url possibly: #{key} "
        cols = cols << key
        _update str, cols
        uctr += 1
      elsif ret > 1
        # these situations of no match are only happening since the file on disk does not match 
        #  URL and i am reverse updating imdbid from files.
        puts "Found #{ret} urls for this key. Not updating"
      else
        puts ">>>>>>>> key failed: #{ckey}, #{key}  "
      end
    else
      cols = cols << key
      _update str, cols
      uctr += 1
    end
    #puts cols.join " | "
  }
  $stderr.puts " #{uctr} rows of #{ctr-1} updated. "
end


if __FILE__ == $0
  $opt_tablename = "movie"
  $opt_db = "movie.sqlite"
  $opt_verbose = false
  $opt_dryrun = false
  begin
    # http://www.ruby-doc.org/stdlib/libdoc/optparse/rdoc/classes/OptionParser.html
    require 'optparse'
    options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options] file.tsv"

      opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        options[:verbose] = v
      end
      opts.on("--dry-run", "check don't actually update") do 
        $opt_dryrun = true
      end
      opts.on("-tTABLE", "--table=TABLE", "Name of table to update") do |v|
        options[:table] = v
        $opt_tablename = v
      end
      opts.on("-dDB", "--db=DATABASE", "Name of database file to use") do |v|
        options[:db] = v
        $opt_db = v
      end
    end.parse!

    #p options
    #p ARGV

    if ARGV.empty?
      $stderr.puts "File name needed to process."
      exit 1
    end
    filename=ARGV[0];
    unless File.exist? filename
      $stderr.puts "File: #{filename} does not exist. Aborting "
      exit 1
    end
    if $opt_verbose
      $stderr.puts "Using db: #{$opt_db} and table: #{$opt_tablename} "
    end
    # or 
    read_file_in_loop filename
  ensure
  end
end

