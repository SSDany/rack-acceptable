# encoding: binary

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'mime_parse.rb'))

SNIPPETS = []
SNIPPETS << "text/html"
SNIPPETS << "text/html;level=1"
SNIPPETS << "text/html;level=1;a=42"
SNIPPETS << "text/html;q=0.5"
SNIPPETS << "text/html;level=1;q=0.5"
SNIPPETS << "text/html;level=1;a=42;q=0.5"
SNIPPETS << "text/html;level=2;a=42;q=0.5;557"
SNIPPETS << "text/html;level=2;a=42;q=0.5;557;b=6537"

TIMES = ARGV[0] ? ARGV[0].to_i : 10_000

RBench.run(TIMES) do

  column :times
  column :one   , :title => 'MP'
  column :two   , :title => 'RA'
  column :diff  , :title => '#2/#1', :compare => [:two, :one]

  group "MIMEParse.parse_mime_type vs RA::MIMETypes.parse_mime_type" do
    SNIPPETS.each do |snippet|
      report snippet.inspect do
        one { MIMEParse::parse_mime_type snippet }
        two { Rack::Acceptable::MIMETypes::parse_mime_type snippet }
      end
    end
    summary ""
  end

  group "MIMEParse.parse_mime_type vs RA::MIMETypes.parse_media_range" do
    SNIPPETS[0..2].each do |snippet|
      report snippet.inspect, TIMES*10 do
        one { MIMEParse::parse_mime_type snippet }
        two { Rack::Acceptable::MIMETypes::parse_media_range snippet }
      end
    end
    summary ""
  end

end

# EOF