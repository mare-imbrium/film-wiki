#!/usr/bin/env bash 
#===============================================================================
#
#          FILE: update_wiki_lists.sh
# 
#         USAGE: ./update_wiki_lists.sh 
# 
#   DESCRIPTION: updates list so fzf can use for searches.
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 12/25/2015 10:27
#      REVISION:  2016-01-22 20:51
#===============================================================================

OUT=/Volumes/Pacino/dziga_backup/rahul/Downloads/MOV/
MYTABLE=movie

# the fields director and actors have comma delimited names so we need to split
# first param is file name to create
# second is column name
split_file() {
    STUB=$1
    COLUMN=$2

    echo "retrieve $COLUMN from sqlite..."
    sqlite3 $MYDB "select $COLUMN from $MYTABLE;"  > $OUT/$STUB.tmp
    < $OUT/$STUB.list
    echo "remove space after comma in $STUB.tmp"
    sed 's/, /,/g' $OUT/$STUB.tmp | sponge $OUT/$STUB.tmp
    echo "splitting file on comma ..."
    while IFS=',' read -ra ADDR; do
        for i in "${ADDR[@]}"; do
            #i=$( echo "$i" | sed 's/^[[:space:]]*//g;s/[[:space:]]*$//g;' )
            echo "$i" >> $OUT/$STUB.list
        done
    done < $OUT/$STUB.tmp
    wc -l $OUT/$STUB.list
    echo "removing some junk entries with and"
    egrep -v "^and | and " $OUT/$STUB.list | sponge $OUT/$STUB.list

    echo "Sorting unique..."

    sort -u $OUT/$STUB.list | sponge $OUT/$STUB.list

    wc -l $OUT/$STUB.list
    rm $OUT/$STUB.tmp
}
MYDB=movie.sqlite
cd /Volumes/Pacino/dziga_backup/rahul/Downloads/MOV/ || exit 1
if [[ ! -f "$MYDB" ]]; then
    echo "File: $MYDB not found"
    exit 1
fi
echo "generating titles.list"
sqlite3 --separator $'\t' $MYDB "select title, year from $MYTABLE;" | sort > $OUT/titles.list
wc -l $OUT/titles.list
echo

split_file "actors" "starring"
split_file "director" "directed_by"
