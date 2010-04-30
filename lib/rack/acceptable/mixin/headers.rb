require 'rack/acceptable/mimetypes'

module Rack #:nodoc:
  module Acceptable #:nodoc:
    module Headers

      def self.included(mod)
        mod.send(:include, Charsets)
        mod.send(:include, Encodings)
        mod.send(:include, Languages)
        mod.send(:include, Media)
      end

    end
  end
end

# EOF