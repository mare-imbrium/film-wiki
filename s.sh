#!/usr/bin/env bash

# DESCRIPTION: does a LIKE search on title and prints out movies matching. --id ID
#  --url to print url. -a to print all cols
#sqlite3 movie.sqlite "select id, title, directed_by from movie where title like '%"$*"%';"
# # rowid needed for deletes and for using edit.sh

cd $MOV || exit 1

OPT_VERBOSE=
OPT_DEBUG=
HISTFILE=~/tmp/histfile.tmp
OPT_COLS="rowid, title, year, directed_by, starring , url"
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
        --debug)        shift
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
        OPT_WHERE=" title like '%"$1"%'"
    fi
fi

_query() {
    RES=$( sqlite3 -separator $'\t'  -nullvalue 'NULL' movie.sqlite "SELECT ${OPT_COLS} FROM movie WHERE $OPT_WHERE ;" )
    echo -e "$RES" | term-table.rb -H --wrap
    echo -e "$RES" | cut -f1 > $HISTFILE

}
_compare() {

    echo -e "\\033[1mComparing $row1 and $row2\\033[22m"
    sqlite3 -line  movie.sqlite "select * from movie where rowid = $row1; "  > t.1
    sqlite3 -line  movie.sqlite "select * from movie where rowid = $row2; "  > t.2
    #comm -3 t.1 t.2
    # -y side by side
    /usr/bin/diff --suppress-common-lines -y t.1 t.2
    rm t.1 t.2

}

_query

while true ; do
    cd $MOV
    #echo -e -n "\\033[1m>> Enter rowid (or String): \\033[22m"
    #read rowid
    rowid=$(rlwrap -pYellow -S 'Enter rowid (or pattern): ' -H ${HISTFILE} -o cat)
    #echo -n ">> Enter rowid (or string): "
    if [[ -z "$rowid" ]]; then
        rm $HISTFILE
        exit 0
    fi
    # if it is a rowid then show complete row, otherwise do another search in titles
    if [[ "$rowid" = +([0-9]) ]]; then
        sqlite3 -line  -nullvalue '---' movie.sqlite "SELECT rowid, * FROM movie WHERE rowid=$rowid ;"
    elif [[ $rowid =~ ^tt ]]; then
        sqlite3 -line  -nullvalue '---' movie.sqlite "SELECT rowid, * FROM movie WHERE imdbid=\"$rowid\" ;"
    elif [[ $rowid =~ ^delete ]]; then
        row=$( echo "$rowid" | cut -f2 -d' ')
        oldprogs/deleterow.sh "$row"
    elif [[ $rowid =~ ^edit ]]; then
        row=$( echo "$rowid" | cut -f2 -d' ')
        ./edit.sh "$row"
    elif [[ $rowid =~ ^compare ]]; then
        row1=$( echo "$rowid" | cut -f2 -d' ')
        row2=$( echo "$rowid" | cut -f3 -d' ')
        _compare "$row1" "$row2"
    else
        OPT_WHERE=" title like '%"$rowid"%'"
        _query
    fi

    #sqlite3 -separator $'\t'  movie.sqlite "SELECT * FROM movie WHERE rowid=$rowid ;"
done
