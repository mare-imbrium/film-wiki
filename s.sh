#!/usr/bin/env bash
# ----------------------------------------------------------------------------- #
#         File: s.sh
#  Description: This searches the movie database on title and gives the rowid.
#               Rowid is required to use the edit.sh program to edit a movie.
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2016 ??
#      License: MIT
#  Last update: 2018-02-23 23:42
# ----------------------------------------------------------------------------- #
#  s.sh  Copyright (C) 2012-2018 j kepler

# DESCRIPTION: does a LIKE search on title and prints out movies matching. --id ID
#  --url to print url. -a to print all cols
#sqlite3 movie.sqlite "select id, title, directed_by from $_TABLE where title like '%"$*"%';"
# # rowid needed for deletes and for using edit.sh
# TODO:
# + allow viewing of wiki for a row
# - allow viewing of imdb data for a row

cd $MOV || ( echo "Can't cd to $MOV."; exit 1 )

OPT_VERBOSE=
OPT_DEBUG=
_DATABASE=movie.sqlite
_TABLE=movie
_SEARCHCOL=title
SQLITE=$(brew --prefix sqlite)/bin/sqlite3

HISTFILE=~/tmp/histfile.tmp
OPT_COLS="rowid, title, year, directed_by, starring , url"
OPT_COLS="rowid, title, year, directed_by, starring "

pverbose(){
    if [[ -n "$OPT_VERBOSE" ]]; then
        echo -e "INFO: $*"
    fi
}
pecho(){
    if [[ -n "$OPT_DEBUG" ]]; then
        echo -e "DEBUG: $*"
    fi
}

while [[ $1 = -* ]]; do
    case "$1" in
        -a|--all)   shift
            OPT_COLS="rowid, *"
            ;;
        --url)   shift
            OPT_COLS="$OPT_COLS , url "
            ;;
        --id)   shift
            OPT_WHERE=" rowid = $1 "
            shift
            ;;
        -V|--verbose)   shift
            OPT_VERBOSE=1
            ;;
        -D|--debug)        shift
            OPT_DEBUG=1
            ;;
        -h|--help)
            cat <<-! | sed 's|^     ||g'
            $0 Version: 0.1.0 Copyright (C) 2016 jkepler
            This program prints details for a movie title given part of title

            Usage:
            $0 <part of title>
            Print movie details for a rowid
              $0 --id <rowid>
            Display for a given imdbid
              $0 tt0010111 
            Search within a url (not title)
              $0 /Wars

            Options:
            --url         Print url also
            --all         Print all fields

            -V  --verbose     Displays more information
            --debug       Displays debug information
!
            # no shifting needed here, we'll quit!
            exit
            ;;
        --edit)
            echo "this is to edit the file generated if any "
            exit
            ;;
        --source)
            echo "this is to edit the source "
            vim $0
            exit
            ;;
        *)
            echo "Error: Unknown option: $1" >&2   
            echo "Use -h or --help for usage" 1>&2
            exit 1
            ;;
    esac
done

if [  $# -gt 0 ]; then
    if [[ $1 =~ ^tt ]]; then
        # if starts with tt then check imdbid
        OPT_WHERE=" imdbid = '$1'"
    elif [[ $1 =~ ^/ ]]; then
        # if starts with / then check URL for pattern
        cmd=${1#/}
        OPT_WHERE=" url LIKE '%"$cmd"%'"
    else
        OPT_WHERE=" $_SEARCHCOL LIKE '%"$1"%'"
    fi
fi

_commands(){
    #cmd=${1#:}
    cmd="$*"
    cmd=${cmd:1}
    pecho commands got $cmd
    #IFS=':'  read -ra ADDR <<< "$cmd"
    #F1=${ADDR[0]}
    #F2=${ADDR[1]}
    F1=$(echo "$cmd" | cut -f1 -d' ')
    F2=$(echo "$cmd" | cut -f2- -d' ')
    pecho "first is $F1, second is $F2"
    case $F1 in
        "search")
            pecho "setting searchcol"
            _SEARCHCOL=$F2;;
        table)
            _TABLE=$F2;;
        db)
            _DATABASE=$F2;;
        where)
            OPT_WHERE=$F2
            pecho "Setting opt_where to $OPT_WHERE"
            _query
            ;;
        cols)
            OPT_COLS=$F2;;
        wiki)
            # added 2018-02-23 - view wiki file for rowid
            _get_for_rowid $F2 "url"
            url=$(echo "$_REPLY.html" | sed 's/^\///')
            echo $url
            file=$(printf '%q' "$url")

            echo "$file"
            #ls -l "$file"
            ls -l "$url"
            #w3m $file
            w3m $url
            ;;
        imdb)
            # added 2018-02-23 - view imdb info for rowid
            _get_for_rowid $F2 "imdbid"
            echo $_REPLY
            imdbid=$JSONDIR/$_REPLY.json
            echo $imdbid
            ls -l $imdbid
            cat $imdbid | jq '.' | head
            ;;

        *)
            echo "wrong answer $F1"
            ;;
    esac
}
_query() {
    pecho "REACHED QUERY with $_DATABASE:$_TABLE:$_SEARCHCOL:$OPT_WHERE."
    RES=$( sqlite3 -separator $'\t'  -nullvalue 'NULL' $_DATABASE "SELECT ${OPT_COLS} FROM $_TABLE WHERE $OPT_WHERE ;" )
    pecho AFTER QUERY
    echo -e "$RES" | term-table.rb -H --wrap
    echo -e "$RES" | cut -f1 > $HISTFILE
    num=$( wc -l $HISTFILE | cut -f1 -d' ')
    echo "Rows returned $num"
    # FIXME if no rows still says 1 and displays those pluses
    # FIXME we are erasing previous commands here in histfile. that is not desirable.
    # before overwriting save the HISTFILE entries starting with :. then reappend them.

}
_compare() {

    echo -e "\\033[1mComparing $row1 and $row2\\033[22m"
    sqlite3 -line  $_DATABASE "select * from $_TABLE where rowid = $row1; "  > t.1
    sqlite3 -line  $_DATABASE "select * from $_TABLE where rowid = $row2; "  > t.2
    #comm -3 t.1 t.2
    # -y side by side
    /usr/bin/diff --suppress-common-lines -y t.1 t.2
    rm t.1 t.2

}
# for the given rowid fetch and return the given column
_get_for_rowid() {
    rowid=$1
    COL=$2
    _REPLY=$( sqlite3 $_DATABASE "SELECT ${COL} FROM $_TABLE WHERE rowid = $rowid ;" )
}

_query

_SELECTED=
while true ; do
    cd $MOV


    ## rlwrap and histfile allows user to press up arrow and get rowids of rows displayed and avoid typing
    rowid=$(rlwrap -pYellow -S 'Enter rowid (or pattern): ' -H ${HISTFILE} -o cat)

    if [[ -z "$rowid" ]]; then
        rm $HISTFILE
        exit 0
    fi
    # if it is a rowid then show complete row, otherwise do another search in titles
    if [[ "$rowid" = +([0-9]) ]]; then
        sqlite3 -line  -nullvalue '---' $_DATABASE "SELECT rowid, * FROM $_TABLE WHERE rowid=$rowid ;"
        _SELECTED=$rowid
    elif [[ $rowid =~ ^tt ]]; then
        sqlite3 -line  -nullvalue '---' $_DATABASE "SELECT rowid, * FROM $_TABLE WHERE imdbid=\"$rowid\" ;"
        # TODO set _SELECTED with rowid
    elif [[ $rowid =~ ^delete ]]; then
        row=$( echo "$rowid" | cut -f2 -d' ')
        oldprogs/deleterow.sh "$row"
    elif [[ $rowid == "edit" ]]; then
        if [[ -n "$_SELECTED" ]]; then
            ./edit.sh "$_SELECTED"
        else
            echo "No row selected yet"
        fi
    elif [[ $rowid =~ ^edit ]]; then
        row=$( echo "$rowid" | cut -f2 -d' ')
        field=$( echo "$rowid" | cut -f3 -d' ')
        # we need to get a field name to edit from the user TODO
        echo "row is ($row) field is ($field)"
        if [[ "$row" = +([0-9]) ]]; then
            ./edit.sh "$row" "$field"
        else
            echo "rowid must be a number"
        fi
    elif [[ $rowid =~ ^yml ]]; then
        ## 2018-02-22 - I recently added this so we could update the yml file
        ## and from that the database. However NOTE that the yml could be
        ## outdated. IF we update row directly, then yml is no longer in sync.
        row=$( echo "$rowid" | cut -f2 -d' ')
        #sqlite3 movie.sqlite "SELECT htmlpath FROM $_TABLE WHERE rowid=$row"
        path=$(sqlite3 $_DATABASE "SELECT htmlpath FROM $_TABLE WHERE rowid=$row ;")
        echo $path
        path=$( echo $path | sed 's/wiki/yml/;s/\.html/.yml/')
        echo $path
        echo Press Enter to edit in vim
        echo NOTE THAT YML may not be in sync with database
        read
        vim $path
        echo Press Enter to update to database 
        read
        ./updateyml2db.rb $path
    elif [[ $rowid =~ ^compare ]]; then
        # enter "compare rowid1 rowid2" to compare side by side
        row1=$( echo "$rowid" | cut -f2 -d' ')
        row2=$( echo "$rowid" | cut -f3 -d' ')
        _compare "$row1" "$row2"
    elif [[ $rowid == ":" ]]; then

        # 2018-02-22 - this our power option for changing database table and column
        # to start with lets change _SEARCHCOL

        XXX=$( $SQLITE -separator $'\t' movie.sqlite <<! | cut -f2 | fzf -1 -0 
        PRAGMA table_info($_TABLE)
!
        )
        [[ -z "$XXX" ]] && { echo "Nothing selected, quitting." 1>&2; exit 1; }
        _SEARCHCOL=$XXX
        echo "Setting search column to $_SEARCHCOL"
    elif [[ $rowid =~ ^: ]]; then
        _commands $rowid
    else
        OPT_WHERE=" $_SEARCHCOL LIKE '%"$rowid"%'"
        _SELECTED=
        _query
        # FIXME one can't go up to earlier queries or commands
    fi

    #sqlite3 -separator $'\t'  $_DATABASE "SELECT * FROM $_TABLE WHERE rowid=$rowid ;"
done
