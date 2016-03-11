#!/usr/bin/env bash 
#===============================================================================
#
#          FILE: fetchmovie.sh
# 
#         USAGE: fetchmovie.sh  URL
#                fetchmovie.sh  --filename urls.txt
# 
#   DESCRIPTION: chains fetching, parsing and updating of database.
#      This is to replace fetchupdate.rb which did everything in one large loop,
#      and thus i could not execute parts of it, like only updating the db or fetching a file again.
#
#      After inserting, use the oldprogs/findimdbid_for_wikiurl.sh to generate a file called
#      insert.tsv containing new urls and possible imdb ids. edit it and import it into 
#      imlinks2.
# 
#       OPTIONS: --force force fetch of a file so as to update existing file.
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 02/20/2016 23:58
#      REVISION:  2016-02-21 14:54
#===============================================================================

source ~/bin/sh_colors.sh
# not required since we determine the file name beforehand
#  and tell each program what the output file should be
_getpath() {
    path=$( cat lastfile.tmp | tr "\n" "" )
    echo ">>> lastfile has $path."
}
_update_url() {
    # if we are changing the URL to the canonical, then update the URL in the table too
    #  so that updates can happen.

    SQLITE=$(brew --prefix sqlite)/bin/sqlite3
    MYDATABASE=movie.sqlite
    exists=$( $SQLITE $MYDATABASE <<!
       select rowid from movie where url = "$DECODE_CANON";
!
)
    if [[ -n "$exists" ]]; then
        echo -e "\\033[1m\\033[0;31m${DECODE_CANON} already exists as ${exists}. Please merge. Cannot rename.\\033[22m\\033[0m" >&2
        echo "rowid:$exists has $DECODE_CANON. Merge with $OLDURL" >> error.log
        return 1
    fi
    $SQLITE $MYDATABASE <<!
      UPDATE movie set url = "$DECODE_CANON" where url = "$OLDURL";
!
}

# run the entire process for one url
_process() {

    URL=$1
    URL=$( echo "$URL" | sed 's|http.*\.org/|/|')
    echo "  Parturl is $URL"
    # determine html filename from URL
    HTMLFILE=$( ./uri2filename.sh $URL )
    # determine YML filename from path
    YMLFILE=$( echo "$HTMLFILE" | sed 's|\.html|.yml|;s|^wiki/|yml/|' )
    echo "  URL = $URL HTML = $HTMLFILE YML = $YMLFILE"
    # download the file and write it in wiki/
    ./downloadfilm.rb $VERBOSE_OPTION $DOWNLOAD_OPTION $URL "$HTMLFILE"
    if [  $? -eq 0 ]; then
        # 2016-03-07 - here is where we can determing correct html and fix URL HTML and YML based on canonical

        CANONICAL=$( ./oldprogs/grepcanonical.sh -h "${HTMLFILE}" )
        if [[ -n "$CANONICAL" ]]; then
            DECODE_CANON=$( echo "$CANONICAL" | decode_uri.rb )
            if [[ "$URL" != "$DECODE_CANON" ]]; then
                echo "   >>>> canon=$CANONICAL"
                echo "   >>>> decod=$DECODE_CANON"
                echo -e "  CHANGING url to $DECODE_CANON ... press ENTER"
                #read ANS </dev/tty
                OLDURL="$URL"
                URL="$DECODE_CANON"
                # TODO NOTE changing URL means that a new row can be inserted, although updateyml2db.rb will
                #  prevent that from happening, so update will fail too. This is in case of a force update
                #  if user wanted to update data, and have the URL corrected by canonical
                ## Update the tables url from OLDURL to DECODE_CANON if OLD exists.
                
                _update_url "$OLDURL" "$DECODE_CANON"

            fi
            TMPFILE=$( ./uri2filename.sh "${CANONICAL}" )
            if [[ "$TMPFILE" != "$HTMLFILE" ]]; then
                echo -e "  CHANGING $HTMLFILE to $TMPFILE press ENTER"
                #read ANS </dev/tty
                # sometimes the case is different, so OSX gives an error, so i do this double move.
                mv "$HTMLFILE" "$HTMLFILE.tmp"
                mv "$HTMLFILE.tmp" "$TMPFILE"
                HTMLFILE="$TMPFILE"
                YMLFILE=$( echo "$HTMLFILE" | sed 's|\.html|.yml|;s|^wiki/|yml/|' )
                echo "  +URL = $URL HTML = $HTMLFILE YML = $YMLFILE"
            fi
        else
            echo "Could not find canonical link"
        fi



        # parse the html and place parsed info as a YML in yml/
        # NOTE: can we do without sending url to parsedoc since it reads up file ?
        ./parsedoc.rb $VERBOSE_OPTION "$HTMLFILE" $URL "$YMLFILE"
        if [  $? -eq 1 ]; then
            # no data in html file, probably wrong url.
            return 1
        fi
        # read YML into database
        ./updateyml2db.rb $VERBOSE_OPTION $DOWNLOAD_OPTION "$YMLFILE"
        if [  $? -eq 1 ]; then
            # duplicate detected after downloading the parsing html
            return 1
        fi
        # convert all links to local links so browser can link
        wiki/src/convert_all_links.sh "$HTMLFILE"
        return 0
    else
        return 1
    fi

 }

 # read URLs from a file
 _loop() {
     INFILE=$1
     total=$( wc -l "$1" | cut -f1 -d' ' )
     ctr=0
     pctr=1
     failctr=0
     while IFS='' read line
     do
         pinfo ">> ($pctr/${total}) loop: $line      (failed $failctr)"
         _process $line
         if [  $? -eq 0 ]; then
             (( ctr++ ))
             (( pctr++ ))
             echo "$line" >> url.log
             sleep 1
         else
             (( failctr++ ))
             echo "$line" >> error.log
             sleep 5
         fi
     done < $INFILE
     pdone "$ctr of ${total} movies inserted/updated" 
     if [[ $failctr -gt 0 ]]; then
         perror "$failctr failed."
     fi

 }
ScriptVersion="1.0"

#===  FUNCTION  ================================================================
#         NAME:  usage
#  DESCRIPTION:  Display usage information.
#===============================================================================
function usage ()
{
	cat <<- EOT
  $0 v${ScriptVersion}. This programs fetches the given film URL from wikipedia, parses the film info,
    and updates the database. The html is stored in wiki/ and the yml file containing the parsed info
    is stored in yml/.

  Usage :  ${0##/*/} [options] arg
           ${0##/*/} --filename urls.txt
           ${0##/*/} "/wiki/Citizen_Kane"
           ${0##/*/} --force "/wiki/Spotlight"

  Options: 
  -f, --filename FILE Filename to read URLs from
  --force          Force download of URL even if file exists in database

  -h, --help       Display this message
  -v, --version    Display script version
  -V, --verbose    Display processing information
  --no-verbose     Suppress extra information
  --debug          Display debug information

	EOT
}    # ----------  end of function usage  ----------


#-------------------------------------------------------------------------------
# handle command line options
#-------------------------------------------------------------------------------
OPT_VERBOSE=
OPT_DEBUG=
while [[ $1 = -* ]]; do
case "$1" in
    -f|--filename)   shift
                     filename=$1
                     shift
                     ;;
    -V|--verbose)   shift
                     OPT_VERBOSE=1
                     VERBOSE_OPTION="--verbose"
                     ;;
    --no-verbose)   shift
                     OPT_VERBOSE=
                     ;;
    --debug)        shift
                     OPT_DEBUG=1
                     ;;
    --force)        shift
                     OPT_FORCE=1
                     DOWNLOAD_OPTION="--force"
                     ;;
    -h|--help)
        usage
        exit
    ;;
    *)
        echo "$0 Error: Unknown option: $1" >&2   # rem _
        echo "Use -h or --help for usage" 1>&2
        exit 1
        ;;
esac
done

if [[ -n "$filename" ]]; then
    _loop $filename
    exit 0
fi
if [ $# -eq 0 ]
then
    echo "$0: Please pass a URL to download." 1>&2
    exit 1
else
    echo "Got $*" 1>&2
fi
_process "$1"
