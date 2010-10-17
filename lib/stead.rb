$:.unshift(File.dirname(__FILE__)) unless
$:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module Stead
  VERSION = '0.0.1'

  CONTAINER_TYPES = [
    "album",
    "artifactbox",
    "audiocassette",
    "audiotape",
    "box",
    "cardbox",
    "carton",
    "cassette",
    "cassettebox",
    "cdbox",
    "diskette",
    "drawingsbox",
    "flatbox",
    "flatfile",
    "flatfolder",
    "folder",
    "halfbox",
    "item",
    "largeenvelope",
    "legalbox",
    "mapcase",
    "mapfolder",
    "notecardbox",
    "othertype",
    "oversize",
    "oversizebox",
    "oversizeflatbox",
    "reel",
    "reelbox",
    "scrapbook",
    "slidebox",
    "tube",
    "tubebox",
    "videotape",
    "volume"
  ]
end

require 'rubygems'
require 'nokogiri'
require 'csv'
if CSV.const_defined? :Reader
  require 'fastercsv'
end

require 'pp'

require 'stead/stead'
require 'stead/ead'
require 'stead/error'

