require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

shared_examples_for "media-range parser" do

  it "raises an ArgumentError when the media range is malformed" do
    %w(*/html %$/whatever whatever/%$ mastah/of/shock).each do |snippet|
      lambda { parse(snippet) }.should raise_error ArgumentError, %r{Malformed MIME-Type}
    end
  end

  it "extracts type and subtype" do
    parse('*/*')[0..1].should                             == ["*", "*"]
    parse('text/*')[0..1].should                          == ["text", "*"]
    parse('text/xml')[0..1].should                        == ["text", "xml"]
    parse('text/html;level=1')[0..1].should               == ["text", "html"]
    parse('text/html;level=1;q=0.33')[0..1].should        == ["text", "html"]
    parse('text/html;level=1;q=0.33;a=42')[0..1].should   == ["text", "html"]
  end

  it "works case-insensitively with type and subtype" do
    parse('TEXT/html')[0..1].should == ['text', 'html']
    parse('text/HtML')[0..1].should == ['text', 'html']
  end

  it "extracts parameter (as Hash)" do
    parse('text/xml')[2].should                 == {}
    parse('text/xml;a=1')[2].should             == {'a' => '1'}
    parse('text/xml ; a=1')[2].should           == {'a' => '1'}
    parse('text/xml;a=1;b=2')[2].should         == {'a' => '1', 'b' => '2'}
    parse('text/xml;a=1;b=foo bar ')[2].should  == {'a' => '1', 'b' => 'foo bar'}
    parse('text/xml;a=foo bar ;b=2')[2].should  == {'a' => 'foo bar', 'b' => '2'}
  end

  it "works case-insensitively with parameter's keys" do
    parsed = Rack::Acceptable::Utils.parse_mime_type('text/html;LeVEL=WhatEVER')
    parsed[2].should == {'level' => 'WhatEVER'}
  end

#  it "raises an ArgumentError when the syntax of parameter is invalid" do
#    lambda { Rack::Acceptable::Utils.parse_mime_type('text/xml;foo =bar') }.should
#    raise_error ArgumentError, %r{Malformed parameter syntax}

#    lambda { Rack::Acceptable::Utils.parse_mime_type('text/xml;foo= bar') }.should
#    raise_error ArgumentError, %r{Malformed parameter syntax}
#  end

end

describe Rack::Acceptable::Utils, ".parse_media_range" do

  def parse(thing)
    Rack::Acceptable::Utils.parse_media_range(thing)
  end

  it_should_behave_like "media-range parser"

  it "ignores accept-params (incl. 'q' parameter)" do
    parsed = Rack::Acceptable::Utils.parse_media_range('text/html;level=2;q=0.3;answer=42')
    parsed[2].should == {'level' => '2'}

    parsed = Rack::Acceptable::Utils.parse_media_range('text/html;a=1;b=2;q=0.3')
    parsed[2].should == {'a' => '1', 'b' => '2'}

    parsed = Rack::Acceptable::Utils.parse_media_range('text/html;a=1;b=2;Q=0.3')
    parsed[2].should == {'a' => '1', 'b' => '2'}
  end

end

describe Rack::Acceptable::Utils, ".parse_mime_type" do

  def parse(thing)
    Rack::Acceptable::Utils.parse_mime_type(thing)
  end

  it_should_behave_like "media-range parser"

  it "extracts well-formed quality factors" do
    parsed = Rack::Acceptable::Utils.parse_mime_type('text/xml;q=1')
    parsed[3].should == 1.0

    parsed = Rack::Acceptable::Utils.parse_mime_type('text/xml;q=0')
    parsed[3].should == 0.0

    parsed = Rack::Acceptable::Utils.parse_mime_type('text/xml;q=0.33')
    parsed[3].should == 0.33

    parsed = Rack::Acceptable::Utils.parse_mime_type('text/xml;q=0.333')
    parsed[3].should == 0.333

    parsed = Rack::Acceptable::Utils.parse_mime_type('text/xml;q=1.')
    parsed[3].should == 1.0
  end

  it "raises an ArgumentError when the quality factor is malformed" do
    malformed = ["42", "bogus", "", ".3", "-0.4", "1/3", "0.3333", "1.01", "2.22"]
    malformed.each do |qvalue|
      snippet = "text/xml;q=#{qvalue}"
      lambda { Rack::Acceptable::Utils.parse_mime_type(snippet) }.should
      raise_error ArgumentError, %r{Malformed quality factor}
    end
  end

  it "extracts accept-extension (as Hash)" do

    parsed = Rack::Acceptable::Utils.parse_mime_type('text/xml;a=42;q=0.333')
    parsed[4].should == {}

    parsed = Rack::Acceptable::Utils.parse_mime_type('text/xml;a=42;q=0.333 ; a=557')
    parsed[4].should == {'a' => '557'}

    parsed = Rack::Acceptable::Utils.parse_mime_type('text/xml;a=42;q=0.333;a=foo bar baz ;b=557')
    parsed[4].should == {'a' => 'foo bar baz', 'b' => '557'}

    parsed = Rack::Acceptable::Utils.parse_mime_type('text/xml;a=42;q=0.333;a=557;b=foo bar baz ')
    parsed[4].should == {'a' => '557', 'b' => 'foo bar baz'}

  end

  it "works case-insensitively with accept-params's keys (incl. 'q' parameter)" do
    parsed = Rack::Acceptable::Utils.parse_mime_type('text/html;level=2;Q=0.3;AnsWER=WhatEVER')
    parsed[3].should == 0.3
    parsed[4].should == {'answer' => 'WhatEVER'}
  end

#  it "raises an ArgumentError when the syntax of accept-params is invalid" do
#    lambda { Rack::Acceptable::Utils.parse_mime_type('text/xml;q =0.1') }.should
#    raise_error ArgumentError, %r{Malformed parameter syntax}

#    lambda { Rack::Acceptable::Utils.parse_mime_type('text/xml;q= 0.1') }.should
#    raise_error ArgumentError, %r{Malformed parameter syntax}

#    lambda { Rack::Acceptable::Utils.parse_mime_type('text/xml;q=0.1;foo= bar') }.should
#    raise_error ArgumentError, %r{Malformed parameter syntax}

#    lambda { Rack::Acceptable::Utils.parse_mime_type('text/xml;q=0.1;foo =bar') }.should
#    raise_error ArgumentError, %r{Malformed parameter syntax}
#  end

end

# EOF