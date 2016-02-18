#!/usr/bin/env bash 
#===============================================================================
#
#          FILE: refresh_academy_awards_links.sh
# 
#         USAGE: ./refresh_academy_awards_links.sh 
# 
#   DESCRIPTION: Yearly refresh of Academy Award listings.
#                This does not affect the database or any other files, so its safe
#                Should be done somewhere at end of February.
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 01/01/2016 15:03
#      REVISION:  2016-01-01 15:10
#===============================================================================

echo "Am about to overwrite all Academy Award files in MOV/wiki folder."
cd /Volumes/Pacino/dziga_backup/rahul/Downloads/MOV/wiki
cat src/academy_awards_links.txt | src/add_wiki_links.rb --force

echo -e "\\033[1mDone.\\033[22m"
