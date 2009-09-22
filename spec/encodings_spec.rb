require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

describe Rack::Acceptable::Utils, ".parse_http_accept_encoding" do

  before :all do
    @parser = lambda { |thing| Rack::Acceptable::Encodings.parse_accept_encoding(thing) }
    @qvalue = lambda { |thing| Rack::Acceptable::Encodings.parse_accept_encoding(thing).first.last }
    @sample = 'deflate'
    @message = %r{Malformed Accept-Encoding header}
  end

  describe "when parsing standalone snippet" do

    it_should_behave_like 'simple qvalues parser'

    it "downcases Content-Codings" do
      Rack::Acceptable::Encodings.parse_accept_encoding('Deflate;q=0.1').should == [['deflate', 0.1]]
      Rack::Acceptable::Encodings.parse_accept_encoding('dEFLATE;q=0.1').should == [['deflate', 0.1]]
    end

    it "raises an ArgumentError when there's a malformed Content-Coding" do
      lambda { Rack::Acceptable::Encodings.parse_accept_encoding("with\\separators?") }.
      should raise_error ArgumentError, @message

      lambda { Rack::Acceptable::Encodings.parse_accept_encoding("yet_another_with@separators") }.
      should raise_error ArgumentError, @message

      lambda { Rack::Acceptable::Encodings.parse_accept_encoding("header=malformed;q=0.3") }.
      should raise_error ArgumentError, @message

      lambda { Rack::Acceptable::Encodings.parse_accept_encoding("q=0.3") }.
      should raise_error ArgumentError, @message
    end

  end

  it_should_behave_like 'simple HTTP_ACCEPT_ENCODING parser'
  it_should_behave_like 'simple parser of 1#(element) lists'

end

# EOF