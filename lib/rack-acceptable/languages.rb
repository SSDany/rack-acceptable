# encoding: binary

module Rack #:nodoc:
  module Acceptable #:nodoc:
    module Languages

      path = IO.read(::File.expand_path(::File.join(::File.dirname(__FILE__), 'data', 'grandfathered_language_tags.yml')))
      GRANDFATHERED_TAGS = YAML.load(path)

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

      PRIVATEUSE = 'x'.freeze
      GRANDFATHERED = 'i'.freeze

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
        ret.reject! { |tag,_| tag == PRIVATEUSE || tag == GRANDFATHERED }
        ret
      rescue
        raise ArgumentError, "Malformed Accept-Language header: #{header.inspect}"
      end

      #:stopdoc

      language    = '([a-z]{2,3}(?:-[a-z]{3})?|[a-z]{5,8})'
      script      = '(?:-([a-z]{4}))?'
      region      = '(?:-([a-z]{2}|\d{3}))?'
      variants    = '(?:-[a-z\d]{5,8}|-\d[a-z\d]{3})*'
      extensions  = '(?:-[a-wy-z\d]{1}(?:-[a-z\d]{2,8})+)*'
      privateuse  = '(?:-x(?:-[a-z\d]{1,8})+)?'

      #:startdoc:

      LANGTAG_EXTENDED_REGEX  = /^#{language}#{script}#{region}(?=#{variants}#{extensions}#{privateuse}$)/o.freeze
      LANGTAG_REGEX           = /^#{language}#{script}#{region}(#{variants})(?=#{extensions}#{privateuse}$)/o.freeze
      PRIVATEUSE_REGEX        = /^x(?:-[a-z\d]{1,8})+$/i.freeze
      GRANDFATHERED_REGEX     = /^i(?:-[a-z\d]{2,8}){1,2}$/.freeze

      def privateuse?(tag)
        PRIVATEUSE_REGEX === tag
      end

      def grandfathered?(tag)
        GRANDFATHERED_TAGS.key?(tag) || GRANDFATHERED_TAGS.key?(tag.downcase)
      end

      def irregular_grandfathered?(tag)
        return false unless tr = GRANDFATHERED_TAGS[tag] || GRANDFATHERED_TAGS[tag.downcase]
        tr.at(1)
      end

      # ==== Parameters
      # tag<String>:: The Language-Tag snippet.
      #
      # ==== Returns
      # Array or nil::
      #   It returns +nil+, when the Language-Tag passed:
      #   * does not conform the 'langtag' ABNF, i.e, malformed
      #     grandfathered or starts with 'x' singleton ('privateuse').
      #   * contains duplicate variants
      #   * contains duplicate singletons
      #
      #   Otherwise you'll get an +Array+ with:
      #   * primary subtag (as +String+, downcased),
      #   * extlang (as +String+) or +nil+,
      #   * script (as +String+, capitalized) or +nil+,
      #   * region (as +String+, upcased) or +nil+
      #   * downcased variants (+Array+, could be empty).
      #   * extensions (+Hash+, could be empty).
      #   * privateuse (+Array+, could be empty).
      #
      def extract_full_language_info(langtag)

        tag = langtag.downcase
        return nil unless LANGTAG_EXTENDED_REGEX === tag

        primary     = $1
        extlang     = nil
        script      = $2
        region      = $3
        components  = $'.split(Utils::HYPHEN_SPLITTER)
        components.shift

        primary, extlang = primary.split(Utils::HYPHEN_SPLITTER) if primary.include?(Const::HYPHEN)
        script.capitalize! if script
        region.upcase! if region

        singleton = nil
        extensions = {}
        variants = []

        while c = components.shift
          if c.size == 1
            break if c == PRIVATEUSE
            return nil if extensions.key?(c)
            extensions[singleton = c] = []
          elsif singleton
            extensions[singleton] << c
          else
            return nil if variants.include?(c)
            variants << c
          end
        end

        [primary, extlang, script, region, variants, extensions, components]
      end

      # ==== Parameters
      # tag<String>:: The Language-Tag snippet.
      #
      # ==== Returns
      # Array or nil::
      #   It returns +nil+, when the Language-Tag passed does not conform
      #   the 'langtag' ABNF, i.e, malformed, grandfathered or starts with
      #   'x' singleton ('privateuse').
      #
      #   Otherwise you'll get an +Array+ with:
      #   * primary subtag (as +String+, downcased),
      #   * extlang (as +String+, downcased) or +nil+,
      #   * script (as +String+, capitalized) or +nil+,
      #   * region (as +String+, upcased) or +nil+
      #   * downcased variants (+Array+, could be empty).
      #
      # ==== Notes
      # In most cases, it's quite enough. Take a look, for example, at
      # {'35-character recomendation'}[http://tools.ietf.org/html/rfc5646#section-4.6].
      # Anyway, there's #extract_full_language_info: it performs all
      # validations which could be performed without IANA registry, and
      # extracts all data which could be extracted from the 'langtag'.
      #
      def extract_language_info(langtag)
        tag = langtag.downcase
        return nil unless LANGTAG_REGEX === tag

        primary     = $1
        extlang     = nil
        script      = $2
        region      = $3
        variants    = $4.split(Utils::HYPHEN_SPLITTER)
        variants.shift

        primary, extlang = primary.split(Utils::HYPHEN_SPLITTER) if primary.include?(Const::HYPHEN)
        script.capitalize! if script
        region.upcase! if region

        [primary, extlang, script, region, variants]
      end

    end
  end
end

# EOF