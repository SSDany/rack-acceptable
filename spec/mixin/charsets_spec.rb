require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Rack::Acceptable::Headers do

  before :all do
    @_request = Class.new(Rack::Request){ include Rack::Acceptable::Charsets }
  end

  def fake_request(options = {})
    env = Rack::MockRequest.env_for('/', options)
    @_request.new(env)
  end

  describe "#acceptable_charsets" do

    before :all do
      @parser = lambda { |thing| fake_request('HTTP_ACCEPT_CHARSET' => thing).acceptable_charsets }
      @qvalue = lambda { |thing| fake_request('HTTP_ACCEPT_CHARSET' => thing).acceptable_charsets.first.last }
      @sample = 'iso-8859-1'
      @message = %r{Malformed Accept-Charset header}
    end

    describe "when parsing standalone snippet" do

      it_should_behave_like 'simple qvalues parser'

      it "raises an ArgumentError when there's a malformed Charset" do
        lambda { fake_request('HTTP_ACCEPT_CHARSET' => "with\\separators?").acceptable_charsets }.
        should raise_error ArgumentError, @message

        lambda { fake_request('HTTP_ACCEPT_CHARSET' => "yet_another_with@separators").acceptable_charsets }.
        should raise_error ArgumentError, @message

        lambda { fake_request('HTTP_ACCEPT_CHARSET' => "header=malformed;q=0.3").acceptable_charsets }.
        should raise_error ArgumentError, @message

        lambda { fake_request('HTTP_ACCEPT_CHARSET' => "q=0.3").acceptable_charsets }.
        should raise_error ArgumentError, @message
      end

      it "downcases Charsets" do
        fake_request('HTTP_ACCEPT_CHARSET' => 'uNICODE-1-1;q=0.1').acceptable_charsets.should == [['unicode-1-1', 0.1]]
        fake_request('HTTP_ACCEPT_CHARSET' => 'Unicode-1-1;q=0.1').acceptable_charsets.should == [['unicode-1-1', 0.1]]
      end

    end

    it_should_behave_like 'simple HTTP_ACCEPT_CHARSET parser'
    it_should_behave_like 'simple parser of 1#(element) lists'

  end

  describe "#accept_charset?" do

    before :all do
      @helper = lambda { |chs, accepts| 
        request = fake_request('HTTP_ACCEPT_CHARSET' => accepts)
        request.accept_charset?(chs)
        }
    end

    it "checks, if the Charset passed acceptable" do

      @helper[  'iso-8859-1'  , '*;q=0.0'                     ].should == false
      @helper[  'iso-8859-1'  , 'iso-8859-1;q=0.0'            ].should == false
      @helper[  'iso-8859-1'  , 'iso-8859-1;q=0.0, *;q=1.0'   ].should == false
      @helper[  'utf-8'       , '*;q=0.0'                     ].should == false
      @helper[  'iso-8859-1'  , '*;q=1.0'                     ].should == true
      @helper[  'utf-8'       , '*;q=1.0'                     ].should == true

      accepts = 'iso-8859-5;q=0.3, windows-1252;q=0.5, utf-8; q=0.0'

      @helper[  'windows-1252'  , accepts ].should == true
      @helper[  'iso-8859-1'    , accepts ].should == true
      @helper[  'utf-8'         , accepts ].should == false
      @helper[  'bogus'         , accepts ].should == false

    end

    it "returns false if there's malformed Accept-Charset header" do
      @helper[  'iso-8859-1'  , 'baaang!@'                ].should == false
      @helper[  'iso-8859-1'  , 'iso-8859-1;q=malformed'  ].should == false
    end

  end

  describe "#preferred_charset_from" do

    it "passes incoming arguments into the Rack::Acceptable::Utils#detect_best_charset" do
      request = fake_request('HTTP_ACCEPT' => 'text/plain;q=0.7, text/*;q=0.7')

      Rack::Acceptable::Utils.should_receive(:detect_best_charset).with(['foo','bar'], request.acceptable_charsets).and_return(:the_best_one)
      request.preferred_charset_from('foo', 'bar').should == :the_best_one

      Rack::Acceptable::Utils.should_receive(:detect_best_charset).with(['foo','bar'], request.acceptable_charsets).and_return(:the_best_one)
      request.preferred_charset_from('foo', 'bar').should == :the_best_one

      Rack::Acceptable::Utils.should_receive(:detect_best_charset).with(['foo','bar'], request.acceptable_charsets).and_return(:the_best_one)
      request.preferred_charset_from('foo', 'bar').should == :the_best_one
    end

  end

end

# EOF