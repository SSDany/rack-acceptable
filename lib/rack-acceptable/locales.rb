module Rack #:nodoc:
  module Acceptable #:nodoc:
    module Locales

      # ==== Returns
      # Result of parsing. An Array with wildcards / primary subtags (as +Strings+)
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
          accepts
        end
      end

      def preferred_locale_from(*provides)
        candidates = preferred_locales & (provides << Const::WILDCARD)
        if (candidate = candidates.first) == Const::WILDCARD
          (provides - preferred_locales - @_undesirable_locales).first || candidates.at(1)
        else
          candidate
        end
      end

      def accept_locale?(locale)
        (preferred_locales.include?(locale) || preferred_locales.include?(Const::WILDCARD)) && 
        !@_undesirable_locales.include?(locale)
      end

    end
  end
end

# EOF