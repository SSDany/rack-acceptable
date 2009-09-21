# encoding: binary

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
          entry =~ QUALITY_REGEX
          thing, qvalue = $` || entry, $1
          raise ArgumentError, "Malformed quality factor: #{qvalue.inspect}" if qvalue && qvalue !~ QVALUE_REGEX
          [thing, qvalue ? qvalue.to_f : QVALUE_DEFAULT]
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