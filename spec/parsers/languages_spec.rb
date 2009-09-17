require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

shared_examples_for "simple Language-Tag parser" do

  it "extracts basic components (language, script, region and variants)" do
    @parser[ 'de'               ].should == ['de', nil    , nil   , []                  ]
    @parser[ 'fr'               ].should == ['fr', nil    , nil   , []                  ]
    @parser[ 'de-DE'            ].should == ['de', nil    , 'DE'  , []                  ]
    @parser[ 'en-US'            ].should == ['en', nil    , 'US'  , []                  ]
    @parser[ 'zh-Hant'          ].should == ['zh', 'Hant' , nil   , []                  ]
    @parser[ 'zh-Hans'          ].should == ['zh', 'Hans' , nil   , []                  ]
    @parser[ 'zh-Hans-CN'       ].should == ['zh', 'Hans' , 'CN'  , []                  ]
    @parser[ 'sr-Latn-CS'       ].should == ['sr', 'Latn' , 'CS'  , []                  ]
    @parser[ 'sl-rozaj'         ].should == ['sl', nil    , nil   , ['rozaj' ]          ]
    @parser[ 'sl-nedis'         ].should == ['sl', nil    , nil   , ['nedis' ]          ]
    @parser[ 'sl-rozaj-nedis'   ].should == ['sl', nil    , nil   , ['rozaj','nedis']   ]
    @parser[ 'de-CH-1901'       ].should == ['de', nil    , 'CH'  , ['1901']            ]
    @parser[ 'sl-IT-nedis'      ].should == ['sl', nil    , 'IT'  , ['nedis']           ]
    @parser[ 'sl-Latn-IT-nedis' ].should == ['sl', 'Latn' , 'IT'  , ['nedis']           ]
  end

  it "conveniently transforms basic components" do
    @parser[ 'DE'               ].should == ['de', nil    , nil   , []        ]
    @parser[ 'de-de'            ].should == ['de', nil    , 'DE'  , []        ]
    @parser[ 'zh-hAnt'          ].should == ['zh', 'Hant' , nil   , []        ]
    @parser[ 'sl-RoZaj'         ].should == ['sl', nil    , nil   , ['rozaj'] ]
    @parser[ 'sl-Latn-it-NEDIS' ].should == ['sl', 'Latn' , 'IT'  , ['nedis'] ]
  end

  it "returns nil when there's a 'privateuse' Language-Tag" do
    @parser[ 'x-private'            ].should == nil
    @parser[ 'x-private1-private2'  ].should == nil
  end

  it "returns nil when there's a 'grandfathered' Language-Tag" do
    @parser[ 'i-enochian' ].should == nil
    @parser[ 'i-klingon'  ].should == nil
  end

  it "returns nil when there's something malformed" do

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
      'i-bogus',
      'i-@@' 
    ].each { |tag| @parser[tag].should == nil }

  end

end

describe Rack::Acceptable::Languages, '.extract_language_info' do

  before :all do
    @parser = lambda { |tag| Rack::Acceptable::Languages.extract_language_info(tag) }
  end

  it_should_behave_like "simple Language-Tag parser"

end

describe Rack::Acceptable::Languages, '.extract_full_language_info' do

  before :all do
    @parser = lambda do |tag|
      ret = Rack::Acceptable::Languages.extract_full_language_info(tag)
      ret.nil? ? nil : ret[0..3]
    end
  end

  it_should_behave_like "simple Language-Tag parser"

  it "extracts extension components into a Hash" do
    extension = Rack::Acceptable::Languages.extract_full_language_info('en-GB-a-xxx-yyy-b-zzz-x-private')[4]
    extension.should == {'a' => ['xxx', 'yyy'], 'b' => ['zzz']}
  end

  it "downcases extension components (both singletons and subtags)" do
    extension = Rack::Acceptable::Languages.extract_full_language_info('en-GB-a-Xxx-YYY-B-zzZ')[4]
    extension.should == {'a' => ['xxx', 'yyy'], 'b' => ['zzz']}
  end

  it "returns nil when there's a repeated singleton (this mean the Language-Tag is malformed)" do
    Rack::Acceptable::Languages.extract_full_language_info('en-GB-a-xxx-b-yyy-a-zzz-x-private').should === nil
    Rack::Acceptable::Languages.extract_full_language_info('en-GB-a-xxx-b-yyy-A-zzz-x-private').should === nil
  end

  it "extracts privateuse components into an Array" do
    extension = Rack::Acceptable::Languages.extract_full_language_info('en-GB-x-en-private')[5]
    extension.should == ['en', 'private']
  end

  it "downcases privateuse components" do
    extension = Rack::Acceptable::Languages.extract_full_language_info('en-GB-x-EN-pRivate-SUBTAGS')[5]
    extension.should == ['en', 'private', 'subtags']
  end

end

describe Rack::Acceptable::Languages, "misc" do

  it "knows about 'privateuse' Language-Tags" do
    Rack::Acceptable::Languages.privateuse?('X-private').should == true
    Rack::Acceptable::Languages.privateuse?('x-private').should == true
    Rack::Acceptable::Languages.privateuse?('en-GB').should == false
    Rack::Acceptable::Languages.privateuse?('x-veryverylong').should == false
    Rack::Acceptable::Languages.privateuse?('x').should == false
    Rack::Acceptable::Languages.privateuse?('x-').should == false
    Rack::Acceptable::Languages.privateuse?('x-@@').should == false
  end

  it "knows about 'grandfathered' Language-Tags" do
    Rack::Acceptable::Languages.grandfathered?('i-enochian').should == true
    Rack::Acceptable::Languages.grandfathered?('I-Enochian').should == true
    Rack::Acceptable::Languages.grandfathered?('i-hak').should == true
    Rack::Acceptable::Languages.grandfathered?('i-HAK').should == true
    Rack::Acceptable::Languages.grandfathered?('i-bogus').should == false
  end

  it "knows about irregular 'grandfathered' Language-Tags" do
    Rack::Acceptable::Languages.irregular_grandfathered?('i-hak').should == true
    Rack::Acceptable::Languages.irregular_grandfathered?('I-Hak').should == true
    Rack::Acceptable::Languages.irregular_grandfathered?('i-enochian').should == false

    Rack::Acceptable::Languages.irregular_grandfathered?('i-irregular').should == false      # not a grandfathred Language-Tag
    Rack::Acceptable::Languages.irregular_grandfathered?('i-one-two-three').should == false  # not a grandfathred Language-Tag
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