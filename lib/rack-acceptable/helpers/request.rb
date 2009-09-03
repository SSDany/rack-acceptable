module Rack #:nodoc:
  module Acceptable #:nodoc:
    module RequestHelpers

      def acceptable_encodings(reparse = false)
        return @env[Const::ENV_ACCEPTABLE_ENCODINGS] if !reparse &&
          @env.key?(Const::ENV_ACCEPTABLE_ENCODINGS)

        header = @env[Const::ENV_HTTP_ACCEPT_ENCODING].to_s.strip
        @env[Const::ENV_ACCEPTABLE_ENCODINGS] = Utils.parse_http_accept_encoding(header)
      end

      alias :acceptable_content_codings :acceptable_encodings

    end
  end
end

# EOF