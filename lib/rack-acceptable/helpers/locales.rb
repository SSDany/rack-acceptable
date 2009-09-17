module Rack #:nodoc:
  module Acceptable #:nodoc:
    module Helpers::Locales

      def preferred_locales
        @env[Const::ENV_PREFERRED_LOCALES] ||= begin

          # get list of locales and qvalues from the Accept-Language header
          accepts = Languages.parse_locales(@env[Const::ENV_HTTP_ACCEPT_LANGUAGE].to_s)

          # stub undesirable
          @env[Const::ENV_UNDESIRABLE_LOCALES] = []
          accepts.reject! { |l,q| @env[Const::ENV_UNDESIRABLE_LOCALES] << l if q == 0 }

          i = 0
          # sort and uniq preferred locales
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
          (provides - preferred_locales - @env[Const::ENV_UNDESIRABLE_LOCALES]).first || candidates.at(1)
        else
          candidate
        end
      end

      def accept_locale?(locale)
        (preferred_locales.include?(locale) || preferred_locales.include?(Const::WILDCARD)) && 
        !@env[Const::ENV_UNDESIRABLE_LOCALES].include?(locale)
      end

    end
  end
end

# EOF