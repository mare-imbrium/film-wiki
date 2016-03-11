#!/bin/zsh
###!/usr/bin/env zsh
# vared failed with /usr/local/bin/zsh/ works with /bin/zsh
#  Last update: 2016-03-10 12:51

# Description: edit a given row and column
# params: rowid and columns to edit

source ~/bin/sh_colors.sh

CHECK_MARK="\u2713"
X_MARK="\u2717"

if [  $# -eq 0 ]; then
    echo "Please pass a rowid and a field name to edit"
    echo " Use s.sh to get the rowid of a film"
    exit 1
fi

cd $MOV || ( echo "$0: Cannot change directory to $MOV" ; exit 1 )
if [[ ! -f "movie.sqlite" ]]; then
    echo "$0: File movie.sqlite not found in $PWD" 1<&2
    exit 1
fi

rowid=$1
sqlite3 -line -nullvalue '---' movie.sqlite "select * from movie where rowid = $rowid" | grep -v '\-\-\-'
echo "----"
#echo "if vared does not allow backspacing then use cursor left arrow then add a letter"
#echo "Now you can go right and BS"
#echo "----"

shift
while [ "$1" != "" ]; do
    #col=${2:-"title"}
    col=$1
    TITLE=$(sqlite3 movie.sqlite "select $col from movie where rowid = $rowid")
    pbold "Row: $rowid. $col: ($TITLE)"
    vared TITLE
    #TITLE=$(rlwrap -pYellow -S 'Edit? ' -P "$TITLE" -o cat)
    
    [[ -z "$TITLE" ]] && { echo "${X_MARK} Error: $col blank." 1>&2; exit 1; }
    # vared not working with /usr/local/bin/zsh. works with /bin/zsh
   #read TITLE
    sqlite3 movie.sqlite "update movie set $col = '"$TITLE"' where rowid = $rowid"
    shift

    pinfo "${CHECK_MARK} Updated $col "
    sqlite3 -line movie.sqlite "select rowid, url, $col from movie where rowid = $rowid"
done

