require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

describe Rack::Acceptable::Request do

  include SpecHelpers::FakeRequest

  before :all do
    fake_request!(Rack::Acceptable::Request)
  end

  it "has the Rack::Acceptable::Encodings included" do
    Rack::Acceptable::Request.should include Rack::Acceptable::Encodings
  end

  it "has the Rack::Acceptable::Languages included" do
    Rack::Acceptable::Request.should include Rack::Acceptable::Languages
  end

  it "has the Rack::Acceptable::Charsets included" do
    Rack::Acceptable::Request.should include Rack::Acceptable::Charsets
  end

  it "has the Rack::Acceptable::Media included" do
    Rack::Acceptable::Request.should include Rack::Acceptable::Media
  end

  describe "#accept_content?" do

    it "returns true if content acceptable" do
      request = fake_request('HTTP_ACCEPT' => '*/*', 'HTTP_ACCEPT_CHARSET' => 'utf-8')
      request.accept_content?('text/plain;charset=utf-8').should == true
      request.accept_content?('TEXT/PLAIN;charset=UTF-8').should == true
      request.accept_content?('text/plain').should == true

      request = fake_request('HTTP_ACCEPT' => 'text/*', 'HTTP_ACCEPT_CHARSET' => 'utf-8')
      request.accept_content?('text/plain;charset=utf-8').should == true
      request.accept_content?('TEXT/PLAIN;charset=UTF-8').should == true
      request.accept_content?('text/plain').should == true
    end

    it "returns false, if there's unacceptable charset" do
      request = fake_request('HTTP_ACCEPT' => '*/*', 'HTTP_ACCEPT_CHARSET' => 'utf-8')
      request.accept_content?('text/plain;charset=unknown').should == false
      request = fake_request('HTTP_ACCEPT' => '*/*', 'HTTP_ACCEPT_CHARSET' => '@bogus')
      request.accept_content?('text/plain;charset=@bogus').should == false
    end

    it "returns false, if there's unacceptable media" do
      request = fake_request('HTTP_ACCEPT' => 'text/*')
      request.accept_content?('application/xml').should == false
      request.accept_content?('video/quicktime').should == false
      request.accept_content?('bogus!').should == false

      request = fake_request('HTTP_ACCEPT' => 'bogus!')
      request.accept_content?('bogus!').should == false
    end

  end

  describe "#acceptable_media" do

    it "memoizes result of parsing" do
      request = fake_request('HTTP_ACCEPT' => '*/*')
      acceptable_media = request.acceptable_media
      request.should_not_receive(:env)
      request.acceptable_media.should == acceptable_media
    end

  end

  describe "#acceptable_charsets" do

    it "memoizes result of parsing" do
      request = fake_request('HTTP_ACCEPT_ENCODING' => '*')
      acceptable_charsets = request.acceptable_charsets
      request.should_not_receive(:env)
      request.acceptable_charsets.should == acceptable_charsets
    end

  end

end

# EOF