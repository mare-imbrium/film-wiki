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

# not required since we determine the file name beforehand
#  and tell each program what the output file should be
_getpath() {
    path=$( cat lastfile.tmp | tr "\n" "" )
    echo ">>> lastfile has $path."
}

# run the entire process for one url
_process() {

    URL=$1
    URL=$( echo "$URL" | sed 's|http.*\.org/|/|')
    echo "Parturl is $URL"
    # determine html filename from URL
    HTMLFILE=$( ./uri2filename.sh $URL )
    # determine YML filename from path
    YMLFILE=$( echo "$HTMLFILE" | sed 's|\.html|.yml|;s|^wiki/|yml/|' )
    echo "URL = $URL HTML = $HTMLFILE YML = $YMLFILE"
    # download the file and write it in wiki/
    ./downloadfilm.rb $VERBOSE_OPTION $DOWNLOAD_OPTION $URL "$HTMLFILE"
    # parse the html and place parsed info as a YML in yml/
    ./parsedoc.rb $VERBOSE_OPTION "$HTMLFILE" $URL "$YMLFILE"
    # read YML into database
    ./updateyml2db.rb $VERBOSE_OPTION "$YMLFILE"
    # convert all links to local links so browser can link
    wiki/src/convert_all_links.sh "$HTMLFILE"

 }

 # read URLs from a file
 _loop() {
     INFILE=$1
     while IFS='' read line
     do
         echo -e "loop: $line"
         _process $line
     done < $INFILE
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
