require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

describe Rack::Acceptable::Charsets, ".parse_accept_charset" do

  before :all do
    @parser = lambda { |thing| Rack::Acceptable::Charsets.parse_accept_charset(thing) }
    @qvalue = lambda { |thing| Rack::Acceptable::Charsets.parse_accept_charset(thing).first.last }
    @sample = 'iso-8859-1'
    @message = %r{Malformed Accept-Charset header}
  end

  describe "when parsing standalone snippet" do

    it_should_behave_like 'simple qvalues parser'

    it "raises an ArgumentError when there's a malformed Charset" do
      lambda { Rack::Acceptable::Charsets.parse_accept_charset("with\\separators?") }.
      should raise_error ArgumentError, @message

      lambda { Rack::Acceptable::Charsets.parse_accept_charset("yet_another_with@separators") }.
      should raise_error ArgumentError, @message

      lambda { Rack::Acceptable::Charsets.parse_accept_charset("header=malformed;q=0.3") }.
      should raise_error ArgumentError, @message

      lambda { Rack::Acceptable::Charsets.parse_accept_charset("q=0.3") }.
      should raise_error ArgumentError, @message
    end

    it "downcases Charsets" do
      Rack::Acceptable::Charsets.parse_accept_charset('uNICODE-1-1;q=0.1').should == [['unicode-1-1', 0.1]]
      Rack::Acceptable::Charsets.parse_accept_charset('Unicode-1-1;q=0.1').should == [['unicode-1-1', 0.1]]
    end

  end

  it_should_behave_like 'simple HTTP_ACCEPT_CHARSET parser'
  it_should_behave_like 'simple parser of 1#(element) lists'

end

# EOF