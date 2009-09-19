require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

HEADERS = []

HEADERS << '*'
HEADERS << 'gzip,deflate'
HEADERS << 'gzip,deflate,*;q=0.1'
HEADERS << 'gzip,deflate;q=0.8,*;q=0.7'
HEADERS << 'gzip;q=0.7,deflate;q=0.8,compress;q=0.3,*;q=0.6'
HEADERS << 'gzip;q=0.7,deflate;q=0.8,compress;q=0.3,identity;q=0.1,*;q=0.5'

PROVIDES = %w(deflate identity)

TIMES = ARGV[0] ? ARGV[0].to_i : 10_000

RBench.run(TIMES) do

  column :times
  column :one   , :title => 'Rack'
  column :two   , :title => 'RA'
  column :diff  , :title => '#2/#1', :compare => [:two, :one]

  group "Rack::Request.accept_encoding vs RA::Encodings.parse_accept_encoding" do

    HEADERS.each do |header|

      env = Rack::MockRequest.env_for('/', 'HTTP_ACCEPT_ENCODING' => header)
      request = Rack::Request.new(env)
      request.accept_encoding

      report header.inspect, TIMES do
        one { request.accept_encoding }
        two { Rack::Acceptable::Encodings.parse_accept_encoding(header) }
      end

    end

    summary ''
  end

  group "Rack::Request.accept_encoding vs RA::Utils.extract_qvalues" do

    HEADERS.each do |header|

      env = Rack::MockRequest.env_for('/', 'HTTP_ACCEPT_ENCODING' => header)
      request = Rack::Request.new(env)
      request.accept_encoding

      report header.inspect, TIMES do
        one { request.accept_encoding }
        two { Rack::Acceptable::Utils.extract_qvalues(header) }
      end

    end

    summary ''
  end

  group "Detecting the best Content-Coding, one of #{PROVIDES.inspect}" do

    HEADERS.each do |header|
      accepts = Rack::Acceptable::Utils::extract_qvalues(header)
      report header.inspect, TIMES*10 do
        one { Rack::Utils.select_best_encoding PROVIDES, accepts }
        two { Rack::Acceptable::Encodings::detect_best_encoding PROVIDES, accepts }
      end
    end

    summary ''
  end

end

# EOF