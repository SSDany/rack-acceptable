require 'rubygems'
require 'rbench'

require File.expand_path(File.join(File.dirname(__FILE__), '../lib/rack-acceptable'))
require File.expand_path(File.join(File.dirname(__FILE__), 'lib/mime_parse.rb'))

SNIPPETS = []
SNIPPETS << "text/html"
SNIPPETS << "text/html;level=1;q=0.5"
SNIPPETS << "text/html;level=2;q=0.5;a=42"

TIMES = ARGV[0] ? ARGV[0].to_i : 100_000

RBench.run(TIMES) do

  format :width => 110

  column :mimeparse,  :title => 'MIMEParse'
  column :acceptable, :title => 'Rack::Acceptable'
  column :diff,       :title => '#2/#1', :compare => [:acceptable, :mimeparse]

  group "Parse MIME-Type snippet (vs MIMEParse; times: #{TIMES})" do
    SNIPPETS.each do |snippet|
      report "snippet: #{snippet.inspect}" do
        mimeparse   { MIMEParse::parse_mime_type snippet }
        acceptable  { Rack::Acceptable::Utils::parse_mime_type snippet }
      end
    end
  end

end

# EOF