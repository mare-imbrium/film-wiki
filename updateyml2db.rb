#!/usr/bin/env ruby
# ----------------------------------------------------------------------------- #
#         File: updateyml2db.rb
#  Description: this updates the movie.sqlite database from a yaml file
#               Pass the yml/xxxxx.yml file name to update
#               The update happens on the URL field since this file does not 
#               have the rowid.
#               This is called during the initial fetch process. The YML is created by parsedoc
#               and then this program is called to insert/update the YML data into the database.
#
#               This program can be called when the YML is manually updated too.
#       Author:  
#         Date: 2016-02-20 - 00:22
#  Last update: 2018-02-20 14:38
#      License: MIT License
# ----------------------------------------------------------------------------- #
#
# TODO
#  Maybe we can check against columns of database and only insert those. that allows me to put all information
#   into the YML that comes in info box, so i can see what has changed.
#  2016-03-10 - check if imdbid already in database for another url
#
# == Changelog
# - 2018-02-20 - Added comment on top of file
# - 2016-03-05 - added update_dt so we know when a record was changed, maybe a force_fetch
# - 2016-03-10 - added check for imdbid already existing. Currently we allow update of earlier rows url.

require 'yaml'
require 'sqlite3'
require 'color'

dbname = "movie.sqlite"
$db = SQLite3::Database.new(dbname)

def tty_gets
    fd = IO.sysopen "/dev/tty", "r"
    ios = IO.new(fd, "r")
    ans = ios.gets 
    if ans
      return ans.chomp
    end
    return "n"
end
# ---------- get_column_names ------------------------------------------ # 
# return an array of columns names for given table
#  @example :  column_array = get_column_names(db, table)
# ---------------------------------------------------------------------- # 

def get_column_names db, table
  columns, *rows = db.execute2(" select * from #{table} limit 1; ")
  return columns
end


# ---------------------------------------------------------------------- # 
# read up yaml file
# then update table
# ---------------------------------------------------------------------- # 
def readfile filename
  if filename.index(".json")
    require 'json'
    str = File.read(filename)
    hash = JSON.parse(str)
  elsif filename.index ".yml"
    hash = YAML::load( File.open( filename ) )
  else
    $stderr.puts "#{$0}: Don't know how to handle #{filename}, pass either .json or .yml"
    exit 1
  end
  # 2016-03-05 - adding processing of update_dt
  hash["update_dt"] = File.mtime(filename).to_s[0,19]

  if $opt_verbose
    hash.each_pair {|k, v| 
      puts "#{k} : #{v}"
    }
  end
  puts "  #{$0}: URL=" + hash[:url]
  rowid = table_insert_hash $db, "movie", :url, hash
  return rowid
  #puts rowid
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
# --------- _update_url ------------------------------------------------------- #
# Update another row's url to this url so that that row is updated.
#  This is to avoid a duplicate entry, and if we do not insert this URL then the 
#  update will fail too.
# ------------------------------------------------------------------------------#
def _update_url db, oldurl, newurl
  selstr = "select rowid from movie where url = ?"
  rowid = db.get_first_value(selstr, [newurl])
  if rowid
    $stderr.puts color(" ERROR: #{rowid} contains #{newurl} already. Pls merge with #{oldurl} ", "yellow", "reverse")
    return false
  end

  str = "UPDATE movie set url = ? where url = ?;"
  db.execute( str, [newurl, oldurl] )
  $stderr.puts "Updated #{oldurl} to #{newurl} ." if $opt_verbose
  return true
end

# --------------- check_duplicate ------------------------------------------------- #
#  check for possible duplication. 1st check for the same imbdcode in another row
#  Then check for same title and year in another row.
# --------------------------------------------------------------------------------- #
def check_duplicate(db, table, keyname, hash)
  title = hash["title"]
  year = hash["year"].to_i
  title = hash[:title]
  year = hash[:year].to_i
  newurl = hash[:url]
  nimdbid = hash["imdbid"]
  if nimdbid and nimdbid.strip != ""
    str = %Q[select url from movie where imdbid = ? and url != ? ;]
    url = db.get_first_value( str , [ nimdbid, newurl ] )
    if url
      $stderr.puts color(" updateyml: ERROR: #{newurl} already exists as #{url} -> #{title} #{year}:#{nimdbid}", "red" )
      $stdout.print color("Do you wan't to update #{url} to #{newurl} ? (y/n): ", "white", "reverse")
      ans = tty_gets
      if ans == "y"
        return _update_url db, url, newurl
      end
    end
  end
  url = db.get_first_value( str , [ nimdbid, newurl ] )
  str = %Q[select url from movie where title = ? and year = ? and url != ? ;]
  #puts str
  url = db.get_first_value( str , [ title, year, newurl ] )
  if url
    $stderr.puts color(" updateyml: ERROR: #{newurl} already exists as #{url} -> #{title} #{year} ", "red" )
    $stdout.print color("Do you wan't to update #{url} to #{newurl} ? (y/n): ", "white", "reverse")
    fd = IO.sysopen "/dev/tty", "r"
    ios = IO.new(fd, "r")
    ans = ios.gets 
    #ans = STDIN.gets
    if ans
      if ans.chomp == "y"
        return _update_url db, url, newurl
      end
    end
    return true
  end
  return false
end

# takes a hash containing column name and value.
# keyname is name of keyfield which will either be inserted or else updated. This assumes that 
# all other values can be NULL since I update after insert.
# TODO maybe to be safe do a complete insert followed by a UPDATE is no insert happened. this way if 
#  a table has a NOT NULL or unique constraint that won't fail.
# TODO - we should check title plus year to make sure that it's not there already, or key plus year
#   currently, this is preventing an update
def table_insert_hash db, table, keyname, hash
  rowid = nil
  ret = check_duplicate(db, table, keyname, hash)
  key = hash.delete keyname
  raise ArgumentError, "#{$app}: key is nil #{keyname}" unless key
  # 2016-03-05 - adding processing for create_dt and update_dt
  create_dt = hash.delete "create_dt"
  if ret
    $stderr.puts color(" updateyml: WARNING: not inserting #{key} ", "red" )
  else
    # next line crashed when url had single quote
    #str = "INSERT OR IGNORE INTO #{table} (#{keyname}, create_dt) VALUES ('#{key}', '#{create_dt}') ;"
    str = "INSERT OR IGNORE INTO #{table} (#{keyname}, create_dt) VALUES (? , ?);"
    $stderr.puts str if $opt_verbose
    db.execute(str, [key, create_dt])
    rowid = db.get_first_value( "select last_insert_rowid();")
    if rowid == 0
      puts color("  EXISTS:   #{rowid}", "red", "bold")
    else
      puts color("  INSERTED: #{rowid}", "green", "bold")
    end
  end
  column_array = get_column_names(db, table)

  str = "UPDATE #{table} SET "
  qstr = [] # question marks
  bind_vars = [] # values to insert
  hash.each_pair { |name, val| 
    # 2016-03-10 -  added check for whether exists in column array
    if column_array.include? name.to_s
      bind_vars << val
      qstr << " #{name}=? "
    end
  }
  #str << fstr
  #str << ") values ("
  str << qstr.join(",")
  str << %Q[ WHERE #{keyname} = ? ]
  str << ";"
  $stderr.puts str if $opt_verbose
  $stderr.puts "#{key}    #{hash["title"]} " if $opt_verbose
  #puts " #{hash["Title"]} #{hash["imdbID"]} "
  bind_vars << key
  retval = db.execute(str, bind_vars)
  #rowid = db.get_first_value( "select last_insert_rowid();")
  if rowid.nil?
    # check if update really happened since INSERT was not allowed
    str = %Q[select count(1) from movie where url = ? ;]
    url = db.get_first_value( str , [ key ] )
    if url == 0
      $stderr.puts color(" updateyml: ERROR: #{key} not present, so UPDATE not successful.", "red" )
    end
  end
  return rowid
end

if __FILE__ == $0
  include Color
   $app = File.basename($0)

  $opt_verbose = false
  $opt_force = false
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
      opts.on("-f", "--force", "force download even if exists") do 
        options[:force] = true
        $opt_force = true
      end
    end.parse!

    #p options
    #p ARGV

    if ARGV.size == 0
      raise ArgumentError, "#{$0}: YML or JSON file with movie details required"
    end
    filename=ARGV[0];
    if !File.exist? filename
      $stderr.puts "#{$0}: File does not exist #{filename}. Aborting."
      exit 1
    end
    ret = readfile filename
    if ret == -1
      # update aborted due to duplicate
      exit 1
    else
      exit 0
    end
  ensure
  end
end

