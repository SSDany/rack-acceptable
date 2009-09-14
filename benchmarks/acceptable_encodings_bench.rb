require 'rubygems'
require 'rbench'

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'rack-acceptable'))

HEADERS = []

HEADERS << 'gzip,deflate'
HEADERS << 'gzip,deflate,*;q=0.1'
HEADERS << 'gzip,deflate;q=0.8,*;q=0.7'
HEADERS << 'gzip;q=0.3,deflate;q=0.8,compress;q=1.0,*;q=0.7'

TIMES = ARGV[0] ? ARGV[0].to_i : 10_000

RBench.run(TIMES) do

  format :width => 110

  column :rack,       :title => 'Rack'
  column :acceptable, :title => 'Rack::Acceptable'
  column :diff,       :title => '#2/#1', :compare => [:acceptable, :rack]

  group "Parse Accept-Encoding header (vs Rack, times: #{TIMES})" do
    HEADERS.each do |header|

      request = Rack::Request.new(Rack::MockRequest.env_for('/', 'HTTP_ACCEPT_ENCODING' => header))
      request.accept_encoding

      report "header: #{header.inspect}" do
        rack        { request.accept_encoding }
        acceptable  { Rack::Acceptable::Encodings.parse_accept_encoding(header) }
      end

    end
  end
end