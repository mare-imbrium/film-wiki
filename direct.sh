#!/usr/bin/env zsh
#
# DESCRIPTION:  display movies for given director name then user selects by entering rowid  and sees the wiki page
#    Much better to use hdir.sh
#
# CHANGES
#   2016-01-21 - 20:18 No longer using wiki table. But do we map to file name, does the URL map exactly ?

function show_wiki () {
    # we now are moving to main tables rowid
    #sqlite3 movie.sqlite "select w.wiki from movie_wiki w, movie m where m.rowid = $1 and w.url = m.url" |  w3m -T 'text/html'
    url=$( sqlite3 movie.sqlite "select url from  movie where rowid = $1 ")
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
if [[ "$1" == <1-> ]]; then
    show_wiki $1
else
    # we now are moving to main tables rowid
    sqlite3 movie.sqlite "select rowid, title, year, directed_by , won, nom,starring, running_time from movie where directed_by like '%"$1"%'"
    echo "Enter rowid to view wiki entry, or blank to exit: "
    read rowid
    [[ -z $rowid ]] && exit
    show_wiki $rowid
fi

