#!/usr/bin/env bash 
#===============================================================================
#
#          FILE: palmecommands.sh
# 
#         USAGE: ./command.sh fetch | update_file | missing 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 02/04/2016 23:46
#      REVISION:  2016-03-04 18:44
#===============================================================================
#
# TODO: cannes field is palme, it should have been cannes with 3 values P for palme
#  G for Grand Prix (2nd place) and Jury Award 3rd place.
#  Currently i have W for the win. So i can use G and J.
#  https://en.wikipedia.org/wiki/Grand_Prix_%28Cannes_Film_Festival%29
#  https://en.wikipedia.org/wiki/Jury_Prize_%28Cannes_Film_Festival%29

update_file() {
    # create the file required to update into movie.tsv
    # first check missing
    file=palme.html
    echo writing to palme.tsv
    echo "url	palme" > palme.tsv
    ./greplinks.sh $file | sed 's|$|	W|' >> palme.tsv
    wc -l palme.tsv
}
missing() {
    file=palme.html
    echo -e "links not present in movies.sqlite" 1<&2
    ./greplinks.sh $file | ../check_url.rb | grep FAILED | cut -f2- -d:
    # you will want to place these in urls.txt and fire command fetch
}
links() {
    file=palme.html
    echo -e "reporting all links in $file " 1<&2
    ./greplinks.sh $file | ../check_url.rb 
}
fetch() {

    # fetch the file containing palme results each year.
    file=palme.html
    curl "https://en.wikipedia.org/wiki/Palme_d'Or" > palme.html
    if [[ ! -s "$file" ]]; then
        echo "$file empty download failed"
        echo why the hell is curl failing when wget is okay
        wget "https://en.wikipedia.org/wiki/Palme_d'Or"
        mv "Palme_d'Or" palme.html
    else
        echo "$file succeeded."
    fi
    wc -l $file

}
if [[ $1 =~ ^(fetch|missing|links|update_file)$ ]]; then
  "$@"
else
  echo "Invalid subcommand $1" >&2
  exit 1
fi
