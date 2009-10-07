require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Rack::Acceptable::Formats do

  include SpecHelpers::FakeFactory

  before :all do
    app!('rack-acceptable.formats.candidates')
    @middleware = Rack::Acceptable::Formats.new(app,
      :json => %w(text/x-json application/json),
      :xml  => %w(application/xml text/xml),
      :text => %w(text/plain)
      )
  end

  describe "when there's an Accept request-header" do

    it "detects acceptable formats" do
      request!('HTTP_ACCEPT' => 'text/x-json;q=0,application/json;q=0.5')
      @response.should be_ok
      body.should == [[:json]]

      request!('HTTP_ACCEPT' => 'text/plain;q=0.5,application/json;q=0.5')
      @response.should be_ok
      body.should == [[:text, :json]]

      request!('HTTP_ACCEPT' => 'text/plain;q=0.3,application/json;q=0.5')
      @response.should be_ok
      body.should == [[:json, :text]]

      request!('HTTP_ACCEPT' => 'text/plain;q=0.3,application/json;q=0.5,text/xml;q=0.5')
      @response.should be_ok
      body.should == [[:json, :xml, :text]]

      request!('HTTP_ACCEPT' => 'text/plain;q=0.3,*/*')
      @response.should be_ok
      body.should == [[:all, :text]]

      request!('HTTP_ACCEPT' => 'text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5')
      @response.should be_ok
      body.should == [[:xml, :text, :all]]

      request!("HTTP_ACCEPT" => "text/x-json;q=0,text/plain;q=0.3")
      @response.should be_ok
      YAML.load(@response.body).should == [[:text]]

    end

    it "returns 406 'Not Acceptable' only when there's really nothing to provide" do
      request!('HTTP_ACCEPT' => 'image/png;q=0.5')
      @response.should_not be_ok
      @response.status.should == 406
      @response.body.should match %r{could not be found}

      request!('HTTP_ACCEPT' => 'image/png;q=0.5,*/*;q=0.3')
      @response.should be_ok
      YAML.load(@response.body).should == [[:all]]
    end

  end

  describe "when there's no Accept request-header" do

    it "assumes that everything is acceptable" do
      request!
      @response.should be_ok
      body.should == [[:all]]
    end

  end

end

# EOF