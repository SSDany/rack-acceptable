# encoding: binary

module Rack #:nodoc:
  module Acceptable #:nodoc:
    module Encodings

      HTTP_ACCEPT_ENCODING_REGEX = /^\s*(#{Utils::TOKEN_PATTERN})#{Utils::QUALITY_PATTERN}\s*$/o.freeze

      module_function

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
      def parse_accept_encoding(header)
        Utils.parse_header(header.downcase, HTTP_ACCEPT_ENCODING_REGEX)
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

    end
  end
end

# EOF