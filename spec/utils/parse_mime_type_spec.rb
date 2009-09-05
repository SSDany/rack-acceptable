require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

require SHARED_EXAMPLES_ROOT + 'qvalues_parser'

shared_examples_for "media-range parser" do

  it "raises an ArgumentError when Media-Range is malformed" do
    lambda { @parser['']                          }.should raise_error ArgumentError, %r{Malformed MIME-Type}
    lambda { @parser[' ']                         }.should raise_error ArgumentError, %r{Malformed MIME-Type}
    lambda { @parser['foo']                       }.should raise_error ArgumentError, %r{Malformed MIME-Type}
    lambda { @parser['foo/bar/baz']               }.should raise_error ArgumentError, %r{Malformed MIME-Type}
    lambda { @parser['*/foo']                     }.should raise_error ArgumentError, %r{Malformed MIME-Type}
    lambda { @parser['something:with@separators'] }.should raise_error ArgumentError, %r{Malformed MIME-Type}
  end

  it "extracts type and subtype (when there's no parameter/accept-params)" do
    @parser[ '*/*'      ][0..1].should == ["*", "*"]
    @parser[ 'text/*'   ][0..1].should == ["text", "*"]
    @parser[ 'text/xml' ][0..1].should == ["text", "xml"]
  end

  it "extracts type and subtype (when there's parameter/accept-params)" do
    @parser[ 'text/html;q=0.33'               ][0..1].should == ["text", "html"]
    @parser[ 'text/html;q=0.33;a=42'          ][0..1].should == ["text", "html"]
    @parser[ 'text/html;level=1'              ][0..1].should == ["text", "html"]
    @parser[ 'text/html;level=1;q=0.33'       ][0..1].should == ["text", "html"]
    @parser[ 'text/html;level=1;q=0.33;a=42'  ][0..1].should == ["text", "html"]
  end

  it "works case-insensitively with type and subtype" do
    @parser['TEXT/html'][0..1].should == ['text', 'html']
    @parser['text/HtML'][0..1].should == ['text', 'html']
  end

  it "extracts parameter (as Hash)" do
    @parser[ 'text/xml'                 ][2].should == {}
    @parser[ 'text/xml;a=1'             ][2].should == {'a' => '1'}
    @parser[ 'text/xml ; a=1'           ][2].should == {'a' => '1'}
    @parser[ 'text/xml;a=1;b=2'         ][2].should == {'a' => '1', 'b' => '2'}
    @parser[ 'text/xml;a=1;b="foo bar"' ][2].should == {'a' => '1', 'b' => '"foo bar"'}
  end

  it "works case-insensitively with parameter's keys" do
    @parser['text/html;LeVEL=WhatEVER'][2].should == {'level' => 'WhatEVER'}
  end

end

describe Rack::Acceptable::Utils, ".parse_media_range" do

  before :all do
    @parser = lambda { |thing| Rack::Acceptable::Utils.parse_mime_type(thing) }
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

  it "ignores whitespaces (acc. to RFC 2616, sec. 2.1)" do
    parsed = Rack::Acceptable::Utils.parse_media_range(' text/html ; level=2 ; q=0.3 ; answer=42 ')
    parsed.should == ['text', 'html', {'level' => '2'}]
  end

end

describe Rack::Acceptable::Utils, ".parse_mime_type", "deal with quality_factors" do

  before :all do
    @qvalue = lambda { |thing| Rack::Acceptable::Utils.parse_mime_type(thing).at(3) }
    @sample = 'text/xml'
  end

  it_should_behave_like "simple qvalues parser"

  it "picks out the FIRST 'q' parameter (if any)" do
    @qvalue['application/xml;q=0.5;p=q;q=557;a=42'].should == 0.5
  end

end

describe Rack::Acceptable::Utils, ".parse_mime_type" do

  before :all do
    @parser = lambda { |thing| Rack::Acceptable::Utils.parse_mime_type(thing) }
  end

  it_should_behave_like "media-range parser"

  it "extracts accept-extension (as Hash)" do

    parsed = Rack::Acceptable::Utils.parse_mime_type('text/xml;a=42;q=0.333')
    parsed[4].should == {}

    parsed = Rack::Acceptable::Utils.parse_mime_type('text/xml;a=42;q=0.333;a=557')
    parsed[4].should == {'a' => '557'}

    parsed = Rack::Acceptable::Utils.parse_mime_type('text/xml;a=42;q=0.333;a=557;b="foo bar baz"')
    parsed[4].should == {'a' => '557', 'b' => '"foo bar baz"'}

    parsed = Rack::Acceptable::Utils.parse_mime_type('text/xml;a=42;q=0.333;557;6537;b=value')
    parsed[4].should == {'557' => true, '6537' => true, 'b' => 'value'}

  end

  it "works case-insensitively with 'q' parameter" do
    parsed = Rack::Acceptable::Utils.parse_mime_type('text/html;level=2;Q=0.3;AnsWER=WhatEVER')
    parsed[3].should == 0.3
    parsed = Rack::Acceptable::Utils.parse_mime_type('text/html;level=2;q=0.3;AnsWER=WhatEVER')
    parsed[3].should == 0.3
  end

  it "respects the accept-params keys/values" do
    parsed = Rack::Acceptable::Utils.parse_mime_type('text/html;level=2;q=0.3;AnsWER=WhatEVER')
    parsed[4].should == {'AnsWER' => 'WhatEVER'}
    parsed = Rack::Acceptable::Utils.parse_mime_type('text/html;level=2;q=0.3;AnsWER')
    parsed[4].should == {'AnsWER' => true}
  end

  it "ignores whitespaces (acc. to RFC 2616, sec. 2.1)" do
    parsed = Rack::Acceptable::Utils.parse_mime_type(' text/xml ; a=42 ; q=0.333 ; a="foo bar baz" ; b=557 ')
    parsed.should == ['text', 'xml', {'a' => '42'}, 0.333, {'a' => '"foo bar baz"', 'b' => '557'} ]
  end

end

# EOF