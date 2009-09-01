module Rack #:nodoc:
  module Acceptable #:nodoc:
    module Helpers

      def acceptable_encodings
        Utils.parse_http_accept_encoding(@env[Const::ENV_HTTP_ACCEPT_ENCODING].to_s)
      end

    end
  end
end

# EOF