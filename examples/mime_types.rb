require 'rubygems'
require 'rack'
require 'rack/acceptable'

class Request < Rack::Request
  include Rack::Acceptable::Media
end

env = Rack::MockRequest.env_for('/', 'HTTP_ACCEPT' => 
  'text/*;q=0.3, text/html;q=0.7, text/html;level=1, text/html;level=2;q=0.4, */*;q=0.5')

request = Request.new(env)
accepts = request.acceptable_media

p Rack::Acceptable::MIMETypes.qualify_mime_type('text/html;level=1',accepts) #=> 1.0
p Rack::Acceptable::MIMETypes.qualify_mime_type('text/html',accepts) #=> 0.7
p Rack::Acceptable::MIMETypes.qualify_mime_type('text/plain',accepts) #=> 0.3
p Rack::Acceptable::MIMETypes.qualify_mime_type('image/jpeg',accepts) #=> 0.5
p Rack::Acceptable::MIMETypes.qualify_mime_type('text/html;level=2',accepts) #=> 0.4
p Rack::Acceptable::MIMETypes.qualify_mime_type('text/html;level=3',accepts) #=> 0.7

# EOF