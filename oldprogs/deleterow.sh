#!/usr/bin/env bash 
#===============================================================================
#
#          FILE: deleterow.sh
# 
#         USAGE: ./deleterow.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 03/05/2016 00:00
#      REVISION:  2016-03-05 00:03
#===============================================================================

if [  $# -eq 0 ]; then
    echo you must pass a rowid to delete
    exit 1
fi
sqlite3 -line ../movie.sqlite "select rowid, title, year, url, directed_by from movie where rowid = $1 ;"

echo -n "Do you wish to delete" '[y/n] ' ; read ans
case "$ans" in
    y*|Y*) echo "deleting $1 ..." ;;
    *) exit 1 ;;
esac
sqlite3 ../movie.sqlite "delete from movie where rowid = $1; "

echo "done"
