#!/usr/bin/env bash

# DESCRIPTION: does a LIKE search on title and prints out movies matching.
#sqlite3 movie.sqlite "select id, title, directed_by from movie where title like '%"$*"%';"
# # rowid needed for deletes and for using edit.sh

OPT_VERBOSE=
OPT_DEBUG=
OPT_COLS="rowid, title, year, directed_by, starring "
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
            $0 Version: 0.0.0 Copyright (C) 2016 jkepler
            This program does the following:.. TODO

            Usage:
            $0 --filename abc.txt

            Options:
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
    OPT_WHERE=" title like '%"$1"%'"
fi

_query() {
    sqlite3 -separator $'\t'  -nullvalue 'NULL' movie.sqlite "SELECT ${OPT_COLS} FROM movie WHERE $OPT_WHERE ;" | term-table.rb -H --wrap
}

_query

while true ; do
    echo -n ">> Enter rowid (or string): "
    read rowid
    if [[ -z "$rowid" ]]; then
        exit 0
    fi
    # if it is a rowid then show complete row, otherwise do another search in titles
    if [[ "$rowid" = +([0-9]) ]]; then
        sqlite3 -line  -nullvalue '---' movie.sqlite "SELECT * FROM movie WHERE rowid=$rowid ;"
    else
        OPT_WHERE=" title like '%"$rowid"%'"
        _query
    fi

    #sqlite3 -separator $'\t'  movie.sqlite "SELECT * FROM movie WHERE rowid=$rowid ;"
done
