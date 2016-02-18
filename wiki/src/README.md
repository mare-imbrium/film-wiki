# SRC

This contains mostly programs that parse the academy award listings and create TSV's.
They can be queries directly or later used to update the movie.sqlite table in a parent
directory.

There are also some programs that download directors or actors pages so we can cross-link from a movie to some notable actor or director.

## CROSS-LINKING FILES

1) Use convert_all_links.sh whenever adding a new file. Use it just for
   the newly added file. no need to do it for the earlier ones.


it is better to change ALL href="/wiki/xxx" to
href="/wiki/WHATEVER.html"
Then we do not have to keep running it for all. As a file is added, it
will get linked to earlier files automatically.
Also, we can run this whenever a file is added.


## TODO

Would like to add the directors pages here too.
And other pages like Academy Awards for recent years etc.

I think i have a script which extracts the titles of director from a
file.
