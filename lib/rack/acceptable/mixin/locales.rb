require 'rack/acceptable/utils'

module Rack #:nodoc:
  module Acceptable #:nodoc:
    module Locales

      # ==== Returns
      # An Array with wildcards / primary subtags (as +Strings+)
      # and associated quality factors (qvalues). Default qvalue is 1.0.
      #
      # ==== Raises
      # ArgumentError::
      #   Syntax of the The Accept-Language request-header is bad.
      #   For example, one of Language-Ranges is not in a RFC 'Language-Range'
      #   pattern, one of quality factors is malformed etc.
      #
      # ==== Notes
      # * Validation pattern is same as in #parse_accept_language
      # * It *downcases* primary subtags.
      # * It does *not* reduce the result, because of:
      #   - the difference between empty header and header composed with zero-qualified Language-Tags.
      #   - the *possible* difference between the 'best locale lookup' algorithms.
      #
      def acceptable_locales
        header = env[Const::ENV_HTTP_ACCEPT_LANGUAGE].to_s
        ret = Utils.parse_header(header.downcase, Utils::HTTP_ACCEPT_LANGUAGE_PRIMARY_TAGS_REGEX)
        ret.reject! { |l,_| l.length == 1 && l != Const::WILDCARD } # acc. to the Language-Tag ABNF
        ret
      rescue
        raise ArgumentError, "Malformed Accept-Language header: #{header.inspect}"
      end

      # ==== Returns
      # An Array with 'preferred' locales / wildcards in appropriate
      # order, *without* quality factors.
      #
      def preferred_locales
        @_preferred_locales ||= begin
          accepts = acceptable_locales
          @_undesirable_locales = []
          accepts.reject! { |l,q| @_undesirable_locales << l if q == 0 }

          i = 0
          accepts = accepts.sort_by { |_,q| [-q,i+=1] }
          accepts.map! { |l,_| l }
          accepts.uniq!
          @_undesirable_locales -= accepts
          # TODO: should we treat 'en;q=0,en;q=1' as "'en' is acceptable" ?
          accepts
        end
      end

      # Returns the best one of locales passed or +nil+.
      def negotiate_locale(*provides)
        candidates = preferred_locales & (provides << Const::WILDCARD)
        if (candidate = candidates.first) == Const::WILDCARD
          (provides - preferred_locales - @_undesirable_locales).first || candidates.at(1)
        else
          candidate
        end
      end

      alias :preferred_locale_from :negotiate_locale

      # Checks if locale passed acceptable.
      def accept_locale?(locale)
        (preferred_locales.include?(locale) || preferred_locales.include?(Const::WILDCARD)) && 
        !@_undesirable_locales.include?(locale)
      rescue
        false
      end

    end
  end
end

# EOF