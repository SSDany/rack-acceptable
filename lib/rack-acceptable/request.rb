require 'rack-acceptable/headers'

module Rack #:nodoc:
  module Acceptable
    class Request < Rack::Request
      include Rack::Acceptable::Headers

    end
  end
end

# EOF