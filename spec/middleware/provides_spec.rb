require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Rack::Acceptable::Provides do

  def request!(options = {})
    @response = Rack::MockRequest.new(@middleware).request('GET', '/', options)
  end

  before :all do

    app = lambda do |env|
      body = env['rack-acceptable.provides.candidate'].to_yaml
      size = Rack::Utils::bytesize(body)
      [200, {'Content-Type' => 'text/plain', 'Content-Length' => size.to_s}, [body]]
    end

    provides = []
    provides.concat %w(text/x-json application/json)
    provides.concat %w(application/xml text/xml)
    provides.concat %w(text/plain)

    @middleware = Rack::Acceptable::Provides.new(app, provides)

  end

  describe "when there's an Accept request-header" do

    describe "and some of available MIME-Types are also acceptable" do

      it "detects the best MIME-Type" do
        request!('HTTP_ACCEPT' => 'text/x-json;q=0,application/json;q=0.5')
        @response.should be_ok
        YAML.load(@response.body).should == 'application/json'

        request!('HTTP_ACCEPT' => 'text/plain;q=0.5,application/json;q=0.5')
        @response.should be_ok
        YAML.load(@response.body).should == 'text/plain'

        request!('HTTP_ACCEPT' => 'text/plain;q=0.3,application/json;q=0.5')
        @response.should be_ok
        YAML.load(@response.body).should == 'application/json'

        request!('HTTP_ACCEPT' => 'text/plain;q=0.3,application/json;q=0.5,text/xml;q=0.5')
        @response.should be_ok
        YAML.load(@response.body).should == 'application/json'

        request!('HTTP_ACCEPT' => 'text/plain;q=0.3,*/*')
        @response.should be_ok
        YAML.load(@response.body).should == 'text/x-json'

        request!('HTTP_ACCEPT' => 'text/plain,*/*')
        @response.should be_ok
        YAML.load(@response.body).should == 'text/plain'

        request!('HTTP_ACCEPT' => 'text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5')
        @response.should be_ok
        YAML.load(@response.body).should == 'text/xml'
      end

      it "ignores MIME-Types with zero qvalues" do
        request!("HTTP_ACCEPT" => "text/x-json;q=0,text/plain;q=0.3")
        @response.should be_ok
        YAML.load(@response.body).should == 'text/plain'
      end

      it "memoizes results" do
        header = 'text/plain,text/*,*/*'
        request!('HTTP_ACCEPT' => header)
        @response.should be_ok
        YAML.load(@response.body).should == 'text/plain'

        Rack::Acceptable::Provides::LOOKUP.should have_key(header)
        Rack::Acceptable::Provides::LOOKUP[header].should == 'text/plain'
        Rack::Acceptable::MIMETypes.should_not_receive(:parse_accept)
        Rack::Acceptable::MIMETypes.should_not_receive(:detect_best_mime_type)

        request!('HTTP_ACCEPT' => header)
        @response.should be_ok
        YAML.load(@response.body).should == 'text/plain'
      end

    end

    describe "but none of available MIME-Types are acceptable" do

      it "returns 406 'Not Acceptable'" do
        request!('HTTP_ACCEPT' => 'image/png;q=0.5')
        @response.should_not be_ok
        @response.status.should == 406
        @response.body.should match %r{Not Acceptable}
      end

      it "memoizes results" do
        request!('HTTP_ACCEPT' => 'video/quicktime')
        @response.should_not be_ok
        @response.status.should == 406
        @response.body.should match %r{Not Acceptable}

        Rack::Acceptable::Provides::LOOKUP.should have_key('video/quicktime')
        Rack::Acceptable::Provides::LOOKUP['video/quicktime'].should == nil
        Rack::Acceptable::MIMETypes.should_not_receive(:parse_accept)
        Rack::Acceptable::MIMETypes.should_not_receive(:detect_best_mime_type)

        request!('HTTP_ACCEPT' => 'video/quicktime')
        @response.should_not be_ok
        @response.status.should == 406
        @response.body.should match %r{Not Acceptable}
      end

    end

  end

  describe "when there's no Accept request-header" do

    it "assumes that everything is acceptable, and picks out the first one of available MIME-Types" do
      request!
      @response.should be_ok
      YAML.load(@response.body).should == 'text/x-json'
    end

  end

end

# EOF