module Rack #:nodoc:
  module Acceptable #:nodoc:
    module Helpers::Locales

      def preferred_locales
        @_preferred_locales ||= begin
          accepts = Languages.parse_locales(@env[Const::ENV_HTTP_ACCEPT_LANGUAGE].to_s)

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
        return nil if provides.empty?
        candidates = preferred_locales & (provides + [Const::WILDCARD])
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