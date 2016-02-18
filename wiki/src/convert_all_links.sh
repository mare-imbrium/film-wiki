#!/usr/bin/env bash 
#===============================================================================
#
#          FILE: convert_all_links.sh
# 
#         USAGE: ./convert_all_links.sh 
# 
#   DESCRIPTION: This converts all the links in the given file to point to current directory
#                whether the file exists or not. In any case the link is useless.
#                Later when the file comes it will automatically link, so this needs to be run once
#                per file.
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 12/31/2015 15:14
#      REVISION:  2015-12-31 15:15
#===============================================================================

change_link() {
    local VAR="$1"
    if [[  -f "$VAR" ]]; then
        sed -i.bk 's|href="/wiki/\([^"]*\)|href="\1.html|g' $VAR
    else
        echo -e "$0:\\033[1m\\033[0;31m$VAR not a file. Ignoring.\\033[22m\\033[0m" >&2
    fi
}
if [ $# -eq 0 ]
then
    echo "I got no filename. For stdin use --stdin." 1>&2
    exit 1
elif [[ $1 == "--stdin" ]]; then
    while IFS='' read line
    do
        echo -e "$line"
        change_link "$line"
    done < /dev/stdin
fi

for file in "$@"; do
    echo "File: $file"
    # takes all strings with href="/wiki/ and removes /wiki/ and appends .html to it.
    change_link "$file"
    echo "$0 converted links in $file".
done
