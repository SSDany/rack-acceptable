require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

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