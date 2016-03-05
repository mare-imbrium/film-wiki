#!/usr/bin/env ruby -w
require 'shellwords'
require 'sqlite3'
require 'nokogiri'
require 'logger'
require 'fileutils'

# Desc: copy one rowid to another 
# This is happeneing due to dupe ids. 
# Pass source rowid and target rowid.
# one by one compare and update values from source to target and then delete target.
# If update uRL will not be able to set without deleting.
#


def getdb
  $db = SQLite3::Database.new("../movie.sqlite")
end

# make a key from the url removing everything but alphanum and % and downcasing
# There will still be some dupes with a "The_" preceding but if we remove this
# we could have genuinely different movies colliding.
#

getdb

sou=ARGV[0]
tar=ARGV[1]
exit if sou.nil? || tar.nil?

table = "movie"
$log = Logger.new((File.join(ENV["LOGDIR"] || "./" ,"X.log")))

$log.level = Logger::DEBUG
cols, *dummy = $db.execute2("select rowid, * from #{table} where rowid = ?;", [sou])
dum, *data = $db.execute2("select rowid, title, url, directed_by from #{table} where rowid = ?;", [sou])
dum, *datanew = $db.execute2("select rowid, title, url, directed_by from #{table} where rowid = ?;", [tar])

puts "GOOD: "
datanew.each { |c| print " #{c} , " }
puts
puts "BAD: "
data.each { |c| print " #{c} , " }
puts "------"
puts "WARNING #{datanew[1]} =! #{data[1]} " if datanew[1] != data[1]

$stdin.gets



$my_errors = []
#HOST="http://en.wikipedia.org"
# do not update these fields
[ "rowid", "id", "title", "year", "nom", "won", "seen", "rating", "poss_dupe"].each do |c|
  cols.delete c
end
cols.each do |c|
  nval = $db.get_first_value("select #{c} from #{table} where rowid = ?", [sou])
  oval = $db.get_first_value("select #{c} from #{table} where rowid = ?", [tar])

  if oval == nval
    puts "    #{c}: oval and nval are same, skipping ..."
    next
  end
  sugg="n"
  if oval.nil? && nval
    puts "YOU SHOULD update"
    sugg = "y"
  end
  if oval && nval.nil?
    puts "==> you should NOT update as you will overrwrite with nil"
    sugg = "n"
  end
  puts " old val is: #{oval} "
  puts " new val is #{c} = #{nval}, should i update: #{sugg}. (ENTER or n] "
  ans = $stdin.gets().chomp
  if ans == "n"
    puts "   skipping #{c} "
    next
  end
  $db.execute("update #{table} set #{c} = ? where rowid = ?", [ nval, tar])
end

puts "New row is:"
cols, *nline = $db.execute2("select rowid, * from #{table} where rowid = ?;", [tar])
nline[0].each_with_index do |v, i|
  puts " #{cols[i]} : #{v} "
end
puts "Should I delete #{sou} ? (y)"
ans = $stdin.gets().chomp
if ans == "y"
  $db.execute("delete from #{table} where rowid = ?", [ sou])
  puts "deleted #{sou}"
end
