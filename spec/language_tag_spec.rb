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

shared_examples_for "simple langtag parser" do

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
    @parser[ 'de'               ].should == ['de', nil            , nil     , nil   , nil                 ]
    @parser[ 'fr'               ].should == ['fr', nil            , nil     , nil   , nil                 ]
    @parser[ 'de-DE'            ].should == ['de', nil            , nil     , 'DE'  , nil                 ]
    @parser[ 'en-US'            ].should == ['en', nil            , nil     , 'US'  , nil                 ]
    @parser[ 'zh-Hant'          ].should == ['zh', nil            , 'Hant'  , nil   , nil                 ]
    @parser[ 'zh-Hans'          ].should == ['zh', nil            , 'Hans'  , nil   , nil                 ]
    @parser[ 'zh-Hans-CN'       ].should == ['zh', nil            , 'Hans'  , 'CN'  , nil                 ]
    @parser[ 'sr-Latn-CS'       ].should == ['sr', nil            , 'Latn'  , 'CS'  , nil                 ]
    @parser[ 'sl-rozaj'         ].should == ['sl', nil            , nil     , nil   , ['rozaj' ]          ]
    @parser[ 'sl-nedis'         ].should == ['sl', nil            , nil     , nil   , ['nedis' ]          ]
    @parser[ 'sl-rozaj-biske'   ].should == ['sl', nil            , nil     , nil   , ['rozaj','biske']   ]
    @parser[ 'de-CH-1901'       ].should == ['de', nil            , nil     , 'CH'  , ['1901']            ]
    @parser[ 'sl-IT-nedis'      ].should == ['sl', nil            , nil     , 'IT'  , ['nedis']           ]
    @parser[ 'sl-Latn-IT-nedis' ].should == ['sl', nil            , 'Latn'  , 'IT'  , ['nedis']           ]
    @parser[ 'zh-cmn-Hans-CN'   ].should == ['zh', ['cmn']        , 'Hans'  , 'CN'  , nil                 ]
    @parser[ 'zh-yue-HK'        ].should == ['zh', ['yue']        , nil     , 'HK'  , nil                 ]
    @parser[ 'zh-yue'           ].should == ['zh', ['yue']        , nil     , nil   , nil                 ]
    @parser[ 'xr-lxs-qut'       ].should == ['xr', ['lxs', 'qut'] , nil     , nil   , nil                 ]
  end

  it "conveniently transforms essential components" do
    @parser[ 'DE'               ].should == ['de', nil            , nil     , nil   , nil       ]
    @parser[ 'de-de'            ].should == ['de', nil            , nil     , 'DE'  , nil       ]
    @parser[ 'zh-hAnt'          ].should == ['zh', nil            , 'Hant'  , nil   , nil       ]
    @parser[ 'sl-RoZaj'         ].should == ['sl', nil            , nil     , nil   , ['rozaj'] ]
    @parser[ 'sl-Latn-it-NEDIS' ].should == ['sl', nil            , 'Latn'  , 'IT'  , ['nedis'] ]
    @parser[ 'zh-Yue'           ].should == ['zh', ['yue']        , nil     , nil   , nil       ]
    @parser[ 'zh-YUE-HK'        ].should == ['zh', ['yue']        , nil     , 'HK'  , nil       ]
    @parser[ 'xr-LXS-quT'       ].should == ['xr', ['lxs', 'qut'] , nil     , nil   , nil       ]
  end

end

describe Rack::Acceptable::LanguageTag, ".extract_language_info" do

  before :all do
    @parser = lambda { |tag| Rack::Acceptable::LanguageTag.extract_language_info(tag) }
  end

  it_should_behave_like "simple langtag parser"

  it "returns nil when there's a 'privateuse' Language-Tag" do
    @parser[ 'x-private'            ].should == nil
    @parser[ 'x-private1-private2'  ].should == nil
  end

  it "returns nil when there's a 'grandfathered' Language-Tag" do
    @parser[ 'i-enochian'   ].should == nil
    @parser[ 'cel-gaulish'  ].should == nil
    @parser[ 'art-lojban'   ].should == nil
    @parser[ 'i-klingon'    ].should == nil
    @parser[ 'zh-min-nan'   ].should == nil
    @parser[ 'zh-xiang'     ].should == nil
  end

  it "returns nil when there's something malformed" do
    ::MALFORMED_LANGUAGE_TAGS.each { |tag| @parser[tag].should == nil }
  end

end

describe Rack::Acceptable::LanguageTag, ".parse" do

  it "returns the argument passed, if it is already a Rack::Acceptable::LanguageTag" do
    tag = Rack::Acceptable::LanguageTag.parse('de-DE')
    Rack::Acceptable::LanguageTag.parse(tag).should == tag
  end

  it "attempts to create the new LanguageTag using the #recompose method otherwise" do
    Rack::Acceptable::LanguageTag.should_receive(:new).and_return(tag = mock)
    tag.should_receive(:recompose).and_return(:tag)
    Rack::Acceptable::LanguageTag.parse('whatever').should == :tag
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

  describe "without arguments" do

    before :each do
      @tag.recompose('en-GB')
      @old_composition = @tag.instance_variable_get(:@composition)
    end

    it "returns self immediately if there are no changes" do
      @tag.region = 'GB'
      @tag.recompose
      @old_composition.should be_eql @tag.instance_variable_get(:@composition)
    end

    it "recomposes self if there are some changes" do
      @tag.region = 'US'
      @tag.recompose
      @old_composition.should_not be_eql @tag.instance_variable_get(:@composition)
    end

    it "blabla" do
      @tag.region = 'US'
      @tag.recompose('en-us')
      @old_composition.should be_eql @tag.instance_variable_get(:@composition)
    end

  end

  it "raises an ArgumentError when there's something malformed" do
    ::MALFORMED_LANGUAGE_TAGS.each do |tag|
      lambda { @tag.recompose(tag) }.
      should raise_error ArgumentError, %r{Malformed, grandfathered or 'privateuse' Language-Tag}
    end
  end

  it "raises an ArgumentError when the argument passed represents a 'grandfathered' Language-Tag" do
    lambda { @tag.recompose('zh-hakka') }.should raise_error ArgumentError, %r{Malformed, grandfathered or 'privateuse' Language-Tag}
    lambda { @tag.recompose('i-enochian') }.should raise_error ArgumentError, %r{Malformed, grandfathered or 'privateuse' Language-Tag}
  end

  it "raises an ArgumentError when the argument passed represents a 'privateuse' Language-Tag" do
    lambda { @tag.recompose('x-private') }.
    should raise_error ArgumentError, %r{Malformed, grandfathered or 'privateuse' Language-Tag}
  end

  describe "when the argument passed represents a 'langtag'" do

    it_should_behave_like "simple langtag parser"

    it "raises an ArgumentError when there's a repeated singleton (RFC 5646, sec. 2.2.9)" do
      lambda { @tag.recompose('en-GB-a-xxx-b-yyy-a-zzz-x-private') }.
      should raise_error ArgumentError, %r{Invalid langtag \(repeated singleton: "a"\)}

      lambda { @tag.recompose('en-GB-a-xxx-b-yyy-A-zzz-x-private') }.
      should raise_error ArgumentError, %r{Invalid langtag \(repeated singleton: "a"\)}
    end

    it "raises an ArgumentError when there's a repeated variant (RFC 5646, sec. 2.2.9)" do
      lambda { @tag.recompose('sl-IT-nedis-nedis') }.
      should raise_error ArgumentError, %r{Invalid langtag \(repeated variant: "nedis"\)}

      lambda { @tag.recompose('sl-IT-nedis-nEdIS') }.
      should raise_error ArgumentError, %r{Invalid langtag \(repeated variant: "nedis"\)}
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

  it "raises a TypeError, when the argument passed is not stringable (#to_str)" do
    tag = Rack::Acceptable::LanguageTag.new
    lambda { tag.recompose(42) }.should raise_error TypeError, %r{Can't convert Fixnum into String}
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

    tag.variants = ['Rozaj']
    tag.should have_variant 'rozaj'
    tag.should have_variant 'ROZAJ'
  end

  it "returns false otherwise" do
    tag = Rack::Acceptable::LanguageTag.parse('sl-rozaj-biske')
    tag.should_not have_variant 'nedis'
    tag.should_not have_variant 'NEDIS'
  end

end

describe Rack::Acceptable::LanguageTag, "#==" do

  it "returns true, when there's a Rack::Acceptable::LanguageTag and tags are equal" do
    tag1 = Rack::Acceptable::LanguageTag.parse('sl-rozaj-biske')
    tag2 = Rack::Acceptable::LanguageTag.parse('sl-rozaj-biske')
    tag3 = Rack::Acceptable::LanguageTag.parse('SL-ROZAJ-biske')
    (tag1 == tag1).should == true
    (tag1 == tag2).should == true
    (tag1 == tag3).should == true
    (tag2 == tag3).should == true
  end

  it "even if tags are invalid" do
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

  it "returns true, when there's a Rack::Acceptable::LanguageTag and tags are equal" do
    tag1 = Rack::Acceptable::LanguageTag.parse('sl-rozaj-biske')
    tag2 = Rack::Acceptable::LanguageTag.parse('sl-rozaj-biske')
    tag3 = Rack::Acceptable::LanguageTag.parse('SL-ROZAJ-biske')
    (tag1 === tag1).should == true
    (tag1 === tag2).should == true
    (tag1 === tag3).should == true
    (tag2 === tag3).should == true
  end

  it "even if tags are invalid" do
    tag1 = Rack::Acceptable::LanguageTag.parse('en')
    tag2 = Rack::Acceptable::LanguageTag.parse('en')
    tag1.variants = ['boooooogus!']
    tag2.variants = ['boooooogus!']
    (tag1 === tag2).should == true
  end

  it "returns true, when there's a stringable thing (#to_str) which represents the same tag" do
    tag = Rack::Acceptable::LanguageTag.parse('sl-rozaj-biske')
    (tag === 'sl-rozaj-biske').should == true
    (tag === 'SL-ROZAJ-biske').should == true
  end

  it "even if the tag is invalid" do
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

  it "returns true, when self is valid" do
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

describe Rack::Acceptable::LanguageTag, "#has_prefix?" do

  describe "when self is a valid Language-Tag" do

    it "returns true, when the thing passed is a valid prefix for self" do
      tag = Rack::Acceptable::LanguageTag.parse('de-DE-1996-a-xxx-b-yyy-x-private')
      tag.has_prefix?('de-DE-1996-a-xxx').should == true
      tag.has_prefix?('de-DE-1996').should == true
      tag.has_prefix?('de-DE').should == true

      tag.has_prefix?(Rack::Acceptable::LanguageTag.parse('de-DE-1996-a-xxx')).should == true
      tag.has_prefix?(Rack::Acceptable::LanguageTag.parse('de-DE-1996')).should == true
      tag.has_prefix?(Rack::Acceptable::LanguageTag.parse('de-DE')).should == true
    end

    it "returns false otherwise" do
      tag = Rack::Acceptable::LanguageTag.parse('de-DE-1996-a-xxx-b-yyy-x-private')
      tag.has_prefix?('de-Latn-DE').should == false
      tag.has_prefix?('bogus!').should == false
      tag.has_prefix?(42).should == false
    end

  end

  it "returns false, when self is not valid" do
    tag = Rack::Acceptable::LanguageTag.new('de', 'bogus!')
    tag.has_prefix?('de').should == false
    tag.has_prefix?(Rack::Acceptable::LanguageTag.new('de')).should == false
  end

end

describe Rack::Acceptable::LanguageTag, "#matched_by_extended_range?" do

  describe "when self is a valid Language-Tag" do

    before :all do
      @helper = lambda { |l,r| Rack::Acceptable::LanguageTag.parse(l).matched_by_extended_range?(r) }
    end

    it "returns true, when self matches the Language-Range passed" do
      @helper[ 'de'             , 'de'      ].should == true
      @helper[ 'de'             , '*'       ].should == true
      @helper[ 'de-DE'          , 'de-DE'   ].should == true
      @helper[ 'de-DE'          , 'de-de'   ].should == true
      @helper[ 'de-DE'          , 'de-*-DE' ].should == true
      @helper[ 'de-Latn-DE'     , 'de-DE'   ].should == true
      @helper[ 'de-Latn-DE'     , 'de-*-DE' ].should == true
      @helper[ 'de-DE-x-goethe' , 'de-DE'   ].should == true
      @helper[ 'de-DE-x-goethe' , 'de-*-DE' ].should == true
      @helper[ 'de-DE-x-goethe' , '*'       ].should == true
    end

    it "returns false otherwise" do
      @helper[ 'de-x-DE'  , 'de-DE' ].should == false
      @helper[ 'de'       , 'de-DE' ].should == false
    end

  end

  it "returns false, when self is not valid" do
    tag = Rack::Acceptable::LanguageTag.new('de', 'bogus!')
    tag.matched_by_extended_range?('de-bogus!').should == false
    tag.matched_by_extended_range?('de').should == false
  end

end

describe Rack::Acceptable::LanguageTag, "#nicecased" do

  it "recomposes the LanguageTag first" do
    tag = Rack::Acceptable::LanguageTag.parse('ZH-YUE-hk')
    tag.should_receive(:recompose)
    tag.nicecased
  end

  it "returns the 'nicecased' form of the LanguageTag, if recomposition was successful" do
    tag = Rack::Acceptable::LanguageTag.parse('ZH-YUE-hk')
    tag.nicecased.should == 'zh-yue-HK'
    tag = Rack::Acceptable::LanguageTag.parse('sl-latN-it-NEDIS')
    tag.nicecased.should == 'sl-Latn-IT-nedis'
    tag = Rack::Acceptable::LanguageTag.parse('sl-latN-it-NEDIS-B-YYY-A-XXX-ZZZ-X-A-b')
    tag.nicecased.should == 'sl-Latn-IT-nedis-a-xxx-zzz-b-yyy-x-a-b'
  end

end

describe Rack::Acceptable::LanguageTag, ".length" do

  it "does not perform recomposition" do
    tag = Rack::Acceptable::LanguageTag.parse('zh-yue-hk')
    tag.should_not_receive(:recompose)
    tag.length.should == 3
  end

  it "calculates the number of subtags in the Language-Tag" do
    tag = Rack::Acceptable::LanguageTag.parse('zh-yue-hk')
    tag.length.should == 3
    tag = Rack::Acceptable::LanguageTag.parse('sl-latn-it-nedis')
    tag.length.should == 4
    tag = Rack::Acceptable::LanguageTag.parse('sl-latn-it-nedis-a-xxx-b-yyy-zzz')
    tag.length.should == 9
    tag = Rack::Acceptable::LanguageTag.parse('sl-latn-it-nedis-a-xxx-b-yyy-zzz-x-a-b')
    tag.length.should == 12
  end

end

# EOF