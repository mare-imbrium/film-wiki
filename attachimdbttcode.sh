#!/usr/bin/env bash 
# ----------------------------------------------------------------------------- #
#         File: attachimdbttcode.sh
#  Description: find which ttcodes are present in wiki but absent in imdbdata dir
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2017-03-09 - 12:18
#      License: MIT
#  Last update: 2017-03-11 09:15
# ----------------------------------------------------------------------------- #
#  YFF Copyright (C) 2012-2016 j kepler


SQLITE=$(brew --prefix sqlite)/bin/sqlite3
MYDATABASE=movie.sqlite
MYTABLE=movie
MYCOL=yyy
OUTFILE=imdbmissing.tsv
$SQLITE $MYDATABASE <<! > $OUTFILE
attach database "imdb.sqlite" as im;
.mode tabs
SELECT imdbid,title FROM movie where imdbid NOT IN (SELECT imdbid from im.imdb);
!
wc -l $OUTFILE
echo "-----------------"
echo some results will have more than one imdbid in them
echo please correct these.
echo Then take this list to the imdb folder and use fetch on that list.
echo remove the titles before updating
