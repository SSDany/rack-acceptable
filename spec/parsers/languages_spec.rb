require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

shared_examples_for "simple Language-Tag parser" do

  describe "when there's a full Language-Tag" do

    it "extracts language data (language, script, region and variants)" do
      @parser[ 'de'               ].should == ['de', nil    , nil   , nil                 ]
      @parser[ 'fr'               ].should == ['fr', nil    , nil   , nil                 ]
      @parser[ 'de-DE'            ].should == ['de', nil    , 'DE'  , nil                 ]
      @parser[ 'en-US'            ].should == ['en', nil    , 'US'  , nil                 ]
      @parser[ 'zh-Hant'          ].should == ['zh', 'Hant' , nil   , nil                 ]
      @parser[ 'zh-Hans'          ].should == ['zh', 'Hans' , nil   , nil                 ]
      @parser[ 'zh-Hans-CN'       ].should == ['zh', 'Hans' , 'CN'  , nil                 ]
      @parser[ 'sr-Latn-CS'       ].should == ['sr', 'Latn' , 'CS'  , nil                 ]
      @parser[ 'sl-rozaj'         ].should == ['sl', nil    , nil   , ['rozaj' ]          ]
      @parser[ 'sl-nedis'         ].should == ['sl', nil    , nil   , ['nedis' ]          ]
      @parser[ 'sl-rozaj-nedis'   ].should == ['sl', nil    , nil   , ['rozaj','nedis']   ]
      @parser[ 'de-CH-1901'       ].should == ['de', nil    , 'CH'  , ['1901']            ]
      @parser[ 'sl-IT-nedis'      ].should == ['sl', nil    , 'IT'  , ['nedis']           ]
      @parser[ 'sl-Latn-IT-nedis' ].should == ['sl', 'Latn' , 'IT'  , ['nedis']           ]
    end

    it "conveniently transforms language, script, region and variants" do
      @parser[ 'DE'               ].should == ['de', nil    , nil   , nil       ]
      @parser[ 'de-de'            ].should == ['de', nil    , 'DE'  , nil       ]
      @parser[ 'zh-hAnt'          ].should == ['zh', 'Hant' , nil   , nil       ]
      @parser[ 'sl-RoZaj'         ].should == ['sl', nil    , nil   , ['rozaj'] ]
      @parser[ 'sl-Latn-it-NEDIS' ].should == ['sl', 'Latn' , 'IT'  , ['nedis'] ]
    end

  end

  describe "when there's a 'privateuse' Language-Tag" do

    it "parses it into a simple Array" do
      @parser[ 'x-private'            ].should == ['x', 'private']
      @parser[ 'x-private1-private2'  ].should == ['x', 'private1', 'private2']
    end

    it "downcases primary tag and subtags" do
      @parser[ 'X-Private'            ].should == ['x', 'private']
      @parser[ 'X-pRivate1-pRivate2'  ].should == ['x', 'private1', 'private2']
    end

  end

  describe "when there's a 'grandfathered' Language-Tag" do

    it "parses it into a simple Array" do
      @parser[ 'i-enochian'   ].should == ['i', 'enochian']
      @parser[ 'i-some-thing' ].should == ['i', 'some', 'thing']
    end

    it "downcases primary tag and subtags" do
      @parser[ 'I-Enochian'   ].should == ['i', 'enochian']
      @parser[ 'I-sOme-thing' ].should == ['i', 'some', 'thing']
    end

  end

  it "raises an Argument Error when there's something malformed" do

    [ '1-GB',
      'a',
      'en--US',
      'en-value-a-b',
      'en-value-a-b-value',
      'en-veryverylong',
      'en-a-x-value',
      'sl-rozaj-Latn',
      'sl-rozaj-IT',
      'sl-IT-Latn',
      'x',
      'x-',
      'x-veryverylong',
      'x-@@',
      'i',
      'i-one-two-three',
      'i-veryverylong',
      'i-@@' 
    ].each do |tag|
      lambda { @parser['en-veryverylong'] }.should raise_error ArgumentError, %r{Malformed Language-Tag}
    end

  end

end

describe Rack::Acceptable::Languages, '.parse_language_tag' do

  before :all do
    @parser = lambda { |tag| Rack::Acceptable::Languages.parse_language_tag(tag) }
  end

  it_should_behave_like "simple Language-Tag parser"

end

describe Rack::Acceptable::Languages, '.parse_extended_language_tag' do

  before :all do
    @parser = lambda { |tag| Rack::Acceptable::Languages.parse_extended_language_tag(tag)[0..3] }
  end

  it_should_behave_like "simple Language-Tag parser"

  it "extracts extension into a Hash" do
    extension = Rack::Acceptable::Languages.parse_extended_language_tag('en-GB-a-xxx-yyy-b-zzz-x-private')[4]
    extension.should == {'a' => ['xxx', 'yyy'], 'b' => ['zzz']}
  end

  it "extracts privateuse data into an Array" do
    extension = Rack::Acceptable::Languages.parse_extended_language_tag('en-GB-x-en-private')[5]
    extension.should == ['en', 'private']
  end

  it "raises an ArgumentError when there's a repeated singleton" do
    lambda { @parser['en-GB-a-xxx-b-yyy-a-zzz-x-private'] }.should raise_error ArgumentError, %r{Malformed Language-Tag}
    lambda { @parser['en-GB-a-xxx-b-yyy-A-zzz-x-private'] }.should raise_error ArgumentError, %r{Malformed Language-Tag}
  end

end

describe Rack::Acceptable::Languages, ".parse_accept_language" do

  before :all do
    @parser = lambda { |thing| Rack::Acceptable::Languages.parse_accept_language(thing) }
    @qvalue = lambda { |thing| Rack::Acceptable::Languages.parse_accept_language(thing).first.last }
    @sample = 'en-gb'
    @message = %r{Malformed Accept-Language header}
  end

  describe "when parsing standalone snippet" do

    it_should_behave_like 'simple qvalues parser'

    it "raises an ArgumentError when there's a malformed Language-Range" do
      lambda { Rack::Acceptable::Languages.parse_accept_language("veryverylongstring") }.
      should raise_error ArgumentError, @message

      lambda { Rack::Acceptable::Languages.parse_accept_language("en-gb-veryverylongstring") }.
      should raise_error ArgumentError, @message

      lambda { Rack::Acceptable::Languages.parse_accept_language("non_alpha") }.
      should raise_error ArgumentError, @message

      lambda { Rack::Acceptable::Languages.parse_accept_language("header=malformed;q=0.3") }.
      should raise_error ArgumentError, @message

      lambda { Rack::Acceptable::Languages.parse_accept_language("q=0.3") }.
      should raise_error ArgumentError, @message
    end

  end

  it_should_behave_like 'simple HTTP_ACCEPT_LANGUAGE parser'
  it_should_behave_like 'simple parser of 1#(element) lists'

end

describe Rack::Acceptable::Languages, ".parse_locales" do

  before :all do
    @parser = lambda { |thing| Rack::Acceptable::Languages.parse_locales(thing) }
    @qvalue = lambda { |thing| Rack::Acceptable::Languages.parse_locales(thing).first.last }
    @sample = 'en'
    @message = %r{Malformed Accept-Language header}
  end

  describe "when parsing standalone snippet" do

    it_should_behave_like 'simple qvalues parser'

    it "raises an ArgumentError when there's a malformed Language-Range" do
      lambda { Rack::Acceptable::Languages.parse_locales("veryverylongstring") }.
      should raise_error ArgumentError, @message

      lambda { Rack::Acceptable::Languages.parse_locales("en-gb-veryverylongstring") }.
      should raise_error ArgumentError, @message

      lambda { Rack::Acceptable::Languages.parse_locales("non_alpha") }.
      should raise_error ArgumentError, @message

      lambda { Rack::Acceptable::Languages.parse_locales("header=malformed;q=0.3") }.
      should raise_error ArgumentError, @message

      lambda { Rack::Acceptable::Languages.parse_locales("q=0.3") }.
      should raise_error ArgumentError, @message
    end

    it "downcases locale" do
      qvalues = Rack::Acceptable::Languages.parse_locales('EN-GB;q=0.1')
      qvalues.should == [['en', 0.1]]
    end

    it "ignores all language subtags except the primary one" do
      qvalues = Rack::Acceptable::Languages.parse_locales('en-GB;q=0.1')
      qvalues.should == [['en', 0.1]]

      qvalues = Rack::Acceptable::Languages.parse_locales('sl-rozaj;q=0.5')
      qvalues.should == [['sl', 0.5]]

      qvalues = Rack::Acceptable::Languages.parse_locales('en-GB-a-xxx-b-yyy-x-private;q=0.5')
      qvalues.should == [['en', 0.5]]
    end

    it "ignores 'i' and 'x' singletons" do
      qvalues = Rack::Acceptable::Languages.parse_locales('x-pig-latin;q=0.1,en-GB;q=0.5')
      qvalues.should == [['en', 0.5]]

      qvalues = Rack::Acceptable::Languages.parse_locales('en-GB;q=0.5, i-enochian;q=0.03')
      qvalues.should == [['en', 0.5]]
    end

  end

  it_should_behave_like 'simple parser of 1#(element) lists'

end

# EOF