require 'rubygems'
require 'rbench'

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'rack-acceptable'))
require File.expand_path(File.join(File.dirname(__FILE__), 'lib', 'mime_parse.rb'))

HEADERS = []
HEADERS << "text/html;a=2;q=0.5, text/html;a=1;q=0.3, */*"
HEADERS << "text/html;a=2;q=0.3, text/html;a=1;q=0.5, */*"
HEADERS << "text/html;a=2;q=0.3, text/html;a=1;q=0.5, */*;q=0.1"

PROVIDES = %w(text/html;a=1 text/html;a=2 text/html)

TIMES = ARGV[0] ? ARGV[0].to_i : 10_000

RBench.run(TIMES) do

  format :width => 110

  column :mimeparse,  :title => 'MIMEParse'
  column :acceptable, :title => 'Rack::Acceptable'
  column :diff,       :title => '#2/#1', :compare => [:acceptable, :mimeparse]

  group "Detecting the best MIME-Type (vs MIMEParse; times: #{TIMES})" do
    HEADERS.each do |header|
      report "header: #{header.inspect}" do
        mimeparse { MIMEParse::best_match(PROVIDES, header) }
        acceptable do
          accepts = Rack::Acceptable::Utils::parse_http_accept(header)
          Rack::Acceptable::Utils::detect_best_mime_type(PROVIDES, accepts) 
        end
      end
    end
  end

end

# EOF