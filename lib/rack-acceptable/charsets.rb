# encoding: binary

module Rack #:nodoc:
  module Acceptable #:nodoc:
    module Charsets

      HTTP_ACCEPT_CHARSET_REGEX = /^\s*(#{Utils::TOKEN_PATTERN})#{Utils::QUALITY_PATTERN}\s*$/o.freeze

      module_function

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
      def parse_accept_charset(header)
        Utils.parse_header(header.downcase, HTTP_ACCEPT_CHARSET_REGEX)
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

        (candidates & provides).first
      end

    end
  end
end

# EOF