require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Rack::Acceptable::Utils, ".extract_qvalues" do

  before :all do
    @parser = lambda { |thing| Rack::Acceptable::Utils.extract_qvalues(thing) }
    @qvalue = lambda { |thing| Rack::Acceptable::Utils.extract_qvalues(thing).first.last }
    @sample = 'whatever'
    @message = %r{Malformed quality factor}
  end

  describe "when parsing standalone snippet" do

    it_should_behave_like 'simple qvalues parser'

    it "picks out the FIRST 'q' parameter (if any)" do
      @qvalue['application/xml;q=0.5;p=q;q=557;a=42'].should == 0.5
    end

  end

  it "returns an empty array if the value it was passed is an empty string" do
    Rack::Acceptable::Utils.extract_qvalues("").should == []
  end

  it_should_behave_like 'simple HTTP_ACCEPT_LANGUAGE parser'
  it_should_behave_like 'simple HTTP_ACCEPT_CHARSET parser'
  it_should_behave_like 'simple HTTP_ACCEPT_ENCODING parser'
  it_should_behave_like 'simple HTTP_ACCEPT parser'

end

describe Rack::Acceptable::Utils, ".parse_http_accept_language" do

  before :all do
    @parser = lambda { |thing| Rack::Acceptable::Utils.parse_http_accept_language(thing) }
    @qvalue = lambda { |thing| Rack::Acceptable::Utils.parse_http_accept_language(thing).first.last }
    @sample = 'en-gb'
    @message = %r{Malformed Accept-Language header}
  end

  describe "when parsing standalone snippet" do

    it_should_behave_like 'simple qvalues parser'

    it "raises an ArgumentError when Language-Range is malformed" do
      lambda { Rack::Acceptable::Utils.parse_http_accept_language("veryverylongstring") }.
      should raise_error ArgumentError, @message

      lambda { Rack::Acceptable::Utils.parse_http_accept_language("en-gb-veryverylongstring") }.
      should raise_error ArgumentError, @message

      lambda { Rack::Acceptable::Utils.parse_http_accept_language("non_alpha") }.
      should raise_error ArgumentError, @message

      lambda { Rack::Acceptable::Utils.parse_http_accept_language("header=malformed;q=0.3") }.
      should raise_error ArgumentError, @message

      lambda { Rack::Acceptable::Utils.parse_http_accept_language("q=0.3") }.
      should raise_error ArgumentError, @message
    end

    it "works case-insensitively with Language-Ranges" do
      Rack::Acceptable::Utils.parse_http_accept_language('EN-gb;q=0.1').should == [['en', 'gb', 0.1]]
      Rack::Acceptable::Utils.parse_http_accept_language('en-GB;q=0.1').should == [['en', 'gb', 0.1]]
    end

  end

  it "returns an empty array if the value it was passed is an empty string" do
    Rack::Acceptable::Utils.parse_http_accept_language("").should == []
  end

  it "is able to extract Language Tags from the well-formed HTTP_ACCEPT_LANGUAGE header (without number of tags)" do

    qvalues = Rack::Acceptable::Utils.parse_http_accept_language('da;q=0.3')
    qvalues.should == [['da', 0.3]]

    qvalues = Rack::Acceptable::Utils.parse_http_accept_language('da;q=0.3, en-us')
    qvalues.should == [['da', 0.3], ['en', 'us', 1.0]]

    qvalues = Rack::Acceptable::Utils.parse_http_accept_language('en-gb, en-us')
    qvalues.should == [['en', 'gb', 1.0], ['en', 'us', 1.0]]

    qvalues = Rack::Acceptable::Utils.parse_http_accept_language('en-us;q=0.5, en-gb;q=1.0')
    qvalues.should == [['en', 'us', 0.5], ['en', 'gb', 1.0]]

    qvalues = Rack::Acceptable::Utils.parse_http_accept_language('en-gb;q=1.0, en-us;q=0.5, *;q=0.3')
    qvalues.should == [['en', 'gb', 1.0], ['en', 'us', 0.5], ['*', 0.3]]

  end

  it "is able to extract Language Tags from the well-formed HTTP_ACCEPT_LANGUAGE header (with number of tags)" do

    header = 'en-us-foo;q=0.3, en-us, da;q=0.1'

    qvalues = Rack::Acceptable::Utils.parse_http_accept_language(header, 1)
    qvalues.should == [['en', 0.3], ['en', 1.0], ['da', 0.1]]

    qvalues = Rack::Acceptable::Utils.parse_http_accept_language(header, 2)
    qvalues.should == [['en', 'us', 0.3], ['en', 'us', 1.0], ['da', 0.1]]

    qvalues = Rack::Acceptable::Utils.parse_http_accept_language(header, 3)
    qvalues.should == [['en', 'us', 'foo', 0.3], ['en', 'us', 1.0], ['da', 0.1]]

  end

end

describe Rack::Acceptable::Utils, ".parse_http_accept_encoding" do

  before :all do
    @parser = lambda { |thing| Rack::Acceptable::Utils.parse_http_accept_encoding(thing) }
    @qvalue = lambda { |thing| Rack::Acceptable::Utils.parse_http_accept_encoding(thing).first.last }
    @sample = 'deflate'
    @message = %r{Malformed Accept-Encoding header}
  end

  describe "when parsing standalone snippet" do

    it_should_behave_like 'simple qvalues parser'

    it "works case-insensitively with Content-Codings" do
      Rack::Acceptable::Utils.parse_http_accept_encoding('Deflate;q=0.1').should == [['deflate', 0.1]]
      Rack::Acceptable::Utils.parse_http_accept_encoding('dEFLATE;q=0.1').should == [['deflate', 0.1]]
    end

    it "raises an ArgumentError when Content-Coding is malformed" do
      lambda { Rack::Acceptable::Utils.parse_http_accept_encoding("with\\separators?") }.
      should raise_error ArgumentError, @message

      lambda { Rack::Acceptable::Utils.parse_http_accept_encoding("yet_another_with@separators") }.
      should raise_error ArgumentError, @message

      lambda { Rack::Acceptable::Utils.parse_http_accept_encoding("header=malformed;q=0.3") }.
      should raise_error ArgumentError, @message

      lambda { Rack::Acceptable::Utils.parse_http_accept_encoding("q=0.3") }.
      should raise_error ArgumentError, @message
    end

  end

  it_should_behave_like 'simple HTTP_ACCEPT_ENCODING parser'

  it "returns an empty array if the value it was passed is an empty string" do
    Rack::Acceptable::Utils.parse_http_accept_encoding("").should == []
  end

end

describe Rack::Acceptable::Utils, ".parse_http_accept_charset" do

  before :all do
    @parser = lambda { |thing| Rack::Acceptable::Utils.parse_http_accept_charset(thing) }
    @qvalue = lambda { |thing| Rack::Acceptable::Utils.parse_http_accept_charset(thing).first.last }
    @sample = 'iso-8859-1'
    @message = %r{Malformed Accept-Charset header}
  end

  describe "when parsing standalone snippet" do

    it_should_behave_like 'simple qvalues parser'

    it "raises an ArgumentError when Charset is malformed" do
      lambda { Rack::Acceptable::Utils.parse_http_accept_charset("with\\separators?") }.
      should raise_error ArgumentError, @message

      lambda { Rack::Acceptable::Utils.parse_http_accept_charset("yet_another_with@separators") }.
      should raise_error ArgumentError, @message

      lambda { Rack::Acceptable::Utils.parse_http_accept_charset("header=malformed;q=0.3") }.
      should raise_error ArgumentError, @message

      lambda { Rack::Acceptable::Utils.parse_http_accept_charset("q=0.3") }.
      should raise_error ArgumentError, @message
    end

    it "works case-insensitively with Charsets" do
      Rack::Acceptable::Utils.parse_http_accept_charset('uNICODE-1-1;q=0.1').should == [['unicode-1-1', 0.1]]
      Rack::Acceptable::Utils.parse_http_accept_charset('Unicode-1-1;q=0.1').should == [['unicode-1-1', 0.1]]
    end

  end

  it_should_behave_like 'simple HTTP_ACCEPT_CHARSET parser'

  it "returns an empty array if the value it was passed is an empty string" do
    Rack::Acceptable::Utils.parse_http_accept_charset("").should == []
  end

end

# EOF