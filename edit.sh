#!/usr/bin/env zsh
#-----!/bin/zsh
# vared failed with /usr/local/bin/zsh/ works with /bin/zsh
# however stat -c fails with /bin/zsh since it uses /usr/bin/stat
# env zsh uses usr/local/bin/stat
# nope, now that is not working too
# /usr/bin/stat -f "%Sm" -t "%Y%m%d%H%M%S"
#  Last update: 2018-02-21 11:45

# Description: edit a given row and column of a table (movie) given rowid
# params: rowid and columns to edit
#
# TODO make a version of this that can be used for any database and table
# e.g. --db movie.sqlite --table movie OR movie.sqlite:movie
# should not ask the user to enter db and table each time.

source ~/bin/sh_colors.sh
# so that gnu commands take precedence
export PATH="$(brew --prefix coreutils)/libexec/gnubin:/usr/local/bin:$PATH"

DBNAME=movie.sqlite
TBNAME=movie

CHECK_MARK="\u2713"
X_MARK="\u2717"

function _save_to_db {
    # read each row of the file and update value for the column one by one
    # format of file is list format of sqlite
    # col = value
	rowid=$1
    file=$2

	while read p; do
		col=$(echo "$p" | cut -f1 -d'=' | sed 's/ $//;s/^ *//;')
		val=$(echo "$p" | cut -f2- -d'=' | sed 's/^ //;')
        #echo "key is:$col:"
        #echo "val is:$val:"
		sqlite3 $DBNAME "update $TBNAME set $col = '"$val"' where rowid = $rowid"
        echo -n "Retval:$? "
        echo Updated $col with $val
	done < $file


}
function _edit_row {
    # put data for that row into a file and allow user to edit the file
    # If the file is changed, then update the database with the values of each row
    # Columns with null values are not being given presently
    # We may want to enter values in null fields later.
    rowid=$1
    #TMP_FILE=$(mktemp XXXEDIT)
    TMP_FILE=${TMPDIR:-/tmp}/prog.$$
    trap "rm -f '${TMP_FILE}'" 0               # EXIT
    trap "rm -f '${TMP_FILE}'; exit 1" 2       # INT
    trap "rm -f '${TMP_FILE}'; exit 1" 1 15    # HUP TERM

    sqlite3 -line -nullvalue '---' $DBNAME "select * from $TBNAME where rowid = $rowid" | grep -v '\-\-\-' > $TMP_FILE

    # this uses gnu stat not BSD
    mtime=`stat -c %Y $TMP_FILE`
    #mtime=$(/usr/bin/stat -f "%Sm" -t "%Y%m%d%H%M%S" $TMP_FILE)
    vim $TMP_FILE
    mtime2=`stat -c %Y $TMP_FILE`
    #mtime2=$(/usr/bin/stat -f "%Sm" -t "%Y%m%d%H%M%S" $TMP_FILE)
    #echo mtime2 $mtime2
    if [ $mtime2 -gt $mtime ] 
    then
        echo "edited"
        _save_to_db $rowid $TMP_FILE
    else
        echo not edited
    fi
    echo $TMP_FILE

}

if [  $# -eq 0 ]; then
    echo "Please pass a rowid and a field name to edit"
    echo " Use s.sh to get the rowid of a film"
    exit 1
fi

cd $MOV || ( echo "$0: Cannot change directory to $MOV" ; exit 1 )
if [[ ! -f "$DBNAME" ]]; then
    echo "$0: File $DBNAME not found in $PWD" 1<&2
    exit 1
fi

rowid=$1
sqlite3 -line -nullvalue '---' $DBNAME "select * from $TBNAME where rowid = $rowid" | grep -v '\-\-\-'
echo "----"
#echo "if vared does not allow backspacing then use cursor left arrow then add a letter"
#echo "Now you can go right and BS"
#echo "----"

shift
if [  $# -eq 0 ]; then
    _edit_row $rowid
    exit 0
fi
# this is the old method in which the column was also passed on command line
# and was edited one by one using vared
## loop through columns given on command line and run update on them one by one
while [ "$1" != "" ]; do

    col=$1
    TITLE=$(sqlite3 $DBNAME "select $col from $TBNAME where rowid = $rowid")
    pbold "Row: $rowid. $col: ($TITLE)"
    vared TITLE
    #TITLE=$(rlwrap -pYellow -S 'Edit? ' -P "$TITLE" -o cat)
    
    [[ -z "$TITLE" ]] && { echo "${X_MARK} Error: $col blank." 1>&2; exit 1; }
    # vared not working with /usr/local/bin/zsh. works with /bin/zsh
   #read TITLE
    sqlite3 $DBNAME "update $TBNAME set $col = '"$TITLE"' where rowid = $rowid"
    shift

    pinfo "${CHECK_MARK} Updated $col "
    sqlite3 -line $DBNAME "select rowid, url, $col from $TBNAME where rowid = $rowid"
done
