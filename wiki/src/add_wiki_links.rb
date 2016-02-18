#!/usr/bin/env ruby -w
require 'FileUtils'
# ----------------------------------------------------------------------------- #
#         File: add_wiki_links.rb
#  Description: This can be used to add non-movie links to the wiki folder
#   after grepping them from another file.
#
#   e.g. 
# grep  -i 'academy award for best ' Academy_Award.html | grep -o 'href="Academy[^"]*' | 
# sed 's/href="//' | sort -u > academy_awards_links.txt #| head -10 | src/add_wiki_links.rb
# The above greps out links of academy award pages for specific awards and saves them.
#
#       Author:  r kumar
#         Date: 2016-01-01 - 14:21
#  Last update: 2016-01-15 19:39
#      License: MIT License
# ----------------------------------------------------------------------------- #
#

# this snippet reads lines from stdin or arguments on command line.
# The other filter treats all input as file names, this does not.
$force = false
require 'optparse'
OptionParser.new do |options|
  # This banner is the first line of your help documentation.
  options.set_banner "Usage: add_wiki_links.rb  [options] [files]\n" \
    "takes links as input, downloads them and converts links. Not to be used for films."

  # Separator just adds a new line with the specified text.
  options.separator ""
  options.separator "Specific options:"

  options.on("--force", "Overwrite file if it exists") do |flag|
    $force = true
  end

  #options.on("-m", "--max NUM", Integer, "Maximum line length") do |max|
    #maximum_line_length = max
  #end

  options.on_tail("-h", "--help", "You're looking at it!") do
    $stderr.puts options
    exit 1
  end
end.parse!

$host="https://en.wikipedia.org"
$mydir="/Volumes/Pacino/dziga_backup/rahul/Downloads/MOV/wiki"

def process_line link
    link = link.chomp
    # if ends with film) then give a warning and don't change
    if link =~ /film\)$/
      $stderr.puts "This is a film and should go through fetchupdate"
      return 1
    end
    if link =~ /\.html$/
      output_line = link.sub(/\.html$/, '').sub(/^/, '/wiki/')
    elsif link =~ /^\/wiki\//
      puts "okay in correct format #{link}"
      output_line = link
    else
      $stderr.puts "Not sure how to handle this: #{link}."
      return 1
    end
    uri = "#{$host}#{output_line}"
    ofile = output_line.sub('/wiki/', '').gsub('/','_')
    ofile = "#{ofile}.html"
    ofile = `decode_uri.rb "#{ofile}"`.chomp

    begin
      $stdout.puts ofile
      $stdout.puts uri
      unless $force
        if File.exist? ofile
          $stderr.puts "File exists #{ofile}. Ignoring"
          return 1
        end
      end
      %x[ curl "#{uri}" > "#{ofile}" ]
      %x[ src/convert_all_links.sh "#{ofile}" ]
      #curl $URI > $OFILE
      #src/convert_all_links.sh "$OFILE"
    rescue Errno::EPIPE
      exit(74)
    end
end
# Keep reading lines of input as long as they're coming.
FileUtils.cd($mydir)
unless ARGV.empty?
  ARGV.each do |link|
    process_line link
  end
else
  $stdin.each_line do |link|
    process_line link
  end
end
