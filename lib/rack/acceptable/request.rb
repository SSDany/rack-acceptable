require 'rack/request'
require 'rack/acceptable/mixin/headers'
require 'rack/acceptable/mixin/media'

module Rack #:nodoc:
  module Acceptable #:nodoc:
    class Request < Rack::Request

      include Rack::Acceptable::Headers
      include Rack::Acceptable::Charsets
      include Rack::Acceptable::Media

      def acceptable_charsets
        @_acceptable_charsets ||= super
      end

      def accept_content?(content_type)
        media = MIMETypes.parse_media_range(content_type)
        chs = media.last.delete(Const::CHARSET)
        chs ||= Const::ISO_8859_1 if media.first == Const::TEXT
        if chs
          accept_media?(media) && accept_charset?(chs)
        else
          accept_media?(media)
        end
      rescue
        false
      end

    end
  end
end

# EOF