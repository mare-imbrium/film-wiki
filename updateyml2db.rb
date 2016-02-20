#!/usr/bin/env ruby -w
# ----------------------------------------------------------------------------- #
#         File: updateyml2db.rb
#  Description: this updates the movie.sqlite database from a yaml file
#       Author:  
#         Date: 2016-02-20 - 00:22
#  Last update: 2016-02-20 20:32
#      License: MIT License
# ----------------------------------------------------------------------------- #
#

require 'yaml'
require 'sqlite3'

dbname = "movie.sqlite"
$db = SQLite3::Database.new(dbname)
# read up yaml file
# then update table
def readfile filename
  if filename.index(".json")
    require 'json'
    str = File.read(filename)
    hash = JSON.parse(str)
  elsif filename.index ".yml"
    hash = YAML::load( File.open( filename ) )
  else
    $stderr.puts "Don't know how to handle #{filename}, pass either .json or .yml"
    exit 1
  end

  if $opt_verbose
    hash.each_pair {|k, v| 
      puts "#{k} : #{v}"
    }
  end
  puts "URL=" + hash[:url]
  rowid = table_insert_hash $db, "movie", :url, hash
  puts rowid
=begin
  url = hash.delete(:url)
  puts "URL=" + url
  hash.each_pair {|k, v| 
    if v
      s = %[ update movie set #{k} = "#{v}" where url = "#{url}" ;]
      puts s
    end
  }
=end


end

# takes a hash containing column name and value.
# keyname is name of keyfield which will either be inserted or else updated. This assumes that 
# all other values can be NULL since I update after insert.
# TODO maybe to be safe do a complete insert followed by a UPDATE is no insert happened. this way if 
#  a table has a NOT NULL or unique constraint that won't fail.
def table_insert_hash db, table, keyname, hash
    key = hash.delete keyname
    raise ArgumentError, "key is nil #{keyname}" unless key
    str = "INSERT OR IGNORE INTO #{table} (#{keyname}) VALUES ('#{key}') ;"
    $stderr.puts str if $opt_verbose
    db.execute(str)
    str = "UPDATE #{table} SET "
    qstr = [] # question marks
    bind_vars = [] # values to insert
    hash.each_pair { |name, val| 
      bind_vars << val
      qstr << " #{name}=? "
    }
    #str << fstr
    #str << ") values ("
    str << qstr.join(",")
    str << %Q[ WHERE #{keyname} = '#{key}' ]
    str << ";"
    $stderr.puts str if $opt_verbose
    $stderr.puts "#{hash[keyname]}    #{hash["title"]} "
    #puts " #{hash["Title"]} #{hash["imdbID"]} "
    retval = db.execute(str, bind_vars)
    #rowid = db.get_first_value( "select last_insert_rowid();")
    return retval
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

    #p options
    #p ARGV

    if ARGV.size == 0
      raise ArgumentError, "YML or JSON file with movie details required"
    end
    filename=ARGV[0];
    if !File.exist? filename
      $stderr.puts "File does not exist #{filename}. Aborting."
      exit 1
    end
    readfile filename
  ensure
  end
end

