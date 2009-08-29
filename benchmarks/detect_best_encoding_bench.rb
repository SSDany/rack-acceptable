require 'rubygems'
require 'rbench'
require 'rack/utils'

require File.expand_path(File.join(File.dirname(__FILE__), '../lib/rack-acceptable'))

HEADERS = []
HEADERS << 'compress;q=0.5,gzip;q=1.0,deflate,*;q=0.5'
HEADERS << 'compress;q=0.5,gzip;q=1.0,deflate,identity;q=0.1'

PROVIDES = %w(compress gzip identity)

RBench.run(ARGV[0] ? ARGV[0].to_i : 10_000) do

  format :width => 100

  column :origin,     :title => 'Rack'
  column :alternate,  :title => 'Rack::Acceptable'
  column :diff,       :title => '#2/#1', :compare => [:alternate, :origin]

  group "Detecting the best content-coding" do
    HEADERS.each do |header|
      accepts = Rack::Acceptable::Utils::extract_qvalues(header)
      report "#{header}" do
        origin    { Rack::Utils.select_best_encoding PROVIDES, accepts }
        alternate { Rack::Acceptable::Utils::detect_best_encoding PROVIDES, accepts }
      end
    end
  end

end

# EOF