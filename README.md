# film-wiki

This repo contains code that retrieves a movie page from wikipedia and parses the movie info and stores it in an sqlite database.
There are some programs to query the data, or view the pages too.

This is NOT a database of all movies. It only contains a few thousand select movies that are mostly award winners or notable ones. The json database is much larger and contains tens of thousands of movies taking data using the OMDB api.

`fetchupdate.rb` WAS the main program which reads a list of urls from the given file or urls.txt
  fetches the wiki link, and updates the info, and saves the page in ./wiki.
It has now been broken into 3 programs which are called from `fetchmovie.sh`. I usually just issue: `./command fetch`
for new files (or ./command force_fetch which downloads and updated the files).

I recently introduced canonical url since different pages can have different URL's that get referred to the same movie url. I had hoped this url would be a permanent one. But i now discover that the URL of a movie changes over time. What once pointed to a movie, now becomes a disambiguation page. This happened since i wanted to update all the 3800 or so movies, and get their canonical urls. This makes it a bit difficult to prevent the same movie getting entered twice with two different URLs.
I know compare title and year, and also imdbid with existing data to look for possible duplicates.

It seems the imdbid is the only permanent entry in the database for a movie. Even titles can change over a period of time, or the year can be revised. However, many movies have multiple imdbid's so even that has to be corrected or examined.
In such cases, i may store the other imdbids in another field.

I am now thinking of dropping the `id` field. Earlier this was used to link with the movie_wiki table, which is no longer used since i store the wiki page in the wiki directory.

## NEW

 I have broken up the `fetchupdate.rb` so it can be run independently to redownload and update the db.
 The combined command is now `fetchmovie.sh`.

     ./downloadfilm.rb "/wiki/Fading_Gigolo"
     ./downloadfilm.rb --force "/wiki/Fading_Gigolo" (to overwrite)

 - parse to downloaded document giving path, and wiki url which is the key field. This results in a yml file
   in the yml folder which matches the wiki file name with yml extension.

     ./parsedoc.rb wiki/Fading_Gigolo.html /wiki/Fading_Gigolo

 - update the yml file into the database. IF not existing, a new record will be inserted, else the record will 
   be updated.

     ./updateyml2db.rb -v yml/Fading_Gigolo.yml

### TSV files

There are three tab seperated values files exported from the sqlite database. You may import them into sqlite or any db and therefore avoid having to run the above programs.

- movie.tsv: contains the data for each movie. (Ignore the ID column). This contains about 3400 movies as of date, most of them are either nominated or have won a major award. Recently, I have added more movies that are popular, or belong to some well-known directors or actors. The URL of the movie is the key field. However, sometimes there can be errors if some page used a URL that redirected to another. This could lead to a duplicate in the db.

- imlinks.tsv: this contains the URL of the movie (wikipedia URL) and the corresponding IMDB ID (tt000000) code. This has been mostly manually done, or through programs that matched the title, so their could be errors.

- crosslink.tsv: this is the output of a command that links the imdb Id from the above table to the IMDB id in the IMDB database and prints the title and year of that IMDB id. This output may be used to verify that the IMDB id is correct.


## EARLIER

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

x Upload TSV of the database after correcting bad rows. Some rows of actors have come in.
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

- don't we have to run convert_all_links.sh for the files downloaded by fetchupdate.rb ?
 i seem to have done it long ago for files before creating the director files.
 Recent files since Jan are not crosslinking.
 Yes, i did run this in one shot on Dec 31st 2015. But we need to do it for all downloaded files.

 i am noticing a lot of redirecting urls are causeing duplicates here. som pages have
urls that redirect. thus our key field needs to remove all junk and do a match.


checking dupes: 

418 good earth points to book

2134 points to movie but does not have the acad count info, need to combine both
   correct url and requery that ? or delete 418 and manually update 2134 with count and change id?

We need a prog to update info for a given url (or id), if we've updated the url
but to avoid duplication of processing.
