# encoding: binary

require 'rack/acceptable/const'

module Rack #:nodoc:
  module Acceptable #:nodoc:
    module Utils

      #--
      # http://tools.ietf.org/html/rfc2616#section-2.1
      # http://tools.ietf.org/html/rfc2616#section-2.2
      # http://tools.ietf.org/html/rfc2616#section-3.9
      #++

      QUALITY_PATTERN     = '\s*(?:;\s*q=(0|0\.\d{0,3}|1|1\.0{0,3}))?'.freeze
      QUALITY_REGEX       = /\s*;\s*q\s*=([^;\s]*)/i.freeze
      QVALUE_REGEX        = /^0$|^0\.\d{0,3}$|^1$|^1\.0{0,3}$/.freeze

      QVALUE_DEFAULT      = 1.00
      QVALUE              = 'q'.freeze

      # see benchmarks/simple/split_bench.rb
      if RUBY_VERSION < '1.9.1'

        PAIR_SPLITTER       = /\=/.freeze
        HYPHEN_SPLITTER     = /-/
        COMMA_SPLITTER      = /,/
        SEMICOLON_SPLITTER  = /;/.freeze

      else

        PAIR_SPLITTER       = '='.freeze
        HYPHEN_SPLITTER     = Const::HYPHEN
        COMMA_SPLITTER      = Const::COMMA
        SEMICOLON_SPLITTER  = Const::SEMICOLON

      end

      COMMA_WS_SPLITTER   = /,\s*/.freeze
      TOKEN_PATTERN       = "[A-Za-z0-9#{Regexp.escape('!#$&%\'*+-.^_`|~')}]+".freeze

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
      #   thereto a bunch of more specific parsers is provided.
      #
      def extract_qvalues(header)
        header.split(COMMA_WS_SPLITTER).map! { |entry|
          QUALITY_REGEX === entry
          thing = $` || entry
          if !(qvalue = $1)
            [thing, QVALUE_DEFAULT]
          elsif QVALUE_REGEX === qvalue
            [thing, qvalue.to_f]
          else
            raise ArgumentError, "Malformed quality factor: #{qvalue.inspect}"
          end
        }
      end

      #:stopdoc:

      def parse_header(header, regex)
        header.split(COMMA_SPLITTER).map! do |entry|
          raise unless regex === entry
          [$1, ($2 || QVALUE_DEFAULT).to_f]
        end
      end

      #:startdoc:

      HTTP_ACCEPT_ENCODING_REGEX = /^\s*(#{Utils::TOKEN_PATTERN})#{Utils::QUALITY_PATTERN}\s*$/o.freeze

      module_function

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
        identity_or_wildcard_prohibited = nil # explicit 'identity;q=0' or '*;q=0'

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

        candidate = (candidates & provides).first
        return candidate if candidate
        return Const::IDENTITY if identity && !identity_or_wildcard_prohibited
        nil
      end

      HTTP_ACCEPT_CHARSET_REGEX = /^\s*(#{Utils::TOKEN_PATTERN})#{Utils::QUALITY_PATTERN}\s*$/o.freeze

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

        (candidates & provides).first
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

      HTTP_ACCEPT_LANGUAGE_REGEX              = /^\s*(\*|[a-z]{1,8}(?:-[a-z\d]{1,8})*)#{Utils::QUALITY_PATTERN}\s*$/io.freeze
      HTTP_ACCEPT_LANGUAGE_PRIMARY_TAGS_REGEX = /^\s*(\*|[a-z]{1,8})(?:-[a-z\d]{1,8})*#{Utils::QUALITY_PATTERN}\s*$/o.freeze

      def normalize_header(header)
        ret = header.strip
        ret.gsub!(/\s*(?:,\s*)+/, Const::COMMA)
        ret.gsub!(/^,|,$/, Const::EMPTY_STRING)
        ret
      end

      def blank?(s)
        s.empty? || s.strip.empty?
      end

    end
  end
end

# EOF