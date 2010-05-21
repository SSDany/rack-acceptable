require File.expand_path(File.join(File.dirname(__FILE__), '..', 'helper'))

class Request < Rack::Request
  include Rack::Acceptable::Languages
end

env = Rack::MockRequest.env_for('/','HTTP_ACCEPT_LANGUAGE' => 'zh-Hans;q=0.9,en')
request = Request.new(env)
p request.acceptable_language_ranges #=> [["zh-Hans", 0.9], ["en", 1.0]]

p request.accept_language?("nl") #=> false
p request.accept_language?("en-US") #=> true
p request.accept_language?("en-GB") #=> false
p request.accept_language?("zh") #=> false # "Hans" script is required
p request.accept_language?("zh-Hans") #=> true

env = Rack::MockRequest.env_for('/','HTTP_ACCEPT_LANGUAGE' => 'de-de,sl-nedis')
request = Request.new(env)

p request.accept_language?("de-de") #=> true
p request.accept_language?("de-DE") #=> true
p request.accept_language?("de-Latn-de") #=> true
p request.accept_language?("de-Latf-DE") #=> true
p request.accept_language?("de-DE-x-goethe") #=> true
p request.accept_language?("de-Latn-DE-1996") #=> true
p request.accept_language?("de-Deva-DE") #=> true

p request.accept_language?("de") #=> false
p request.accept_language?("de-x-DE") #=> false
p request.accept_language?("de-Deva") #=> false

p request.accept_language?("sl-nedis") #=> true
p request.accept_language?("sl-Latn-nedis") #=> true
p request.accept_language?("sl-rozaj") #=> false

# EOF