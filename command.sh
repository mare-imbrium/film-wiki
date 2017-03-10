#!/usr/bin/env bash 
#===============================================================================
#
#          FILE: command.sh
# 
#         USAGE: ./command.sh 
# 
#   DESCRIPTION: several important commands: fetch, dump
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 02/04/2016 23:46
#      REVISION:  2016-03-10 10:24
#===============================================================================

dupes() {
    echo "== checking duplicate title and year"
    sqlite3 movie.sqlite "select  title, year, count(*) from movie group by title, year having count(*) > 1;"
    echo "== checking duplicate imdbids"
    sqlite3 movie.sqlite "select  imdbid, count(*) from movie group by imdbid having count(*) > 1;"
}
dump() {
    ./dump.sh
}
fetch() {
    file=${1:-"urls.txt"}
    wc -l $file
    ./fetchmovie.sh -f $file
}

force_fetch() {
    file=${1:-"urls.txt"}
    wc -l $file
    ./fetchmovie.sh --force -f $file
}

if [[ $1 =~ ^(dump|fetch|force_fetch|dupes)$ ]]; then
  "$@"
else
  echo "Invalid subcommand $1" >&2
  echo "Commands are dump fetch force_fetch"
  exit 1
fi
