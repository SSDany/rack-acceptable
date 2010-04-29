require 'rack/acceptable/utils'

module Rack #:nodoc:
  module Acceptable #:nodoc:
    module Headers

      # ==== Returns
      # An Array with wildcards / *downcased* Content-Codings
      # and associated quality factors (qvalues). Default qvalue is 1.0.
      #
      # ==== Raises
      # ArgumentError::
      #   Syntax of the Accept-Encoding request-header is bad.
      #   For example, one of Content-Codings is not a 'token',
      #   one of quality factors is malformed etc.
      #
      def acceptable_encodings
        Utils.parse_header(
          env[Const::ENV_HTTP_ACCEPT_ENCODING].to_s.downcase,
          Utils::HTTP_ACCEPT_TOKEN_REGEX)
      rescue
        raise ArgumentError,
        "Malformed Accept-Encoding header: #{env[Const::ENV_HTTP_ACCEPT_ENCODING].inspect}"
      end

    end
  end
end

# EOF