#!/usr/bin/env bash 
#===============================================================================
#
#          FILE: download_actors.sh
# 
#         USAGE: ./download_actors.sh [filename]
# 
#   DESCRIPTION: loops through ./actorlinks.txt and calls ./add_link_non_movie.sh for each
#              You may specify another file with links e.g actresslinks.txt
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 01/17/2016 20:36
#      REVISION:  2016-01-18 19:06
#===============================================================================

infile=${1:-actorslinks.txt}
source ~/bin/sh_colors.sh
check_exists() {
    local line="$1"
    local actor=$( echo $line | sed 's|.*/||;s|\.html||' )
    local file="../actors/${actor}.html"
    if [[ ! -f "$file" ]]; then
        return 0
    fi
    perror "File $file already exists, not downloading."
    return 1
}
cd /Volumes/Pacino/dziga_backup/rahul/Downloads/MOV/wiki/src
if [[ ! -f "$infile" ]]; then
    echo "File: $infile not found" 1<&2
    exit 1
else
    echo using $infile
fi
while IFS='' read line
do
    echo -e "$line"
    check_exists "$line"
    if [  $? -eq 1 ]; then
        next
    fi
    ./add_link_non_movie.sh -t actors "$line"
    lastfile=$(ls -tr ../actors/*.html | tail -1 ) #| sed 's|.*/||')
    if [[ ! -f "$lastfile" ]]; then
        preverse "File: $lastfile not found" 
        exit 1
    fi
    echo "last file was $lastfile"
    patt=$( echo "$lastfile" | sed 's|.*/||;s|\.html||')
    patt="${patt}_filmography.html"
    echo "pattern is $patt"
    found=$(grep "$patt" $lastfile)
    if [[ -n "$found" ]]; then
        pinfo "found filmography ..."
        #read </dev/stdin
        ./add_link_non_movie.sh -t actors "$patt"
    else
        perror "Filmography links not found "
    fi
    echo sleeping 4 seconds
    sleep 4
done < $infile
