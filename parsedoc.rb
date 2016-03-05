#!/usr/bin/env ruby -w
require 'nokogiri'
require 'logger'
require 'fileutils'
require 'yaml'
require 'color'
# ----------------------------------------------------------------------------- #
#         File: parsedoc.rb
#  Description: xml-parse the downloaded wiki file into YML hash and store
#       Author:  r kumar
#         Date: 2016-02-19 - 20:34
#  Last update: 2016-03-05 00:07
#      License: MIT License
# ----------------------------------------------------------------------------- #
# 2016-02-19 - I am trying to break the process of fetching and updating the db
#  into independent steps, so i can modify the DB if the page is updated etc.
#  I am currently thinking we can create a YML or JSON hash and either return it
#  or else store it in a folder, so it can be updated and then given to a program 
#  that updates the table based on the YML file.

def parse_doc _file, url
  return nil unless _file
  return nil unless url
  parturl = url
  key = %x[ ./convert_url_to_key.rb "#{parturl}" ]
  # FIXED XXX we have been putting in keys with  newline, so matching won't happen ! 2016-03-04 - 19:59 
  key = key.chomp
  id = nil
  res = Hash.new
  #$my_errors = []
  inserting = true
  page = Nokogiri::HTML(open(_file))
  return nil unless page
  $title = ""
  title = page.css("h1")
  if title
    title = title.text
    title.gsub('(film)','')
    title = title.strip
    $title = title
  else 
    puts "ERROR: title not found for #{id} #{parturl}"
    #$my_errors << "no title for #{id}.. #{parturl} pls delete from movie and movie_wiki where id = #{id}"
    return nil
  end
  # A few movies do not have this info box, usually very old movies
  # or old foreign ones. So i was taking at least the title from here for updating
  # But while entering in bulk, sometimes there are other links that pop in and we 
  # should err on the side of reject a link unless sure
  links = page.css("table[class = 'infobox vevent']")
  if links
    if links[0].nil?
      puts " >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> "
      puts "links[0] nil skipping #{id}.. #{$title}"
      puts " <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< "
      #$my_errors << "links[0] nil skipping #{id}.. #{$title} NO INSERT"
      puts "Links: #{links}"
      # XXX please check log file after each run to see what's been rejected.
      # it could be a genuine movie or a fake link
      #$log.warn "XXXX~#{parturl}~SKIPPING~#{id}"
      return nil
    end
    nid = nil
    if true
      if inserting
      #hashputs "ACTUAL INSERT for #{REVERSE} #{$title} #{REVERSE_OFF}: #{nid} : #{parturl} : #{key} "
        #$db.execute("insert into #{table} (id, url, title, key) values (?,?,?,?)", [nid, parturl, $title, key])
        res[:id] = nid
        res[:url] = parturl
        res[:title] = $title
        res[:key] = key
        res[:htmlpath] = _file # TODO needs to be added in table
      end
      links[0].css("tr").each_with_index do |node, iix|
        nt = node.text.strip.gsub(/&#160;/,' ')
        nt = nt.gsub('&#160;',' ')
        s = nt.tr_s("\n","\n").split("\n")
        #$log.debug "XXX:  #{id} #{s}"
        if s[0].nil?
          #$my_errors << "s[0] nil skipping #{id}.. #{$title}" 
          # this could be another fake link that needs to be erased
          #$log.warn "XXX~SKIPPING~#{parturl}~no s[0]~#{$title}"
          $stderr.puts " ERROR: s[0] nil #{$title} "
          $stderr.puts " node: #{node.text.strip} "
          next
          #return nil
        end
        if iix == 0
          puts "   -----  [#{s[0]}] could be title  updating ..."
          title = s[0]
          res[:title] = title
          #$db.execute("update movie set title = ? where url = ?", [ title, parturl] )
        end
        column = s[0].downcase.tr(' ','_')

        column = column.tr_s("()","")
        #puts "updateing #{column} for #{id}"
        flag = false
        case s[0]
        when "Directed by"
          flag = true
          puts "   found #{s[0]}, #{s[1]}"
        when "Starring"
          flag = true
        when "Produced by"
          flag = true
        when "Screenplay by"
          flag = true
        when "Story by"
          flag = true
        when "Music by"
          flag = true
        when "Cinematography"
          flag = true
        when "Editing by", "Edited by"
          flag = true
        when "Distributed by"
          flag = true
        when "Studio"
          flag = true
        when "Country"
          flag = true
        when "Language"
          flag = true
        when "Budget"
          flag = true
        when "Box office"
          flag = true
        when "Running time"
          flag = true
          # next was earlier Release date(s) but is now Release dates
        when "Release date(s)", "Release dates"
          flag = true
          # calc year at this point
          _data = s[1..-1].join(",")
          _t = _data.scan(/19\d\d/)
          if _t.size == 0
            _t = _data.scan(/20\d\d/)
          end
          #$log.debug "XXX: setting year to #{_t[0]} "
          puts "setting year to #{_t[0]} ---------- " if $opt_verbose
          res[:year] = _t.first
          #$db.execute("update movie set year = ? where url = ?", [ _t[0], parturl] )
        end
        if flag
          #puts "update #{id},column is #{column}, data is #{s.join}"
          #$log.debug "update #{id},column is #{column}, data is #{s.join}"
          puts "    update #{parturl},column is #{column}, data is #{s[1..-1].join(',')}" if $opt_verbose
          #$db.execute("update movie set #{column} = ? where url = ?", [ s[1..-1].join(","), parturl] )
          res[column] = s[1..-1].join(",")
        end
      end
    end # false
  else
    puts "No links for #{id} #{$title}"
    #$my_errors << "NO LINKS FOR #{id}.. #{$title}" 
    #return nil
  end
  return res
end

$opt_verbose = false
if __FILE__ == $0
  include Color
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

    if ARGV.size < 2
      raise ArgumentError, "parsedoc requires html filename and url, and optionally name of output YML file"
    end
    filename=ARGV[0];
    url = ARGV[1];
    outfile=ARGV[2] || filename.sub("wiki/","yml/").sub(".html",".yml")
    hash  = parse_doc filename, url
    # if json extension then do a json file, if yml then yaml dump
    # write the yml
    if hash
      File.open(outfile, 'w' ) do |f|
        f << YAML::dump(hash)
      end
      #puts outfile
      File.open("lastfile.tmp","w") {|f2| f2.write(outfile) }
    else
      $stderr.puts color("ERROR: #{$0}: No file updated due to errors", "red")
      File.open("lastfile.tmp","w") {|f2| f2.write("") }
      exit 1
    end
  ensure
  end
end

