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
      # Result of parsing. An Array with wildcards / 'locales' (as +Strings+)
      # and associated quality factors (qvalues). Default qvalue is 1.0.
      #
      # ==== Notes
      # * Validation pattern is same as in #parse_accept_language
      # * It *downcases* primary tags (aka 'locales').
      # * It does *not* reduce the result, because of:
      #   - the difference between empty header and header composed with zero-qualified tags.
      #   - the *possible* difference between the 'best locale lookup' algorithms.
      #
      def parse_locales(header)
        Utils.parse_header(header.downcase, HTTP_ACCEPT_LANGUAGE_PRIMARY_TAGS_REGEX)
      rescue
        raise ArgumentError, "Malformed Accept-Language header: #{header.inspect}"
      end

      #:stopdoc

      language    = '([a-z]{2,8})'
      scrypt      = '(?:-([a-z]{4}))?'
      region      = '(?:-([a-z]{2}|\d{3}))?'
      variants    = '((?:-[a-z\d]{5,8}|-\d[a-z\d]{3})*)'
      extensions  = '(?:-[a-wy-z\d]{1}(?:-[a-z\d]{2,8})+)*'
      privateuse  = '(?:-x(?:-[a-z\d]{1,8})+)?'

      #:startdoc:

      LANGUAGE_TAG_REGEX                = /^#{language}#{scrypt}#{region}#{variants}#{extensions}#{privateuse}$/o.freeze
      LANGUAGE_TAG_PRIVATEUSE_REGEX     = /^x(?:-[a-z\d]{1,8})+$/.freeze
      LANGUAGE_TAG_GRANDFATHERED_REGEX  = /^i(?:-[a-z\d]{2,8}){1,2}$/.freeze

      def parse_extended_language_tag(tag)
        raise NotImplementedError
      end

      # ==== Parameters
      # tag<String>:: The Language-Tag snippet.
      #
      # ==== Raises
      # ArgumentError:: The Language Tag is malformed.
      #
      # ==== Returns
      # Array::
      #   Basic components of the Language-Tag:
      #   * when there's a full Language-Tag:
      #     - language (as +String+, downcased; aka 'locale')
      #     - script (as +String+, capitalized) or +nil+,
      #     - region (as +String+, upcased) or +nil+
      #     - downcased variants.
      #   * when there's a 'privateuse' or 'grandfathered' Language-Tag:
      #     - primary tag and subtags (downcased)
      #
      # ==== Notes
      # As of now, it *does not* perform *strong* validation of 'singlethons',
      # i.e, checks only ABNF conformance, and treats 'en-a-xxx-b-yyy-a-zzz' as
      # well-formed Language-Tag (but it's better than nothing, whether or no).
      #
      def parse_language_tag(tag)
        case t = tag.downcase
        when LANGUAGE_TAG_REGEX

          language  = $1
          script    = $2
          region    = $3
          variants  = $4

          script.capitalize! if script
          region.upcase! if region
          variants = variants && variants.split(Utils::HYPHEN_SPLITTER)[1..-1]
          variants ? [language, script, region, *variants] : [language, script, region]

        when LANGUAGE_TAG_GRANDFATHERED_REGEX, LANGUAGE_TAG_PRIVATEUSE_REGEX
          t.split(Utils::HYPHEN_SPLITTER)
        else
          raise ArgumentError, "Malformed Language-Tag: #{tag.inspect}"
        end
      end

    end
  end
end

# EOF