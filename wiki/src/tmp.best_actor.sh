#!/usr/bin/env bash 
#===============================================================================
#
#          FILE: best_actor.sh
# 
#         USAGE: ./best_actor.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 01/02/2016 13:07
#      REVISION:  2016-01-02 13:25
#===============================================================================

cd /Volumes/Pacino/dziga_backup/rahul/Downloads/MOV/wiki/
TMPFILE=$(mktemp wiki)
trap "rm -f '${TMPFILE}'" 0               # EXIT
trap "rm -f '${TMPFILE}'; exit 1" 2       # INT
trap "rm -f '${TMPFILE}'; exit 1" 1 15    # HUP TERM
sed -n '/1927 in film/,/^<h2>/p' Academy_Award_for_Best_Actor.html | grep -oE 'href="[^"]*|^<tr>' | sed 's/href="//' | grep -v '^#' | grep -v '^/w/index.php' | src/best_actor.rb

#best_actor.rb $TMPDIR


