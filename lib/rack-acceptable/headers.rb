module Rack #:nodoc:
  module Acceptable #:nodoc:
    module Headers

      # ==== Returns
      # Result of parsing. An Array with wildcards / *downcased* Content-Codings
      # and associated quality factors (qvalues). Default qvalue is 1.0.
      #
      # ==== Raises
      # ArgumentError::
      #   Syntax of the Accept-Encoding request-header is bad.
      #   For example, one of Content-Codings is not a 'token',
      #   one of quality factors is malformed etc.
      #
      def http_accept_encoding
        Utils.parse_header(
          env[Const::ENV_HTTP_ACCEPT_ENCODING].to_s.downcase,
          Utils::HTTP_ACCEPT_ENCODING_REGEX)
      rescue
        raise ArgumentError,
        "Malformed Accept-Encoding header: #{env[Const::ENV_HTTP_ACCEPT_ENCODING].inspect}"
      end

      # ==== Returns
      # Result of parsing, an Array with wildcards / *downcased* Charsets and
      # associated quality factors (qvalues). Default qvalue is 1.0.
      #
      # ==== Raises
      # ArgumentError::
      #   Syntax of the Accept-Charset request-header is bad.
      #   For example, one of Charsets is not a 'token',
      #   one of quality factors is malformed etc.
      #
      def http_accept_charset
        Utils.parse_header(
          env[Const::ENV_HTTP_ACCEPT_CHARSET].to_s.downcase,
          Utils::HTTP_ACCEPT_CHARSET_REGEX)
      rescue
        raise ArgumentError,
        "Malformed Accept-Charset header: #{env[Const::ENV_HTTP_ACCEPT_CHARSET].inspect}"
      end

      # ==== Returns
      # Result of parsing. An Array with wildcards / Language-Tags (as +Strings+)
      # and associated quality factors (qvalues). Default qvalue is 1.0.
      #
      # ==== Raises
      # ArgumentError::
      #   Syntax of the Accept-Language request-header is bad.
      #   For example, one of Language-Ranges is not in a RFC 'Language-Range'
      #   pattern, one of quality factors is malformed etc.
      #
      # ==== Notes
      # * It uses {Basic Language-Range pattern}[http://tools.ietf.org/html/rfc4647#section-2.1].
      # * It does *not* perform 'convenient transformations' (downcasing of primary tags etc).
      #   In other words, it parses Accept-Language header in unpretentious manner.
      #
      def http_accept_language
        Utils.parse_header(
          env[Const::ENV_HTTP_ACCEPT_LANGUAGE].to_s,
          Utils::HTTP_ACCEPT_LANGUAGE_REGEX)
      rescue
        raise ArgumentError,
        "Malformed Accept-Language header: #{env[Const::ENV_HTTP_ACCEPT_LANGUAGE].inspect}"
      end

      # ==== Returns
      # Result of parsing, an Array with completely parsed MIME-Types
      # (incl. qvalues and accept-extensions). Default qvalue is 1.0.
      #
      # ==== Raises
      # ArgumentError::
      #   Syntax of the The Accept request-header is bad.
      #   For example, one of Media-Ranges is not in a RFC 'Media-Range'
      #   pattern (type or subtype is invalid, or there's something like "*/foo")
      #   or, at last, one of MIME-Types has malformed qvalue.
      #
      def http_accept
        header = env[Const::ENV_HTTP_ACCEPT].to_s
        header.strip.split(Utils::COMMA_WS_SPLITTER).map! { |entry| MIMETypes.parse_mime_type(entry) }
      end

    end
  end
end

# EOF