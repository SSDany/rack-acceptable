require 'rubygems'
require 'rbench'

require File.expand_path(File.join(File.dirname(__FILE__), '../lib/rack-acceptable'))
require File.expand_path(File.join(File.dirname(__FILE__), 'lib/mime_parse.rb'))

PROVIDES = []
PROVIDES << %w(text/html;level=1)
PROVIDES << %w(text/html;level=1 text/html;level=2)
PROVIDES << %w(text/html;level=1 text/html;level=2 text/html)

HEADER = "text/html;level=2;q=0.5, text/html;level=1;q=0.6, */*"

RBench.run(ARGV[0] ? ARGV[0].to_i : 10_000) do

  format :width => 100

  column :origin,     :title => 'MIMEParse'
  column :alternate,  :title => 'Rack::Acceptable'
  column :diff,       :title => '#2/#1', :compare => [:alternate, :origin]

  group "Detecting the best MIME-Type" do
    PROVIDES.each do |provides|
      report "number of available MIME-Types: #{provides.size}" do
        origin { ::MIMEParse::best_match(provides, HEADER) }
        alternate {
          accepts = ::Rack::Acceptable::Utils::parse_http_accept(HEADER)
          ::Rack::Acceptable::Utils::detect_best_mime_type(provides, accepts) 
        }
      end
    end
  end

end

# EOF