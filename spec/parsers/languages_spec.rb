require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Rack::Acceptable::Languages, '.parse_language_tag' do

  before :all do
    @helper = lambda { |tag| Rack::Acceptable::Languages.parse_language_tag(tag) }
  end

  describe "when there's a full Language-Tag" do

    it "extracts language data (language, script, region and variants)" do
      @helper[ 'de'               ].should == ['de', nil    , nil                       ]
      @helper[ 'fr'               ].should == ['fr', nil    , nil                       ]
      @helper[ 'de-DE'            ].should == ['de', nil    , 'DE'                      ]
      @helper[ 'en-US'            ].should == ['en', nil    , 'US'                      ]
      @helper[ 'zh-Hant'          ].should == ['zh', 'Hant' , nil                       ]
      @helper[ 'zh-Hans'          ].should == ['zh', 'Hans' , nil                       ]
      @helper[ 'zh-Hans-CN'       ].should == ['zh', 'Hans' , 'CN'                      ]
      @helper[ 'sr-Latn-CS'       ].should == ['sr', 'Latn' , 'CS'                      ]
      @helper[ 'sl-rozaj'         ].should == ['sl', nil    , nil   , 'rozaj'           ]
      @helper[ 'sl-nedis'         ].should == ['sl', nil    , nil   , 'nedis'           ]
      @helper[ 'sl-rozaj-nedis'   ].should == ['sl', nil    , nil   , 'rozaj', 'nedis'  ]
      @helper[ 'de-CH-1901'       ].should == ['de', nil    , 'CH'  , '1901'            ]
      @helper[ 'sl-IT-nedis'      ].should == ['sl', nil    , 'IT'  , 'nedis'           ]
      @helper[ 'sl-Latn-IT-nedis' ].should == ['sl', 'Latn' , 'IT'  , 'nedis'           ]
    end

    it "conveniently transforms all components" do
      @helper[ 'DE'               ].should == ['de', nil    , nil           ]
      @helper[ 'de-de'            ].should == ['de', nil    , 'DE'          ]
      @helper[ 'zh-hAnt'          ].should == ['zh', 'Hant' , nil           ]
      @helper[ 'sl-RoZaj'         ].should == ['sl', nil    , nil , 'rozaj' ]
      @helper[ 'sl-Latn-it-NEDIS' ].should == ['sl', 'Latn' , 'IT', 'nedis' ]
    end

  end

  describe "when there's a 'privateuse' Language-Tag" do

    it "parses it into a simple Array" do
      @helper[ 'x-private'            ].should == ['x', 'private']
      @helper[ 'x-private1-private2'  ].should == ['x', 'private1', 'private2']
    end

    it "downcases primary tag and subtags" do
      @helper[ 'X-Private'            ].should == ['x', 'private']
      @helper[ 'X-pRivate1-pRivate2'  ].should == ['x', 'private1', 'private2']
    end

  end

  describe "when there's a 'grandfathered' Language-Tag" do

    it "parses it into a simple Array" do
      @helper[ 'i-enochian'   ].should == ['i', 'enochian']
      @helper[ 'i-some-thing' ].should == ['i', 'some', 'thing']
    end

    it "downcases primary tag and subtags" do
      @helper[ 'I-Enochian'   ].should == ['i', 'enochian']
      @helper[ 'I-sOme-thing' ].should == ['i', 'some', 'thing']
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
      lambda { @helper['en-veryverylong'] }.should raise_error ArgumentError, %r{Malformed Language-Tag}
    end

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