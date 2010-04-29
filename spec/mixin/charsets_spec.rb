require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Rack::Acceptable::Headers do

  before :all do
    @_request = Class.new(Rack::Request){ include Rack::Acceptable::Charsets }
  end

  def fake_request(options = {})
    env = Rack::MockRequest.env_for('/', options)
    @_request.new(env)
  end

  it "provides the #acceptable_charsets method" do
    request = fake_request('HTTP_ACCEPT_CHARSET' => 'unicode-1-1, iso-8859-5;q=0.5')
    request.should respond_to :acceptable_charsets
    lambda { request.acceptable_charsets }.should_not raise_error
  end

  describe "#acceptable_charsets" do

    before :all do
      @parser = lambda { |thing| fake_request('HTTP_ACCEPT_CHARSET' => thing).acceptable_charsets }
      @qvalue = lambda { |thing| fake_request('HTTP_ACCEPT_CHARSET' => thing).acceptable_charsets.first.last }
      @sample = 'iso-8859-1'
      @message = %r{Malformed Accept-Charset header}
    end

    describe "when parsing standalone snippet" do

      it_should_behave_like 'simple qvalues parser'

      it "raises an ArgumentError when there's a malformed Charset" do
        lambda { fake_request('HTTP_ACCEPT_CHARSET' => "with\\separators?").acceptable_charsets }.
        should raise_error ArgumentError, @message

        lambda { fake_request('HTTP_ACCEPT_CHARSET' => "yet_another_with@separators").acceptable_charsets }.
        should raise_error ArgumentError, @message

        lambda { fake_request('HTTP_ACCEPT_CHARSET' => "header=malformed;q=0.3").acceptable_charsets }.
        should raise_error ArgumentError, @message

        lambda { fake_request('HTTP_ACCEPT_CHARSET' => "q=0.3").acceptable_charsets }.
        should raise_error ArgumentError, @message
      end

      it "downcases Charsets" do
        fake_request('HTTP_ACCEPT_CHARSET' => 'uNICODE-1-1;q=0.1').acceptable_charsets.should == [['unicode-1-1', 0.1]]
        fake_request('HTTP_ACCEPT_CHARSET' => 'Unicode-1-1;q=0.1').acceptable_charsets.should == [['unicode-1-1', 0.1]]
      end

    end

    it_should_behave_like 'simple HTTP_ACCEPT_CHARSET parser'
    it_should_behave_like 'simple parser of 1#(element) lists'

  end

end

# EOF