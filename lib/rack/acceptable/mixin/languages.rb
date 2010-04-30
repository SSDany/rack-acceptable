require 'rack/acceptable/language_tag'

module Rack #:nodoc:
  module Acceptable #:nodoc:
    module Languages

      # ==== Returns
      # An Array with wildcards / Language-Tags (as +Strings+)
      # and associated quality factors (qvalues). Default qvalue is 1.0.
      #
      # ==== Raises
      # ArgumentError::
      #   Syntax of the Accept-Language request-header is bad.
      #   For example, one of Language-Ranges is not in a RFC 'Language-Range'
      #   pattern, one of quality factors is malformed etc.
      #
      # ==== Notes
      # * It uses {Extended Language-Range pattern}[http://tools.ietf.org/html/rfc4647#section-2.2].
      # * It does *not* perform 'convenient transformations' (downcasing of primary tags etc).
      #   In other words, it parses Accept-Language header in unpretentious manner.
      #
      def acceptable_language_ranges
        Utils.parse_header(
          env[Const::ENV_HTTP_ACCEPT_LANGUAGE].to_s,
          Utils::HTTP_ACCEPT_LANGUAGE_REGEX)
      rescue
        raise ArgumentError,
        "Malformed Accept-Language header: #{env[Const::ENV_HTTP_ACCEPT_LANGUAGE].inspect}"
      end

      # Checks if the Language-Tag (as a +String+ or
      # +Rack::Acceptable::LanguageTag+) passed acceptable.
      # Works case-insensitively.
      #
      def accept_language?(tag)
        langtag = LanguageTag.parse(tag)
        acceptable_language_ranges.any? { |l,q| q > 0 && langtag.matched_by_extended_range?(l) }
      rescue
        false
      end

    end
  end
end

# EOF