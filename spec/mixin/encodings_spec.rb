require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Rack::Acceptable::Encodings do

  include SpecHelpers::FakeRequest

  before :all do
    fake_request! { include Rack::Acceptable::Encodings }
  end

  describe "methods" do

    before :each do
      @request = fake_request('HTTP_ACCEPT_ENCODING' => '*')
    end

    it "provides the #acceptable_encodings method" do
      @request.should respond_to :acceptable_encodings
      lambda { @request.acceptable_encodings }.should_not raise_error
    end

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

end

# EOF