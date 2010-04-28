# encoding: binary

require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

HEADERS = []
HEADERS << "*/*"
HEADERS << "text/*"
HEADERS << "text/plain"
HEADERS << "text/plain;q=0.5, */*"
HEADERS << "text/plain;q=0.5, text/xml;q=0.9, */*"
HEADERS << "text/plain;q=0.5, text/xml;a=42;q=0.9, */*"
HEADERS << "text/plain;q=0.5, text/*;a=42;q=0.5, */*"
HEADERS << "text/plain;q=0.5, text/*;a=42;q=0.5, text/*;q=0.9, */*"

PROVIDES = %w(text/xml;a=42 text/plain text/html)

TIMES = ARGV[0] ? ARGV[0].to_i : 10_000

RBench.run(TIMES) do

  column :times
  column :one   , :title => 'by qvalue only'
  column :two   , :title => 'by everything possible'
  column :diff  , :title => '#2/#1', :compare => [:two, :one]

  group "Detecting the best MIME-Type, one of #{PROVIDES.inspect}" do
    HEADERS.each do |header|

      env = Rack::MockRequest.env_for('/','HTTP_ACCEPT' => header)
      accepts = Rack::Acceptable::Request.new(env).acceptable_media

      report header.inspect do
        one { Rack::Acceptable::MIMETypes.detect_best_mime_type(PROVIDES, accepts, true) }
        two { Rack::Acceptable::MIMETypes.detect_best_mime_type(PROVIDES, accepts, false) }
      end

    end

    summary ''
  end

end
