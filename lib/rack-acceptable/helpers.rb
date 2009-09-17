module Rack
  module Acceptable
    module Helpers

      def self.included(base)
        base.send(:include, Essentials)
        base.send(:include, Locales)
      end

      autoload :Essentials  , 'rack-acceptable/helpers/essentials'
      autoload :Locales     , 'rack-acceptable/helpers/locales'

    end
  end
end

# EOF