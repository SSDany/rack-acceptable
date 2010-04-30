require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Rack::Acceptable::Languages do

  include SpecHelpers::FakeRequest

  before :all do
    fake_request! { include Rack::Acceptable::Languages }
  end

  describe "methods" do

    before :each do
      @request = fake_request('HTTP_ACCEPT_LANGUAGE' => '*')
    end

    it "provides the #acceptable_language_ranges method" do
      @request.should respond_to :acceptable_language_ranges
      lambda { @request.acceptable_language_ranges }.should_not raise_error
    end

    it "provides the #accept_language? method" do
      @request.should respond_to :accept_language?
      lambda { @request.accept_language?('en') }.should_not raise_error
    end

  end

  describe "#acceptable_language_ranges" do

    before :all do
      @parser = lambda { |thing| fake_request('HTTP_ACCEPT_LANGUAGE' => thing).acceptable_language_ranges }
      @qvalue = lambda { |thing| fake_request('HTTP_ACCEPT_LANGUAGE' => thing).acceptable_language_ranges.first.last }
      @sample = 'en-gb'
      @message = %r{Malformed Accept-Language header}
    end

    describe "when parsing standalone snippet" do

      it_should_behave_like 'simple qvalues parser'

      it "raises an ArgumentError when there's a malformed Language-Range" do
        lambda { fake_request('HTTP_ACCEPT_LANGUAGE' => "veryverylongstring").acceptable_language_ranges }.
        should raise_error ArgumentError, @message

        lambda { fake_request('HTTP_ACCEPT_LANGUAGE' => "en-gb-veryverylongstring").acceptable_language_ranges }.
        should raise_error ArgumentError, @message

        lambda { fake_request('HTTP_ACCEPT_LANGUAGE' => "non_alpha").acceptable_language_ranges }.
        should raise_error ArgumentError, @message

        lambda { fake_request('HTTP_ACCEPT_LANGUAGE' => "header=malformed;q=0.3").acceptable_language_ranges }.
        should raise_error ArgumentError, @message

        lambda { fake_request('HTTP_ACCEPT_LANGUAGE' => "q=0.3").acceptable_language_ranges }.
        should raise_error ArgumentError, @message
      end

    end

    it_should_behave_like 'simple HTTP_ACCEPT_LANGUAGE parser'
    it_should_behave_like 'simple parser of 1#(element) lists'

  end

  describe "#accept_language_range?" do

    describe "#accept_charset?" do

      before :all do
        @helper = lambda { |l, accepts| 
          request = fake_request('HTTP_ACCEPT_LANGUAGE' => accepts)
          request.accept_language?(l)
          }
      end

      it "checks, if the Language passed acceptable" do

        accepts = 'de-Deva,sl-latn-nedis-rozaj,en-a-xxx-b-yyy-zzz-x-a-b,ru;q=0'

        @helper[  'de-Deva'                           , accepts ].should == true
        @helper[  'de-Deva-DE'                        , accepts ].should == true
        @helper[  'de-Deva-DE-a-xxx-b-yyy-zzz-x-a-b'  , accepts ].should == true
        @helper[  'de-Deva-DE-a-sss-b-yyy-zzz-x-a-b'  , accepts ].should == true
        @helper[  'de-DE'                             , accepts ].should == false

        @helper[  'sl-latn-nedis-rozaj'               , accepts ].should == true
        @helper[  'sl-latn'                           , accepts ].should == false
        @helper[  'sl-latn-nedis'                     , accepts ].should == false

        @helper[  'en-a-xxx-b-yyy-zzz-x-a-b-c'        , accepts ].should == true
        @helper[  'en-a-xxx-b-yyy-zzz-x-a-b'          , accepts ].should == true
        @helper[  'en-a-xxx-b-yyy-zzz-www-x-a-b'      , accepts ].should == true
        @helper[  'en-a-xxx-b-yyy-www-x-a-b'          , accepts ].should == false
        @helper[  'en-a-xxx-b-yyy-zzz-x-a'            , accepts ].should == false
        @helper[  'en-a-xxx-b-yyy'                    , accepts ].should == false
        @helper[  'en-a-xxx-b-yyy-zzz'                , accepts ].should == false

        @helper[  'ru'                                , accepts ].should == false

      end

      it "returns false if there's malformed Accept-Language header" do
        @helper[  'en'  , 'baaang!@'        ].should == false
        @helper[  'en'  , 'en;q=malformed'  ].should == false
      end

    end

  end
end

# EOF