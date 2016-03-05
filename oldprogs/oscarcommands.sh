#!/usr/bin/env bash 
#===============================================================================
#
#          FILE: oscarcommands.sh
# 
#         USAGE: ./oscarcommands.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 02/26/2016 20:29
#      REVISION:  2016-03-02 12:17
#===============================================================================

# NOTE : for oscar awards go to wiki/src/ where there are progs like best_picture.sh which calls best_picture.rb 
#  then use oldprogs/update_... on first_col.rb with that file to update

tsv() {

    ./list.rb ./List_of_Academy_Award-winning_films.html > t.t
    wc -l t.t
    awk -F$'\t' 'BEGIN{OFS="\t"}{ print $5, $3,$4, $1, $2 ;}' t.t > o.t
    wc -l o.t
    echo "Please edit the file and remove junk after Zorba the Greek"
    echo "Now run check command (oscar.rb) or check_url.rb on o.t"
}
update_file(){
    echo -n "Enter year to create an update file for: "
    read year
    echo "url	won	nom" > o.tsv
    grep "$year" o.t | cut -f1-3 >> o.tsv
    wc -l o.tsv
}
create_insert_file() {
    echo "this creates a list of urls for the urls.txt which can be force_fetch 'ed after the oscar awards" >&2
    echo "You can run this list through check_url.rb to see which are not found or have a different url" >&2
    echo -n "Enter year to create an update file for: "
    read year
    grep "${year}$" o.t | cut -f1 
}
check() {
    if [[ ! -f "o.t" ]]; then
        echo "File: o.t not found" 1<&2
        exit 1
    fi
    wc -l o.t

    ./oscar.rb

}
download() {
    echo "downloading file ..."
    curl "https://en.wikipedia.org/wiki/List_of_Academy_Award-winning_films" > List_of_Academy_Award-winning_films.html
    echo "run tsv to generate o.t from which you can isolate a year and first 3 cols and update that."
}

if [[ $1 =~ ^(download|check|tsv|update_file|create_insert_file)$ ]]; then
  "$@"
else
  echo "Invalid subcommand $1" >&2
  exit 1
fi
