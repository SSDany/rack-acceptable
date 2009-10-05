require 'rubygems'
require 'rack'
require 'rack/acceptable'

class Request < Rack::Request
  include Rack::Acceptable::Locales
end

env = Rack::MockRequest.env_for('/','HTTP_ACCEPT_LANGUAGE' => 'en-GB,sl-Latn-rozaj,i-enochian;q=0.8')
request = Request.new(env)
p request.preferred_locales # => ["en","sl"] # it's not the real locales, but "macrolanguages"

env = Rack::MockRequest.env_for('/','HTTP_ACCEPT_LANGUAGE' => 'en-GB;q=0,en-Latn;q=0.1,ru;q=0,*')
request = Request.new(env)
p request.accept_locale?('ru') #=> false
p request.accept_locale?('en') #=> true
p request.preferred_locale_from('en','ru') #=> "en"

env = Rack::MockRequest.env_for('/','HTTP_ACCEPT_LANGUAGE' => 'en-GB;q=0,en-Latn;q=0.1,zh-Hans;q=0.3,ru;q=0,*')
request = Request.new(env)
p request.preferred_locale_from('en','ru') #=> "en"
p request.preferred_locale_from('en','zh') #=> "zh"

# EOF