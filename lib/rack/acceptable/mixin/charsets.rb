require 'rack/acceptable/utils'

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

      # Checks if the Charset (as a +String+) passed acceptable.
      # Works case-insensitively.
      #
      def accept_charset?(chs)
        chs = chs.downcase
        return true if (accepts = acceptable_charsets).empty?
        if ch = accepts.assoc(chs) || accepts.assoc(Const::WILDCARD)
          ch.last > 0
        else
          chs == Const::ISO_8859_1
        end
      rescue
        false
      end

      # Detects the best Charset.
      # Works case-insensitively.
      #
      def negotiate_charset(*things)
        things.map!{|t| t.downcase}
        Utils.detect_best_charset(things, acceptable_charsets)
      end

      alias :preferred_charset_from :negotiate_charset

    end
  end
end

# EOF