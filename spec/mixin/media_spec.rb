require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Rack::Acceptable::Media do

  before :all do
    @_request = Class.new(Rack::Request) { include Rack::Acceptable::Media }
  end

  def fake_request(opts = {})
    env = Rack::MockRequest.env_for('/', opts)
    @_request.new(env)
  end

  describe "#accept_mime_type?" do

    it "returns true, if the MIME-Type passed acceptable" do
      request = fake_request('HTTP_ACCEPT' => 'application/xml, text/*;q=0.3')
      request.accept_mime_type?('text/plain').should == true
      request.accept_mime_type?('text/css').should == true
      request.accept_mime_type?('application/xml').should == true
    end

    it "returns false otherwise" do
      request = fake_request('HTTP_ACCEPT' => 'application/xml, text/*;q=0.3')
      request.accept_mime_type?('video/quicktime').should == false
      request.accept_mime_type?('image/jpeg').should == false
    end

    it "even if the thing passed is not a well-formed MIME-Type" do
      request = fake_request('HTTP_ACCEPT' => 'application/xml, text/*;q=0.3')
      request.accept_mime_type?('bogus!').should == false
      request.accept_mime_type?(42).should == false
    end

  end

end

# EOF