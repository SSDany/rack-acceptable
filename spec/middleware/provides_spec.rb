require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Rack::Acceptable::Provides do

  include SpecHelpers::FakeFactory

  before :all do
    @keys = %w(rack-acceptable.provides.candidate rack-acceptable.provides.candidate_info)
    @provides = []
    @provides.concat %w(text/x-json application/json)
    @provides.concat %w(application/xml text/xml)
    @provides.concat %w(text/plain)
    Rack::Acceptable::MIMETypes.reset
  end

  describe "when there's an Accept request-header" do

    before :each do
      app!(@keys)
      @middleware = Rack::Acceptable::Provides.new(app, @provides)
    end
  
    describe "and some of available MIME-Types are also acceptable" do

      it "detects the best MIME-Type" do

        @middleware = Rack::Acceptable::Provides.new(app, @provides)

        request!('HTTP_ACCEPT' => 'text/x-json;q=0,application/json;q=0.5')
        @response.should be_ok
        body.should == ['application/json', ['application', 'json', {}]]

        request!('HTTP_ACCEPT' => 'text/plain;q=0.5,application/json;q=0.5')
        @response.should be_ok
        body.should == ['text/plain', ['text', 'plain', {}]]

        request!('HTTP_ACCEPT' => 'text/plain;q=0.3,application/json;q=0.5')
        @response.should be_ok
        body.should == ['application/json', ['application', 'json', {}]]

        request!('HTTP_ACCEPT' => 'text/plain;q=0.3,application/json;q=0.5,text/xml;q=0.5')
        @response.should be_ok
        body.should == ['application/json', ['application', 'json', {}]]

        request!('HTTP_ACCEPT' => 'text/plain;q=0.3,*/*')
        @response.should be_ok
        body.should == ['text/x-json', ['text', 'x-json', {}]]

        request!('HTTP_ACCEPT' => 'text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5')
        @response.should be_ok
        body.should == ['text/xml', ['text', 'xml', {}]]

        request!("HTTP_ACCEPT" => "text/x-json;q=0,text/plain;q=0.3")
        @response.should be_ok
        body.should == ['text/plain', ['text', 'plain', {}]]

        request!('HTTP_ACCEPT' => 'text/plain,*/*')
        @response.should be_ok
        body.should == ['text/plain', ['text', 'plain', {}]]

        @middleware = Rack::Acceptable::Provides.new(app, @provides, :negotiate_by => :qvalue_only)

        request!('HTTP_ACCEPT' => 'text/plain,*/*')
        @response.should be_ok
        body.should == ['text/x-json', ['text', 'x-json', {}]]

      end

      it "sets the Content-Type response-header, if necessary" do

        app!(@keys)
        @middleware = Rack::Acceptable::Provides.new(app, @provides)

        request!('HTTP_ACCEPT' => 'text/x-json;q=0,application/json;q=0.5')
        @response.should be_ok
        @response['Content-Type'].should == 'application/json'
        body.should == ['application/json', ['application', 'json', {}]]

        app!(@keys, 200, 'Content-Type' => 'text/plain')
        @middleware = Rack::Acceptable::Provides.new(app, @provides)

        request!('HTTP_ACCEPT' => 'text/x-json;q=0,application/json;q=0.5')
        @response.should be_ok
        @response['Content-Type'].should == 'text/plain'
        body.should == ['application/json', ['application', 'json', {}]]

        app!(@keys, 204)
        @middleware = Rack::Acceptable::Provides.new(app, @provides)

        request!('HTTP_ACCEPT' => 'text/x-json;q=0,application/json;q=0.5')
        @response.status.should == 204
        @response['Content-Type'].should == nil
        body.should == ['application/json', ['application', 'json', {}]]

      end

      it "memoizes results" do
        header = 'text/plain,text/*,*/*'
        request!('HTTP_ACCEPT' => header)
        @response.should be_ok
        body.should == ['text/plain', ['text', 'plain', {}]]

        Rack::Acceptable::MIMETypes.should_not_receive(:parse_mime_type)
        Rack::Acceptable::MIMETypes.should_not_receive(:detect_best_mime_type)

        request!('HTTP_ACCEPT' => header)
        @response.should be_ok
        body.should == ['text/plain', ['text', 'plain', {}]]
      end

    end

    describe "but none of available MIME-Types are acceptable" do

      it "returns 406 'Not Acceptable'" do
        request!('HTTP_ACCEPT' => 'image/png;q=0.5')
        @response.should_not be_ok
        @response.status.should == 406
        @response.body.should match %r{could not be found}
      end

      it "memoizes results" do
        request!('HTTP_ACCEPT' => 'video/quicktime')
        @response.should_not be_ok
        @response.status.should == 406
        @response.body.should match %r{could not be found}

        Rack::Acceptable::MIMETypes.should_not_receive(:parse_mime_type)
        Rack::Acceptable::MIMETypes.should_not_receive(:detect_best_mime_type)

        request!('HTTP_ACCEPT' => 'video/quicktime')
        @response.should_not be_ok
        @response.status.should == 406
        @response.body.should match %r{could not be found}
      end

    end

    describe "or the Accept header is malformed" do

      it "returns 406 'Not Acceptable'" do
        request!('HTTP_ACCEPT' => 'bogus!')
        @response.should_not be_ok
        @response.status.should == 406
        @response.body.should match %r{could not be found}
      end

      it "memoizes results" do
        request!('HTTP_ACCEPT' => 'bogus!')
        @response.should_not be_ok
        @response.status.should == 406
        @response.body.should match %r{could not be found}

        Rack::Acceptable::MIMETypes.should_not_receive(:parse_mime_type)

        request!('HTTP_ACCEPT' => 'bogus!')
        @response.should_not be_ok
        @response.status.should == 406
        @response.body.should match %r{could not be found}
      end

    end

  end

  describe "when there's no Accept request-header" do

    before :all do
      app!(@keys)
      @middleware = Rack::Acceptable::Provides.new(app, @provides)
    end

    it "assumes that everything is acceptable and picks out the first one of available MIME-Types" do
      request!
      @response.should be_ok
      body.should == ['text/x-json', ['text', 'x-json', {}]]
    end

  end

  describe "when :force_format is on" do

    before :all do
      app!('PATH_INFO')
    end

    it "adds a proper format (extension) to the PATH_INFO" do
      @middleware = Rack::Acceptable::Provides.new(@app, @provides, :force_format => true)

      request!('/rack/acceptable', 'HTTP_ACCEPT' => 'application/json')
      @response.should be_ok
      body.should == ['/rack/acceptable.json']

      request!('/rack/acceptable.whatever', 'HTTP_ACCEPT' => 'application/json')
      @response.should be_ok
      body.should == ['/rack/acceptable.whatever.json']

      request!('/', 'HTTP_ACCEPT' => 'application/json')
      @response.should be_ok
      body.should == ['/']

      request!('/rack/acceptable/', 'HTTP_ACCEPT' => 'application/json')
      @response.should be_ok
      body.should == ['/rack/acceptable.json']

      request!('/rack/acceptable.whatever/', 'HTTP_ACCEPT' => 'application/json')
      @response.should be_ok
      body.should == ['/rack/acceptable.whatever.json']
    end

    it "uses default format (extension, if any) when there's no extension for the picked MIME-Type" do
      @middleware = Rack::Acceptable::Provides.new(@app, @provides, :force_format => true)
      request!('/rack/acceptable.whatever', 'HTTP_ACCEPT' => 'text/x-json')
      @response.should be_ok
      body.should == ['/rack/acceptable.whatever']

      @middleware = Rack::Acceptable::Provides.new(@app, @provides, :force_format => true, :default_format => '  ') 
      request!('/rack/acceptable.whatever', 'HTTP_ACCEPT' => 'text/x-json')
      @response.should be_ok
      body.should == ['/rack/acceptable.whatever']

      @middleware = Rack::Acceptable::Provides.new(@app, @provides, :force_format => true, :default_format => '.txt') 
      request!('/rack/acceptable.whatever', 'HTTP_ACCEPT' => 'text/x-json')
      @response.should be_ok
      body.should == ['/rack/acceptable.whatever.txt']

      @middleware = Rack::Acceptable::Provides.new(@app, @provides, :force_format => true, :default_format => 'txt') 
      request!('/rack/acceptable.whatever', 'HTTP_ACCEPT' => 'text/x-json')
      @response.should be_ok
      body.should == ['/rack/acceptable.whatever.txt']
    end

  end

  after :all do
    Rack::Acceptable::MIMETypes.clear
  end

end

# EOF