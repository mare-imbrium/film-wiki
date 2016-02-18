#!/usr/bin/env bash 
#===============================================================================
#
#          FILE: add_link_non_movie.sh
# 
#         USAGE: ./add_link_non_movie.sh 
# 
#   DESCRIPTION: this is to just add a link of a director or actor or award list to MOV/wiki
#    Also update its links.
#    This just dumps the file in the wiki directory without updating the database, so should not
#    be used for films.
# I can get either a link in the form of /wiki/Spencer_Tracy
# or Spencer_Tracy.html
# or even just Spencer_Tracy
#   NOTE : we need to put non-movie links in either director actor or lists folder
#      and make a link from wiki
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 12/31/2015 20:56
#      REVISION:  2015-12-31 21:15
#===============================================================================
TARGETDIR=

OPT_VERBOSE=
OPT_DEBUG=
while [[ $1 = -* ]]; do
    case "$1" in
        -t|--target)   shift
            TARGETDIR=$1
            shift
            ;;
        -V|--verbose)   shift
            OPT_VERBOSE=1
            ;;
        --debug)        shift
            OPT_DEBUG=1
            ;;
        -h|--help)
            cat <<-!
            $0 Version: 0.0.0 Copyright (C) 2015 jkepler
            This program downloads and saves a link in the given subdirectory of MOV/wiki
            and then creates a soft link from wiki to that directory.
            Usually the target dir will be director or actor or lists
!
            # no shifting needed here, we'll quit!
            exit
            ;;
        *)
            echo "Error: Unknown option: $1" >&2   
            echo "Use -h or --help for usage" 1>&2
            exit 1
            ;;
    esac
done

[[ -z "$TARGETDIR" ]] && { echo "Error: TARGETDIR blank. use -t or --target to specify where file is to be downloaded" 1>&2; exit 1; }
if [ $# -eq 0 ]
then
    echo "I got no link" 1>&2
    exit 1
else
    echo "Got $*" 1>&2
    #echo "Got $1"
fi
HOST="https://en.wikipedia.org/wiki/"
link="$1"
# I can get either a link in the form of /wiki/Spencer_Tracy
# or Spencer_Tracy.html
# or even just Spencer_Tracy
if grep -q "film)$" <<< "$link"; then
    echo "This link appears to be a film, and should go through ./fetchupdate"
    exit 1
fi
if grep -q "\.html$" <<< "$link"; then
    # remove .html at end
    link=$( echo $link | sed 's/\.html//' )
    echo $link
fi
# check if starts with wiki
if grep -q "^/wiki/" <<< "$link"; then
    # remove wiki from start since we are adding it now as part of host
    link=$( echo $link | sed 's|^/wiki/||' )
    echo $link
fi
if grep -q "/wiki/" <<< "$link"; then
    # full link may have been sent
    link=$( echo $link | sed 's|.*/wiki/||' )
    echo $link
fi
echo "${HOST}${link}"
URI="${HOST}${link}"
OFILE=$( echo "$link" | sed 's|/wiki/||;s|/|_|g' )
cd /Volumes/Pacino/dziga_backup/rahul/Downloads/MOV/wiki
if [[ ! -d "$TARGETDIR" ]]; then
    echo "Directory: $TARGETDIR not found" 1<&2
    exit 1
fi
OFILE="${OFILE}.html"
LINKFILE=$OFILE
OFILE=$( decode_uri.rb "$OFILE" )
OFILE="$TARGETDIR/${OFILE}"
echo "OFILE=${OFILE}"
curl $URI > $OFILE
src/convert_all_links.sh "$OFILE"
wc -l $OFILE
if [[ -f "$LINKFILE" ]]; then
    echo "$LINKFILE exists, moving to .bak"
    mv "$LINKFILE" "$LINKFILE.bak"
fi
ln -s "$PWD/$OFILE" .
