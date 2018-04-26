#!/usr/bin/env ruby -W0
# ----------------------------------------------------------------------------- #
#         File: convert_url_to_key.rb
#  Description: converts wikipedia URL to a key so i can map similar URLs. Often a movie 
#   is mentioned by different URL's in different places, and i need to check so one movie does
#   not get entered by two URLs. Also when updating oscar or other info, i need to map the different URL
#   to what;s in the system using this key.
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2016-02-28 - 19:04
#      License: MIT
#  Last update: 2018-02-23 12:24
# ----------------------------------------------------------------------------- #
# == Changelog
# -- 2016-03-06 - added call to unidecoder otherwise there are variations in key
require 'URI'
require 'unidecoder'
# convert url to key
# NOTE: This is actually necessary since other wiki pages (such as oscar and other lists) have slightly different
#  links, some contain film or year+film some don't. So we need something other than URL to check.
#   This is defective since it does not remove the year in film. We need to remove _(1925_film), 
#   Also, we need to run decode_uri.rb to convert single quotes, question marks etc and remove them.
#   2016-02-28 - taken care of removing year, and decoding % signs
def converturl url
  return nil unless url
  url = url.chomp
  begin
    url = URI.decode(url)
    # 2016-03-06 - added call to unidecoder 
    url =  url.to_ascii
    # TODO
    # i need to unidecode it here otherwise different encodings make a difference to key
    newurl = url.sub('/wiki/','').downcase().sub('_(film)','').sub(/([12][8901].._film)/,'')
    # some have 1992_American_film or 1960_Japanese_film etc.
    newurl = newurl.sub(/([12][8901].._.*_film)/,'').sub("(short_film)","")
    # accept only alphanum and %
    #$stderr.puts newurl
    newurl.gsub!(/[^0-9a-z%]/i,'')
    $stdout.puts newurl
  rescue Errno::EPIPE
    exit(74)
  end
end




if __FILE__ == $0
  begin
    # http://www.ruby-doc.org/stdlib/libdoc/optparse/rdoc/classes/OptionParser.html
    require 'optparse'
    options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} URI"
      opts.banner += "\nConvert a wikipedia movie URL to a key for comparing against other URLs"

      opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        options[:verbose] = v
      end
    end.parse!
    # Keep reading lines of input as long as they're coming.
    unless ARGV.empty?
      ARGV.each do |line|
        converturl line
      end
    else
      $stdin.each_line do |line|
        converturl line
      end
    end

  ensure
  end
end

