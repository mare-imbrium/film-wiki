CREATE TABLE "movie"(
  id INT,
  title TEXT,
  year TEXT,
  nom INT,
  won INT,
  directed_by TEXT,
  running_time TEXT,
  screenplay_by TEXT,
  produced_by TEXT,
  starring TEXT,
  music_by,
  cinematography TEXT,
  editing_by,
  distributed_by TEXT,
  release_dates TEXT,
  story_by TEXT,
  studio TEXT,
  country TEXT,
  language TEXT,
  budget TEXT,
  box_office TEXT,
  url TEXT,
  "key" TEXT,
  best_pic TEXT,
  best_actor TEXT,
  best_cinemato TEXT,
  best_director TEXT,
  best_foreign TEXT,
  palme TEXT,
  goldenbear TEXT,
  goldenlion TEXT
, htmlpath TEXT, best_actress CHAR(2), best_supp_actress CHAR(2), best_supp_actor CHAR(2));
CREATE UNIQUE INDEX movie_url on movie(url);
CREATE TABLE imlinks2(
  "url" TEXT,
  "imdb_url" TEXT
);
