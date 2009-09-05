module Rack #:nodoc:
  module Acceptable #:nodoc:
    module RequestHelpers

      def acceptable_encodings
        @env[Const::ENV_PARSED_ENCODINGS] ||=
        Utils.parse_http_accept_encoding(@env[Const::ENV_HTTP_ACCEPT_ENCODING].to_s)
      end

      def acceptable_charsets
        @env[Const::ENV_PARSED_CHARSETS] ||=
        Utils.parse_http_accept_charset(@env[Const::ENV_HTTP_ACCEPT_CHARSET].to_s)
      end

      def acceptable_media_ranges
        raise NotImplementedError
      end

      #--
      # TODO: move to extras?
      # Normally, the FULL parse and weighing of MIME-Types is
      # perfectionistic and unnecessary action. Quick detection
      # of the acceptable one may cover the most cases.
      #++

      def acceptable_mime_types
        @env[Const::ENV_PARSED_MIME_TYPES] ||=
        Utils.parse_http_accept(@env[Const::ENV_HTTP_ACCEPT].to_s)
      end

    end
  end
end

# EOF