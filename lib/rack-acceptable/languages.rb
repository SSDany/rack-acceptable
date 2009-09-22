# encoding: binary

module Rack #:nodoc:
  module Acceptable #:nodoc:
    module Languages

      module_function

      #--
      # RFC 2616, sec. 3.10:
      # White space is not allowed within the tag and all tags are case-
      # insensitive.
      #
      # RFC 4647, sec. 2.1
      # Note that the ABNF [RFC4234] in [RFC2616] is incorrect, since it disallows the
      # use of digits anywhere in the 'language-range' (see [RFC2616errata]).
      #++

      HTTP_ACCEPT_LANGUAGE_REGEX              = /^\s*(\*|[a-z]{1,8}(?:-[a-z\d]{1,8})*)#{Utils::QUALITY_PATTERN}\s*$/io.freeze
      HTTP_ACCEPT_LANGUAGE_PRIMARY_TAGS_REGEX = /^\s*(\*|[a-z]{1,8})(?:-[a-z\d]{1,8})*#{Utils::QUALITY_PATTERN}\s*$/o.freeze

      # ==== Parameters
      # header<String>:: The Accept-Language request-header.
      #
      # ==== Raises
      # ArgumentError::
      #   Syntax of the header passed is bad.
      #   For example, one of Language-Ranges is not in a RFC 'Language-Range'
      #   pattern, one of quality factors is malformed etc.
      #
      # ==== Returns
      # Result of parsing. An Array with wildcards / Language-Tags (as +Strings+)
      # and associated quality factors (qvalues). Default qvalue is 1.0.
      #
      # ==== Notes
      # * It uses {Basic Language-Range pattern}[http://tools.ietf.org/html/rfc4647#section-2.1].
      # * It does *not* perform 'convenient transformations' (downcasing of primary tags etc).
      #   In other words, it parses Accept-Language header in unpretentious manner.
      #
      def parse_accept_language(header)
        Utils.parse_header(header, HTTP_ACCEPT_LANGUAGE_REGEX)
      rescue
        raise ArgumentError, "Malformed Accept-Language header: #{header.inspect}"
      end

      # ==== Parameters
      # header<String>:: The Accept-Language request-header.
      #
      # ==== Raises
      # ArgumentError::
      #   Syntax of the header passed is bad.
      #   For example, one of Language-Ranges is not in a RFC 'Language-Range'
      #   pattern, one of quality factors is malformed etc.
      #
      # ==== Returns
      # Result of parsing. An Array with wildcards / primary subtags (as +Strings+)
      # and associated quality factors (qvalues). Default qvalue is 1.0.
      #
      # ==== Notes
      # * Validation pattern is same as in #parse_accept_language
      # * It *downcases* primary subtags.
      # * It does *not* reduce the result, because of:
      #   - the difference between empty header and header composed with zero-qualified Language-Tags.
      #   - the *possible* difference between the 'best locale lookup' algorithms.
      #
      def parse_locales(header)
        ret = Utils.parse_header(header.downcase, HTTP_ACCEPT_LANGUAGE_PRIMARY_TAGS_REGEX)
        ret.reject! { |l,_| l == LanguageTag::PRIVATEUSE || l == LanguageTag::GRANDFATHERED }
        ret
      rescue
        raise ArgumentError, "Malformed Accept-Language header: #{header.inspect}"
      end

    end
  end
end

# EOF