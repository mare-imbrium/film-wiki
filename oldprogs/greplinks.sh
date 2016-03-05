#!/usr/bin/env bash
#  Last update: 2016-03-04 11:36

## Description: given a file with film urls, extracts them to stdout
# In some cases, the winner of the year is in <i><b>. That 
# is why there are several filter.sh files.
## vim:ts=4:sw=4:tw=100:ai:nowrap:formatoptions=croqln:filetype=sh


# I have added td to remove duplicates since pages like Golden_Bear. Palme etc
# have a list of links at the end too.
# 2016-03-04 - 11:36 NOTE: this will work with a file that has not had links converted.
#  converted files don't have /wiki. and have html.
grep -h -o '<td><i><a href=\"/wiki/[^"]*\"' $1 | \
sed -n 's/\"$//p' | \
sed -n 's/^.*"//p' 
