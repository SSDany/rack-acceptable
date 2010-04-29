require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Rack::Acceptable::Headers do

  before :all do
    @_request = Class.new(Rack::Request){ include Rack::Acceptable::Headers }
  end

  def fake_request(options = {})
    env = Rack::MockRequest.env_for('/', options)
    @_request.new(env)
  end

  it "provides the #acceptable_encodings method" do
    request = fake_request('HTTP_ACCEPT_ENCODING' => 'gzip;q=0.9,deflate;q=0.8,identity;q=0.1')
    request.should respond_to :acceptable_encodings
    lambda { request.acceptable_encodings }.should_not raise_error
  end

  it "provides the #acceptable_language_ranges method" do
    request = fake_request('HTTP_ACCEPT_LANGUAGE' => 'de,it,da,ru,zh-Hans')
    request.should respond_to :acceptable_language_ranges
    lambda { request.acceptable_language_ranges }.should_not raise_error
  end

  it "provides the #acceptable_media_ranges method" do
    request = fake_request('HTTP_ACCEPT' => 'text/plain,text/*;q=0.8,*/*;q=0.7')
    request.should respond_to :acceptable_media_ranges
    lambda { request.acceptable_media_ranges }.should_not raise_error
  end

  describe "#acceptable_encodings" do

    before :all do
      @parser = lambda { |thing| fake_request('HTTP_ACCEPT_ENCODING' => thing).acceptable_encodings }
      @qvalue = lambda { |thing| fake_request('HTTP_ACCEPT_ENCODING' => thing).acceptable_encodings.first.last }
      @sample = 'deflate'
      @message = %r{Malformed Accept-Encoding header}
    end

    describe "when parsing standalone snippet" do

      it_should_behave_like 'simple qvalues parser'

      it "downcases Content-Codings" do
        fake_request('HTTP_ACCEPT_ENCODING' => 'Deflate;q=0.1').acceptable_encodings.should == [['deflate', 0.1]]
        fake_request('HTTP_ACCEPT_ENCODING' => 'dEFLATE;q=0.1').acceptable_encodings.should == [['deflate', 0.1]]
      end

      it "raises an ArgumentError when there's a malformed Content-Coding" do
        lambda { fake_request('HTTP_ACCEPT_ENCODING' => "with\\separators?").acceptable_encodings }.
        should raise_error ArgumentError, @message

        lambda { fake_request('HTTP_ACCEPT_ENCODING' => "yet_another_with@separators").acceptable_encodings }.
        should raise_error ArgumentError, @message

        lambda { fake_request('HTTP_ACCEPT_ENCODING' => "header=malformed;q=0.3").acceptable_encodings }.
        should raise_error ArgumentError, @message

        lambda { fake_request('HTTP_ACCEPT_ENCODING' => "q=0.3").acceptable_encodings }.
        should raise_error ArgumentError, @message
      end

    end

    it_should_behave_like 'simple HTTP_ACCEPT_ENCODING parser'
    it_should_behave_like 'simple parser of 1#(element) lists'

  end

  describe "#acceptable_language_ranges" do

    before :all do
      @parser = lambda { |thing| fake_request('HTTP_ACCEPT_LANGUAGE' => thing).acceptable_language_ranges }
      @qvalue = lambda { |thing| fake_request('HTTP_ACCEPT_LANGUAGE' => thing).acceptable_language_ranges.first.last }
      @sample = 'en-gb'
      @message = %r{Malformed Accept-Language header}
    end

    describe "when parsing standalone snippet" do

      it_should_behave_like 'simple qvalues parser'

      it "raises an ArgumentError when there's a malformed Language-Range" do
        lambda { fake_request('HTTP_ACCEPT_LANGUAGE' => "veryverylongstring").acceptable_language_ranges }.
        should raise_error ArgumentError, @message

        lambda { fake_request('HTTP_ACCEPT_LANGUAGE' => "en-gb-veryverylongstring").acceptable_language_ranges }.
        should raise_error ArgumentError, @message

        lambda { fake_request('HTTP_ACCEPT_LANGUAGE' => "non_alpha").acceptable_language_ranges }.
        should raise_error ArgumentError, @message

        lambda { fake_request('HTTP_ACCEPT_LANGUAGE' => "header=malformed;q=0.3").acceptable_language_ranges }.
        should raise_error ArgumentError, @message

        lambda { fake_request('HTTP_ACCEPT_LANGUAGE' => "q=0.3").acceptable_language_ranges }.
        should raise_error ArgumentError, @message
      end

    end

    it_should_behave_like 'simple HTTP_ACCEPT_LANGUAGE parser'
    it_should_behave_like 'simple parser of 1#(element) lists'

  end

  describe "#acceptable_media_ranges" do

    before :all do
      @parser = lambda { |thing| fake_request('HTTP_ACCEPT' => thing).acceptable_media_ranges }
      @qvalue = lambda { |thing| fake_request('HTTP_ACCEPT' => thing).acceptable_media_ranges.first.last }
      @sample = 'text/plain'
      @message = %r{Malformed Accept header}
    end

    describe "when parsing standalone snippet" do
      it_should_behave_like 'simple qvalues parser'
    end

    it_should_behave_like 'simple HTTP_ACCEPT parser'
  end

end

# EOF