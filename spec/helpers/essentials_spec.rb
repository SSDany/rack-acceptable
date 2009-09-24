require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Rack::Acceptable::Helpers::Essentials do

  before :all do
    @_request = Class.new(Rack::Request) { include Rack::Acceptable::Helpers::Essentials }
  end

  def fake_request(opts = {})
    env = Rack::MockRequest.env_for('/', opts)
    @_request.new(env)
  end

  it "adds the #acceptable_encodings method" do
    request = fake_request('HTTP_ACCEPT_ENCODING' => 'gzip;q=0.9,deflate;q=0.8,identity;q=0.1')
    request.should respond_to :acceptable_encodings
    request.acceptable_encodings.should == [['gzip', 0.9], ['deflate', 0.8], ['identity',0.1]]
  end

  it "adds the #acceptable_charsets method" do
    request = fake_request('HTTP_ACCEPT_CHARSET' => 'unicode-1-1, iso-8859-5;q=0.5')
    request.should respond_to :acceptable_charsets
    request.acceptable_charsets.should == [['unicode-1-1', 1.0], ['iso-8859-5', 0.5]]
  end

end

# EOF