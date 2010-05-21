require File.expand_path(File.join(File.dirname(__FILE__), '..', 'helper'))

class Request < Rack::Request
  include Rack::Acceptable::Charsets
end

env = Rack::MockRequest.env_for('/','HTTP_ACCEPT_CHARSET' => 'utf-8')
request = Request.new(env)

p request.acceptable_charsets #=> [["utf-8", 1.0]]
p request.accept_charset?('utf-8') #=> true
p request.accept_charset?('UTF-8') #=> true
p request.accept_charset?('iso-8859-5') #=> false
p request.accept_charset?('iso-8859-1') #=> true

env = Rack::MockRequest.env_for('/','HTTP_ACCEPT_CHARSET' => 'utf-8,*;q=0')
request = Request.new(env)

p request.acceptable_charsets #=> [["utf-8", 1.0], ["*", 0.0]]
p request.accept_charset?('utf-8') #=> true
p request.accept_charset?('UTF-8') #=> true
p request.accept_charset?('iso-8859-5') #=> false
p request.accept_charset?('iso-8859-1') #=> false

# negotiation

env = Rack::MockRequest.env_for('/','HTTP_ACCEPT_CHARSET' => 'utf-8;q=0.9,iso-8859-5;q=0.8')
request = Request.new(env)

p request.preferred_charset_from("utf-8","iso-8859-5") #=> # "utf-8"
p request.preferred_charset_from("UTF-8","ISO-8859-5") #=> # "utf-8" # case-insensitivity
p request.preferred_charset_from("utf-8","iso-8859-1") #=> # "iso-8859-1"

env = Rack::MockRequest.env_for('/','HTTP_ACCEPT_CHARSET' => 'utf-8;q=1.0,iso-8859-5;q=0.8')
request = Request.new(env)

p request.preferred_charset_from("utf-8","iso-8859-5") #=> # "utf-8"
p request.preferred_charset_from("utf-8","iso-8859-1") #=> # "utf-8"

env = Rack::MockRequest.env_for('/','HTTP_ACCEPT_CHARSET' => 'utf-8;q=1.0,iso-8859-5;q=0.8,iso-8859-1;q=0.9')
request = Request.new(env)

p request.preferred_charset_from("utf-8","iso-8859-5") #=> # "utf-8"
p request.preferred_charset_from("utf-8","iso-8859-1") #=> # "utf-8"
p request.preferred_charset_from("iso-8859-5","iso-8859-1") #=> # "iso-8859-1"

# EOF