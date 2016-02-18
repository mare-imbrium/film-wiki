#!/usr/bin/env zsh
#
# first use fzf to select a director, then his movies, and then show wiki for movie
#
# This is a bit clunky since it shows a rowid and then translates rowid to url and then page.
# I guess I could just show the URL and convert it
# It would be nice to actually list films in HTML format and let user browse that as a page with other film info
#    then user can click a link and see movie, return and see other movies.
#

function show_wiki () {
    # we now are moving to main tables rowid
    url=$( sqlite3 movie.sqlite "select url from movie where rowid = $1 ")
    url=$( echo "$url" | sed 's|/wiki/||;s|/|_|g;' )
    url=$( echo "$url" | decode_uri.rb )
    url="wiki/$url.html"
    echo "$url"
    if [[ ! -f "$url" ]]; then
        print "$url not found"
        exit 1
    else 
        #print "$url exists!"
        w3m "$url"
    fi
}
SQLITE=$(brew --prefix sqlite)/bin/sqlite3

cd /Volumes/Pacino/dziga_backup/rahul/Downloads/MOV/ || exit 1

# DESCRIPTION: let user select  director from list, the select film, and see wiki for that (uses fzf)
# TODO the list has joined names, too. We should separate names into another table, or file.
# TODO same for actors
STR=$( $SQLITE movie.sqlite "SELECT distinct directed_by from movie;" | fzf --query="$1" -1 -0 )
[[ -z "$STR" ]] && { echo "Nothing selected, quitting." 1>&2; exit 1; }
echo -e "$STR" 1<&2

# display and let user select a film
MOV=$( $SQLITE -separator $'\t' movie.sqlite <<! | fzf -1 -0 
SELECT title, year, rowid from movie where directed_by = "$STR" ORDER by year ;
!
)
[[ -z "$MOV" ]] && { echo "Nothing selected, quitting." 1>&2; exit 1; }

# extract rowid from line
rowid=$( echo "$MOV" | cut -f3 )
[[ -z $rowid ]] && exit
show_wiki $rowid

