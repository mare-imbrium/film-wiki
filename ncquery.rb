#!/usr/bin/env ruby
# Description: Browse MOV database - do we really need this?
# Last update: 2018-04-26 08:54
# 2018-04-22
require 'umbra'
require 'umbra/label'
require 'umbra/listbox'
require 'umbra/box'
require 'umbra/togglebutton'
require 'umbra/field'
require 'umbra/menu'
require 'umbra/textbox'
require 'sqlite3'

#---------- TODO
# DONE link to description from IMDB database. Or should we use the plot in the wiki files ?
# DONE show status on side from movie_status
# NOTE: If we link to imdb in all our queries, and that database moves, then this app will not work at all!
# TODO - genre ? take from imdb or link to it. Should have it in queries
# TODO - imdb rating. query and display, sort by rating. Shown at bottom right now.

def startup # {{{
  require 'logger'
  require 'date'

    path = File.join(ENV["LOGDIR"] || "./" ,"v.log")
    file   = File.open(path, File::WRONLY|File::TRUNC|File::CREAT) 
    $log = Logger.new(path)
    $log.level = Logger::DEBUG
    today = Time.now.to_s
    $log.info "MOV #{$0} started on #{today}"
    FFI::NCurses.init_pair(10,  FFI::NCurses::BLACK,   FFI::NCurses::GREEN) # statusline
    dbname = "movie.sqlite"
    @imdbfile = '/Volumes/Pacino/dziga_backup/rahul/Downloads/MOV/imdbdata/imdb.sqlite'
    @db = SQLite3::Database.new(dbname)
    @tablename = "movie"
    #@query ="SELECT rowid, year, title, directed_by, starring , language"
    @total = @db.get_first_value("select count(*) from #{@tablename}")
end # }}}
def flow row, scol, *widgets # {{{
  widgets.each do |w|
    w.row = row
    w.col = scol
    if w.width and w.width > 0
      scol += w.width + 1
    elsif w.text 
      scol += w.text.length + 1
    else
      scol += 10
    end
  end
end # }}}
def get_data db, sql # {{{
  $log.debug "SQL: #{sql} "
  $columns, *rows = db.execute2(sql)
  #$log.debug "XXX COLUMNS #{sql}, #{rows.count}  "
  content = rows
  return nil if content.nil? or content[0].nil?
  $datatypes = content[0].types #if @datatypes.nil?
  return content
end # }}}
def current_row_as_array lb
  lb.list()[lb.current_index]
end
# update the status field in the yify table
# We need to update in list also, for highlighting to show
def update_status lb # {{{
  row = current_row_as_array(lb)
  id = row.first
  imdbid = get_imdbid(lb)

  h = { :x => :hide, :i => :interested, :n => 'not interested', :s => :seen, :m => 'seen by mum',
        :"1" => :bad, :"2" => :average , :"3" => :good , :"4" => :vgood, :"5" => :great, :"0" => :unrated }
  m = Menu.new "Movie Status Menu", h
  ch = m.getkey
  #menu_text = h[ch.to_sym]
  return unless ch # escape pressed
  $log.debug "  update_status: setting #{id} to #{ch} "
  tablename = "movie_status"
  # if not existing, we need to insert
  db = SQLite3::Database.new(@imdbfile)

  status = ch.to_s
  row[6] = status
  lb.touch
  count = db.get_first_value("SELECT count(1) FROM movie_status WHERE imdbid = '#{imdbid}'")
  if count == 0
    $log.debug  ">>>No row in imdb.sqlite movie_status for #{imdbid}"
    str = "INSERT INTO movie_status (imdbid, status) VALUES (?,?)"
    db.execute(str, [imdbid, status])
    return
  end
  ret = db.execute("UPDATE movie_status SET status = ? WHERE imdbid = ?", [ status, imdbid ])
end # }}}
def sort_menu lb # {{{
  h = { :y => :year, :r => :rating, :t => :title, :i => :id, :n => "newest" }
  m = Menu.new "Sort Menu", h
  ch = m.getkey
  l = lb.list
  sorted = nil
  case ch
  when "y"
    sorted = l.sort_by { |k| k[2] }
  when "n"
    sorted = l.sort_by { |k| k[2].to_i()*-1 }
  when "r"
    sorted = l.sort_by { |k| k[4].to_i()*-1 }
  when "t"
    sorted = l.sort_by { |k| k[3] }
  when "i"
    sorted = l.sort_by { |k| k[0] }
  else
    alert("sortmenu got #{ch} unhandled")
    return
  end
  lb.list = sorted if sorted
end # }}}
def view_details lb, db # {{{
  data = lb.current_row()
  #id = data.first
  id = data[0,4]
  file='/Volumes/Pacino/dziga_backup/rahul/Downloads/MOV/movie.sqlite'
  res = %x{ sqlite3 #{file} -line "select * from movie where rowid = '#{id}'"}
  $log.debug "  RETURNED from movie with: "
  $log.debug "  #{res} "
  if res and !res.empty?
    #res = wrap_text(res, 80)
    res = res.split("\n")
    $log.debug "wrapped:  #{res} "
    view res
  end
  #row = @db.get_first_row("SELECT cast(id as text), title, cast(year as text), language, genres, url, imdbid, rating, description_full FROM #{@tablename} WHERE rowid = #{id}")
  #row = @db.get_first_row("SELECT * FROM #{@tablename} WHERE rowid = #{id}")
  #desc = wrap_text(row[-1]) if row[-1]
  #desc ||= ["No description"]
  #row[-1] = "--------------------"
  #row.push(*desc)

  #$log.debug "  ROWW: #{row}"
  #view row
end # }}}
# remove a row from screen and also update database with hide status
def delete_row lb # {{{
  index = lb.current_index
  id = lb.list[lb.current_index].first
  lb.list().delete_at(index)
  lb.touch
  ret = @db.execute("UPDATE #{@tablename} SET status = ? WHERE rowid = ?", [ "x", id ])
end # }}}
# wraps given string to width characters, returning an array
# returns nil if null string given
def wrap_text(s, width=78)    # {{{
  return nil unless s
	s.gsub(/(.{1,#{width}})(\s+|\Z)/, "\\1\n").split("\n")
end
def statusline win, str, column = 1
  # LINES-2 prints on second last line so that box can be seen
  win.printstring( FFI::NCurses.LINES-1, 0, " "*(win.width), 6, REVERSE)
  #win.printstring( FFI::NCurses.LINES-1, column, str, 6, REVERSE)
  # printing fields in two alternating colors so easier to see
  str.split("|").each_with_index {|s,ix|
    _color = 6
    _color = 5 if ix%2==0
    win.printstring( FFI::NCurses.LINES-1, column, s, _color, REVERSE)
    column += s.length+1
  }
end   # }}}
def view_in_browser lb # {{{
  ## view imdb page in browser
  imdbid = get_columns_as_array(lb, "imdbid").first
  system("open https://www.imdb.com/title/#{imdbid}/")
end # }}}
def view_wiki_page lb # {{{
  ## view wiki page in browser
  url = get_columns_as_array(lb, "url").first
  #https://en.wikipedia.org/wiki/
  system("open https://en.wikipedia.org#{url}")
end # }}}
def get_imdbid(lb)
  imdbid = get_columns_as_array(lb, "imdbid").first
end
def join_imdb lb # {{{
  curr = lb.current_index
  data = lb.list[curr]
  imdbid = get_imdbid(lb)
  $log.debug "  join :: imdbid:#{imdbid}. data:#{data}"
  file='/Volumes/Pacino/dziga_backup/rahul/Downloads/MOV/imdbdata/imdb.sqlite'
  res = %x{ sqlite3 #{file} -line "select * from imdb where imdbid = '#{imdbid}'"}
  $log.debug "  RETURNED rfom imdb with: "
  $log.debug "  #{res} "
  if res and !res.empty?
    #res = wrap_text(res, 80)
    res = res.split("\n")
    # we need to wrap the plot but it looks bad wrapped in the middle since there are no indents.
    #  So I am adding it to the end.
    plot = res[10]
    res.delete_at(10)
    res.insert(-1,*wrap_text(plot,80))
    $log.debug "wrapped:  #{res} "
    view res
  else
    ret = alert("No data in #{File.basename(file)} for #{imdbid}. Shall I fetch?", buttons: ["Ok","Cancel"])
    # the dialog continues to show until the next command is over
    # should i do a refresh here, or panel update ?
    # If the next command hangs then the window also gets stuck on screen
    if ret == 0

      #$mywin.refresh # this solves the issue of the dialog remaining here, but user will wonder why
                     # app is unresponsive
      # f.sh fetches from omdb api
      command = File.expand_path("~/bin/src/f.sh")
      # system screwed up the display
      #system("#{command} #{imdbid}")
      res = %x{#{command} #{imdbid} 2>&1}

      $log.debug "==> f.sh: #{res}"
    end
  end
end # }}}
# returns array
def get_columns_from_imdb(lb, *columns)
  imdbid = get_imdbid(lb)
  db = SQLite3::Database.new(@imdbfile)
  cols = columns.join(", ")
  return db.get_first_row("SELECT #{cols} FROM imdb WHERE imdbid = '#{imdbid}'")
end
def generic_edit data, columns # {{{
  # unused as yet
  # Since the number of columns can be long, we should perhaps the the vim file way of editing
  #   and then update from the file.
  require 'umbra/messagebox'
  require 'umbra/labeledfield'
  array = []
  mb = MessageBox.new title: "Editing #{data.first}", width: 80 do
    data.each_with_index do |r, ix|
      f =  LabeledField.new label: columns[ix], name: columns[ix], text: r, col: 20, color_pair: CP_CYAN, attr: REVERSE
      add f
      array << f
    end
  end
  ret = mb.run
  # return a hash rather than an array. maybe we should pass a hash also
  return ret, array
end # }}}
def edit_row lb # {{{
  # TODO put actual widths and maxlens for various fields.
  index = lb.current_index
  id = lb.list[lb.current_index].first
  # NOTE: using * will hang system as field will go off screen.
  rowdata = get_data(@db, "select title, starring, directed_by, nom, won, imdbid from #{@tablename} WHERE rowid = #{id}")
  $log.debug "  DATA = #{rowdata}"
  $log.debug "  COLS = #{$columns}"
  return unless rowdata
  return if rowdata.empty?
  return if rowdata.first.empty?
  data = rowdata.first
  require 'umbra/messagebox'
  require 'umbra/labeledfield'
  
  array = []
  mb = MessageBox.new title: "Editing #{data.first}", width: 80 do
    data.each_with_index do |r, ix|
      # FIXME bug in Field.rb such that if width is 20, then field will allow only 40 chars even though it shows maxlen as 100 or 1000.
      x =  LabeledField.new label: $columns[ix], name: $columns[ix], text: r, col: 20, width: 50, maxlen: 100, color_pair: CP_CYAN, attr: REVERSE
      array << x
      add x
    end
  end
  ret = mb.run
  if ret == 0
    # okay pressed
    _update_row(@db, id, $columns, data, array)
    # TODO the on-screen row also to be updated.
  end
end # }}}
def _update_row db, id, columns, data, array # {{{
  columns.each_with_index do |c, ix|
    next if c == "id" or c == "rowid"
    oldvalue = data[ix]
    value = array[ix].text
    if oldvalue != value
      $log.debug "  updating #{c} to #{value} for #{id}  "
      ret = db.execute("UPDATE #{@tablename} SET #{c} = ? WHERE rowid = ?", [ value, id ])
    end
  end
end # }}}
def update_genre(lb) # {{{
  imdbid = get_columns_as_array(lb, "imdbid").first
  $log.debug "  IMDBID is #{imdbid}"
  if !File.exist?(@imdbfile)
    alert "IMDB file does not exist!"
    return
  end
  db = SQLite3::Database.new(@imdbfile)
  genre, language = db.get_first_row("SELECT genre, language FROM imdb WHERE imdbid = '#{imdbid}'")
  $log.debug "  IMDB: #{genre} :: #{language}"
  if genre.nil? and language.nil?
    alert "No row in imdb.sqlite for #{imdbid}"
    return
  end
  #alert "  IMDB: #{genre}:: #{language}"
  #alert " Got #{data}"
  ret = @db.execute("UPDATE #{@tablename} SET genres = ?, language = ? WHERE imdbid = ?", [ genre, language, imdbid ])
  row = lb.list()[lb.current_index]
  row[4] = genre
  lb.touch
end # }}}
def get_columns_as_array(lb, *cols)
  id = get_id(lb)
  $log.debug "  ID is #{id} "
  columns = cols.join(", ")
  $log.debug "  get_columns: #{columns}"
  rows = @db.execute("select #{columns} from #{@tablename} where rowid = ?", [id])
  return rows.first
end
#  return rowid
def get_id(lb)
  curr = lb.current_index
  data = lb.list[curr]
  id = data.first
end
begin
  include Umbra
  init_curses
  startup
  win = Window.new
  #$mywin = win
  statusline(win, " "*(win.width-0), 0)
  statusline(win, "Press C-q to quit #{win.height}:#{win.width}", 20)
  str = "----- Wikipedia titles (#{@total}) -----"
  win.title str
  # join with movie_status and show on side
  # TODO make this a LEFT JOIN
  #query = #{@query} FROM #{@tablename} WHERE status is NULL or status != 'x' ORDER BY id desc LIMIT 1000"
  @query ="SELECT m.rowid, year, title, directed_by, starring , language, ms.status FROM #{@tablename} m LEFT JOIN imdb.movie_status ms ON m.imdbid = ms.imdbid "
  @db.execute("ATTACH DATABASE ? AS imdb;", [ "/Volumes/Pacino/dziga_backup/rahul/Downloads/MOV/imdbdata/imdb.sqlite"])

  #query = "#{@query}, ms.status FROM #{@tablename} m, imdb.movie_status ms WHERE m.imdbid = ms.imdbid and ms.status != 'x'  ORDER BY m.rowid desc LIMIT 1000"
  query = "#{@query} WHERE ms.status != 'x'  ORDER BY m.rowid desc LIMIT 1000"
  alist = get_data @db, query

  catch(:close) do
    form = Form.new win
    boxrow = 2
    ltitle = Label.new text: "Title :", row: boxrow-1, col: 4, mnemonic: "T"
    title  = Field.new name: "title", row: ltitle.row, col: 20, width: 20, attr: REVERSE, color_pair: CP_CYAN
    lyear  = Label.new text: "Year :", row: boxrow-1, col: 4, mnemonic: "y"
    year   = Field.new name: "year", row: ltitle.row, col: 20, width: 4, attr: REVERSE, color_pair: CP_CYAN
    lyearto = Label.new text: "-", row: boxrow-1, col: 4
    yearto = Field.new name: "yearto", row: ltitle.row, col: 20, width: 4, attr: REVERSE, color_pair: CP_CYAN
    #lgenre = Label.new text: "Genre :", row: boxrow-1, col: 4
    #genre = Field.new name: "genre", row: ltitle.row, col: 20, width: 10, attr: REVERSE, color_pair: CP_CYAN
    lstarring = Label.new text: "Starring :", row: boxrow-1, col: 4
    starring = Field.new name: "starring", row: ltitle.row, col: 20, width: 10, maxlen: 30, attr: REVERSE, color_pair: CP_CYAN
    ldirector = Label.new text: "Director :", row: boxrow-1, col: 4
    director = Field.new name: "director", row: ltitle.row, col: 20, width: 10, attr: REVERSE, color_pair: CP_CYAN
    #lstatus = Label.new text: "Status :", row: boxrow-1, col: 4
    #status = Field.new name: "status", row: ltitle.row, col: 20, width: 1, attr: REVERSE, color_pair: CP_CYAN

    ltitle.related_widget = title
    lyear.related_widget = year

    searchb = Button.new text: "Search", mnemonic: "s"

    form.add_widget ltitle, title, lyear, year, lyearto, yearto
    #form.add_widget lgenre, genre
    form.add_widget lstarring, starring
    form.add_widget ldirector, director
    form.add_widget searchb
    #flow(ltitle.row, 4, ltitle, title, lyear, year, lyearto, yearto, lgenre, genre, lstatus, status)
    flow(ltitle.row, 4, ltitle, title, lyear, year, lyearto, yearto, lstarring, starring, ldirector, director)
    searchb.col = FFI::NCurses.COLS-10
    searchb.row = ltitle.row

    box = Box.new row: boxrow, col: 0, width: win.width, height: win.height-7
    #lb = Listbox.new list: data
    #lb = Listbox.new list: alist
    lb = Listbox.new selection_key: 0 # Ctrl-0. We arent using selection here.
    # this event will register after listbox has been populated the first time. That is why I am setting 
    #  the list after the bind_event
    lb.bind_event(:CHANGED) { |list| box.title = "#{list.size} rows"; box.touch; }
    lb.list = alist
    def lb._format_value(line)
      #@query ="SELECT rowid, year, title, directed_by, starring , language"
      "%4s %4s %-40s %-20s %-s" % line
    end
    def lb._format_color(index, state) # {{{
      arr = super
      if state == :NORMAL
        # make bold if it status is i
        row = self.list[index]
        status = row[6]
        #$log.debug "#{index}.  STATUS =#{status}, row = #{row}"
        if status == "i"
          arr[0] = CP_YELLOW
          arr[1] = BOLD
        elsif ["x", "n", "1"].include?(status)
          arr[0] = CP_BLUE
        elsif ["4", "5"].include?(status)
          arr[0] = CP_GREEN
          arr[1] = BOLD
        end
      end
      arr
    end # }}}
    def lb._format_mark(index, state)  # {{{
      checkmark = "\u2713".encode('utf-8');
      xmark = "\u2717".encode('utf-8');
      emptymark = "\u2610".encode('utf-8');
      mark = super
      if state == :NORMAL
        # make bold if it status is i
        row = self.list[index]
        status = row[6]
        #$log.debug "#{index}.  STATUS =#{status}, row = #{row}"
        if status == "i" 
          mark = emptymark

        elsif ["x", "n"].include?(status)
          mark = xmark
        elsif status.nil? or status == "0" or status == "."
        else
          mark = checkmark
        end
      end
      mark
    end # }}}
    #data = format_data alist, "%4s %8s %4s %-50s %-3s %-s"
    box.fill lb
    brow = box.row+box.height

    textb = Textbox.new row: brow, col: 0, width: FFI::NCurses.COLS-1, height: FFI::NCurses.LINES-brow-1

    # we are no longer showing these two test buttons taking up space and useless. REMOVE TODO

    # bind the most common event for a listbox which is ENTER_ROW
    lb.command do |ix|
      data = lb.current_row()
      id = data[0,4]
      curr = lb.current_index+1
      #id = data.first
      # display some stuff in statusline for row under cursor
      row = @db.get_first_row("SELECT imdbid, language, country FROM #{@tablename} WHERE rowid = #{id}")
      # display some stuff in textbox for row under cursor
      # Get plot from imdb table for imdbid
      imdbid = row[2]
      imrow = get_columns_from_imdb(lb, "plot, genre, imdbrating")
      plot = imrow.first if imrow
      if imrow
        row << imrow[1]
        row << imrow[2]
      end
      statusline(win, "#{curr}/#{lb.list.size}| #{id}|#{row.join("| ")}       ")
      desc = wrap_text(plot, textb.width) if plot
      textb.list = desc || ["No record in imdb database."]
    end
    lb.bind_key('s', 'update status') { |w| update_status(w); w.cursor_down; }
    lb.bind_key(?v.getbyte(0), 'view details')  { view_details(lb, @db) }
    lb.bind_key(?V.getbyte(0), 'view IMDB')  { join_imdb(lb) }
    lb.bind_key(?S.getbyte(0), 'sort menu')  { sort_menu(lb) }
    lb.bind_key(?D.getbyte(0), 'delete row') { delete_row(lb) }
    lb.bind_key('o', 'open IMDB in browser') { view_in_browser(lb) }
    lb.bind_key('e', 'edit row')             { edit_row(lb) }
    lb.bind_key('w', 'open wikipedia page')  { view_wiki_page(lb) }
    lb.bind_key('u', 'update genres')        { update_genre(lb) }
    searchb.command do # {{{
      # construct an sql statement using title, year and genre
      sql = "#{@query}"
      query = []
      bind_vars = []
      if title.text.length >= 3
        query << " TITLE LIKE ? "
        bind_vars << "%#{title.text}%"
      end
      if year.text.length == 4
        query << " YEAR >= ? "
        bind_vars << year.text.to_i
      end
      if yearto.text.length == 4
        query << " YEAR <= ? "
        bind_vars << yearto.text.to_i
      end
      if false
      if genre.text.length > 2
        query << " GENRES LIKE ? "
        bind_vars << "%#{genre.text}%"
      end
      if status.text.length > 0
        query << " STATUS = ? "
        bind_vars << "#{status.text}"
      end
      end # false
      if starring.text.length > 2
        query << " STARRING LIKE ? "
        bind_vars << "%#{starring.text}%"
      end
      if director.text.length > 0
        query << " DIRECTED_BY LIKE ? "
        bind_vars << "%#{director.text}%"
      end
      if !query.empty?
        sql +=  "WHERE " + query.join("AND")
      end
      #sql += " ORDER BY rating DESC"
      sql += " ORDER BY YEAR DESC"
      if query.empty?
        sql += " LIMIT 1000 "
      end
      $log.debug "  SQL: #{sql} "
      $log.debug "  ibv:  #{bind_vars.join ','} "
      #alert sql
      #alert bind_vars.join " , "
      #alist = get_data @db, query
      alist = @db.execute( sql, bind_vars)
      $log.debug "  SQL alist #{alist.class}, #{alist.size} "
      #data = format_data alist, "%4s %8s %4s %-50s %-3s %-s"
      #lb.list = data
      lb.list = alist
    end # }}}
    # bind to another event of listbox
    form.add_widget box, lb, textb
    form.pack
    form.select_first_field
    win.wrefresh

    while (ch = win.getkey) != FFI::NCurses::KEY_CTRL_Q
      begin
        form.handle_key ch
      rescue => e
        #puts e
        #puts e.backtrace.join("\n")
        $log.debug "INSIDE WHILE BLOCK 513"
        $log.debug e.to_s
        $log.debug e.backtrace.join("\n")
        view([ e.to_s , *e.backtrace], title: "Exception")

      end
      win.wrefresh
    end
  end # close

rescue => e
  win.destroy if win
  win = nil
  FFI::NCurses.endwin
  puts "ex4 rescue"
  puts e
  puts e.backtrace.join("\n")
  $log.debug "rescue block"
  $log.debug e.to_s
  $log.debug e.backtrace.join("\n")
ensure
  win.destroy if win
  FFI::NCurses.endwin
  if e
    puts "ex4 ensure"
    puts e 
    puts e.backtrace.join("\n")
    $log.debug "ensure block"
    $log.debug e.to_s
    $log.debug e.backtrace.join("\n")
  end
end
