require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Rack::Acceptable::Locales do

  before :all do
    @_request = Class.new(Rack::Request) { include Rack::Acceptable::Locales }
  end

  def fake_request(opts = {})
    env = Rack::MockRequest.env_for('/', opts)
    @_request.new(env)
  end

  describe "#acceptable_locales" do

    before :all do
      @parser = lambda { |thing| fake_request('HTTP_ACCEPT_LANGUAGE' => thing).acceptable_locales }
      @qvalue = lambda { |thing| fake_request('HTTP_ACCEPT_LANGUAGE' => thing).acceptable_locales.first.last }
      @sample = 'en'
      @message = %r{Malformed Accept-Language header}
    end

    describe "when parsing standalone snippet" do

      it_should_behave_like 'simple qvalues parser'

      it "raises an ArgumentError when there's a malformed Language-Range" do
        lambda { fake_request('HTTP_ACCEPT_LANGUAGE' => "veryverylongstring").acceptable_locales }.
        should raise_error ArgumentError, @message

        lambda { fake_request('HTTP_ACCEPT_LANGUAGE' => "en-gb-veryverylongstring").acceptable_locales }.
        should raise_error ArgumentError, @message

        lambda { fake_request('HTTP_ACCEPT_LANGUAGE' => "non_alpha").acceptable_locales }.
        should raise_error ArgumentError, @message

        lambda { fake_request('HTTP_ACCEPT_LANGUAGE' => "header=malformed;q=0.3").acceptable_locales }.
        should raise_error ArgumentError, @message

        lambda { fake_request('HTTP_ACCEPT_LANGUAGE' => "q=0.3").acceptable_locales }.
        should raise_error ArgumentError, @message
      end

      it "downcases locale" do
        qvalues = fake_request('HTTP_ACCEPT_LANGUAGE' => 'EN-GB;q=0.1').acceptable_locales
        qvalues.should == [['en', 0.1]]
      end

      it "ignores all language subtags except the primary one" do
        qvalues = fake_request('HTTP_ACCEPT_LANGUAGE' => 'en-GB;q=0.1').acceptable_locales
        qvalues.should == [['en', 0.1]]

        qvalues = fake_request('HTTP_ACCEPT_LANGUAGE' => 'sl-rozaj;q=0.5').acceptable_locales
        qvalues.should == [['sl', 0.5]]

        qvalues = fake_request('HTTP_ACCEPT_LANGUAGE' => 'en-GB-a-xxx-b-yyy-x-private;q=0.5').acceptable_locales
        qvalues.should == [['en', 0.5]]
      end

      it "ignores 'i' and 'x' singletons" do
        qvalues = fake_request('HTTP_ACCEPT_LANGUAGE' => 'x-pig-latin;q=0.1,en-GB;q=0.5').acceptable_locales
        qvalues.should == [['en', 0.5]]

        qvalues = fake_request('HTTP_ACCEPT_LANGUAGE' => 'en-GB;q=0.5, i-enochian;q=0.03').acceptable_locales
        qvalues.should == [['en', 0.5]]
      end

    end

    it_should_behave_like 'simple parser of 1#(element) lists'

  end

  describe "#preferred_locales" do

    it "returns a list of the user-preferred locales" do
      request = fake_request('HTTP_ACCEPT_LANGUAGE' => 'en-GB,sl-Latn-rozaj,i-enochian;q=0.03')
      request.preferred_locales.should == ['en', 'sl']

      request = fake_request('HTTP_ACCEPT_LANGUAGE' => 'en-GB,sl-Latn-rozaj,it;q=0')
      request.preferred_locales.should == ['en','sl']
    end

  end

  describe "#accept_locale?" do

    it "is able to check if locale acceptable" do
      request = fake_request('HTTP_ACCEPT_LANGUAGE' => 'en-GB,it;q=0')
      request.accept_locale?('it').should == false
      request.accept_locale?('en').should == true

      request = fake_request('HTTP_ACCEPT_LANGUAGE' => 'en-GB,*;q=0')
      request.accept_locale?('it').should == false
      request.accept_locale?('en').should == true

      request = fake_request('HTTP_ACCEPT_LANGUAGE' => 'en-GB,*;q=0.3')
      request.accept_locale?('it').should == true
      request.accept_locale?('en').should == true

      request = fake_request('HTTP_ACCEPT_LANGUAGE' => 'bogus!')
      request.accept_locale?('whatever').should == false

      request = fake_request('HTTP_ACCEPT_LANGUAGE' => 'en-GB;q=0,en-Latn;q=0.1')
      request.accept_locale?('en').should == true
    end

  end

  describe "#preferred_locale_from" do

    it "is able to lookup the preferred locale" do

      #ignores prohibited locales
      request = fake_request('HTTP_ACCEPT_LANGUAGE' => 'en-GB,da,it;q=0')
      request.preferred_locale_from('it','en').should == 'en'
      request.preferred_locale_from('it','da','en').should == 'en'

      #respects qvalues
      request = fake_request('HTTP_ACCEPT_LANGUAGE' => 'en-GB;q=0.3,da;q=0.5,*;q=0.1')
      request.preferred_locale_from('it','en').should == 'en'
      request.preferred_locale_from('it','da','en').should == 'da'
      request.preferred_locale_from('en','it').should == 'en'

      #respects qvalues
      request = fake_request('HTTP_ACCEPT_LANGUAGE' => 'en-GB;q=0.5,da;q=0.3,*;q=0.1')
      request.preferred_locale_from('it','en').should == 'en'
      request.preferred_locale_from('it','da','en').should == 'en'
      request.preferred_locale_from('en','it').should == 'en'

      #once again: respects qvalues and wildcards
      request = fake_request('HTTP_ACCEPT_LANGUAGE' => 'ru;q=1.0,en-GB;q=0.5,da;q=0.3,*;q=0.9')
      request.preferred_locale_from('it','en').should == 'it'
      request.preferred_locale_from('it','da','en').should == 'it'
      request.preferred_locale_from('en','it').should == 'it'
      request.preferred_locale_from('en','da').should == 'en'
      request.preferred_locale_from('ru','da').should == 'ru'

      request = fake_request('HTTP_ACCEPT_LANGUAGE' => 'ru;q=0.0,en-GB;q=0.0')
      request.preferred_locale_from('it','en').should == nil
      request.preferred_locale_from('ru','en').should == nil

      request = fake_request('HTTP_ACCEPT_LANGUAGE' => '*;q=0.3,ru;q=0.5,en-GB;q=0.5')
      request.preferred_locale_from('ru','en').should == 'ru'

      request = fake_request('HTTP_ACCEPT_LANGUAGE' => 'en-GB;q=0,en-Latn;q=0.1,ru;q=0,*')
      request.preferred_locale_from('en','ru').should == 'en'

      request = fake_request('HTTP_ACCEPT_LANGUAGE' => '*;q=0.3,ru;q=0.5,en-GB;q=0.5')
      request.preferred_locale_from().should == nil

    end

  end

end

# EOF