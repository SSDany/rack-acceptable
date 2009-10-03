# encoding: binary

require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))
require File.expand_path(File.join(File.dirname(__FILE__), 'lib', 'mime_parse.rb'))

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
  column :one   , :title => 'MP'
  column :two   , :title => 'RA'
  column :diff  , :title => '#2/#1', :compare => [:two, :one]

  group "Weighing of the MIME-Types, each of #{PROVIDES.inspect}" do
    HEADERS.each do |header|

      env = Rack::MockRequest.env_for('/','HTTP_ACCEPT' => header)
      request = Rack::Acceptable::Request.new(env)
      accepts = request.acceptable_media

      report header.inspect do
        one { PROVIDES.each { |t| MIMEParse.fitness_and_quality_parsed(t,accepts) }}
        two { PROVIDES.each { |t| Rack::Acceptable::MIMETypes.weigh_mime_type(t,accepts) }}
      end

    end

    summary ''
  end

  group "Detecting the best MIME-Type, one of #{PROVIDES.inspect}" do
    HEADERS.each do |header|

      env = Rack::MockRequest.env_for('/','HTTP_ACCEPT' => header)

      report header.inspect do
        one { MIMEParse::best_match(PROVIDES, header) }
        two do
          accepts = Rack::Acceptable::Request.new(env).acceptable_media
          Rack::Acceptable::MIMETypes.detect_best_mime_type(PROVIDES, accepts)
        end
      end

    end

    summary ''
  end

end

# EOF