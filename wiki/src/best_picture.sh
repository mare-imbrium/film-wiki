#!/usr/bin/env bash 
#===============================================================================
#
#          FILE: best_picture.sh
# 
#         USAGE: ./best_picture.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 01/01/2016 18:22
#      REVISION:  2016-01-02 11:47
#===============================================================================

# problem with this is that the selector can change next year
cat Academy_Award_for_Best_Picture.html | scrape -b -e 'table.navbox:nth-child(148)' | xml2json | jq '.' | grep href | sed 's/"href": //' | sed 's/"\(.*\)".*/\1/;s/\.html//' | grep -vE '^\s*Template|index.php'


# this is much better since it is not likely to change. and the sed basically replaces TABS in between so we get all four fields in one row unlike previous. 
# title file name | title (film) | title bare | year/s
# next year you should increase this to 2015 (after the oscar is over)
sed -n '/<div style="font-size:114%"><strong class="selflink">Academy Award for Best Picture<\/strong><\/div>/,/2014/p' Academy_Award_for_Best_Picture.html | grep -o "href.*)"  | sed 's/href="//;s/" title="/	/;s/">/	/;s|</a></i> |	|' 

exit

# nominees
# filename | title | title bare
# # this still needs to be linked to URL so we can map to movie table and get year. need to fetch year from there
# and update here.

gsed -n '/<table class="wikitable"/,/<\/table>/p' Academy_Award_for_Best_Picture.html  | grep '<td><i><a href="' | gsed 's/<td><i><a href="//;s/" title="/	/;s/"[^>]*>/	/;s|</a>.*||' > t.t

# this prints only filename to start with and year.
# in case of fredrick march and william beary it only prints the first name

sed -n '/<li><a href="Emil_Jannings.html"/,/(2014)/p' Academy_Award_for_Best_Actor.html | grep href= | sed 's|<li><a href="\([^"]*\)".*</a> *(\(.*\))</li>|\1	\2|' > best_actor
