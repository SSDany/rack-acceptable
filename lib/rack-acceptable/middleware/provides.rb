module Rack #:nodoc:
  module Acceptable #:nodoc:

    # * Fishes out the best one of available MIME-Types.
    # * Memoizes results, since the full negotiation is not
    #   the 'week' (but quick!) lookup.
    # * Stops processing and responds with 406 'Not Acceptable',
    #   when there's nothing to provide.
    #
    # ==== Example
    #
    #   use Rack::Acceptable::Provides w(text/x-json application/json)
    #
    class Provides

      PREFERRED = 'rack-acceptable.provides.candidate'

      LOCK = Mutex.new
      LOOKUP = {}

      # ==== Parameters
      # app<String>:: Rack application.
      # provides<Array>:: List of available MIME-Types.
      #
      def initialize(app, provides)
        raise "You should provide the list of available MIME-Types." if provides.empty?
        @app, @provides = app, provides
      end

      def call(env)
        if accepts = env[Const::ENV_HTTP_ACCEPT]
          return Const::NOT_ACCEPTABLE_RESPONSE unless preferred = _negotiate(accepts)
          env[PREFERRED] = preferred
        else
          env[PREFERRED] = @provides.first
        end
        @app.call(env)
      end

      private

      # Performs negotiation and memoizes result.
      #
      def _negotiate(header)
        LOCK.synchronize do
          return LOOKUP[header] if LOOKUP.key?(header)
        end

        accepts = Rack::Acceptable::MIMETypes.parse_accept(header)
        preferred = Rack::Acceptable::MIMETypes.detect_best_mime_type(@provides, accepts)
        LOCK.synchronize do
          return LOOKUP[header] = preferred
        end
      end

    end
  end
end

# EOF