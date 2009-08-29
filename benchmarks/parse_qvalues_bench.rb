require 'rubygems'
require 'rbench'
require 'webrick'

require File.expand_path(File.join(File.dirname(__FILE__), '../lib/rack-acceptable'))

HEADERS = []
HEADERS << 'en-us, en-gb'
HEADERS << 'en-us;q=0.5, en-gb;q=1.0'
HEADERS << 'en-gb;q=1.0, en-us;q=0.5, *;q=0'

RBench.run(ARGV[0] ? ARGV[0].to_i : 10_000) do

  format :width => 100

  column :origin,     :title => 'WEBrick'
  column :alternate,  :title => 'Rack::Acceptable'
  column :diff,       :title => '#2/#1', :compare => [:alternate, :origin]

  group "Extracting qvalues (vs WEBrick)" do
    HEADERS.each do |header|
      report header do
        origin    { ::WEBrick::HTTPUtils.parse_qvalues header }
        alternate { ::Rack::Acceptable::Utils::extract_qvalues header }
      end
    end
  end

end

# EOF