require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Rack::Acceptable::Utils, ".parse_mime_type" do

  describe "parses MIME-Types (really :)" do

    it "extracts type and subtype" do

      parsed = Rack::Acceptable::Utils.parse_mime_type('*/*')
      parsed.should == ["*", "*", 1.0, {}, {}]

      parsed = Rack::Acceptable::Utils.parse_mime_type('text/*')
      parsed.should == ["text", "*", 1.0, {}, {}]

      parsed = Rack::Acceptable::Utils.parse_mime_type('text/xml')
      parsed.should == ["text", "xml", 1.0, {}, {}]

    end

    it "extracts quality factors" do

      parsed = Rack::Acceptable::Utils.parse_mime_type('text/xml;q=1')
      parsed.should == ["text", "xml", 1.0, {}, {}]

      parsed = Rack::Acceptable::Utils.parse_mime_type('text/xml;q=0')
      parsed.should == ["text", "xml", 0.0, {}, {}]

      parsed = Rack::Acceptable::Utils.parse_mime_type('text/xml;q=0.333')
      parsed.should == ["text", "xml", 0.333, {}, {}]

    end

    it "extracts parameter Hash" do

      parsed = Rack::Acceptable::Utils.parse_mime_type('text/xml;a=1')
      parsed.should == ["text", "xml", 1.0, {'a' => '1'}, {}]

      parsed = Rack::Acceptable::Utils.parse_mime_type('text/xml ; a=1')
      parsed.should == ["text", "xml", 1.0, {'a' => '1'}, {}]

      parsed = Rack::Acceptable::Utils.parse_mime_type('text/xml;a=1;b=2;q=0.333')
      parsed.should == ["text", "xml", 0.333, {'a' => '1', 'b' => '2'}, {}]

      parsed = Rack::Acceptable::Utils.parse_mime_type('text/xml;a=foo bar ;b=2;q=0.333')
      parsed.should == ["text", "xml", 0.333, {'a' => 'foo bar', 'b' => '2'}, {}]

    end

    it "extracts accept-params Hash" do

      parsed = Rack::Acceptable::Utils.parse_mime_type('text/xml;a=42;q=0.333; a=557')
      parsed.should == ["text", "xml", 0.333, {'a' => '42'}, {'a' => '557'}]

      parsed = Rack::Acceptable::Utils.parse_mime_type('text/xml;a=42;q=0.333; a=557 ; b=foo bar baz')
      parsed.should == ["text", "xml", 0.333, {'a' => '42'}, {'a' => '557', 'b' => 'foo bar baz'}]

    end

  end

  it "raises an ArgumentError when the media range is malformed" do
    %w(*/html %$/whatever whatever/%$).each do |snippet|
      lambda { Rack::Acceptable::Utils.parse_mime_type(snippet) }.should
      raise_error ArgumentError, %r{Malformed MIME-Type}
    end
  end

  it "raises an ArgumentError when the quality factor is malformed" do
    malformed = ["42", "bogus", "", ".3", "-0.4", "1/3", "0.3333", "1.01", "2.22"]
    malformed.each do |qvalue|
      snippet = "text/xml;q=#{qvalue}"
      lambda { Rack::Acceptable::Utils.parse_mime_type(snippet) }.should
      raise_error ArgumentError, %r{Malformed quality factor}
    end
  end

  it "raises an ArgumentError when the syntax of parameter/accept-params is invalid" do
    lambda { Rack::Acceptable::Utils.parse_mime_type('text/xml;foo =bar') }.should
    raise_error ArgumentError, %r{Malformed parameter syntax}

    lambda { Rack::Acceptable::Utils.parse_mime_type('text/xml;foo= bar') }.should
    raise_error ArgumentError, %r{Malformed parameter syntax}
  end

  it "works case-insensitively with type and subtype" do
    parsed = Rack::Acceptable::Utils.parse_mime_type('TEXT/html')
    parsed[0].should == 'text'
    parsed[1].should == 'html'

    parsed = Rack::Acceptable::Utils.parse_mime_type('text/HtML')
    parsed[0].should == 'text'
    parsed[1].should == 'html'
  end

  it "works case-insensitively with parameter/accept-params's keys" do
    snippet = 'text/html;LeVEL=2;Q=0.3;AnsWER=42'
    parsed = Rack::Acceptable::Utils.parse_mime_type(snippet)

    parsed[0].should == 'text'
    parsed[1].should == 'html'
    parsed[2].should == 0.3
    parsed[3].should == {'level' => '2'}
    parsed[4].should == {'answer' => '42'}
  end

end

# EOF