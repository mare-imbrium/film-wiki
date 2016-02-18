#!/usr/bin/env zsh
#  Last update: 2016-02-18 18:39

# Description: edit a given row and column
# params: rowid and columns to edit

if [  $# -eq 0 ]; then
    echo "Please pass a rowid and a field name to edit"
    exit 1
fi
rowid=$1
sqlite3 movie.sqlite "select * from movie where rowid = $rowid"
echo "----"
echo "if vared does not allow backspacing then use cursor left arrow then add a letter"
echo "Now you can go right and BS"
echo "----"

shift
while [ "$1" != "" ]; do
    #col=${2:-"title"}
    col=$1
    TITLE=$(sqlite3 movie.sqlite "select $col from movie where rowid = $rowid")
    echo "Found $col for $rowid : ($TITLE)"
    vared TITLE
    #TITLE=$(rlwrap -pYellow -S 'Edit? ' -P "$TITLE" -o cat)
    
    [[ -z "$TITLE" ]] && { echo "Error: $col blank." 1>&2; exit 1; }
    # vared not working 2016-01-16 - 20:42 
   #read TITLE
    sqlite3 movie.sqlite "update movie set $col = '"$TITLE"' where rowid = $rowid"
    shift

    echo "updated $col ..."
    sqlite3 movie.sqlite "select rowid, url, $col from movie where rowid = $rowid"
done

