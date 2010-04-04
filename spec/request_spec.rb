require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

describe Rack::Acceptable::Request do

  def fake_request(options = {})
    env = Rack::MockRequest.env_for('/', options)
    Rack::Acceptable::Request.new(env)
  end

  it "has the Rack::Acceptable::Headers included" do
    Rack::Acceptable::Request.should include Rack::Acceptable::Headers
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

  describe "#accept_charset?" do

    before :all do
      @helper = lambda { |chs, accepts| 
        request = fake_request('HTTP_ACCEPT_CHARSET' => accepts)
        request.accept_charset?(chs)
        }
    end

    it "checks, if the Charset passed acceptable" do

      @helper[  'iso-8859-1'  , '*;q=0.0'                     ].should == false
      @helper[  'iso-8859-1'  , 'iso-8859-1;q=0.0'            ].should == false
      @helper[  'iso-8859-1'  , 'iso-8859-1;q=0.0, *;q=1.0'   ].should == false
      @helper[  'utf-8'       , '*;q=0.0'                     ].should == false
      @helper[  'iso-8859-1'  , '*;q=1.0'                     ].should == true
      @helper[  'utf-8'       , '*;q=1.0'                     ].should == true

      accepts = 'iso-8859-5;q=0.3, windows-1252;q=0.5, utf-8; q=0.0'

      @helper[  'windows-1252'  , accepts ].should == true
      @helper[  'iso-8859-1'    , accepts ].should == true
      @helper[  'utf-8'         , accepts ].should == false
      @helper[  'bogus'         , accepts ].should == false

    end

    it "returns false if there's malformed Accept-Charset header" do
      @helper[  'iso-8859-1'  , 'baaang!@'                ].should == false
      @helper[  'iso-8859-1'  , 'iso-8859-1;q=malformed'  ].should == false
    end

  end

end

# EOF