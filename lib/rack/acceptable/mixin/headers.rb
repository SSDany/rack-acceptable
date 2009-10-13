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
          Utils::HTTP_ACCEPT_ENCODING_REGEX)
      rescue
        raise ArgumentError,
        "Malformed Accept-Encoding header: #{env[Const::ENV_HTTP_ACCEPT_ENCODING].inspect}"
      end

      # ==== Returns
      # An Array with wildcards / *downcased* Charsets and
      # associated quality factors (qvalues). Default qvalue is 1.0.
      #
      # ==== Raises
      # ArgumentError::
      #   Syntax of the Accept-Charset request-header is bad.
      #   For example, one of Charsets is not a 'token',
      #   one of quality factors is malformed etc.
      #
      def acceptable_charsets
        Utils.parse_header(
          env[Const::ENV_HTTP_ACCEPT_CHARSET].to_s.downcase,
          Utils::HTTP_ACCEPT_CHARSET_REGEX)
      rescue
        raise ArgumentError,
        "Malformed Accept-Charset header: #{env[Const::ENV_HTTP_ACCEPT_CHARSET].inspect}"
      end

      # ==== Returns
      # An Array with wildcards / Language-Tags (as +Strings+)
      # and associated quality factors (qvalues). Default qvalue is 1.0.
      #
      # ==== Raises
      # ArgumentError::
      #   Syntax of the Accept-Language request-header is bad.
      #   For example, one of Language-Ranges is not in a RFC 'Language-Range'
      #   pattern, one of quality factors is malformed etc.
      #
      # ==== Notes
      # * It uses {Extended Language-Range pattern}[http://tools.ietf.org/html/rfc4647#section-2.2].
      # * It does *not* perform 'convenient transformations' (downcasing of primary tags etc).
      #   In other words, it parses Accept-Language header in unpretentious manner.
      #
      def acceptable_language_ranges
        Utils.parse_header(
          env[Const::ENV_HTTP_ACCEPT_LANGUAGE].to_s,
          Utils::HTTP_ACCEPT_LANGUAGE_REGEX)
      rescue
        raise ArgumentError,
        "Malformed Accept-Language header: #{env[Const::ENV_HTTP_ACCEPT_LANGUAGE].inspect}"
      end

      # ==== Returns
      # An Array with Media-Ranges (as +Strings+) / wildcards and
      # associated qvalues. Default qvalue is 1.0.
      #
      # ==== Raises
      # ArgumentError::
      #   There's a malformed qvalue in header.
      #
      def acceptable_media_ranges
        Utils.extract_qvalues(env[Const::ENV_HTTP_ACCEPT].to_s)
      rescue
        raise ArgumentError,
        "Malformed Accept header: #{env[Const::ENV_HTTP_ACCEPT].inspect}"
      end

    end
  end
end

# EOF