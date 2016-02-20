#!/usr/bin/env ruby -w
require 'shellwords'
require 'sqlite3'
require 'nokogiri'
require 'logger'
require 'fileutils'
# URI.decode needed to save file under original name so browsers can link
# http://ruby-doc.org/stdlib-1.9.3/libdoc/uri/rdoc/URI/Escape.html
require 'URI'

REVERSE    = "\e[7m"
REVERSE_OFF    = "\e[27m"

# DESCRIPTION: based on wikipedia URLS in urls.txt, fetches wikipage and stores in wiki directory,
#     parses the wiki page and updates movie table, and also movie_wiki table with page.
#     You may pass in name of file with urls.
#     URL should not be full, it should be in "/wiki/movie_name" format.
#
#     PLEASE DO NOT PASS AMPERSAND IN URL, wget fails. Use single quote for apostrophe
#
#     BUG: if old host passed in then there's an error and a row is inserted. FIXED
#     BUG: if URL is wrong, we still have updated movie with a wrong url which we then 
#     need to delete
#     BUG: we are not escaping single quotes and brackets but the link inside wikipedia
#     files already has many punctuations, decoded. And the browsers cannot read up a file
#     when it is saved with those % codes. 2016-01-01 - we can convert the apostrophes and brackets
#     but what about other unicode character.
#
#     ISSUE: sometimes th wikipedia link of a movie links to director actually, we have no way
#     of knowing this will happen. Then we have two bad rows in system.
#
#     try using wget --restrict-file-names=unix
#     and -k to convert links so we can browse locally.
#     but for this we need to download to disk and not into a variable.
#     We can read up from file them, but how do we know what file it created ?
#
#     If the url does NOT exist in main table, but exists in movie_wiki, 
#     it takes the page from movie_wiki and writes to disk
#     which may be from some old time when were were changing the file name on disk.
#     But now the need is to update files when new info comes in, such as Academy Award
#     info. I don't think i need to store wiki page in table anylonger. it is okay
#     on disk.

## Changes:
# 2016-01-15 - 18:12 insert into movie table only if data found.
# 2016-01-15 - 12:25 remove insert into movie_wiki since it is not used anylonger. I am
#              using the file on disk, since i can hyperlink from it to other files.
#
# 2015-12-14 - INSERTS a row in movie even if wrong url. 
# for the newly added files we need to extract various fields from the info box.
# But now we also need titles since we only put id and url earlier
#
# TODO - wget to trap errorr so we can exit, rather than keep going on. like internet issue
# TODO: sometimes it is not a movie, how to avoid updating such a link
def getdb
  $db = SQLite3::Database.new("movie.sqlite")
end

# convert url to key
def converturl url
  return nil unless url
  newurl = url.sub('/wiki/','').downcase().sub('_(film)','')
  # accept only alphanum and %
  newurl.gsub!(/[^0-9a-z%]/i,'')
  return newurl
end

# ---------------  START -----------------------------
getdb
file = File.open('insert.log', File::WRONLY | File::APPEND | File::CREAT)
urllog = File.open("url.log", 'a');
$log = Logger.new(file)
#$log = Logger.new((File.join(ENV["LOGDIR"] || "./" ,"z.log")))

$log.level = Logger::DEBUG
table = "movie"
#wikitable = "movie_wiki"
starting = $db.get_first_value "select max(id) from #{table};"
puts "starting with #{starting} "
#columns, *rows = $db.execute2 "select id from movie where directed_by is null;"
$my_errors = []
filex = ARGV[0]
filex ||= "urls.txt"
puts "Using #{filex}"
HOST="https://en.wikipedia.org"
OLDHOST="http://en.wikipedia.org"
counter=1
inserting = true
File.open(filex, "r") do |fh|
  fh.each_line do |parturl|
    if parturl.index("&")
      $log.warn "Cannot handle ampersand in URL. please correct #{parturl}"
      puts ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
      puts "Cannot handle ampersand in URL. please correct #{parturl}"
      puts "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
      sleep(5)
      next
    end
    if parturl.index OLDHOST
      # added this block 2015-12-30 
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
      $log.error "Don't know how to handle #{parturl}"
      exit(1)
    end
    #inserting = false
    next if parturl.nil? || parturl.strip == ""
    parturl.chomp!
    nid = counter + starting
    #id = $db.get_first_value "select id from #{table} where url = '#{parturl}';"
    upperurl = parturl.upcase
    # next line crashed due to apostrophe. Monty Python's
    #id = $db.get_first_value "select rowid from #{table} where upper(url) = '#{upperurl}';"
    id = $db.get_first_value %Q[select rowid from #{table} where upper(url) = "#{upperurl}";]
    key = converturl parturl
    if id.nil?
      id = $db.get_first_value "select rowid from #{table} where key = '#{key}';"
      if id
        tmp = $db.get_first_value "select url from #{table} where key = '#{key}';"
        puts "FOUND another row with similar KEY #{key}: #{id} #{tmp} , skipping .."
        $log.warn "XXX:   FOUND another row with similar KEY #{key}: #{id} #{tmp} , SKIPPING .."
      end
    end
    if id.nil?
      # TODO 
      # prior to inserting check if ther is _(film) in url, remove and check for url
      # this is a case of redirection and is resulting in dupes. However, the source
      # must also be corrected if it is being used in a join.
      if false
        # 2016-01-15 - NOTE no longer inserting here, since sometimes the link is bad
        # and we have to delete the rows later.
        puts "=======>>>>>>> INSERTING row #{nid} for '#{parturl}'"
        #exit
        inserting = true
        atitle = parturl.sub("/wiki/","").gsub("_"," ")
        #$db.execute("insert into #{table} (id, url) values (?,?)", [nid, parturl])
        #puts "doing an insert since some pages genuinely have little data such as very old, new or short films"
        $db.execute("insert into #{table} (id, url, title, key) values (?,?,?,?)", [nid, parturl, atitle, key])
        $log.debug "INS:#{table}:#{nid}:#{parturl}, #{key}"
        inserting = false
        counter += 1
      end
    else
      puts "exists #{id} for #{parturl}"
      next
    end
    id = nid
    # don't update old stuff
    #next if id < starting
    #next if exists > 0
    #text = $db.get_first_value "select wiki from movie_wiki where id = #{id};"
    #exit unless text
    #File.open("wiki/#{id}.html","w") { |fw| fw.write(text) }
    #text = %x[w3m -T "text/html" t.html -dump]
    url = HOST + parturl.strip
    # check if we've already downloaded url 
    # 2016-01-15 - no longer updating or using wikitable
    #exists = $db.get_first_value %Q[select count(*) from #{wikitable} where url = "#{parturl}";]
    exists = 0
    if exists > 0
      puts "data exists in movie_wiki for #{parturl}"
      #text = $db.get_first_value %Q[select wiki from #{wikitable} where url = "#{parturl}";]
    else
      # still fails if ampersand in URL regardless of single or double quote
      text = %x[wget -O - "#{url}"] 
      # 2015-12-29 - sometimes the URL is wrong, so we get a blank. The file has zero bytes
      # so we should check here
      if text.nil? or text.chomp == ""
        $stderr.puts "=========== url is wrong, no data received #{url}. pls check ..."
        $my_errors << "no data fetched for #{parturl} pls check/correct."
        next
      end
      #wikiid = $db.get_first_value "select max(id) from #{wikitable};"
      #wikiid += 1
      # changed on 2015-12-16 - now using same id in both tables so easier to link on sql client.
      #wikiid = nid
      # TODO 2015-12-29 - why don't we insert into movie here, so no junk updates
      #$db.execute(" insert into #{wikitable} (id, url, wiki) values (?,?,?)", [wikiid, parturl, text] )
    end
    # this is full of problems, file can have a slash e.g frost/nixon
    partname = parturl.sub('/wiki/','')
    partname = partname.gsub('/','_')
    _file = "wiki/#{partname}.html"
    # wikipedia encodes the URL, which makes browsers unable to link if file saved in encoded manner
    # decode converts % symbols back to punctuation or unicode character
    _file = URI.decode(_file)
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
      puts "    gzip found, expanding"
      FileUtils.mv _file, "#{_file}.gz"
      system "gunzip #{_ff}.gz"
      text = File.readlines(_file).join("\n")
      # should i not update it ??
      #$db.execute(" insert into #{wikitable} (id, url, wiki) values (?,?,?)", [id, parturl, text] )
      #$db.execute(" update #{wikitable} set wiki = ? where url = ?", [text, parturl] )
    end
    page = Nokogiri::HTML(open(_file))
    exit unless page
    $title = ""
    title = page.css("h1")
    if title
      title = title.text
      title.gsub('(film)','')
      title = title.strip
      $title = title
      if false
        # 2016-01-15 - 18:47 not updating any longer till we find the links box
        puts " ============================================================= "
        puts "-----  updating title to #{title} "
        puts " ============================================================= "
        # this often contains (film) or (1978 film) etc, so we try later to get a better one
        # doing this later when we insert
        # now we insert it above, or else we were losing it
        $db.execute("update movie set title = ? where url = ?", [ title, parturl] )
      end
    else 
      puts "title not found for #{id} #{parturl}"
      $my_errors << "no title for #{id}.. #{parturl} pls delete from movie and movie_wiki where id = #{id}"
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
        $my_errors << "links[0] nil skipping #{id}.. #{$title} NO INSERT"
        puts "Links: #{links}"
        # XXX please check log file after each run to see what's been rejected.
        # it could be a genuine movie or a fake link
        $log.warn "XXXX~#{parturl}~SKIPPING~#{id}"
        sleep(5)
        next
      end
      if true
        if inserting
          puts "ACTUAL INSERT for #{REVERSE} #{$title} #{REVERSE_OFF}: #{nid} : #{parturl} : #{key} "
          $db.execute("insert into #{table} (id, url, title, key) values (?,?,?,?)", [nid, parturl, $title, key])
          urllog.puts parturl
          counter += 1
        end
      links[0].css("tr").each_with_index do |node, iix|
        nt = node.text.strip.gsub(/&#160;/,' ')
        nt = nt.gsub('&#160;',' ')
        s = nt.tr_s("\n","\n").split("\n")
        $log.debug "XXX:  #{id} #{s}"
        if s[0].nil?
          $my_errors << "s[0] nil skipping #{id}.. #{$title}" 
          # this could be another fake link that needs to be erased
          $log.warn "XXX~SKIPPING~#{parturl}~no s[0]~#{$title}"
          next
        end
        if iix == 0
          puts "-----  [#{s[0]}] could be title  updating ..."
          title = s[0]
          $db.execute("update movie set title = ? where url = ?", [ title, parturl] )
        end
        column = s[0].downcase.tr(' ','_')

        column = column.tr_s("()","")
        #puts "updateing #{column} for #{id}"
        flag = false
        case s[0]
        when "Directed by"
          flag = true
          puts "found #{s[0]}, #{s[1]}"
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
        when "Editing by"
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
          $log.debug "XXX: setting year to #{_t[0]} "
          puts "setting year to #{_t[0]} ---------- "
          $db.execute("update movie set year = ? where url = ?", [ _t[0], parturl] )
        end
        if flag
          #puts "update #{id},column is #{column}, data is #{s.join}"
          $log.debug "update #{id},column is #{column}, data is #{s.join}"
          puts "    update #{id},column is #{column}, data is #{s[1..-1].join(',')}"
          $db.execute("update movie set #{column} = ? where url = ?", [ s[1..-1].join(","), parturl] )
        end
      end
      end # false
    else
      puts "No links for #{id} #{$title}"
      $my_errors << "NO LINKS FOR #{id}.. #{$title}" 
    end

    # sometimes an insert happens and then we skip without updatng counter
    # so you get muliple updates with one counter
    #exit if counter > 0
    sleep(2)
  end
end
urllog.close

puts "Errors:"
$my_errors.each do |e|
  puts "#{e}"
end
puts "::: #{$my_errors.size}"
puts "Inserted #{counter-1} rows starting at #{starting} "
puts "New files need to be piped through convert_all_links.sh"
