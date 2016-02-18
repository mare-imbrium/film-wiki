#!/usr/bin/env bash
# ----------------------------------------------------------------------------- #
#         File: hdir.sh
#  Description: User can select a director or actor and see html list of movies from which he can select
#        and see local wiki page for that movie.
#
#        This file has been aliased as hact.sh too for actors.
#        Requires fzf and gsed
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2016-01-23 - 20:53
#      License: MIT
#  Last update: 2016-02-18 18:29
# ----------------------------------------------------------------------------- #
#  hdir.sh  Copyright (C) 2012-2016 j kepler
#
# first use fzf to select a director/actor, then show his movies as an html with links to file.
#

# check executable name to see if director or actor
stub=$(basename $0)
if [[ $stub =~ dir ]]; then
    text=director
    listfile="./director.list"
    selcolumn="directed_by"
    dispcolumn="starring"
elif [[ $stub =~ act ]]; then
    echo act
    text=actor
    listfile="./actors.list"
    selcolumn="starring"
    dispcolumn="directed_by"
else
    echo reached none
fi
# convert the url in the database into a local file
# This should work 99% of the time. What about old files ?
url_to_filename() {
    local var=$1
    var=$( echo "$var" | sed 's|/wiki/||;s|/|_|g;' )
    # decode_uri.rb was very slow in a loop so using sed
    #var=$( echo "$var" | decode_uri.rb )
    #var=$(perl -MURI::Escape -e 'print uri_unescape($ARGV[0])' "$var")
    #alias urldecode='sed "s@+@ @g;s@%@\\\\x@g" | xargs -0 printf "%b"'
    # http://unix.stackexchange.com/questions/159253/decoding-url-encoding-percent-encoding
    # sed replaces + with space and % with \x
    var=$( echo "$var" | sed "s@+@ @g;s@%@\\\\x@g" | xargs -0 printf "%b" )
    var="wiki/$var.html"
    RESULT=$var
}
# generate an html file with movies linked to local wiki file so user
# can click a link and see movie, then press B to come back to movie list page
select_html() {

    COLS="url,title,year"
    if [[ -n "$OPT_LONG" ]]; then
       COLS="url,title,year,${dispcolumn},running_time"
    fi
# display and let user select a film
MOV=$( $SQLITE -separator $'\t' movie.sqlite <<!
.headers on
SELECT $COLS from movie where ${selcolumn} LIKE "%$STR%" ORDER by year ;
!
)
[[ -z "$MOV" ]] && { echo "No results. quitting." 1>&2; exit 1; }

# loop through result and link title to file
OUTPUT=tmp.html
echo "Sending output to $OUTPUT"
# border = 1 is nice but we have to key down 2 times.
 echo "<h1>Movies of $STR </h1>" > $OUTPUT
echo "<HTML><TABLE BORDER=$OPT_BORDER>" >> $OUTPUT
# if headers are on then don't hyperlink the first row.
# remove the first row and print it with TR and TD
read header <<< "$MOV"
# remove first col url
header=$( echo "$header" | cut -f2- )
# convert to title-case
header=$( echo "$header" | gsed 's/[^ 	]\+/\L\u&/g' )
echo "<TR><TD align=center>" >> $OUTPUT
echo "$header" | sed 's|	|</TD><TD align=center>|g;s|_| |g' >> $OUTPUT
echo "</TD></TR>" >> $OUTPUT
#MOV=$( echo $MOV | sed '1,$d' )
# remove header row
MOV=$( echo "$MOV" | tail -n +2 )
echo "$MOV" | while IFS='' read line
do
    #echo -e "$line"
    link=$( echo "$line" | cut -f1 )
    url_to_filename $link
    filename=$RESULT
    title=$( echo "$line" | cut -f2 )
    line=$( echo "$line" | cut -f3- )
    echo "<TR><TD>" >> $OUTPUT
    cat <<! >> $OUTPUT
      <a href="$filename">$title</a>
!
    echo "</TD><TD>" >> $OUTPUT
    echo "$line" | sed 's|	|</TD><TD>|g' >> $OUTPUT
    echo "</TD></TR>" >> $OUTPUT
done 
echo "</TABLE></HTML>" >> $OUTPUT
$BROWSER $OUTPUT
}
function show_wiki () {
    # use rowid to get url and convert to filename
    # I am still using decode_uri.rb. If the sed form doesn't work in some case
    #  then check this to see if it is works and correct sed line
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
        $BROWSER "$url"
    fi
}
select_fzf() {
# display and let user select a film
MOV=$( $SQLITE -separator $'\t' movie.sqlite <<! | fzf -1 -0 
SELECT title, year, rowid from movie where ${selcolumn} LIKE "%$STR%" ORDER by year ;
!
)
[[ -z "$MOV" ]] && { echo "Nothing selected, quitting." 1>&2; exit 1; }

# extract rowid from line
rowid=$( echo "$MOV" | cut -f3 )
[[ -z $rowid ]] && exit
show_wiki $rowid
}

# start of program
OPT_FZF=

OPT_VERBOSE=
OPT_DEBUG=
OPT_BORDER=0
while [[ $1 = -* ]]; do
    case "$1" in
        -V|--verbose)   shift
            OPT_VERBOSE=1
            ;;
        --debug)        shift
            OPT_DEBUG=1
            ;;
        --html)        shift
            OPT_FZF=
            ;;
        --fzf)        shift
            OPT_FZF=1
            ;;
        --browser)        shift
            BROWSER=$1
            shift
            ;;
        -l|--long)        shift
            OPT_LONG=1
            OPT_BORDER=1
            ;;
        -h|--help)
            cat <<-! | sed 's|^     ||g'
            $0 Version: 0.0.0 Copyright (C) 2015 jkepler
            This program lets user select ${text} name and then see movie names of the ${text}
            and select one. For that movie, the local wiki page is shown in w3m

            Usage:
              $0 hitchcock
              $0 --fzf redford
              $0 --html eastwood
              $0 --browser open eastwood

            Options:
            --fzf      Use fzf to select movie
            --html     Use HTML page to select movie (the default)
            --browser  Use given browser instead of w3m
!
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

SQLITE=$(brew --prefix sqlite)/bin/sqlite3
BROWSER=w3m
cd /Volumes/Pacino/dziga_backup/rahul/Downloads/MOV/ || exit 1

# let user select  ${text} from list
# TODO the list has joined names, too. We should separate names into another table, or file.
# TODO same for actors
#STR=$( $SQLITE movie.sqlite "SELECT distinct directed_by from movie;" | fzf --query="$1" -1 -0 )
MYDATABASE=movie.sqlite
if [[ $MYDATABASE -nt $listfile ]]; then
    errorstr="$listfile is out of date. pls refresh using update_fzf_lists.sh"
    echo -e "$errorstr" 1<&2
fi
STR=$( cat $listfile | fzf --query="$1" -1 -0 )
[[ -z "$STR" ]] && { echo "Nothing selected, quitting." 1>&2; exit 1; }
echo -e "$STR" 1<&2

if [[ -n "$OPT_FZF" ]]; then
    # use fzf to select movie and open w3m with movie wiki file
    select_fzf "$STR"
else
    # generate html with links to local wiki file
    select_html "$STR"
fi
