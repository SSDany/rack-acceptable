require 'rack-acceptable/mimetypes'

module Rack #:nodoc:
  module Acceptable #:nodoc:
    module Media

      # ==== Returns
      # An Array with *completely* parsed MIME-Types (incl. qvalues
      # and accept-extensions; see Rack::Acceptable::MIMETypes).
      # Default qvalue is 1.0.
      #
      # ==== Raises
      # ArgumentError::
      #   Syntax of the The Accept request-header is bad.
      #   For example, one of Media-Ranges is not in a RFC 'Media-Range'
      #   pattern (type or subtype is invalid, or there's something like "*/foo")
      #   or, at last, one of MIME-Types has malformed qvalue.
      #
      def acceptable_mime_types
        @_acceptable_mime_types ||= begin
          header = env[Const::ENV_HTTP_ACCEPT].to_s.strip
          header.split(Utils::COMMA_WS_SPLITTER).map! { |entry| MIMETypes.parse_mime_type(entry) }
        end
      end

      # Checks if the MIME-Type passed acceptable.
      def accept_mime_type?(thing)
        qvalue = MIMETypes.qualify_mime_type(thing, acceptable_mime_types)
        qvalue > 0
      rescue
        false
      end

      def preferred_mime_type_from(*things)
        MIMETypes.detect_best_mime_type(things, acceptable_mime_types)
      end

    end
  end
end

# EOF