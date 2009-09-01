require 'rubygems'
require 'rbench'
require 'webrick'
require 'rack'
require 'rack/mock'

require File.expand_path(File.join(File.dirname(__FILE__), '../lib/rack-acceptable'))

HEADERS = []

HEADERS << 'en-us, en-gb'
HEADERS << 'en-us;q=0.5, en-gb;q=1.0'
HEADERS << 'en-gb;q=1.0, en-us;q=0.5, *;q=0'

HEADERS << 'gzip,deflate'
HEADERS << 'gzip,deflate,*;q=0.1'
HEADERS << 'gzip,deflate;q=0.8,*;q=0.7'
HEADERS << 'gzip;q=0.3,deflate;q=0.8,compress;q=1.0,*;q=0.7'

TIMES = ARGV[0] ? ARGV[0].to_i : 10_000

RBench.run(TIMES) do

  format :width => 110

  column :webrick,    :title => 'WEBrick'
  column :acceptable, :title => 'Rack::Acceptable'
  column :diff,       :title => '#2/#1', :compare => [:acceptable, :webrick]

  group "Extracting qvalues (vs WEBrick, times: #{TIMES})" do
    HEADERS.each do |header|
      report "header: #{header.inspect}" do
        webrick     { WEBrick::HTTPUtils.parse_qvalues header }
        acceptable  { Rack::Acceptable::Utils::extract_qvalues header }
      end
    end
  end

end

# EOF