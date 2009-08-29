require 'rubygems'
require 'rbench'

require File.expand_path(File.join(File.dirname(__FILE__), '../lib/rack-acceptable'))
require File.expand_path(File.join(File.dirname(__FILE__), 'lib/mime_parse.rb'))

SNIPPETS = []
SNIPPETS << "text/html"
SNIPPETS << "text/html;level=1;q=0.5"
SNIPPETS << "text/html;level=2;q=0.5;a=42"

RBench.run(ARGV[0] ? ARGV[0].to_i : 100_000) do

  format :width => 100

  column :origin,     :title => 'MIMEParse'
  column :alternate,  :title => 'Rack::Acceptable'
  column :diff,       :title => '#2/#1', :compare => [:alternate, :origin]

  group "Parsing standalone MIME-Type snippet" do
    SNIPPETS.each do |snippet|
      report "snippet to parse: #{snippet.inspect}" do
        origin    { ::MIMEParse::parse_mime_type snippet }
        alternate { ::Rack::Acceptable::Utils::parse_mime_type snippet }
      end
    end
  end

end

# EOF