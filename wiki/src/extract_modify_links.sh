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
# 2015-12-31 - some files have 114 i/o 110 and some don't have ; after size
text=$( gsed -n '/<div style="font-size:11.%;\?">Films directed by <a href="/,/>v</p' $file)
if [[ -z "$text" ]]; then
    text=$( sed -n '/<div style="font-size:11.%;">The Films of <a href="/,/>v</p' $file)
    if [[ -z "$text" ]]; then
        text=$( sed -n '/<div style="font-size:11.%;">Films of <a href="/,/>v</p' $file)
    fi
    ftext=$( sed -n '/<div style="font-size:11.%;">.*>filmography<\/a><\/div>/,/>v</p' $file)
    text="${text}	${ftext}"
fi
if [[ -z "$text" ]]; then
    echo not found any links for $file
    echo this program works on MODIFIED files. Once links are converted /wiki/ is removed.
    echo Or else the format of directors films is quite different
    exit 1
fi
#echo "$text" | grep href | grep -o '/wiki/[^"]*' | grep -v ':'
# next line grep -o keeps going and does a greedy match
#echo "$text" | grep -o 'href=".*.html"'  | sed 's|href="|/wiki/|;s|\.html"||' | grep -v ':'

# next line first takes out href and text between double quotes.
# then filters those ending with .html since there's a lot of junk
# then replace href= with /wiki/
# then remove .html at end
# then remove links with : in it. Mostly Category and stuff like that.
echo "$text" | grep -o 'href="[^"]*'  | grep '\.html$' | sed 's|href="|/wiki/|;s|\.html||' | grep -v ':'
