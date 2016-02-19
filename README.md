# film-wiki

This repo contains code that retrieves a movie page from wikipedia and parses the movie info and stores it in an sqlite database.
There are some programs to query the data, or view the pages too.

This is NOT a database of all movies. It only contains a few thousand select movies that are mostly award winners or notable ones. The json database is much larger and contains tens of thousands of movies taking data using the OMDB api.

`fetchupdate.rb` is the main program which reads a list of urls from the given file or urls.txt
  fetches the wiki link, and updates the info, and saves the page in ./wiki.

Earlier, I kept the wiki dump in the database and allowed the user to view it by piping to w3m. However,
this does not allow linking across pages. So now the wiki page are on the disk and one can click and move to other movies.


In some cases, the same movie can have two different urls since one url redirects to the other. 
There should be very few cases like this, such as The Barkleys of Broadway. These got introduced
when i took movies from other lists such as those with various awards.

The first 1000 or more rows are created from a wiki entry of films that have won an oscar.
Then i added movies of various directors.
THen i added movies from lists of oscar nominated movies, movies that won or nominated for
best actor, cinematography, best dir.

I need to add the list for best actress nominees and foriegn movie nominees.

I have created separate tables for these lists so i can create a field in movies_back and update
that field with a YES or something. that way we can query for movies that won BP and BA or BD etc.


## TODO

- Upload TSV of the database after correcting bad rows. Some rows of actors have come in.
- Check the other oscar tsv files and upload. What should location be ? one in wiki/src rest in /wiki ?
- Update oscar nominations and win count every March using data from list.rb.
- currently, there is only oscar info till 2012
- Also update the other fields of best pic, actor, actress etc. Do we have programs to do this 
 so it is not totally manual?
- movie_wiki table may have tt_code / imdb_url. we may like to get it into our movie database
so we can pull more info or connect.
- maybe have a TSV file of the info and upload it in GH so others can use it straight, since we don't have
complex info.

- redownload some url's esp the 2015 ones, and update all the fields. we need to have something to do 
that. there should be some program that updates somewhere.

## ISSUE 

- about 55 movies have no director
- 262 movies have no starring (some may be documentaries).
  Fading Gigolo has very little info, was downloaded too early before release.
  Men in Black has no Starring info in the box.

- we can for them crosscheck with the json database and update these 2 fields
  or even link to the film-list database and update from there.


 i am noticing a lot of redirecting urls are causeing duplicates here. som pages have
urls that redirect. thus our key field needs to remove all junk and do a match.


checking dupes: 

418 good earth points to book

2134 points to movie but does not have the acad count info, need to combine both
   correct url and requery that ? or delete 418 and manually update 2134 with count and change id?

We need a prog to update info for a given url (or id), if we've updated the url
but to avoid duplication of processing.
