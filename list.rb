#!/usr/bin/env ruby
require 'nokogiri'

# extracts movie name, wins and nominations from this page
# Since this is oscar based, it should be run every March, after the Oscar awards.
# We need to update this into the wiki database. Ideally, we should only do the updates for the current year.
#
PAGE_URL="List_of_Academy_Award-winning_films.html"
%x[ sed -n '/<table class="wikitable/,/<.table>/p' #{PAGE_URL} > t.t ]
page = Nokogiri::HTML(open("t.t"))
links = page.css("table")
rows = links[0].xpath("//table/tr")
rows[2].css("td").each { |d| printf "%s\t" % [d.text] }
puts rows[2].css("a")[0]["href"]

rows.each_with_index do |r, ix|
  next if ix < 2
  #puts r.css("td").text
  print r.css("a")[0].text if r.css("a")[0]
  print "\t"
  r.css("td").each_with_index { |d,ix| next if ix == 0; print "%s\t" % [d.text] }
  #r.css("a")[0]["href"]
  h = r.css("a")
  if h && h[0]
    puts h[0]["href"]
  else
    exit
  end
end
