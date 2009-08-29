module Rack #:nodoc:
  module Acceptable #:nodoc:
    module Utils

      QUALITY_REGEX = /^([^;\s]+)(?:.*?;\s*q=([^;\s]*))?/.freeze

      #http://tools.ietf.org/html/rfc2616#section-3.9
      #http://tools.ietf.org/html/rfc2616#section-2.1
      QVALUE_REGEX = /^0$|^0\.\d{0,3}$|^1$|^1\.0{0,3}$/.freeze
      QVALUE_DEFAULT = 1.00
      QVALUE = 'q'.freeze

      module_function

      # ==== Notes
      # This assumes the header it was passed is well-formed (in terms of
      # RFC2616 grammar) and *normalized* (stripped), i.e., only checks the
      # quality factors. Full syntactical inspection of the header is NOT
      # a task of simple qvalues extractor.
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
          thing, qvalue = $1, $2
          raise ArgumentError, "Malformed quality factor: #{qvalue.inspect}" if qvalue && qvalue !~ QVALUE_REGEX
          [thing, qvalue ? qvalue.to_f : QVALUE_DEFAULT]
        }.sort_by { |_,q| -q }
      end

      # ==== Parameters
      # provides<Array>:: The Array of available content-codings. Could be empty.
      # accepts<Array>:: The Array of acceptable content-codings. Could be empty.
      #
      # ==== Returns
      # String:: The best content-coding.
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

      def parse_http_accept(header)
        header.split(Const::COMMA_SPLITTER).map! { |part| parse_mime_type(part) }.sort_by{ |t| -t.at(2) }
      end

      MEDIA_RANGE_REGEX = %r{^(?:([-\w.+]+)/([-\w.+]+|\*)|\*/\*)\s*;?\s*}.freeze

      def parse_mime_type(thing)

        raise ArgumentError, "Malformed MIME-Type: #{thing.inspect}" unless thing =~ MEDIA_RANGE_REGEX
        type, subtype, snippet = $1, $2, $'

        # RFC 2616, sec. 3.7:
        # The type, subtype, and parameter attribute names are case-
        # insensitive. Parameter values might or might not be case-sensitive,
        # depending on the semantics of the parameter name. Linear white space
        # (LWS) MUST NOT be used between the type and subtype, nor between an
        # attribute and its value. The presence or absence of a parameter might
        # be significant to the processing of a media-type, depending on its
        # definition within the media type registry.

        type ? type.downcase! : type = Const::WILDCARD
        subtype ? subtype.downcase! : subtype = Const::WILDCARD
        qvalue, params, accept_extension, has_qvalue = QVALUE_DEFAULT, {}, {}, false

        snippet.split(Const::SEMICOLON_SPLITTER).each do |pair|
          k,v = pair.split("=",2)
          raise ArgumentError, "Malformed parameter syntax: #{pair.inspect}" if k[-1] == ?\s || v[0] == ?\s

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

        [type, subtype, qvalue, params, accept_extension]

      end

      # ==== Parameters
      # type<String>:: Type, the first portion of the MIME-Type's media range.
      # subtype<String>:: Subtype, the second portion of the MIME-Type's media range.
      # params<Hash>:: The MIME-Type parameter, as Hash.
      # types<Array>:: The Array of MIME-Types to check against. MUST be *ordered* (by qvalue).
      #
      # ==== Returns
      # Float:: The quality factor (relative strength of the MIME-Type).
      #
      def qualify_mime_type(type, subtype, params, *types)

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

        types.each do |t,s,q,p,_|
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

        quality
      end

      def detect_best_mime_type(provides, accepts)
        raise NotImplementedError
      end

    end
  end
end

# EOF