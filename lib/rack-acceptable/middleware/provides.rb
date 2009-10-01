module Rack #:nodoc:
  module Acceptable #:nodoc:

    # Inspired (partially) by the Rack::AcceptFormat.
    #
    # * Fishes out the best one of available MIME-Types.
    # * Adds an associated format (extension) to the path_info (optional).
    # * Stops processing and responds with 406 'Not Acceptable',
    #   when there's nothing to provide.
    # * Memoizes results, since the full negotiation is not
    #   the 'week' (but quick!) lookup.
    #
    # ==== Example
    #
    #   use Rack::Acceptable::Provides w(text/x-json application/json text/plain),
    #     :force_format   => true,
    #     :default_format => '.txt'
    #
    class Provides

      CANDIDATE = 'rack-acceptable.provides.candidate'
      CANDIDATE_INFO = 'rack-acceptable.provides.candidate_info'

      # ==== Parameters
      # app<String>:: Rack application.
      # provides<Array>:: List of available MIME-Types.
      # options<Hash>:: Additional options.
      #
      def initialize(app, provides, options = {})
        raise "You should provide the list of available MIME-Types." if provides.empty?
        @app = app
        @provides = provides.map { |type| Rack::Acceptable::MIMETypes.parse_media_range(type) << type }
        @lookup = {}
        @force_format = !!options[:force_format]
        if @force_format && options.key?(:default_format)
          ext = options[:default_format].to_s.strip
          @_extension = ext[0] == ?. ? ext : ".#{ext}" unless ext.empty?
        end
      end

      def call(env)
        accepts = env[Const::ENV_HTTP_ACCEPT]
        preferred = accepts ? _negotiate(accepts) : @provides.first

        return Const::NOT_ACCEPTABLE_RESPONSE unless preferred
        simple = preferred.last
        env[CANDIDATE] = simple
        env[CANDIDATE_INFO] = preferred[0..3]
        return @app.call(env) unless @force_format

        request = Rack::Request.new(env)
        path = request.path_info
        if path != Const::SLASH && ext = _extension_for(simple)
          request.path_info = path.sub(/\/*$/, ext)
        end
        @app.call(env)
      end

      private

      # Picks out an extension for the MIME-Type given.
      # Override this to force the usage of another MIME-Type registry.
      #
      def _extension_for(thing)
        Rack::Mime::MIME_TYPES.invert[thing] || @_extension # FIXME
      end

      # Performs negotiation and memoizes result.
      #
      def _negotiate(header)
        if @lookup.key?(header)
          @lookup[header]
        else
          accepts = Rack::Acceptable::MIMETypes.parse_accept(header)
          @lookup[header] = Rack::Acceptable::MIMETypes.detect_best_mime_type(@provides, accepts)
        end
      end

    end
  end
end

# EOF