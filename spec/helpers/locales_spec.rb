require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

class RequestWithLocaleSupport < Rack::Request
  include Rack::Acceptable::Helpers::Locales
end

describe Rack::Acceptable::Helpers::Locales do

  def fake_request(opts = {})
    env = Rack::MockRequest.env_for('/', opts)
    RequestWithLocaleSupport.new(env)
  end

  it "knows about preferred locales" do
    request = fake_request('HTTP_ACCEPT_LANGUAGE' => 'en-GB,sl-Latn-rozaj,i-enochian;q=0.03')
    request.preferred_locales.should == ['en', 'sl']

    request = fake_request('HTTP_ACCEPT_LANGUAGE' => 'en-GB,sl-Latn-rozaj,it;q=0')
    request.preferred_locales.should == ['en','sl']
  end

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
  end

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

  end

end

# EOF