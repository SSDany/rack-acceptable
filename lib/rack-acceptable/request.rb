require 'rack-acceptable/mixin/headers'
require 'rack-acceptable/mixin/media'

module Rack #:nodoc:
  module Acceptable #:nodoc:
    class Request < Rack::Request
      include Rack::Acceptable::Headers
      include Rack::Acceptable::Media

    end
  end
end

# EOF