#!/usr/bin/env bash 
#===============================================================================
#
#          FILE: comparerows.sh
# 
#         USAGE: ./comparerows.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 03/04/2016 23:22
#      REVISION:  2016-03-05 09:40
#===============================================================================

PATT="$1"
[[ -z "$PATT" ]] && { echo "Error: title blank." 1>&2; exit 1; }
sqlite3 -line -header ../movie.sqlite <<!>t.t
select rowid , * from movie where title like "${PATT}%";
!
wc -l t.t
if [[ ! -s "t.t" ]]; then
    echo "No movie by pattern given. Check and retry"
    exit 1
fi
csplit.rb -p '^$' t.t
egrep -i "rowid|Title" file.1 file.2
echo press enter to diff
read
vimdiff file.1 file.2
echo You may call ./oldprogs/updateRowFromLines.rb file.1
echo "or deleterow.sh for one of the rowids"
