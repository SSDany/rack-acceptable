require 'rack/acceptable/mixin/charsets'
require 'rack/acceptable/mixin/encodings'
require 'rack/acceptable/mixin/languages'
require 'rack/acceptable/mixin/media'

module Rack #:nodoc:
  module Acceptable #:nodoc:
    module Headers

      def self.included(mod)
        mod.send :include, Charsets, Encodings, Languages, Media
      end

    end
  end
end

# EOF