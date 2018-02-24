#!/usr/bin/env bash 
#===============================================================================
#
#          FILE: command.sh
# 
#         USAGE: ./command.sh 
# 
#   DESCRIPTION: several important commands: fetch, dump, sync, force_fetch and fetch_one
# 
#       OPTIONS: filename containing urls
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: rahul
#  ORGANIZATION: 
#       CREATED: 02/04/2016 23:46
#      REVISION:  2018-02-20 12:08
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
sync() {
    # sync this database with imdb database
    # fix any duplicate imdb in imdbID field
    echo "This syncs wiki database with imdb database"
    ./attachimdbttcode.sh
    echo
    echo "Remove any entries with multiple IMDB ids or fix them"
    echo "Copy ./imdbmissing.tsv to imdbdata dir using only first column (imdbid). Rename to files.list"
    echo "Goto imdbdata dir and run command.sh fetch"
    #cut -f1 ./imdbmissing.tsv
    cat ./imdbmissing.tsv
}
fetch_one() {
    # fetch one wiki url
    file=${1:-"url"}
    ./fetchmovie.sh "$file"
    # TODO extract imdbid and download that one in imdb database
}

if [[ $1 =~ ^(dump|fetch|force_fetch|dupes|sync|fetch_one)$ ]]; then
  "$@"
else
  echo "Invalid subcommand $1" >&2
  echo "Commands are dump fetch force_fetch sync"
  exit 1
fi
