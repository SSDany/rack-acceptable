# encoding: binary

module Rack #:nodoc:
  module Acceptable #:nodoc:
    module Utils

      # http://tools.ietf.org/html/rfc2616#section-2.2

      SEPARATORS = "()<>@,;:\\\"/[]?={} \t".freeze
      UNWISE = Regexp.escape(SEPARATORS).freeze

      # TODO:
      # \x0-\x1f\x7f\x80-\xff i.e CONTROLS and non-US-ASCII
      # * check with 1.9 (applicable?)
      # * whose task is it?

      QUALITY_REGEX = /\s*;\s*q=([^;\s]*)/i.freeze

      #http://tools.ietf.org/html/rfc2616#section-3.9
      #http://tools.ietf.org/html/rfc2616#section-2.1

      QVALUE_REGEX = /^0$|^0\.\d{0,3}$|^1$|^1\.0{0,3}$/.freeze
      QVALUE_DEFAULT = 1.00
      QVALUE = 'q'.freeze

      HTTP_ACCEPT_SNIPPET_REGEX = /^([^#{UNWISE}]+)\s*(?:;\s*q=(0|0\.\d{0,3}|1|1\.0{0,3}))?$/io.freeze

      module_function

      # ==== Parameters
      # header<String>:: The 'Accept' request-header, one of: Accept,
      # Accept-Charset, Accept-Encoding, Accept-Language.
      #
      # ==== Returns
      # Array:: Result of parsing. an Array with entries and associated quality
      # factors (qvalues). Default qvalue is 1.0.
      #
      # ==== Raises
      # ArgumentError:: There's a malformed qvalue in header.
      #
      # ==== Notes
      # It checks ONLY quality factors (full syntactical inspection of the
      # HTTP header is NOT a task of simple qvalues extractor).
      # It DOES NOT perform additional operations (downcase etc), thereto
      # a bunch of more specific parsers in Utils is provided.
      #
      # Also note, that construction like "deflate ; q=0.5" is VALID.
      # Take a look at RFC 2616, sec. 2.1:
      # The grammar described by this specification is word-based. Except
      # where noted otherwise, linear white space (LWS) can be included
      # between any two adjacent words (token or quoted-string), and
      # between adjacent words and separators, without changing the
      # interpretation of a field. At least one delimiter (LWS and/or
      # separators) MUST exist between any two tokens (for the definition
      # of "token" below), since they would otherwise be interpreted as a
      # single token.
      #
      def extract_qvalues(header)
        header.split(Const::COMMA_SPLITTER).map! { |entry|
          entry =~ QUALITY_REGEX
          thing, qvalue = $` || entry, $1
          raise ArgumentError, "Malformed quality factor: #{qvalue.inspect}" if qvalue && qvalue !~ QVALUE_REGEX
          [thing, qvalue ? qvalue.to_f : QVALUE_DEFAULT]
        }
      end

      # ==== Parameters
      # header<String>:: The Accept-Encoding request-header.
      #
      # ==== Raises
      # ArgumentError:: Syntax of the header passed is bad. For example,
      # one of Content-Codings is not a RFC 'token', one of quality factors
      # is malformed etc.
      #
      # ==== Returns
      # Array:: Result of parsing. An Array with (downcased) Content-Codings
      # and associated quality factors (qvalues). Default qvalue is 1.0.
      #
      def parse_http_accept_encoding(header)
        header.split(Const::COMMA_SPLITTER).map! { |entry|
          raise ArgumentError, "Malformed Accept-Encoding header: #{entry.inspect}" unless
          HTTP_ACCEPT_SNIPPET_REGEX === entry

          # RFC 2616, sec 3.5:
          # All content-coding values are case-insensitive.

          thing = $1
          thing.downcase!
          [thing, ($2 || QVALUE_DEFAULT).to_f ]
        }
      end

      # ==== Parameters
      # provides<Array>:: The Array of available Content-Codings. Could be empty.
      # accepts<Array>:: The Array of acceptable Content-Codings. Could be empty.
      #
      # ==== Returns
      # String, nil:: The best one of available Content-Codings or nil.
      #
      # ==== Notes
      # Available and acceptable Content-Codings are supposed to be in same notations
      # (downcased/upcased or whenever you want). According to RFC 2616, Content-Codings
      # are case-insensitive.
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

        return (identity ? Const::IDENTITY : provides.first) if accepts.empty?

        # RFC 2616, sec. 14.3:
        # The "identity" content-coding is always acceptable, unless
        # specifically refused because the Accept-Encoding field includes
        # "identity;q=0", or because the field includes "*;q=0" and does
        # not explicitly include the "identity" content-coding. If the
        # Accept-Encoding field-value is empty, then only the "identity"
        # encoding is acceptable.

        candidates, expansion = [], nil
        accepts.sort_by{ |_,q| -q }.each do |c,q|

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
      # ArgumentError:: Syntax of the header passed is bad. For example,
      # one of Content-Codings is not a RFC 'token', one of quality factors
      # is malformed etc.
      #
      # ==== Returns
      # Array:: Result of parsing, an Array with (downcased) Charsets and
      # associated quality factors (qvalues). Default qvalue is 1.0.
      #
      def parse_http_accept_charset(header)
        header.split(Const::COMMA_SPLITTER).map! { |entry|
          raise ArgumentError, "Malformed Accept-Charset header: #{entry.inspect}" unless
          HTTP_ACCEPT_SNIPPET_REGEX === entry

          # RFC 2616, sec 3.4:
          # HTTP character sets are identified by case-insensitive tokens.

          thing = $1
          thing.downcase!
          [thing, ($2 || QVALUE_DEFAULT).to_f]
        }
      end

      # ==== Parameters
      # provides<Array>:: The Array of available Charsets. Could be empty.
      # accepts<Array>:: The Array of acceptable Charsets. Could be empty.
      #
      # ==== Returns
      # String, nil:: The best one of available Charsets or nil.
      #
      # ==== Notes
      # Available and acceptable Charsets are supposed to be in same notations
      # (downcased/upcased or whenever you want). According to RFC 2616, Charsets
      # are case-insensitive.
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

        accepts << [Const::ISO_8859_1, 1.0] unless accepts.assoc(Const::ISO_8859_1) || accepts.assoc(Const::WILDCARD)

        accepts.sort_by{|_,q| -q}.each do |c,q|

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

      HTTP_ACCEPT_LANGUAGE_REGEX = /^(\*|[a-z]{1,8}(?:-[a-z]{1,8})*)\s*(?:;\s*q=(0|0\.\d{0,3}|1|1\.0{0,3}))?$/i.freeze

      # ==== Parameters
      # header<String>:: The Accept-Language request-header.
      # tags<Integer>:: Optional number of Language-Tags to extract.
      #
      # ==== Raises
      # ArgumentError:: Syntax of the header passed is bad. For example,
      # one of Language-Ranges is not in a RFC 'Language-Range' pattern, one of
      # quality factors is malformed etc.
      #
      # ==== Returns
      # Array:: Result of parsing. the flattened Array with (downcased)
      # Language-Ranges and associated quality factors (qvalues).
      # Default qvalue is 1.0.
      #
      def parse_http_accept_language(header, tags = 0)
        header.split(Const::COMMA_SPLITTER).map! { |entry|
          raise ArgumentError, "Malformed Accept-Language header: #{entry.inspect}" unless
          HTTP_ACCEPT_LANGUAGE_REGEX === entry

          thing = $1
          thing.downcase!

          # RFC 2616, sec. 3.10:
          # White space is not allowed within the tag and all tags are case-
          # insensitive.

          qvalue = ($2 || QVALUE_DEFAULT).to_f
          thing.split('-')[0..tags-1] << qvalue
        }
      end

      # ==== Parameters
      # header<String>:: The Accept request-header.
      #
      # ==== Raises
      # ArgumentError:: Syntax of the header passed is bad. For example,
      # one of Media-Ranges is not in a RFC 'Media-Range' (type or subtype is invalid,
      # or there's something like "*/foo") or, at last, one of MIME-Types has malformed
      # qvalue.
      #
      # ==== Returns
      # Array:: Result of parsing, an Array with completely parsed MIME-Types
      # (incl. qvalues and accept-extensions). Default qvalue is 1.0.
      #
      def parse_http_accept(header)
        header.split(Const::COMMA_SPLITTER).map! { |entry| parse_mime_type(entry) }
      end

      MEDIA_RANGE_REGEX = /^\s*([^#{UNWISE}]+)\/([^#{UNWISE}]+)\s*(?:;|$)/o.freeze
      ACCEPT_PARAMS_REGEX = /\s*;\s*q\s*=.*/i.freeze

      def split_mime_type(thing)
        raise ArgumentError, "Malformed MIME-Type: #{thing.inspect}" unless thing =~ MEDIA_RANGE_REGEX
        type, subtype, snippet = $1, $2, $'

        raise ArgumentError, "Malformed MIME-Type: #{thing.inspect}" if 
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

      # ==== Parameters
      # thing<String>:: The MIME-Type snippet.
      #
      # ==== Returns
      # Array[String, String, Hash]::
      # Media-Range of the MIME-Type: type, subtype and parameter (as Hash).
      #
      # ==== Raises
      # Same things as Utils#split_mime_type.
      # In other words, it checks only type/subtype pair.
      #
      def parse_media_range(thing)
        media_range = thing =~ ACCEPT_PARAMS_REGEX ? $` : thing
        type, subtype, snippet = split_mime_type(media_range)

        params = {}
        snippet.split(Const::SEMICOLON_SPLITTER).each do |pair|
          k,v = pair.split("=",2)
          k.downcase!
          params[k] = v
        end

        return type, subtype, params
      end

      # ==== Parameters
      # thing<String>:: The MIME-Type snippet.
      #
      # ==== Returns
      # Array[String, String, Hash, Float, Hash]::
      # Media-Range (type, subtype and parameter, as Hash), quality factor and
      # accept-extension of the MIME-Type.
      #
      # ==== Raises
      # ArgumentError:: MIME-Type has malformed quality factor,
      # or type/subtype pair is not in RFC Media-Range pattern.
      #
      def parse_mime_type(thing)

        # RFC 2616, sec. 3.7:
        # The type, subtype, and parameter attribute names are case-
        # insensitive. Parameter values might or might not be case-sensitive,
        # depending on the semantics of the parameter name. Linear white space
        # (LWS) MUST NOT be used between the type and subtype, nor between an
        # attribute and its value. The presence or absence of a parameter might
        # be significant to the processing of a media-type, depending on its
        # definition within the media type registry.

        type, subtype, snippet = split_mime_type(thing)

        qvalue, params, accept_extension, has_qvalue = QVALUE_DEFAULT, {}, {}, false
        snippet.split(Const::SEMICOLON_SPLITTER).each do |pair|
          k,v = pair.split("=",2)

          k.downcase!

          # RFC 2616, sec. 14.1:
          # Each media-range MAY be followed by one or more accept-params,
          # beginning with the "q" parameter for indicating a relative quality
          # factor. The first "q" parameter (if any) separates the media-range
          # parameter(s) from the accept-params. Quality factors allow the user
          # or user agent to indicate the relative degree of preference for that
          # media-range, using the qvalue scale from 0 to 1 (section 3.9). The
          # default value is q=1.

          if has_qvalue
            accept_extension[k] = v
          elsif k == QVALUE
            raise ArgumentError, "Malformed quality factor: #{qvalue.inspect}." unless QVALUE_REGEX === v
            qvalue = v.to_f
            has_qvalue = true
          else
            params[k] = v
          end

        end

        return type, subtype, params, qvalue, accept_extension
      end

      # ==== Parameters
      # type<String>:: Type, the first portion of the MIME-Type's media range.
      # subtype<String>:: Subtype, the second portion of the MIME-Type's media range.
      # params<Hash>:: Parameter, as Hash; the third portion of the the MIME-Type's media range.
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
      # params<Hash>:: Parameter, as Hash; the third portion of the the MIME-Type's media range.
      # types<Array>:: The Array of MIME-Types to check against. MUST be *ordered* (by qvalue).
      #
      # ==== Returns
      # Array[Float, Integer, Integer]::
      # Quality factor, rate and specificity, i.e full relative weight of MIME-Type.
      #
      def weigh_mime_type(type, subtype, params, *types)

        rate = 0
        specificity = -1
        quality = 0.00

        # RFC 2616, sec. 14.1:
        # Media ranges can be overridden by more specific media ranges or
        # specific media types. If more than one media range applies to a given
        # type, the most specific reference has precedence.
        # ...
        # The media type quality factor associated with a given type is
        # determined by finding the media range with the highest precedence
        # which matches that type.

        types.each do |t,s,p,q,_|
          next unless ((tmatch = type == t) || t == Const::WILDCARD || type == Const::WILDCARD) &&
                      ((smatch = subtype == s) || s == Const::WILDCARD || subtype == Const::WILDCARD)

          r  = tmatch ? 10 : 0
          r += smatch ? 1  : 0
          next if r < rate

          sp = 0
          mismatch = false

          params.each do |k,v|
            next unless p.key?(k)
            p[k] == v ? sp += 1 : (mismatch = true; break)
          end

          # we should skip when:
          # - mismatch: 'text/html;a=2' vs 'text/html;a=1', 'text/*;a=1' etc
          # - rate is lesser (see above)
          # - rates are equal, but sp(ecificity) is lesser or exactly the same
          # - divergence: 'text/html;b=1' vs 'text/html;a=1' etc,
          #   i.e, 'a' parameter is NECESSARY, but our MIME-Type does NOT contain it

          next if mismatch || (r == rate && sp <= specificity) || (p.keys - params.keys).size > 0
          specificity, rate, quality = sp, r, q
        end

        return quality, rate, specificity
      end

      # ==== Parameters
      # provides<Array>:: The Array of available MIME-Types (snippets). Could be empty.
      # accepts<String>:: The Array of acceptable MIME-Types. Could be empty.
      #
      # ==== Returns
      # String, nil:: The best one of available MIME-Types or nil.
      #
      # ==== Raises
      # Same things as Utils#split_mime_type.
      #
      # ==== Notes
      # Acceptable MIME-Types are supposed to have downcased and well-formed type,
      # subtype, parameter's keys (according to RFC 2616, enumerated things are
      # case-insensitive too), and sensible qvalues ("real numbers in the range 0
      # through 1, where 0 is the minimum and 1 the maximum value").
      #
      def detect_best_mime_type(provides, accepts)
        return nil if provides.empty?
        return provides.first if accepts.empty?

        accepts = accepts.sort_by { |t| -t.at(3) }
        candidate = provides.map { |snippet|
          type, subtype, params = parse_media_range(snippet)
          weigh_mime_type(type, subtype, params, *accepts) << snippet
        }.max_by { |t| t[0..2] } #instead of #sort

        candidate.at(0) == 0 ? nil : candidate.at(3)
      end

      def blank?(s)
        s.empty? || s.strip.empty?
      end

    end
  end
end

# EOF