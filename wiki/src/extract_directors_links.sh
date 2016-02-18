#!/usr/bin/env bash 
#===============================================================================
#
#          FILE: extract_directors_links.sh
# 
#         USAGE: ./extract_directors_links.sh 
# 
#   DESCRIPTION: from a film file, extract the directors section and get the links.
#                the cssselector is different for each file so i cannot rely on that.
#
#                This works on the unmodified files. Now /wiki/ has been removed.
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 12/31/2015 11:34
#      REVISION:  2015-12-31 19:30
#===============================================================================

if [  $# -eq 0 ]; then
    echo pass file name
    exit 1
fi
if [[ ! -f "$1" ]]; then
    echo "File: $1 not found"
    exit 1
fi
file=$1
# we have not changed the links .... darn that means we have lost the link, need to redo
text=$( sed -n '/<div style="font-size:110%;">Films directed by <a href="\/wiki\//,/>v</p' $file)
if [[ -z "$text" ]]; then
    text=$( sed -n '/<div style="font-size:110%;">The Films of <a href="\/wiki\//,/>v</p' $file)
fi
if [[ -z "$text" ]]; then
    echo not found any links for $file
    echo this program works on unmodified files. Once links are converted /wiki/ is removed.
    exit 1
fi
echo "$text" | grep href | grep -o '/wiki/[^"]*' | grep -v ':'
