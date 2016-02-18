#!/usr/bin/env bash
# DESCRIPTION: takes a directors name or part of it and prints basic info for it, ordered by year
# We could actually have an option or another program which just pops up the wiki page for that
# director so user can then click on movies and see their details.
#
# TODO select using FZF but put in a condition so we can switch off in future if required

sqlite3 --separator $'\t' movie.sqlite "select title, year, directed_by  from movie where directed_by like '%"$*"%' order by year;"
