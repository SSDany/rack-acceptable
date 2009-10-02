# encoding: binary

module Rack #:nodoc:
  module Acceptable #:nodoc:
    module MIMETypes

      module_function

      MEDIA_RANGE_REGEX = /^\s*(#{Utils::TOKEN_PATTERN})\/(#{Utils::TOKEN_PATTERN})\s*$/o.freeze

      # RFC 2616, sec. 3.7:
      # The type, subtype, and parameter attribute names are case-
      # insensitive. Parameter values might or might not be case-sensitive,
      # depending on the semantics of the parameter name. Linear white space
      # (LWS) MUST NOT be used between the type and subtype, nor between an
      # attribute and its value. The presence or absence of a parameter might
      # be significant to the processing of a media-type, depending on its
      # definition within the media type registry.

      # ==== Parameters
      # thing<String>::
      #   The MIME-Type snippet, *without* 'q' parameter, accept-extensions and so on.
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
        snippets = thing.split(Utils::SEMICOLON_SPLITTER)
        raise ArgumentError, "Malformed MIME-Type: #{thing}" unless MEDIA_RANGE_REGEX === snippets.shift

        type = $1
        subtype = $2
        type.downcase!
        subtype.downcase!

        raise ArgumentError, "Malformed MIME-Type: #{thing}" if
          type == Const::WILDCARD &&
          subtype != Const::WILDCARD

        params = {}
        snippets.each do |pair|
          pair.strip!
          k,v = pair.split(Utils::PAIR_SPLITTER,2)
          k.downcase!
          params[k] = v
        end

        [type, subtype, params]
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

        snippets = thing.split(Utils::SEMICOLON_SPLITTER)
        raise ArgumentError, "Malformed MIME-Type: #{thing}" unless MEDIA_RANGE_REGEX === snippets.shift

        type = $1
        subtype = $2
        type.downcase!
        subtype.downcase!

        raise ArgumentError, "Malformed MIME-Type: #{thing}" if
          type == Const::WILDCARD &&
          subtype != Const::WILDCARD

        qvalue = Utils::QVALUE_DEFAULT
        params = {}
        accept_extension = {}
        has_qvalue = false

        for pair in snippets
          pair.strip!
          k,v = pair.split(Utils::PAIR_SPLITTER,2)

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
            if k == Utils::QVALUE
              raise ArgumentError, "Malformed quality factor: #{v.inspect}" unless Utils::QVALUE_REGEX === v
              qvalue = v.to_f
              has_qvalue = true
            else
              params[k] = v
            end
          end

        end

        [type, subtype, params, qvalue, accept_extension]
      end

      # ==== Parameters
      # thing<String, Array>:: The MIME-Type snippet or *parsed* media-range.
      # types<Array>:: The Array of *parsed* MIME-Types to check against. MUST be *ordered* (by qvalue).
      #
      # ==== Returns
      # Float:: The quality factor (relative strength of the MIME-Type).
      #
      def qualify_mime_type(thing, types)
        weigh_mime_type(thing, types).first
      end

      # ==== Parameters
      # thing<String, Array>:: The MIME-Type snippet or *parsed* media-range.
      # types<Array>:: The Array of *parsed* MIME-Types to check against. MUST be *ordered* (by qvalue).
      #
      # ==== Returns
      # Array[Float, Integer, Integer, Integer]::
      #   Quality factor, rate, specificity and negated index of the most relevant MIME-Type;
      #   i.e full relative weight of the MIME-Type.
      #
      def weigh_mime_type(thing, types)

        type, subtype, params = thing.is_a?(String) ? parse_media_range(thing) : thing

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

          p.each { |k,v| params.key?(k) && params[k] == v ? sp += 1 : (divergence = true; break) }

          next if divergence || (r == rate && sp <= specificity)
          specificity = sp
          rate = r
          quality = q
          index = -i
        end

        [quality, rate, specificity, index]
      end

    end
  end
end

# EOF