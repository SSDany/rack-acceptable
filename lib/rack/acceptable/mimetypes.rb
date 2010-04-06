# encoding: binary

require 'rack/acceptable/utils'

module Rack #:nodoc:
  module Acceptable #:nodoc:
    module MIMETypes

      module_function

      MEDIA_RANGE_REGEX = /^\s*(#{Utils::TOKEN_PATTERN})\/(#{Utils::TOKEN_PATTERN})\s*$/o.freeze

      #--
      # RFC 2616, sec. 3.7:
      # The type, subtype, and parameter attribute names are case-
      # insensitive. Parameter values might or might not be case-sensitive,
      # depending on the semantics of the parameter name. Linear white space
      # (LWS) MUST NOT be used between the type and subtype, nor between an
      # attribute and its value. The presence or absence of a parameter might
      # be significant to the processing of a media-type, depending on its
      # definition within the media type registry.
      #++

      # ==== Parameters
      # thing<String>::
      #   The Media-Type snippet or the single item from the HTTP_ACCEPT
      #   request-header, *without* 'q' parameter, accept-extensions and so on.
      #
      # ==== Returns
      # Array[String, String, Hash]::
      #   Media-Range: type, subtype and parameter (as a +Hash+).
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

        raise ArgumentError,
          "Malformed MIME-Type: #{thing}" if type == Const::WILDCARD && subtype != Const::WILDCARD

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
      # thing<String>::
      #   The Media-Type snippet or the single item from the HTTP_ACCEPT request-header.
      #
      # ==== Returns
      # Array[String, String, Hash, Float, Hash]::
      #   Media-Range (type, subtype and parameter, as a +Hash+), quality factor
      #   and accept-extension (as a +Hash+, if any, or +nil+) of the MIME-Type.
      #
      # ==== Raises
      # ArgumentError::
      #   There's a malformed quality factor, or type/subtype pair
      #   is not in a RFC 'Media-Range' pattern.
      #
      def parse_mime_type(thing)

        snippets = thing.split(Utils::SEMICOLON_SPLITTER)
        raise ArgumentError, "Malformed MIME-Type: #{thing}" unless MEDIA_RANGE_REGEX === snippets.shift

        type = $1
        subtype = $2
        type.downcase!
        subtype.downcase!

        raise ArgumentError,
          "Malformed MIME-Type: #{thing}" if type == Const::WILDCARD && subtype != Const::WILDCARD

        qvalue = Utils::QVALUE_DEFAULT
        params = {}
        has_qvalue = false
        accept_extension = nil

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
            accept_extension ||= {}
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
      # thing<String, Array>:: The Media-Type snippet or *parsed* Media-Type.
      # types<Array>:: Parsed HTTP_ACCEPT request-header to check against.
      #
      # ==== Returns
      # Float:: The quality factor (relative strength of the Media-Type).
      #
      def qualify_mime_type(thing, types)
        weigh_mime_type(thing, types).first
      end

      # ==== Parameters
      # thing<String, Array>:: The Media-Type snippet or *parsed* Media-Type.
      # types<Array>:: Parsed HTTP_ACCEPT request-header to check against.
      # qvalue_only<Boolean>:: Flag to force weighting to return the qvalue only.
      #                        Optional. Default is +false+.
      #
      # ==== Returns
      # Array[Float, Integer, Integer, Integer] or Array[Float]::
      #   Quality factor, rate, specificity and negated index of the most relevant Media-Range;
      #   i.e full relative weight of the Media-Type. If +qvaulue_only+ option is set to true,
      #   returns qvalue only.
      #
      def weigh_mime_type(thing, types, qvalue_only = false)

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

        type_is_a_wildcard = type == Const::WILDCARD
        subtype_is_a_wildcard = subtype == Const::WILDCARD

        types.each_with_index do |(t,s,p,q),i|
          next unless (type_is_a_wildcard     || t == type    || no_type_match    = t == Const::WILDCARD) &&
                      (subtype_is_a_wildcard  || s == subtype || no_subtype_match = s == Const::WILDCARD)

          # we should skip when:
          # - divergence: 
          #     * "text;html;a=2" against "text/html;a=1,text/*;a=1" etc
          #     * "text/html;b=1" or "text/html" against "text/html;a=1" etc,
          #       i.e, 'a' parameter is NECESSARY, but our MIME-Type does NOT contain it
          # - rate is lesser
          # - rates are equal, but sp(ecificity) is lesser or exactly the same

          r  = no_type_match    ? 0 : 10
          r += no_subtype_match ? 0 : 1

          next if r < rate

          sp = 0
          p.each do |k,v|
            if params.key?(k) && params[k] == v
              sp += 1
            else
              sp = -1
              break
            end
          end

          #next if sp == -1 || (r == rate && (sp < specificity || sp == specificity && quality > q))
          if sp > -1 && (r > rate || (sp > specificity || sp == specificity && quality < q))
            specificity = sp
            rate = r
            quality = q
            index = i
          end
        end

        qvalue_only ? [quality] : [quality, rate, specificity, -index]
      end

      # ==== Parameters
      # provides<Array>:: The Array of available Media-Types (snippets or parsed). Could be empty.
      # accepts<String>:: The Array of acceptable Media-Ranges. Could be empty.
      # by_qvalue_only<String>:: Optional flag, see MIMETypes#weigh_mime_type. Default is +false+.
      #
      # ==== Returns
      # The best one of available Media-Types or +nil+.
      #
      # ==== Raises
      # Same things as Utils#parse_media_range.
      #
      # ==== Notes
      # Acceptable Media-Types are supposed to have *downcased* and *well-formed*
      # type, subtype, parameter's keys (according to RFC 2616, enumerated things
      # are case-insensitive too), and *sensible* qvalues ("real numbers in the
      # range 0 through 1, where 0 is the minimum and 1 the maximum value").
      #
      def detect_best_mime_type(provides, accepts, by_qvalue_only = false)
        return nil if provides.empty?
        return provides.first if accepts.empty?
        i = 1
        candidate = provides.map { |t| weigh_mime_type(t,accepts,by_qvalue_only) << i-=1 }.max
        candidate.at(0) == 0 ? nil : provides.at(-candidate.last)
      end

      REGISTRY_PATH = ::File.expand_path(::File.join(::File.dirname(__FILE__), 'data', 'mime.types')).freeze
      REGISTRY = {}
      EXTENSIONS = {}

      # Registers the new MIME-Type and associated extensions.
      # The first one of extensions will be treated as the 'preferred'
      # for the MIME-Type.
      #
      def register(thing, *extensions)
        return if extensions.empty?
        extensions.map! { |ext| ext[0] == ?. ? ext.downcase : ".#{ext.downcase}" }
        extensions.each { |ext| REGISTRY[ext] = thing }
        EXTENSIONS[thing] = extensions.first
        nil
      end

      # Deletes the MIME-Type (and associated extensions) from registry.
      def delete(thing)
        REGISTRY.delete_if { |_,v| v == thing }
        EXTENSIONS.delete thing
      end

      def lookup(ext, fallback = 'application/octet-stream')
        REGISTRY.fetch(ext[0] == ?. ? ext.downcase : ".#{ext.downcase}", fallback)
      end

      def extension_for(thing, fallback = nil)
        EXTENSIONS.fetch thing, fallback
      end

      # Empties the registry.
      def clear
        EXTENSIONS.clear
        REGISTRY.clear
        nil
      end

      # Resets the registry, i.e removes all and loads
      # the default set of the MIME-Types.
      def reset
        clear
        load_from(REGISTRY_PATH)
      end

      # Loads the set of MIME-Types from the Apache compatible mime.types file.
      # original source: webrick.
      def load_from(file)
        open(file) do |io|
          io.each do |line|
            line.strip!
            next if line.empty? || /^#/ === line
            register *line.split(/\s+/)
          end
        end
        true
      end

    end
  end
end

# EOF