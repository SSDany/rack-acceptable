require 'rack/acceptable/mimetypes'

module Rack #:nodoc:
  module Acceptable #:nodoc:
    module Media

      # ==== Returns
      # An Array with Media-Ranges (as +Strings+) / wildcards and
      # associated qvalues. Default qvalue is 1.0.
      #
      # ==== Raises
      # ArgumentError::
      #   There's a malformed qvalue in header.
      #
      def acceptable_media_ranges
        Utils.extract_qvalues(env[Const::ENV_HTTP_ACCEPT].to_s)
      rescue
        raise ArgumentError,
        "Malformed Accept header: #{env[Const::ENV_HTTP_ACCEPT].inspect}"
      end

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
      def acceptable_media
        @_acceptable_media ||= begin
          header = env[Const::ENV_HTTP_ACCEPT].to_s
          header.split(Utils::COMMA_SPLITTER).map! { |entry| MIMETypes.parse_mime_type(entry) }
        end
      end

      # Checks if the MIME-Type passed acceptable.
      def accept_media?(thing)
        qvalue = MIMETypes.weigh_mime_type(thing, acceptable_media).first
        qvalue > 0
      rescue
        false
      end

      # Returns the best match for the MIME-Type or
      # pattern (like "text/*" etc) passed or +nil+.
      def best_media_for(thing)
        weight = MIMETypes.weigh_mime_type(thing, acceptable_media)
        if weight.first > 0
          acceptable_media.at(-weight.last)
        else
          nil
        end
      end

      def negotiate_media(*things)
        flag = (things.last == true || things.last == false) ? things.pop : false
        MIMETypes.detect_best_mime_type(things, acceptable_media, flag)
      end

      alias :preferred_media_from :negotiate_media

    end
  end
end

# EOF