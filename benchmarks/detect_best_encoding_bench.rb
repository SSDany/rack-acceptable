require 'rubygems'
require 'rbench'

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'rack-acceptable'))

HEADERS = []
HEADERS << '*'
HEADERS << 'compress;q=0.5,*;q=1.0'
HEADERS << 'compress;q=0.5,gzip;q=1.0'
HEADERS << 'compress;q=0.5,gzip;q=1.0,deflate,*;q=0.5'
HEADERS << 'compress;q=0.5,gzip;q=1.0,deflate,identity;q=0.1'

PROVIDES = %w(compress gzip identity)

TIMES = ARGV[0] ? ARGV[0].to_i : 100_000

RBench.run(TIMES) do

  format :width => 110

  column :rack,       :title => 'Rack'
  column :acceptable, :title => 'Rack::Acceptable'
  column :diff,       :title => '#2/#1', :compare => [:acceptable, :rack]

  group "Detecting the best Content-Coding (vs Rack, times: #{TIMES})" do
    HEADERS.each do |header|
      accepts = Rack::Acceptable::Utils::extract_qvalues(header)
      report "header: #{header.inspect}" do
        rack        { Rack::Utils.select_best_encoding PROVIDES, accepts }
        acceptable  { Rack::Acceptable::Utils::detect_best_encoding PROVIDES, accepts }
      end
    end
  end

end

# EOF