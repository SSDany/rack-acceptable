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
        ret = Utils.parse_header(header.downcase, HTTP_ACCEPT_LANGUAGE_PRIMARY_TAGS_REGEX)
        ret.reject! { |tag,_| tag == PRIVATEUSE || tag == GRANDFATHERED }
        ret
      rescue
        raise ArgumentError, "Malformed Accept-Language header: #{header.inspect}"
      end

      #:stopdoc

      language    = '([a-z]{2,8})'
      scrypt      = '(?:-([a-z]{4}))?'
      region      = '(?:-([a-z]{2}|\d{3}))?'
      variants    = '(?:-[a-z\d]{5,8}|-\d[a-z\d]{3})*'
      extensions  = '(?:-[a-wy-z\d]{1}(?:-[a-z\d]{2,8})+)*'
      privateuse  = '(?:-x(?:-[a-z\d]{1,8})+)?'

      #:startdoc:

      LANGTAG_EXTENDED_REGEX  = /^#{language}#{scrypt}#{region}(#{variants}#{extensions}#{privateuse})$/o.freeze
      LANGTAG_REGEX           = /^#{language}#{scrypt}#{region}(#{variants})#{extensions}#{privateuse}$/o.freeze
      PRIVATEUSE_REGEX        = /^x(?:-[a-z\d]{1,8})+$/.freeze
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
      #   It returns +nil+, when the Language-Tag passed is malformed
      #   (incl. 'repeated snippet' situation), grandfathered of privateuse);
      #   otherwise you'll get an +Array+ with:
      #   * language (as +String+, downcased; aka 'locale')
      #   * script (as +String+, capitalized) or +nil+,
      #   * region (as +String+, upcased) or +nil+
      #   * downcased variants (+Array+, could be empty).
      #   * extensions (+Hash+, could be empty).
      #   * privateuse (+Array+, could be empty).
      #
      def extract_full_language_info(langtag)

        # RFC 4646, sec. 2.2.9:
        # Check that the tag and all of its subtags, including extension and
        # private use subtags, conform to the ABNF or that the tag is on the
        # list of grandfathered tags.
        #
        # Check that singleton subtags that identify extensions do not
        # repeat. For example, the tag "en-a-xx-b-yy-a-zz" is not well-
        # formed.

        language, script, region, components = extract_language_info(langtag, LANGTAG_EXTENDED_REGEX)
        return nil unless language

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
            variants << c
          end
        end

        [language, script, region, variants, extensions, components]
      end

      # ==== Parameters
      # tag<String>:: The Language-Tag snippet.
      # regex<Regexgp>:: Use it only if you know what you're doing.
      #
      # ==== Returns
      # Array or nil::
      #   It returns +nil+, when the Language-Tag passed does not
      #   conform the 'langtag' ABNF (malformed, grandfathered of privateuse);
      #   otherwise you'll get an +Array+ with:
      #   * language (as +String+, downcased; aka 'locale')
      #   * script (as +String+, capitalized) or +nil+,
      #   * region (as +String+, upcased) or +nil+
      #   * downcased variants (+Array+, could be empty).
      #
      def extract_language_info(langtag, regex = LANGTAG_REGEX)
        tag = langtag.downcase
        return nil unless regex === tag

        language    = $1
        script      = $2
        region      = $3
        components  = $4

        script.capitalize! if script
        region.upcase! if region
        components = components && components.split(Utils::HYPHEN_SPLITTER)[1..-1]
        [language, script, region, components || []]
      end

    end
  end
end

# EOF