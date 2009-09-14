require 'rubygems'
require 'rbench'

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'rack-acceptable'))

HEADERS = []
HEADERS << "text/html"
HEADERS << "text/html, video/quicktime;q=0.3"
HEADERS << "text/html, video/quicktime;q=0.3, */*;q=0.001"
HEADERS << "text/html, text/plain;q=0.5, text/xml;q=0; */*;q=0"
HEADERS << "text/html, text/plain;q=0.5, text/xml;q=0.3; */*;q=0.9"

PROVIDES = %w(video/quicktime text/html)

TIMES = ARGV[0] ? ARGV[0].to_i : 10_000

RBench.run(TIMES) do

  format :width => 110

  column :strong,   :title => 'strong'
  column :weak,     :title => 'weak but quick'
  column :diff,     :title => '#2/#1', :compare => [:weak, :strong]

  group "Detecting the (possibly) best MIME-Type (vs self; times: #{TIMES})" do
    HEADERS.each do |header|
      report "header: #{header.inspect}" do
        weak { Rack::Acceptable::MIMETypes::detect_acceptable_mime_type(PROVIDES, header) }
        strong do
          accepts = Rack::Acceptable::MIMETypes::parse_accept(header)
          Rack::Acceptable::MIMETypes::detect_best_mime_type(PROVIDES, accepts) 
        end
      end
    end
  end

end

# EOF