require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

describe Rack::Acceptable::LanguageTag, ".privateuse?" do

  it "returns true when there's a 'privateuse' Language-Tag" do
    Rack::Acceptable::LanguageTag.privateuse?('X-private').should == true
    Rack::Acceptable::LanguageTag.privateuse?('x-private').should == true
  end

  it "returns false otherwise" do
    Rack::Acceptable::LanguageTag.privateuse?('en-GB').should == false
    Rack::Acceptable::LanguageTag.privateuse?('x-veryverylong').should == false
    Rack::Acceptable::LanguageTag.privateuse?('x').should == false
    Rack::Acceptable::LanguageTag.privateuse?('x-').should == false
    Rack::Acceptable::LanguageTag.privateuse?('x-@@').should == false
  end

end

describe Rack::Acceptable::LanguageTag, ".grandfathered?" do

  it "returns true when there's a 'grandfathered' Language-Tag" do
    Rack::Acceptable::LanguageTag.grandfathered?('i-enochian').should == true
    Rack::Acceptable::LanguageTag.grandfathered?('I-Enochian').should == true
    Rack::Acceptable::LanguageTag.grandfathered?('i-hak').should == true
    Rack::Acceptable::LanguageTag.grandfathered?('i-HAK').should == true
  end

  it "returns false otherwise" do
    Rack::Acceptable::LanguageTag.grandfathered?('i-bogus').should == false
    Rack::Acceptable::LanguageTag.privateuse?('en-GB').should == false
    Rack::Acceptable::LanguageTag.privateuse?('i-veryverylong').should == false
    Rack::Acceptable::LanguageTag.privateuse?('i').should == false
    Rack::Acceptable::LanguageTag.privateuse?('i-').should == false
    Rack::Acceptable::LanguageTag.privateuse?('i-@@').should == false
  end

end

shared_examples_for "simple Language-Tag parser" do

  unless defined? ::MALFORMED_LANGUAGE_TAGS
    ::MALFORMED_LANGUAGE_TAGS = [ '1-GB',
      'a',
      'en--US',
      'en-value-a-b',
      'en-value-a-b-value',
      'en-veryverylong',
      'en-a-x-value',
      'sl-rozaj-Latn',
      'sl-Lath-IT-@@',
      'sl-rozaj-IT',
      'sl-IT-Latn',
      'sl-IT-bo-peeeeeeeeeeeeep',
      'zh-HK-yue',
      'fooo-bar',
      'x',
      'x-',
      'x-veryverylong',
      'x-@@',
      'i',
      'i-bogus',
      'i-@@' 
      ]
  end

  it "extracts essential components (primary subtag, extlang, script, region and variants)" do
    @parser[ 'de'               ].should == ['de', nil    , nil     , nil   , nil                 ]
    @parser[ 'fr'               ].should == ['fr', nil    , nil     , nil   , nil                 ]
    @parser[ 'de-DE'            ].should == ['de', nil    , nil     , 'DE'  , nil                 ]
    @parser[ 'en-US'            ].should == ['en', nil    , nil     , 'US'  , nil                 ]
    @parser[ 'zh-Hant'          ].should == ['zh', nil    , 'Hant'  , nil   , nil                 ]
    @parser[ 'zh-Hans'          ].should == ['zh', nil    , 'Hans'  , nil   , nil                 ]
    @parser[ 'zh-Hans-CN'       ].should == ['zh', nil    , 'Hans'  , 'CN'  , nil                 ]
    @parser[ 'sr-Latn-CS'       ].should == ['sr', nil    , 'Latn'  , 'CS'  , nil                 ]
    @parser[ 'sl-rozaj'         ].should == ['sl', nil    , nil     , nil   , ['rozaj' ]          ]
    @parser[ 'sl-nedis'         ].should == ['sl', nil    , nil     , nil   , ['nedis' ]          ]
    @parser[ 'sl-rozaj-biske'   ].should == ['sl', nil    , nil     , nil   , ['rozaj','biske']   ]
    @parser[ 'de-CH-1901'       ].should == ['de', nil    , nil     , 'CH'  , ['1901']            ]
    @parser[ 'sl-IT-nedis'      ].should == ['sl', nil    , nil     , 'IT'  , ['nedis']           ]
    @parser[ 'sl-Latn-IT-nedis' ].should == ['sl', nil    , 'Latn'  , 'IT'  , ['nedis']           ]
    @parser[ 'zh-cmn-Hans-CN'   ].should == ['zh', 'cmn'  , 'Hans'  , 'CN'  , nil                 ]
    @parser[ 'zh-yue-HK'        ].should == ['zh', 'yue'  , nil     , 'HK'  , nil                 ]
    @parser[ 'zh-yue'           ].should == ['zh', 'yue'  , nil     , nil   , nil                 ]
  end

  it "conveniently transforms essential components" do
    @parser[ 'DE'               ].should == ['de', nil    , nil     , nil   , nil       ]
    @parser[ 'de-de'            ].should == ['de', nil    , nil     , 'DE'  , nil       ]
    @parser[ 'zh-hAnt'          ].should == ['zh', nil    , 'Hant'  , nil   , nil       ]
    @parser[ 'sl-RoZaj'         ].should == ['sl', nil    , nil     , nil   , ['rozaj'] ]
    @parser[ 'sl-Latn-it-NEDIS' ].should == ['sl', nil    , 'Latn'  , 'IT'  , ['nedis'] ]
    @parser[ 'zh-Yue'           ].should == ['zh', 'yue'  , nil     , nil   , nil       ]
    @parser[ 'zh-YUE-HK'        ].should == ['zh', 'yue'  , nil     , 'HK'  , nil       ]
  end

end

describe Rack::Acceptable::LanguageTag, ".extract_language_info" do

  before :all do
    @parser = lambda { |tag| Rack::Acceptable::LanguageTag.extract_language_info(tag) }
  end

  it_should_behave_like "simple Language-Tag parser"

  it "returns nil when there's a 'privateuse' Language-Tag" do
    @parser[ 'x-private'            ].should == nil
    @parser[ 'x-private1-private2'  ].should == nil
  end

  it "returns nil when there's a 'grandfathered' Language-Tag" do
    @parser[ 'i-enochian'   ].should == nil
    @parser[ 'i-klingon'    ].should == nil
    @parser[ 'zh-min-nan'   ].should == nil
    @parser[ 'zh-xiang'     ].should == nil
    @parser[ 'cel-gaulish'  ].should == nil
    @parser[ 'art-lojban'   ].should == nil
  end

  it "returns nil when there's something malformed" do
    MALFORMED_LANGUAGE_TAGS.each { |tag| @parser[tag].should == nil }
  end

end

describe Rack::Acceptable::LanguageTag, "#recompose" do

  before :all do
    @parser = lambda do |thing|
      tag = Rack::Acceptable::LanguageTag.allocate
      tag.recompose(thing)
      if Rack::Acceptable::LanguageTag === tag
        [tag.primary, tag.extlang, tag.script, tag.region, tag.variants]
      else
        tag
      end
    end
  end

  before :each do
    @tag = Rack::Acceptable::LanguageTag.allocate
  end

  it "raises an ArgumentError when there's something malformed" do
    MALFORMED_LANGUAGE_TAGS.each do |tag|
      lambda { @tag.recompose(tag) }.
      should raise_error ArgumentError, %r{Malformed or 'privateuse' Language-Tag}
    end
  end

  describe "when the argument passed represents a 'grandfathered' Language-Tag" do

    before :each do
      Rack::Acceptable::LanguageTag.canonize_grandfathered = false
    end

    it "raises an ArgumentError, when 'canonize_grandfathered' option is off" do
      lambda { @tag.recompose('zh-hakka') }.should raise_error ArgumentError, %r{Grandfathered Language-Tag}
      lambda { @tag.recompose('i-enochian') }.should raise_error ArgumentError, %r{Grandfathered Language-Tag}
    end

    describe "and 'canonize_grandfathered' option is on" do

      before :each do
        Rack::Acceptable::LanguageTag.canonize_grandfathered = true
      end

      it "handles tag, if there's a canonical form" do
        Rack::Acceptable::LanguageTag.canonize_grandfathered = true
        @tag.recompose('zh-hakka')
        @tag.primary.should == 'hak'
        @tag.extlang.should == nil
        @tag.script.should == nil
        @tag.region.should == nil
        @tag.variants.should == nil
        @tag.extensions.should == nil
        @tag.privateuse.should == nil
      end

      it "raises an ArgumentError otherwise" do
        Rack::Acceptable::LanguageTag.canonize_grandfathered = true
        lambda { @tag.recompose('i-enochian') }.should raise_error ArgumentError,
        %r{There's no canonical form for grandfathered Language-Tag}
      end

    end

    after :each do
      Rack::Acceptable::LanguageTag.canonize_grandfathered = false
    end

  end

  describe "when the argument passed represents a 'privateuse' Language-Tag" do
    it("") { pending "should we handle this as a langtag with only the 'privateuse' component?" }
  end

  describe "when the argument passed represents a 'langtag'" do

    it_should_behave_like "simple Language-Tag parser"

    it "raises an ArgumentError when there's a repeated singleton (RFC 5646, sec. 2.2.9)" do
      lambda { @tag.recompose('en-GB-a-xxx-b-yyy-a-zzz-x-private') }.
      should raise_error ArgumentError, %r{Invalid Language-Tag \(repeated singleton: "a"\)}

      lambda { @tag.recompose('en-GB-a-xxx-b-yyy-A-zzz-x-private') }.
      should raise_error ArgumentError, %r{Invalid Language-Tag \(repeated singleton: "a"\)}
    end

    it "raises an ArgumentError when there's a repeated variant (RFC 5646, sec. 2.2.9)" do
      lambda { @tag.recompose('sl-IT-nedis-nedis') }.
      should raise_error ArgumentError, %r{Invalid Language-Tag \(repeated variant: "nedis"\)}

      lambda { @tag.recompose('sl-IT-nedis-nEdIS') }.
      should raise_error ArgumentError, %r{Invalid Language-Tag \(repeated variant: "nedis"\)}
    end

    it "defaults extensions to nil" do
      @tag.recompose('en-GB')
      @tag.extensions.should == nil
    end

    it "defaults 'privateuse' to nil" do
      @tag.recompose('en-GB')
      @tag.privateuse.should == nil
    end

    describe "and there are some extensions" do

      it "extracts extensions into a Hash" do
        @tag.recompose('en-GB-a-xxx-yyy-b-zzz-x-private')
        @tag.extensions.should == {'a' => ['xxx', 'yyy'], 'b' => ['zzz']}
      end

      it "downcases extensions (both singletons and subtags)" do
        @tag.recompose('en-GB-a-Xxx-YYY-B-zzZ')
        @tag.extensions.should == {'a' => ['xxx', 'yyy'], 'b' => ['zzz']}
      end

    end

    describe "and there are some 'privateuse' subtags" do

      it "extracts 'privateuse' subtags into an Array" do
        @tag.recompose('en-GB-x-private-subtags')
        @tag.privateuse.should == ['private', 'subtags']
      end

      it "downcases 'privateuse' subtags" do
        @tag.recompose('en-GB-x-pRivate-SUBTAGS')
        @tag.privateuse.should == ['private', 'subtags']
      end

    end

  end

end

describe Rack::Acceptable::LanguageTag, "#singletons" do

  it "returns an ordered list of downcased singletons, when there are some extensions" do
    tag = Rack::Acceptable::LanguageTag.parse('en-b-xxx-a-yyy-zzz-c-www')
    tag.singletons.should == ['a', 'b', 'c']

    tag = Rack::Acceptable::LanguageTag.parse('en-b-xxx-A-yyy-zzz-C-www')
    tag.singletons.should == ['a', 'b', 'c']
  end

  it "returns nil, when there are no extensions" do
    tag = Rack::Acceptable::LanguageTag.parse('en')
    tag.singletons.should == nil
  end

end

describe Rack::Acceptable::LanguageTag, "#has_singleton?" do

  it "returns true when there's an associated extension" do
    tag = Rack::Acceptable::LanguageTag.parse('en-b-xxx-a-yyy-zzz-c-www')
    tag.should have_singleton 'a'
    tag.should have_singleton 'A'
    tag.should have_singleton 'b'
    tag.should have_singleton 'B'
  end

  it "returns false otherwise" do
    tag = Rack::Acceptable::LanguageTag.parse('en')
    tag.should_not have_singleton 'z'
    tag.should_not have_singleton 'Z'

    tag = Rack::Acceptable::LanguageTag.parse('en-b-xxx-a-yyy-zzz-c-www')
    tag.should_not have_singleton 'z'
    tag.should_not have_singleton 'Z'
  end

end

describe Rack::Acceptable::LanguageTag, "#has_variant?" do

  it "returns true when there's a variant passed" do
    tag = Rack::Acceptable::LanguageTag.parse('sl-rozaj-biske')
    tag.should have_variant 'rozaj'
    tag.should have_variant 'ROZAJ'
    tag.should have_variant 'biske'
    tag.should have_variant 'BISKE'
  end

  it "returns false otherwise" do
    tag = Rack::Acceptable::LanguageTag.parse('sl-rozaj-biske')
    tag.should_not have_variant 'nedis'
    tag.should_not have_variant 'NEDIS'
  end

end

describe Rack::Acceptable::LanguageTag, "#==" do

  it "returns true, when there's a LanguageTag and tags are equal" do
    tag1 = Rack::Acceptable::LanguageTag.parse('sl-rozaj-biske')
    tag2 = Rack::Acceptable::LanguageTag.parse('sl-rozaj-biske')
    tag3 = Rack::Acceptable::LanguageTag.parse('SL-ROZAJ-biske')
    (tag1 == tag1).should == true
    (tag1 == tag2).should == true
    (tag1 == tag3).should == true
    (tag2 == tag3).should == true
  end

  it "even if tags are malformed or invalid" do
    tag1 = Rack::Acceptable::LanguageTag.parse('en')
    tag2 = Rack::Acceptable::LanguageTag.parse('en')
    tag1.variants = ['boooooogus!']
    tag2.variants = ['boooooogus!']
    (tag1 == tag2).should == true
  end

  it "returns false otherwise" do
    tag1 = Rack::Acceptable::LanguageTag.parse('sl-rozaj-biske')
    tag2 = Rack::Acceptable::LanguageTag.parse('en-GB')

    (tag1 == tag2).should == false
    (tag1 == 'sl-rozaj-biske').should == false
    (tag1 == 42).should == false

    tag1 = Rack::Acceptable::LanguageTag.parse('sl-rozaj-biske')
    tag2 = Rack::Acceptable::LanguageTag.parse('sl-rozaj-biske')

    tag1.variants = ['boooooogus!']
    (tag1 == tag2).should == false
  end

end

describe Rack::Acceptable::LanguageTag, "#===" do

  it "returns true, when there's a LanguageTag and tags are equal" do
    tag1 = Rack::Acceptable::LanguageTag.parse('sl-rozaj-biske')
    tag2 = Rack::Acceptable::LanguageTag.parse('sl-rozaj-biske')
    tag3 = Rack::Acceptable::LanguageTag.parse('SL-ROZAJ-biske')
    (tag1 === tag1).should == true
    (tag1 === tag2).should == true
    (tag1 === tag3).should == true
    (tag2 === tag3).should == true
  end

  it "even if tags are malformed or invalid" do
    tag1 = Rack::Acceptable::LanguageTag.parse('en')
    tag2 = Rack::Acceptable::LanguageTag.parse('en')
    tag1.variants = ['boooooogus!']
    tag2.variants = ['boooooogus!']
    (tag1 === tag2).should == true
  end

  it "returns true, when there's an stringable thing (#to_str) which represents the same tag" do
    tag = Rack::Acceptable::LanguageTag.parse('sl-rozaj-biske')
    (tag === 'sl-rozaj-biske').should == true
    (tag === 'SL-ROZAJ-biske').should == true
  end

  it "even if the tag is malformed or invalid" do
    tag = Rack::Acceptable::LanguageTag.parse('en')
    tag.variants = ['boooooogus!']
    (tag === 'en-boooooogus!').should == true
  end

  it "returns false otherwise" do
    tag1 = Rack::Acceptable::LanguageTag.parse('sl-rozaj-biske')
    tag2 = Rack::Acceptable::LanguageTag.parse('sl-nedis')
    (tag1 === 'en-GB').should == false
    (tag1 === 42).should == false
    (tag1 === tag2).should == false

    tag1.variants = ['boooooogus!']
    (tag1 === tag2).should == false
  end

end

describe Rack::Acceptable::LanguageTag, "#valid?" do

  it "returns true, when LanguageTag is wellformed and valid" do
    Rack::Acceptable::LanguageTag.parse('zh-Latn-CN-variant1-a-extend1-x-wadegile-private1').should be_valid
    Rack::Acceptable::LanguageTag.parse('zh-Latn-CN-variant1-a-extend1-x-wadegile').should be_valid
    Rack::Acceptable::LanguageTag.parse('zh-Latn-CN-variant1-a-extend1').should be_valid
    Rack::Acceptable::LanguageTag.parse('zh-Latn-CN-variant1').should be_valid
    Rack::Acceptable::LanguageTag.parse('zh-Latn-CN').should be_valid
    Rack::Acceptable::LanguageTag.parse('zh-Latn').should be_valid
    Rack::Acceptable::LanguageTag.parse('zh').should be_valid
    Rack::Acceptable::LanguageTag.parse('zh-CN').should be_valid
  end

  it "returns false otherwise" do
    Rack::Acceptable::LanguageTag.new('zh', 'whateveryouwant').should_not be_valid
    Rack::Acceptable::LanguageTag.new('zh', nil, 'Latn', nil, 'tooooloooooong').should_not be_valid
    Rack::Acceptable::LanguageTag.new('zh', nil, 'Latn', nil, nil, {'a' => 'xxx', 'A' => 'zzz'}).should_not be_valid
    Rack::Acceptable::LanguageTag.new('zh', nil, 'Latn', nil, ['variant1', 'variant1']).should_not be_valid
  end

end

# EOF