require 'rubygems'
require 'rbench'

require File.expand_path(File.join(File.dirname(__FILE__), '../lib/rack-acceptable'))

SNIPPETS = []
SNIPPETS << "text/html"
SNIPPETS << "text/html;level=1;q=0.5"
SNIPPETS << "text/html;level=2;q=0.5;a=42"

TIMES = ARGV[0] ? ARGV[0].to_i : 100_000

RBench.run(TIMES) do

  format :width => 110

  column :full,       :title => 'Full'
  column :partial,    :title => 'Media-Range only'
  column :diff,       :title => '#2/#1', :compare => [:partial, :full]

  group "Rack::Acceptable's MIME-Type parsers (times: #{TIMES})" do
    SNIPPETS.each do |snippet|
      report "snippet: #{snippet.inspect}" do
        full      { Rack::Acceptable::Utils::parse_mime_type snippet }
        partial   { Rack::Acceptable::Utils::parse_media_range snippet }
      end
    end
  end

end

# EOF