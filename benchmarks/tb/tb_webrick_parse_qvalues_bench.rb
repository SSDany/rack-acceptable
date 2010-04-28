# encoding: binary

require File.expand_path(File.join(File.dirname(__FILE__),  '..', 'helper'))
require 'webrick'

HEADERS = []

HEADERS << '*'
HEADERS << 'en-us,en-gb'
HEADERS << 'en-us;q=0.5,en-gb;q=1.0'
HEADERS << 'en-gb;q=1.0,en-us;q=0.5,*;q=0.3'

HEADERS << 'gzip,deflate'
HEADERS << 'gzip,deflate,*;q=0.1'
HEADERS << 'gzip,deflate;q=0.8,*;q=0.7'
HEADERS << 'gzip;q=0.7,deflate;q=0.8,compress;q=0.3,*;q=0.6'
HEADERS << 'gzip;q=0.7,deflate;q=0.8,compress;q=0.3,identity;q=0.1,*;q=0.5'

TIMES = ARGV[0] ? ARGV[0].to_i : 10_000

RBench.run(TIMES) do

  column :times
  column :one,  :title => 'WEBrick'
  column :two,  :title => 'RA'
  column :diff, :title => '#2/#1', :compare => [:two, :one]

  group "Extracting qvalues" do
    HEADERS.each do |header|
      report header.inspect do
        one { WEBrick::HTTPUtils.parse_qvalues header }
        two { Rack::Acceptable::Utils::extract_qvalues(header).sort_by { |_,q| -q } }
      end
    end

    summary ''
  end

end

# EOF