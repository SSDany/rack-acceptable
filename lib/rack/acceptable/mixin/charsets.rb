module Rack #:nodoc:
  module Acceptable #:nodoc:
    module Charsets

      # ==== Returns
      # An Array with wildcards / *downcased* Charsets and
      # associated quality factors (qvalues). Default qvalue is 1.0.
      #
      # ==== Raises
      # ArgumentError::
      #   Syntax of the Accept-Charset request-header is bad.
      #   For example, one of Charsets is not a 'token',
      #   one of quality factors is malformed etc.
      #
      def acceptable_charsets
        Utils.parse_header(
          env[Const::ENV_HTTP_ACCEPT_CHARSET].to_s.downcase,
          Utils::HTTP_ACCEPT_TOKEN_REGEX)
      rescue
        raise ArgumentError,
        "Malformed Accept-Charset header: #{env[Const::ENV_HTTP_ACCEPT_CHARSET].inspect}"
      end

      def accept_charset?(chs)
        chs = chs.downcase
        accepts = acceptable_charsets
        return true if accepts.empty?
        if ch = accepts.assoc(chs) || accepts.assoc(Const::WILDCARD)
          ch.last > 0
        else
          chs == Const::ISO_8859_1
        end
      rescue
        false
      end

    end
  end
end

# EOF