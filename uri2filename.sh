#!/usr/bin/env bash 
#===============================================================================
#
#          FILE: uri2filename.sh
# 
#         USAGE: ./uri2filename.sh "/wiki/Citizen_Kane"
# 
#   DESCRIPTION: converts a wikipedia film URL to a filename. Do not give the hostname.
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 02/21/2016 11:28
#      REVISION:  2016-03-07 13:05
#===============================================================================

# TODO take stdin also
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
    echo "$var"
}
url_to_filename "$1"
