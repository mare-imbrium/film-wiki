#!/usr/bin/env bash

# DESCRIPTION: does a LIKE search on title and prints out movies matching.
#sqlite3 movie.sqlite "select id, title, directed_by from movie where title like '%"$*"%';"
sqlite3 -separator $'\t'  movie.sqlite "SELECT title, year, url, directed_by, running_time  FROM movie WHERE title LIKE '%"$*"%';"
