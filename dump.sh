#!/usr/bin/env bash 
#===============================================================================
#
#          FILE: dump.sh
# 
#         USAGE: ./dump.sh 
# 
#   DESCRIPTION: exports movie table into a TSV file which is uploaded to github
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 02/18/2016 20:35
#      REVISION:  2017-03-11 09:11
#===============================================================================

## CHANGELOG
# 2016-03-01 - added dumping of schema
#
# 2017-03-11 - i think we need to update those tables imlinks etc
echo "Before running this I think you have to go to oldprogs and run ./oldprogs/crosslink.sh"
_backup() {
    if [[ ! -f "$1" ]]; then
        echo "File: $1 not found" 1<&2
        #exit 1
    fi
    today=$(date +"%Y%m%d%H%M")
    file=$1
    if [[ ! -d "backups" ]]; then
        mkdir backups
    fi
    outfile="${file}.${today}"
    cp -ap "$file" "backups/${outfile}"
}
SQLITE=$(brew --prefix sqlite)/bin/sqlite3
MYDATABASE=movie.sqlite
MYTABLE=movie
_backup "movie.tsv"
$SQLITE $MYDATABASE <<!
.mode tabs
.headers on
.output movie.tsv
  select * from $MYTABLE order by year;
!
wc -l movie.tsv

_backup "imlinks.tsv"
$SQLITE $MYDATABASE <<!
.mode tabs
.headers on
.output imlinks.tsv
  select * from imlinks2 ;
!
wc -l imlinks.tsv

_backup "crosslink.tsv"
$SQLITE $MYDATABASE <<!
attach database "imdbdata/imdb.sqlite" as "im";

.mode tabs
.header on
.output crosslink.tsv
  select a.url, a.imdb_url, b.title, b.year from imlinks2 a, im.imdb b 
      where a.imdb_url = b.imdbID;
!
wc -l crosslink.tsv

_backup "schema.sql"
$SQLITE $MYDATABASE <<!

.output schema.sql
.schema
!
wc -l schema.sql
