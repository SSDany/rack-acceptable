require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Rack::Acceptable::Media do

  before :all do
    @_request = Class.new(Rack::Request) { include Rack::Acceptable::Media }
  end

  def fake_request(opts = {})
    env = Rack::MockRequest.env_for('/', opts)
    @_request.new(env)
  end

  describe "#accept_media?" do

    it "returns true, if the MIME-Type passed acceptable" do
      request = fake_request('HTTP_ACCEPT' => 'application/xml, text/*;q=0.3')
      request.accept_media?('text/plain').should == true
      request.accept_media?('text/css').should == true
      request.accept_media?('application/xml').should == true
    end

    it "returns false otherwise" do
      request = fake_request('HTTP_ACCEPT' => 'application/xml, text/*;q=0.3')
      request.accept_media?('video/quicktime').should == false
      request.accept_media?('image/jpeg').should == false

      request = fake_request('HTTP_ACCEPT' => 'text/plain;q=0,text/*')
      request.accept_media?('text/plain').should == false
    end

    it "even if the thing passed is not a well-formed MIME-Type" do
      request = fake_request('HTTP_ACCEPT' => 'application/xml, text/*;q=0.3')
      request.accept_media?('bogus!').should == false
      request.accept_media?(42).should == false
    end

  end

end

# EOF