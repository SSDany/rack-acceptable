require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Rack::Acceptable::Formats do

  def request!(options = {})
    @response = Rack::MockRequest.new(@middleware).request('GET', '/', options)
  end

  before :all do

    app = lambda do |env|
      body = env['rack-acceptable.provides.formats'].to_yaml
      size = Rack::Utils::bytesize(body)
      [200, {'Content-Type' => 'text/plain', 'Content-Length' => size.to_s}, [body]]
    end

    @middleware = Rack::Acceptable::Formats.new(app,
      :json => %w(text/x-json application/json),
      :xml  => %w(application/xml text/xml),
      :text => %w(text/plain)
      )

  end

  describe "when there's an Accept request-header" do

    it "detects the best format" do
      request!('HTTP_ACCEPT' => 'text/x-json;q=0,application/json;q=0.5')
      @response.should be_ok
      YAML.load(@response.body).should == [:json]
    end

    it "respects quality factors" do
      request!('HTTP_ACCEPT' => 'text/plain;q=0.5,application/json;q=0.5')
      @response.should be_ok
      YAML.load(@response.body).should == [:text, :json]

      request!('HTTP_ACCEPT' => 'text/plain;q=0.3,application/json;q=0.5')
      @response.should be_ok
      YAML.load(@response.body).should == [:json, :text]

      request!('HTTP_ACCEPT' => 'text/plain;q=0.3,application/json;q=0.5,text/xml;q=0.5')
      @response.should be_ok
      YAML.load(@response.body).should == [:json, :xml, :text]

      request!('HTTP_ACCEPT' => 'text/plain;q=0.3,*/*')
      @response.should be_ok
      YAML.load(@response.body).should == [:all, :text]

      request!('HTTP_ACCEPT' => 'text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5')
      @response.should be_ok
      YAML.load(@response.body).should == [:xml, :text, :all]
    end

    it "ignores MIME-Types with zero qvalues" do
      request!("HTTP_ACCEPT" => "text/x-json;q=0,text/plain;q=0.3")
      @response.should be_ok
      YAML.load(@response.body).should == [:text]
    end

    it "returns 406 'Not Acceptable' only when there's no acceptable formats" do
      request!('HTTP_ACCEPT' => 'image/png;q=0.5')
      @response.should_not be_ok
      @response.status.should == 406
      @response.body.should == 'Not Acceptable'

      request!('HTTP_ACCEPT' => 'image/png;q=0.5,*/*;q=0.3')
      @response.should be_ok
      YAML.load(@response.body).should == [:all]
    end

  end

  describe "when there's no Accept request-header" do

    it "assumes that everything is acceptable" do
      request!
      @response.should be_ok
      YAML.load(@response.body).should == [:all]
    end

  end

end

# EOF