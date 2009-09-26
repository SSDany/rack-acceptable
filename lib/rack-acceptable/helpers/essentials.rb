module Rack #:nodoc:
  module Acceptable #:nodoc:
    module Helpers::Essentials

      def acceptable_encodings
        @_encodings ||= Encodings.parse_accept_encoding(@env[Const::ENV_HTTP_ACCEPT_ENCODING].to_s)
      end

      def acceptable_charsets
        @_charsets ||= Charsets.parse_accept_charset(@env[Const::ENV_HTTP_ACCEPT_CHARSET].to_s)
      end

    end
  end
end

# EOF