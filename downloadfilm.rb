#!/usr/bin/env ruby -w
# ----------------------------------------------------------------------------- #
#         File: downloadfilm.rb
#  Description: fetch and save a film from wikipedia given a film URL.
#  Prints the filename saved to stdout. all other output to stderr.
#  Can print nil if nothing returned by wikipedia
#
#  Trying to separate out the logic for downloading a film URL and saving it.
#  Taken from fetchupdate.rb on 2016-02-20 - 
#  This is the first step. After this one would parse the file using parsedoc.rb
#  and then update into db using ./updateyml2db.rb.
#
#  XXX Make sure you run this from the MOV folder since it will save the file in wiki
#
#       Author:  
#         Date: 2016-02-20 - 14:19
#  Last update: 2016-02-20 18:45
#      License: MIT License
# ----------------------------------------------------------------------------- #
#
require 'shellwords'
require 'sqlite3'
require 'nokogiri'
require 'logger'
require 'fileutils'
# URI.decode needed to save file under original name so browsers can link
# http://ruby-doc.org/stdlib-1.9.3/libdoc/uri/rdoc/URI/Escape.html
require 'URI'

def getdb
  db = "movie.sqlite"
  if File.exist?(db)
    $db = SQLite3::Database.new("movie.sqlite")
  else
    raise "#{$0}: #{db} does not exist here! Wrong path"
  end
end
def uri_to_filename parturl
    partname = parturl.sub('/wiki/','')
    partname = partname.gsub('/','_')
    _file = "wiki/#{partname}.html"
    # wikipedia encodes the URL, which makes browsers unable to link if file saved in encoded manner
    # decode converts % symbols back to punctuation or unicode character
    _file = URI.decode(_file)
    return _file
end

# convert url to key
# NOTE: we really don't use key anywhere other than in an extra validation, so don't know if useless
def converturl url
  return nil unless url
  newurl = url.sub('/wiki/','').downcase().sub('_(film)','')
  # accept only alphanum and %
  newurl.gsub!(/[^0-9a-z%]/i,'')
  return newurl
end
HOST="https://en.wikipedia.org"
OLDHOST="http://en.wikipedia.org"
#
# parturl is "/wiki/film_name" without the https://en.wikipedia.org part
# _file is path to save to (optional, if not given will be determined and written to a file)
# @return filename / path file saved as
# @return nil if error in url or nothing returned
def fetchfilm parturl, _file=nil
  return nil unless parturl
  table = "movie"
    if parturl.index("&")
      #$log.warn "Cannot handle ampersand in URL. please correct #{parturl}"
      $stderr.puts ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
      $stderr.puts "Cannot handle ampersand in URL. please correct #{parturl}"
      $stderr.puts "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
      return nil
    end
    # remove HOST and keep last part
    if parturl.index OLDHOST
      parturl = parturl[OLDHOST.length..-1]
    end
    if parturl.index HOST
      parturl = parturl[HOST.length..-1]
    end
    if parturl.index("http:") or parturl.index("https:")
      # added this block 2015-12-30 
      $stderr.puts ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
      $stderr.puts "Don't know how to handle this host : #{parturl}. Pls use #{HOST} if you must."
      $stderr.puts "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
      #$log.error "Don't know how to handle #{parturl}"
      #exit(1)
      return nil
    end
    #inserting = false
    return nil  if parturl.nil? || parturl.strip == ""
    parturl = parturl.chomp
    #nid = counter + starting
    nid = nil
    upperurl = parturl.upcase
    key = converturl parturl
    id = $db.get_first_value %Q[select rowid from #{table} where upper(url) = "#{upperurl}";]
    # in some cases the data on wiki has changed a lot, so we are forcing a download
    unless $opt_force
      if id.nil?
        id = $db.get_first_value "select rowid from #{table} where key = '#{key}';"
        if id
          tmp = $db.get_first_value "select url from #{table} where key = '#{key}';"
          $stderr.puts "FOUND another row with similar KEY #{key}: #{id} #{tmp} , skipping .."
          #$log.warn "XXX:   FOUND another row with similar KEY #{key}: #{id} #{tmp} , SKIPPING .."
          return nil
        end
      else
        $stderr.puts "FOUND another row with #{parturl} ... skipping "
        return nil
      end
    end
    id = nid
    url = HOST + parturl.strip
    # still fails if ampersand in URL regardless of single or double quote
    # TODO should we try curl instead ?
    text = %x[wget -q -O - "#{url}"] 
    # 2015-12-29 - sometimes the URL is wrong, so we get a blank. The file has zero bytes
    # so we should check here
    if text.nil? or text.chomp == ""
      $stderr.puts "=========== url is wrong, no data received #{url}. pls check ..."
      #$my_errors << "no data fetched for #{parturl} pls check/correct."
      return nil
    end
    #_file ||= uri_to_filename(parturl)
    # TODO we need to write this filename in the database so we can open the file if user selects title
    #  from a query
    #  parturl has removed /wiki/ replaced / with _, then decode URL and added wiki/ folder name and .html to get filename
    _ff = Shellwords.escape(_file)
    File.open(_file,"w") {|f2| f2.write(text) }
    type = `file #{_ff}`

    # check if its a zip
    # SOMETime it  comes in zip format. how do contreol that ?
    # if file says zipped then add gz extension and do a gunzip
    if type.index "gzip"
      $stderr.puts "    gzip found, expanding"
      FileUtils.mv _file, "#{_file}.gz"
      system "gunzip #{_ff}.gz"
      #text = File.readlines(_file).join("\n")
    end
    return _file
end


if __FILE__ == $0
  $opt_force = false
  begin
    # http://www.ruby-doc.org/stdlib/libdoc/optparse/rdoc/classes/OptionParser.html
    require 'optparse'
    options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options] URL"

      opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        options[:verbose] = v
      end
      opts.on("-f", "--force", "force download even if exists") do 
        options[:force] = true
        $opt_force = true
      end
    end.parse!

    #p options
    #p ARGV

    parturl=ARGV[0];
    raise ArgumentError, "Require a wikipedia url of a movie" unless parturl
    htmlpath = ARGV[1] || uri_to_filename(parturl);
    getdb
    path = fetchfilm parturl, htmlpath
    $stdout.puts path
    File.open("lastfile.tmp","w") {|f2| f2.write(path) }
  ensure
  end
end

