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
#       CREATED: 03/02/2016 12:08
#      REVISION:  2016-03-02 12:12
#===============================================================================

# use ,fh to generate file header
source ~/bin/sh_colors.sh

echo "hopefull you have refreshed the links ..."

./best_picture.rb > best_picture.tsv

wc -l best_picture.tsv

echo -n "Enter year to process: "
read year
echo "url	best_pic" > tmp.tsv
grep "${year}" best_picture.tsv | cut -f2,3 >> tmp.tsv

wc -l tmp.tsv

