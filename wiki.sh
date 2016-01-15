#!/usr/bin/env zsh
# ----------------------------------------------------------------------------- #
#         File: wiki.sh
#  Description: given a movie pattern, prompts with matches and shows wiki page from movie_wiki table
#     on selection of rowid
#       Or given a ROWID, directly shows wiki page
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: long ago
#      License: MIT
#  Last update: 2016-01-15 12:38
# ----------------------------------------------------------------------------- #
#  wiki.sh  Copyright (C) 2012-2016 j kepler
#
# 2016-01-15 - Earlier `wiki` called this. Now I prefer to use the wiki files on the disk since i can 
#  hyperlink. I also use fzf to select which is better and faster.
#  So this is not used any longer, but is good as an example of rlwrap

function show_wiki () {
    # we now are moving to main tables rowid
    #sqlite3 movie.sqlite "select wiki from movie_wiki where rowid = $1" |  w3m -T 'text/html'
    sqlite3 movie.sqlite "select w.wiki from movie_wiki w, movie m where m.rowid = $1 and w.url = m.url" |  w3m -o confirm_qq=0 -T 'text/html'
}
if [[ "$1" == <1-> ]]; then
    # got a rowid, show file
    show_wiki $1
else
    var="$1"
    MYHISTFILE=~/.HISTFILE_MOVIETITLE
    #echo wiki.sh got $var
    FLD=${FLD:-"title"}
    if [[ "$var" =~ "^dir:" ]]; then 
        FLD="directed_by"; 
        var=${var#dir:}
    fi
    if [[ $var =~ "^actor:" ]]; then 
        FLD="starring"; 
        var=${var#actor:}
    fi
        #echo "var is now $var, FLD is $FLD "
    # we now are moving to main tables rowid
    items=$( sqlite3 movie.sqlite "select rowid, title, year, directed_by , starring from movie where $FLD like '%"$var"%'")
    echo -e "$items" | column -t -s'|'
    #echo -e "$items" 
    [[ -z "$items" ]] && { echo "Error: No movies for $var" 1>&2; exit 1; }
    leni=$( echo -e "${items}" | grep -c . )
    if [[ $leni -eq 0 ]]; then
        echo -e "No movies for this pattern: $var" 1<&2
        exit 1
    fi
    defaulttitle=$( echo -e $items | head -1 | cut -f2 -d'|' )
    defaultrowid=$( echo -e $items | head -1 | cut -f1 -d'|'  )
    TEMPHIST=~/tmp/deleteme.tmp
    if [[ $leni -eq 1 ]]; then
        title="$defaulttitle"
        rowid=$defaultrowid
    else
        titles=$( echo -e "$items" | cut -f2 -d'|')
        echo -e "$titles" > $TEMPHIST
        echo
        PATT=$(rlwrap -pYellow -S "($leni matches). Select one? " -H $TEMPHIST -P $defaulttitle -o cat)
        rm $TEMPHIST
        [[ -z "$PATT" ]] && { exit 1; }
        # was fetching two ids if one was subset of other, e.g. Manon
        rowid=$( echo -e "$items" | grep "|${PATT}|" | cut -f1 -d'|' )
        title="$PATT"
    fi
    echo -e "\\033[1mShowing wiki page for ${title}\\033[22m"
    echo Got rowid $rowid

    [[ -z $rowid ]] && exit
    #title=$( echo -e "$items" | grep "^$rowid" | cut -f2 -d'|' )
    # TODO check if it in the file, if not then append. I should not change the order etc.
    echo "$title" >> $MYHISTFILE
    sort -u $MYHISTFILE > ~/tmp/t.t
    mv ~/tmp/t.t $MYHISTFILE
    show_wiki $rowid
fi

