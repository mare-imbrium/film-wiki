#!/usr/bin/env bash 
#===============================================================================
#
#          FILE: deleterow.sh
# 
#         USAGE: ./deleterow.sh 
# 
#   DESCRIPTION: delete a row from movie.sqlite given a rowid
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 03/05/2016 00:00
#      REVISION:  2016-03-10 12:57
#===============================================================================

if [  $# -eq 0 ]; then
    echo You must pass a rowid to delete
    exit 1
fi
cd $MOV || ( echo "$0: Cannot change directory to $MOV" ; exit 1 )
if [[ ! -f "movie.sqlite" ]]; then
    echo "$0: File movie.sqlite not found in $PWD" 1<&2
    exit 1
fi
sqlite3 -line movie.sqlite "select rowid, title, year, url, nom, won, directed_by from movie where rowid = $1 ;"
echo
echo -n "Are you sure you wish to delete ?" '[y/n] ' ; read ans
case "$ans" in
    y*|Y*) echo "Deleting $1 ..." ;;
    *) exit 1 ;;
esac
mkdir deleted 2>/dev/null
sqlite3 -header -separator $'\t' movie.sqlite "select * from movie where rowid = $1; " > deleted/$1.tsv
sqlite3 movie.sqlite "delete from movie where rowid = $1; "

echo "Done"
