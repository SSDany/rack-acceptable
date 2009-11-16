require 'rubygems'
require 'rack'
require 'rack/utils'
require 'rack/acceptable'

Rack::Acceptable::MIMETypes.reset

class OnlyXML

  BODY = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<body>
  <provides>.xml</provides>
  <headers>
    <fake>%s</fake>
    <original>%s</original>
  </headers>
</body>
XML

  def call(env)
    body = BODY % env.values_at('HTTP_ACCEPT', 'rack-acceptable.fake_accept.original_HTTP_ACCEPT')
    [200, { 'Content-Length' => Rack::Utils.bytesize(body).to_s }, [body]]
  end

end

use Rack::Acceptable::FakeAccept
use Rack::Acceptable::Provides, %w(application/xml text/xml)
run OnlyXML.new

# EOF