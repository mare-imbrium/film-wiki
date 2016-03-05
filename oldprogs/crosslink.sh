#!/usr/bin/env bash 
#===============================================================================
#
#          FILE: crosslink.sh
# 
#         USAGE: ./crosslink.sh 
# 
#   DESCRIPTION: this should crosslink the ttcode in the imlinks2 table with imdb.sqlite
#    and get the title from there, so we can make sure that the links are correct.
#    I guess the TSV file can be uploaded so people can check it out and report an error.
#
#    Use the ./findimdbid_for_wikiurl.sh program to generate an insert.tsv, edit the same
#    and import it into imlinks2.
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 02/25/2016 11:55
#      REVISION:  2016-02-25 11:55
#===============================================================================

cd ..
pwd

SQLITE=$(brew --prefix sqlite)/bin/sqlite3
MYDATABASE=movie.sqlite
MYTABLE=xxx
MYCOL=yyy

missingurls() {
    # list urls in movies that are not present in imlinks2. these should be the freshly added ones
    # as well as those that don't have a wiki page.

$SQLITE $MYDATABASE <<!
.mode tabs
    select rowid, url, htmlpath from movie where url not in (select url from imlinks2);
!
}
generate() {
$SQLITE $MYDATABASE <<!
attach database "imdbdata/imdb.sqlite" as "im";

.mode tabs
.header on
.output crosslink.tsv
  select a.url, a.imdb_url, b.title, b.year from imlinks2 a, im.imdb b 
      where a.imdb_url = b.imdbID;
!
}
crosscheck() {
$SQLITE $MYDATABASE <<!
attach database "imdbdata/imdb.sqlite" as "im";

.mode tabs
.header on
.output crosscheck.tsv
select a.url, a.imdb_url from imlinks2 a where a.imdb_url not in (select imdbID from im.imdb);
!
}


checkimdb() {
    while IFS='' read line
    do
        echo -e "$line"
        url=$(echo -e "$line" | cut -f1)
        id=$(echo -e "$line" | cut -f2)
    if [[ -n "$id" ]]; then
        lenid=${#id}
        if [[ $lenid -eq 9 ]]; then
            #cu.sh --verbose "$id"
            cu.sh "$id"
            #echo PRESS ENTER
            #read </dev/tty
        else
            echo ">>>>>>> $id is not correct size ($lenid) ($url)"
            echo PRESS ENTER
            read </dev/tty
        fi
    fi
    done < crosscheck.tsv
}
updateme() {
    while IFS='' read line
    do
        echo -e "$line"
        url=$(echo -e "$line" | cut -f1)
        id=$(echo -e "$line" | cut -f2)
        _update $url $id
    done < crosscheck.tsv

}
_update() {
    # i have corrected all the imdb_url that were wrong or missing.
    # now i update the file
out=$( $SQLITE $MYDATABASE <<!
select url from  imlinks2 where url = "$1";
!
)
if [[ -n "$out" ]]; then
    $SQLITE $MYDATABASE <<!
    update imlinks2 set imdb_url = "$2" where url = "$1";
!
else
    echo inserting $1
    $SQLITE $MYDATABASE <<!
    insert into imlinks2 (url,  imdb_url) values ( "$1", "$2" );
!

fi
}

missingurls
