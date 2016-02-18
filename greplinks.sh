#!/usr/bin/env bash
#  Last update: 2016-02-18 18:39

## Description: given a file with film urls, extracts them to stdout
# In some cases, the winner of the year is in <i><b>. That 
# is why there are several filter.sh files.
## vim:ts=4:sw=4:tw=100:ai:nowrap:formatoptions=croqln:filetype=sh


# I have added td to remove duplicates since pages like Golden_Bear. Palme etc
# have a list of links at the end too.
grep -h -o '<td><i><a href=\"/wiki/[^"]*\"' $1 | \
sed -n 's/\"$//p' | \
sed -n 's/^.*"//p' 
