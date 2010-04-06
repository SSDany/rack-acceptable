require 'rubygems'
require 'rack'
require 'rack/acceptable'

class Request < Rack::Request
  include Rack::Acceptable::Media
end

env = Rack::MockRequest.env_for('/','HTTP_ACCEPT' => 'text/*')
request = Request.new(env)
p request.accept_media?('text/plain') #=> true

env = Rack::MockRequest.env_for('/','HTTP_ACCEPT' => 'text/plain;q=0,text/*')
request = Request.new(env)
p request.accept_media?('text/css') #=> true
p request.accept_media?('text/plain') #=> false
p request.accept_media?('video/quicktime') #=> false

env = Rack::MockRequest.env_for('/','HTTP_ACCEPT' => 'text/x-json;q=0.9,text/*;q=1.0')
request = Request.new(env)
p request.preferred_media_from('text/x-json','text/css') #=> "text/css"

env = Rack::MockRequest.env_for('/','HTTP_ACCEPT' => 'text/*,text/x-json')
request = Request.new(env)
p request.preferred_media_from('text/css','text/x-json') #=> "text/x-json"
p request.preferred_media_from('text/css','text/x-JSON') #=> "text/x-JSON"

env = Rack::MockRequest.env_for('/','HTTP_ACCEPT' => 'text/*,text/x-json,text/html;p=whatever')
request = Request.new(env)
p request.preferred_media_from('text/css','text/html') #=> "text/css"
p request.preferred_media_from('text/x-json','text/html;p=whatever') #=> "text/html;p=whatever" # most specific wins
p request.preferred_media_from('text/x-json','text/html;p=Whatever') #=> "text/x-json" # parameter values are case-sensitive.


env = Rack::MockRequest.env_for('/','HTTP_ACCEPT' => 'text/*,text/x-json')
request = Request.new(env)

# by_qvalue_only = false
p request.preferred_media_from('text/css','text/x-json', false) #=> "text/x-json"
p request.preferred_media_from('text/x-json','text/css', false) #=> "text/x-json"

# by_qvalue_only = true
p request.preferred_media_from('text/css','text/x-json', true) #=> "text/css" 
p request.preferred_media_from('text/x-json','text/css', true) #=> "text/x-json"

# EOF