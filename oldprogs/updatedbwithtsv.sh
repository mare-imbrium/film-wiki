#!/usr/bin/env bash 
#===============================================================================
#
#          FILE: updatedbwithtsv.sh
# 
#         USAGE: ./updatedbwithtsv.sh -c NUM -n COLUMN file.tsv
# 
#   DESCRIPTION: update specific column of movie table with a column from a tsv.
#     Specify column number in TSV and column name in table.
# 
#       OPTIONS: -c NUM -n COLNAME
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 02/19/2016 12:35
#      REVISION:  2016-02-26 19:59
#===============================================================================

source ~/bin/sh_colors.sh
APPNAME=$( basename $0 )
ext=${1:-"default value"}
today=$(date +"%Y-%m-%d-%H%M")
curdir=$( basename $(pwd))
export TAB=$'\t'



ScriptVersion="1.0"

#===  FUNCTION  ================================================================
#         NAME:  usage
#  DESCRIPTION:  Display usage information.
#===============================================================================
function usage ()
{
	cat <<- EOT

  Update a specific column in the movie table with a specific field in the given TSV.
  It is assumed that column 1 is the rowid in the movie table

  Usage :  ${0##/*/} [options] filename.tsv
           ${0##/*/} -c 5 -n starring   file.tsv
           ${0##/*/} -c 4 -n directed_by  file.tsv

  Options: 
  -c, --col       Column number of tsv (starting 1) 1 is rowid
  -n, --name      Name of column in database to set

  -h|--help       Display this message
  -v|--version    Display script version
  -V|--verbose    Display processing information
  --no-verbose    Suppress extra information
  --debug         Display debug information

	EOT
}    # ----------  end of function usage  ----------


#-------------------------------------------------------------------------------
# handle command line options
#-------------------------------------------------------------------------------
OPT_VERBOSE=
OPT_DEBUG=
FCOL=
while [[ $1 = -* ]]; do
case "$1" in
    -c|--col)   shift
                     FCOL=$1
                     shift
                     ;;
    -n|--name)   shift
                     FCOLNAME=$1
                     shift
                     ;;
    -V|--verbose)   shift
                     OPT_VERBOSE=1
                     ;;
    --no-verbose)   shift
                     OPT_VERBOSE=
                     ;;
    --debug)        shift
                     OPT_DEBUG=1
                     ;;
    -h|--help)
        usage
        exit
    ;;
    *)
        echo "Error: Unknown option: $1" >&2   # rem _
        echo "Use -h or --help for usage" 1>&2
        exit 1
        ;;
esac
done

if [ $# -eq 0 ]
then
    echo "I got no filename" 1>&2
    exit 1
else
    echo "Got $*" 1>&2
   echo "Got File: $1"
    if [[ ! -f "$1" ]]; then
        echo "File:$1 not found" 1>&2
        exit 1
    fi
fi
infile=$1
if [[ -z "$FCOL" ]]; then
    echo "COLUMN NUMBER BLANK. Which columns data to take for updating"
    exit 1
fi
if [[ -z "$FCOLNAME" ]]; then
    echo "COLUMN NAME BLANK. Which column to update ?"
    exit 1
fi
while IFS='' read line
do
    #echo -e "$line"
    rowid=$( echo "$line" | cut -f1)
    value=$( echo "$line" | cut -f${FCOL} )
    if [[ -n "$OPT_VERBOSE" ]]; then
        echo ">>>> ${rowid} = value is $value"
    fi
    echo "update movie set ${FCOLNAME} = \""${value}"\" where rowid = ${rowid};"
done < "${infile}"
