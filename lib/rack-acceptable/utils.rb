# encoding: binary

module Rack #:nodoc:
  module Acceptable #:nodoc:
    module Utils

      #--
      # http://tools.ietf.org/html/rfc2616#section-2.1
      # http://tools.ietf.org/html/rfc2616#section-2.2
      # http://tools.ietf.org/html/rfc2616#section-3.9
      #++

      QUALITY_REGEX       = /\s*;\s*q\s*=([^;\s]*)/i.freeze
      QUALITY_SPLITTER    = /\s*;\s*q\s*=/i.freeze
      QUALITY_PATTERN     = '\s*(?:;\s*q=(0|0\.\d{0,3}|1|1\.0{0,3}))?'.freeze

      QVALUE_REGEX        = /^0$|^0\.\d{0,3}$|^1$|^1\.0{0,3}$/.freeze
      QVALUE_DEFAULT      = 1.00
      QVALUE              = 'q'.freeze

      #--
      # RFC 2616, sec. 4.2:
      # message-header = field-name ":" [ field-value ]
      # field-name     = token
      # field-value    = *( field-content | LWS )
      # field-content  = <the OCTETs making up the field-value
      #                  and consisting of either *TEXT or combinations
      #                  of token, separators, and quoted-string>
      #
      # The field-content does not include any leading or trailing LWS:
      # linear white space occurring before the first non-whitespace character
      # of the field-value or after the last non-whitespace character of the
      # field-value. Such leading or trailing LWS MAY be removed without changing
      # the semantics of the field value. Any LWS that occurs between
      # field-content MAY be replaced with a single SP before interpreting the
      # field value or forwarding the message downstream.
      #
      #++

      PAIR_SPLITTER       = /\=/.freeze
      COMMA_SPLITTER      = /,\s*/.freeze
      SEMICOLON_SPLITTER  = /\s*;\s*/.freeze
      HYPHEN_SPLITTER     = /-/.freeze

      TOKEN = "A-Za-z0-9#{Regexp.escape('!#$&%\'*+-.^_`|~')}".freeze

      module_function

      # ==== Parameters
      # header<String>:: 
      #   The 'Accept' request-header, one of: 
      #   * Accept
      #   * Accept-Charset
      #   * Accept-Encoding
      #   * Accept-Language
      #
      # ==== Returns
      # Result of parsing. An Array with entries (as a +Strings+) and
      # associated quality factors (qvalues). Default qvalue is 1.0.
      #
      # ==== Raises
      # ArgumentError:: There's a malformed qvalue in header.
      #
      # ==== Notes
      # * It checks *only* quality factors (full syntactical inspection of
      #   the HTTP header is *not* a task of simple qvalues extractor).
      # * It does *not* perform additional operations (downcase etc),
      #   thereto a bunch of more specific parsers in Utils is provided.
      # * Also note, that construction like "deflate ; q=0.5" is *valid*
      #   (according to RFC 2616, sec. 2.1).
      #
      def extract_qvalues(header)
        header.split(COMMA_SPLITTER).map! { |entry|
          entry =~ QUALITY_REGEX
          thing, qvalue = $` || entry, $1
          raise ArgumentError, "Malformed quality factor: #{qvalue.inspect}" if qvalue && qvalue !~ QVALUE_REGEX
          [thing, qvalue ? qvalue.to_f : QVALUE_DEFAULT]
        }
      end

      HTTP_ACCEPT_SNIPPET_REGEX = /^([#{TOKEN}]+)#{QUALITY_PATTERN}\s*$/o.freeze

      #:stopdoc:

      def parse_header(header, regex)
        header.split(COMMA_SPLITTER).map! do |entry|
          raise unless regex === entry
          [$1, ($2 || QVALUE_DEFAULT).to_f]
        end
      end

      #:startdoc:

      # ==== Parameters
      # header<String>:: The Accept-Encoding request-header.
      #
      # ==== Raises
      # ArgumentError::
      #   Syntax of the header passed is bad.
      #   For example, one of Content-Codings is not a 'token',
      #   one of quality factors is malformed etc.
      #
      # ==== Returns
      # Result of parsing. An Array with wildcards / *downcased* Content-Codings
      # and associated quality factors (qvalues). Default qvalue is 1.0.
      #
      def parse_http_accept_encoding(header)
        parse_header(header.downcase, HTTP_ACCEPT_SNIPPET_REGEX)
      rescue
        raise ArgumentError, "Malformed Accept-Encoding header: #{header.inspect}"
      end

      # ==== Parameters
      # provides<Array>:: The Array of available Content-Codings. Could be empty.
      # accepts<Array>:: The Array of acceptable Content-Codings. Could be empty.
      #
      # ==== Returns
      # The best one of available Content-Codings (as a +String+) or +nil+.
      #
      # ==== Notes
      # Available and acceptable Content-Codings are supposed to be in same notations
      # (downcased/upcased or whenever you want). According to section 3.5 of RFC 2616,
      # Content-Codings are *case-insensitive*.
      #
      def detect_best_encoding(provides, accepts)
        return nil if provides.empty?

        identity = provides.include?(Const::IDENTITY) # presence of 'identity' in available content-codings
        identity_or_wildcard_prohibited = false # explicit 'identity;q=0' or '*;q=0'

        # RFC 2616, sec. 14.3:
        # If no Accept-Encoding field is present in a request, the server
        # MAY assume that the client will accept any content coding. In this
        # case, if "identity" is one of the available content-codings, then
        # the server SHOULD use the "identity" content-coding, unless it has
        # additional information that a different content-coding is meaningful
        # to the client.

        return Const::IDENTITY if identity && accepts.empty?
        #return (identity ? Const::IDENTITY : provides.first) if accepts.empty?

        # RFC 2616, sec. 14.3:
        # The "identity" content-coding is always acceptable, unless
        # specifically refused because the Accept-Encoding field includes
        # "identity;q=0", or because the field includes "*;q=0" and does
        # not explicitly include the "identity" content-coding. If the
        # Accept-Encoding field-value is empty, then only the "identity"
        # encoding is acceptable.

        candidates = []
        expansion = nil
        i = 0

        accepts.sort_by { |_,q| [-q,i+=1] }.each do |c,q|

          if q == 0
            identity_or_wildcard_prohibited = true if c == Const::IDENTITY || c == Const::WILDCARD
            next
          end

          if c == Const::WILDCARD
            expansion ||= provides - accepts.map { |c| c.first }
            candidates.concat expansion
          else
            candidates << c
          end

        end

        specifics = candidates & provides
        return specifics.first unless specifics.empty?
        return Const::IDENTITY if identity && !identity_or_wildcard_prohibited
        nil
      end

      # ==== Parameters
      # header<String>:: The Accept-Charset request-header.
      #
      # ==== Raises
      # ArgumentError::
      #   Syntax of the header passed is bad.
      #   For example, one of Charsets is not a 'token',
      #   one of quality factors is malformed etc.
      #
      # ==== Returns
      # Result of parsing, an Array with wildcards / *downcased* Charsets and
      # associated quality factors (qvalues). Default qvalue is 1.0.
      #
      def parse_http_accept_charset(header)
        parse_header(header.downcase, HTTP_ACCEPT_SNIPPET_REGEX)
      rescue
        raise ArgumentError, "Malformed Accept-Charset header: #{header.inspect}"
      end

      # ==== Parameters
      # provides<Array>:: The Array of available Charsets. Could be empty.
      # accepts<Array>:: The Array of acceptable Charsets. Could be empty.
      #
      # ==== Returns
      # The best one of available Charsets (as a +String+) or +nil+.
      #
      # ==== Notes
      # Available and acceptable Charsets are supposed to be in same notations
      # (downcased/upcased or whenever you want). According to section 3.4 of
      # RFC 2616, Charsets are *case-insensitive*.
      #
      def detect_best_charset(provides, accepts)
        return nil if provides.empty?

        # RFC 2616, sec 14.2:
        # If no Accept-Charset header is present, the default is that any
        # character set is acceptable. If an Accept-Charset header is present,
        # and if the server cannot send a response which is acceptable
        # according to the Accept-Charset header, then the server SHOULD send
        # an error response with the 406 (not acceptable) status code, though
        # the sending of an unacceptable response is also allowed.

        return provides.first if accepts.empty?

        expansion = nil
        candidates = []
        i = 0

        accepts << [Const::ISO_8859_1, 1.0] unless accepts.assoc(Const::ISO_8859_1) || accepts.assoc(Const::WILDCARD)

        accepts.sort_by { |_,q| [-q,i+=1] }.each do |c,q|

          next if q == 0

          if c == Const::WILDCARD

            # RFC 2616, sec 14.2:
            # The special value "*", if present in the Accept-Charset field,
            # matches every character set (including ISO-8859-1) which is not
            # mentioned elsewhere in the Accept-Charset field. If no "*" is present
            # in an Accept-Charset field, then all character sets not explicitly
            # mentioned get a quality value of 0, except for ISO-8859-1, which gets
            # a quality value of 1 if not explicitly mentioned.

            expansion ||= provides - accepts.map { |c,_| c }
            candidates.concat expansion
          else
            candidates << c
          end
        end

        specifics = candidates & provides
        return specifics.first unless specifics.empty?
        nil
      end

      #--
      # RFC 2616, sec. 3.10:
      # White space is not allowed within the tag and all tags are case-
      # insensitive.
      #
      # RFC 4647, sec. 2.1
      # Note that the ABNF [RFC4234] in [RFC2616] is incorrect, since it disallows the
      # use of digits anywhere in the 'language-range' (see [RFC2616errata]).
      #++

      HTTP_ACCEPT_LANGUAGE_REGEX              = /^(\*|[a-z]{1,8}(?:-[a-z\d]{1,8})*)#{QUALITY_PATTERN}\s*$/io.freeze
      HTTP_ACCEPT_LANGUAGE_PRIMARY_TAGS_REGEX = /^(\*|[a-z]{1,8})(?:-[a-z\d]{1,8})*#{QUALITY_PATTERN}\s*$/o.freeze

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
      def parse_http_accept_language(header)
        parse_header(header, HTTP_ACCEPT_LANGUAGE_REGEX)
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
      # * Validation pattern is same as in Utils#parse_http_accept_language
      # * It *downcases* primary tags (aka 'locales').
      # * It does *not* reduce the result, because of:
      #   - the difference between empty header and header composed with zero-qualified tags.
      #   - the *possible* difference between the 'best locale lookup' algorithms.
      #
      def parse_acceptable_locales(header)
        parse_header(header.downcase, HTTP_ACCEPT_LANGUAGE_PRIMARY_TAGS_REGEX)
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
      #   Result of parsing, an Array with the definitive language information:
      #   * language (as +String+, downcased)
      #   * script (as +String+, capitalized) or +nil+,
      #   * region (as +String+, upcased) or +nil+
      #   * tuple of downcased variants.
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
          variants = variants && variants.split(HYPHEN_SPLITTER)[1..-1]
          variants ? [language, script, region, *variants] : [language, script, region]

        when LANGUAGE_TAG_GRANDFATHERED_REGEX, LANGUAGE_TAG_PRIVATEUSE_REGEX
          t.split(HYPHEN_SPLITTER)
        else
          raise ArgumentError, "Malformed Language-Tag: #{tag.inspect}"
        end
      end

      # ==== Parameters
      # header<String>:: The Accept request-header.
      #
      # ==== Raises
      # ArgumentError::
      #   Syntax of the header passed is bad.
      #   For example, one of Media-Ranges is not in a RFC 'Media-Range'
      #   pattern (type or subtype is invalid, or there's something like "*/foo")
      #   or, at last, one of MIME-Types has malformed qvalue.
      #
      # ==== Returns
      # Result of parsing, an Array with completely parsed MIME-Types
      # (incl. qvalues and accept-extensions). Default qvalue is 1.0.
      #
      def parse_http_accept(header)
        header.split(COMMA_SPLITTER).map! { |entry| parse_media_range_and_qvalue(entry) }
      end

      MEDIA_RANGE_REGEX = /^([#{TOKEN}]+)\/([#{TOKEN}]+)\s*(?:;|$)/io.freeze

      #:stopdoc:

      def split_mime_type(thing)
        raise ArgumentError, "Malformed MIME-Type: #{thing}" unless thing =~ MEDIA_RANGE_REGEX

        type    = $1
        subtype = $2
        snippet = $'

        raise ArgumentError, "Malformed MIME-Type: #{thing}" if
          type == Const::WILDCARD &&
          subtype != Const::WILDCARD

        # RFC 2616, sec. 3.7:
        # The type, subtype, and parameter attribute names are case-
        # insensitive. Parameter values might or might not be case-sensitive,
        # depending on the semantics of the parameter name. Linear white space
        # (LWS) MUST NOT be used between the type and subtype, nor between an
        # attribute and its value. The presence or absence of a parameter might
        # be significant to the processing of a media-type, depending on its
        # definition within the media type registry.

        type.downcase!
        subtype.downcase!
        snippet.strip!

        return type, subtype, snippet
      end

      def parse_media_range_parameter(snippet)
        params = {}
        for pair in snippet.split(SEMICOLON_SPLITTER)
          k,v = pair.split(PAIR_SPLITTER,2)
          k.downcase!
          params[k] = v
        end
        params
      end

      #:startdoc:

      # ==== Parameters
      # thing<String>:: The MIME-Type snippet.
      #
      # ==== Returns
      # Array[String, String, Hash]::
      #   Media-Range of the MIME-Type: type, subtype and parameter (as a +Hash+).
      #
      # ==== Raises
      # Same things as Utils#split_mime_type.
      # In other words, it checks only type/subtype pair.
      #
      def parse_media_range(thing)
        thing =~ QUALITY_SPLITTER
        type, subtype, snippet = split_mime_type($` || thing)
        return type, subtype, parse_media_range_parameter(snippet)
      end

      # ==== Parameters
      # thing<String>:: The MIME-Type snippet (from the Accept request-header).
      #
      # ==== Returns
      # Array[String, String, Hash, Float]::
      #   Media-Range of the MIME-Type: type, subtype, parameter (as a +Hash+),
      #   and quality factor (default value: 1.0)
      #
      # ==== Raises
      # ArgumentError::
      #   MIME-Type has malformed quality factor, or
      #   type/subtype pair is not in a RFC 'Media-Range' pattern.
      #
      def parse_media_range_and_qvalue(thing)
        thing =~ QUALITY_REGEX
        range, qvalue = $` || thing, $1

        raise ArgumentError, "Malformed quality factor: #{qvalue.inspect}" if qvalue && qvalue !~ QVALUE_REGEX
        type, subtype, snippet = split_mime_type(range)
        return type, subtype, parse_media_range_parameter(snippet), (qvalue || QVALUE_DEFAULT).to_f
      end

      # ==== Parameters
      # thing<String>:: The MIME-Type snippet (from the Accept request-header).
      #
      # ==== Returns
      # Array[String, String, Hash, Float, Hash]::
      #   Media-Range (type, subtype and parameter, as a +Hash+), quality factor
      #   and accept-extension of the MIME-Type.
      #
      # ==== Raises
      # ArgumentError::
      #   MIME-Type has malformed quality factor, or
      #   type/subtype pair is not in a RFC 'Media-Range' pattern.
      #
      def parse_mime_type(thing)

        type, subtype, snippet = split_mime_type(thing)

        qvalue, params, accept_extension, has_qvalue = QVALUE_DEFAULT, {}, {}, false
        for pair in snippet.split(SEMICOLON_SPLITTER)
          k,v = pair.split(PAIR_SPLITTER,2)

          # RFC 2616, sec. 14.1:
          # Each media-range MAY be followed by one or more accept-params,
          # beginning with the "q" parameter for indicating a relative quality
          # factor. The first "q" parameter (if any) separates the media-range
          # parameter(s) from the accept-params. Quality factors allow the user
          # or user agent to indicate the relative degree of preference for that
          # media-range, using the qvalue scale from 0 to 1 (section 3.9). The
          # default value is q=1.

          if has_qvalue
            accept_extension[k] = v || true # token [ "=" ( token | quoted-string ) ] - i.e, "v" is OPTIONAL.
          else
            k.downcase!
            if k == QVALUE
              raise ArgumentError, "Malformed quality factor: #{v.inspect}" unless QVALUE_REGEX === v
              qvalue = v.to_f
              has_qvalue = true
            else
              params[k] = v
            end
          end

        end

        return type, subtype, params, qvalue, accept_extension
      end

      # ==== Parameters
      # type<String>:: Type, the first portion of the MIME-Type's media range.
      # subtype<String>:: Subtype, the second portion of the MIME-Type's media range.
      # params<Hash>:: Parameter, as a +Hash+; the third portion of the the MIME-Type's media range.
      # types<Array>:: The Array of MIME-Types to check against. MUST be *ordered* (by qvalue).
      #
      # ==== Returns
      # Float:: The quality factor (relative strength of the MIME-Type).
      #
      def qualify_mime_type(type, subtype, params, *types)
        weigh_mime_type(type, subtype, params, *types).first
      end

      # ==== Parameters
      # type<String>:: Type, the first portion of the MIME-Type's media range.
      # subtype<String>:: Subtype, the second portion of the MIME-Type's media range.
      # params<Hash>:: Parameter, as a +Hash+; the third portion of the the MIME-Type's media range.
      # types<Array>:: The Array of MIME-Types to check against. MUST be *ordered* (by qvalue).
      #
      # ==== Returns
      # Array[Float, Integer, Integer, Integer]::
      #   Quality factor, rate, specificity and negated index of the most relevant MIME-Type;
      #   i.e full relative weight of the MIME-Type.
      #
      def weigh_mime_type(type, subtype, params, *types)

        rate = 0
        specificity = -1
        quality = 0.00
        index = 0

        # RFC 2616, sec. 14.1:
        # Media ranges can be overridden by more specific media ranges or
        # specific media types. If more than one media range applies to a given
        # type, the most specific reference has precedence.
        # ...
        # The media type quality factor associated with a given type is
        # determined by finding the media range with the highest precedence
        # which matches that type.

        types.each_with_index do |(t,s,p,q),i|
          next unless ((tmatch = type == t) || t == Const::WILDCARD || type == Const::WILDCARD) &&
                      ((smatch = subtype == s) || s == Const::WILDCARD || subtype == Const::WILDCARD)

          # we should skip when:
          # - divergence: 
          #     * "text;html;a=2" against "text/html;a=1,text/*;a=1" etc
          #     * "text/html;b=1" or "text/html" against "text/html;a=1" etc,
          #       i.e, 'a' parameter is NECESSARY, but our MIME-Type does NOT contain it
          # - rate is lesser
          # - rates are equal, but sp(ecificity) is lesser or exactly the same

          r  = tmatch ? 10 : 0
          r += smatch ? 1  : 0
          next if r < rate

          sp = 0
          divergence = false

          p.each { |k,v|
            params.key?(k) && params[k] == v ? sp += 1 : (divergence = true; break)
          }

          next if divergence || (r == rate && sp <= specificity)
          specificity = sp
          rate = r
          quality = q
          index = -i
        end

        return quality, rate, specificity, index
      end

      # ==== Parameters
      # provides<Array>:: The Array of available MIME-Types (snippets). Could be empty.
      # accepts<String>:: The Array of acceptable MIME-Types. Could be empty.
      #
      # ==== Returns
      # The best one of available MIME-Types or +nil+.
      #
      # ==== Raises
      # Same things as Utils#parse_media_range.
      #
      # ==== Notes
      # Acceptable MIME-Types are supposed to have *downcased* and *well-formed*
      # type, subtype, parameter's keys (according to RFC 2616, enumerated things
      # are case-insensitive too), and *sensible* qvalues ("real numbers in the
      # range 0 through 1, where 0 is the minimum and 1 the maximum value").
      #
      def detect_best_mime_type(provides, accepts)
        return nil if provides.empty?
        return provides.first if accepts.empty?

        i = 0
        accepts = accepts.sort_by { |t| [-t.at(3), i+=1] }

        candidate = provides.map { |snippet|
          type, subtype, params = parse_media_range(snippet)
          weigh_mime_type(type, subtype, params, *accepts) << snippet
        }.max_by { |t| t[0..3] } #instead of #sort

        candidate.at(0) == 0 ? nil : candidate.last
      end

      def detect_acceptable_mime_type(provides, header)
        return nil if provides.empty?

        i = 0
        accepts = extract_qvalues(header).select{ |_,q| q != 0 }.sort_by { |_,q| [-q,i+=1] }
        accepts.map! { |t,_| t  }

        candidates = accepts & provides
        return candidates.first unless candidates.empty?
        return provides.first if accepts.include?(Const::MEDIA_RANGE_WILDCARD)
        nil
      end

      def blank?(s)
        s.empty? || s.strip.empty?
      end

    end
  end
end

# EOF