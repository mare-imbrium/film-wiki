#!/usr/bin/env bash 
#===============================================================================
#
#          FILE: findimdbid_for_wikiurl.sh
# 
#         USAGE: ./findimdbid_for_wikiurl.sh 
# 
#   DESCRIPTION: fetch those urls from wiki (movie table) that don't have an imdb id in imlinks2 table
#        and then try to figure out imdbid for them.
#        Then insert these into imlinks2
#        I just insert the entries into a file so it can be imported after editing.
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 02/24/2016 20:36
#      REVISION:  2016-02-24 20:36
#===============================================================================

TAB2=imlinks2
OUTFILE="insert.tsv"
insertme() {
    if [[ -z "$1" ]]; then
        echo "Pass url"
        return 1
    fi
    if [[ -z "$2" ]]; then
        echo "Pass imdbid"
        return 1
    fi
    echo "insertme got $1 and $2"
    echo -e "$1	$2" >> $OUTFILE
    # i put it into a file which can be imported into imlinks2 after setting .mode tabs
    # you can edit the file first in case their are multiple id's for a title.
    return 0
sqlite3 movie.sqlite <<!
insert into $TAB2 (url, imdb_url) values ("$1","$2");
!
}
source ~/bin/sh_colors.sh
cd ..
pwd
if [[ ! -f "movie.sqlite" ]]; then
    echo "File: movie.sqlite not found" 1<&2
    exit 1
fi
sqlite3 movie.sqlite <<!>t.3
.mode tabs
select url from movie where url not in ( select url from $TAB2 );
!
wc -l t.3
#grep "/wiki/" t.3 | sed 's|/wiki/||;s/_/ /g;s|(.*||;s|%28.*||;s/%26/\&/g;s/ $//' > t.4
grep "/wiki/" t.3 > t.4
wc -l t.4
while IFS='' read url
do
    echo -n "$url ---> "
    # FIXME XXX what about ( and apostrophe.' %27 -> '.
    #
    line=$( echo -e "$url" |  sed "s|/wiki/||;s/_/ /g;s|%27|'|g;s|(.*||;s|%28.*||;s/%26/\&/g;s/ $//")
    echo -e "$line"
    out=$( getimdbid.sh "$line")
    if [[ -n "$out" ]]; then
        # NOTE we can get two result or more for a film. how do we chose ?
        id=$( echo "$out" | cut -f1 )
        pdone ">>>>>>>>>>>>  $id"
        insertme "$url" "$id"
    else
        echo "${url}	NF" >> tomatch.tsv
        # for these, try cu.sh --verbose TITLE or titlesearch.sh -s TITLE to download the file
        preverse "No Id found"
    fi
done < t.4
