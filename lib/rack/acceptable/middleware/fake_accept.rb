module Rack #:nodoc:
  module Acceptable #:nodoc:
    class FakeAccept

      ORIGINAL_HTTP_ACCEPT = 'rack-acceptable.fake_accept.original_HTTP_ACCEPT'

      def initialize(app, default_media = 'text/html')
        @default_media = default_media
        @app = app
      end

      def call(env)
        request = ::Rack::Request.new(env)
        extname = ::File.extname(request.path_info)
        env[ORIGINAL_HTTP_ACCEPT] = env[Const::ENV_HTTP_ACCEPT]
        env[Const::ENV_HTTP_ACCEPT] = Rack::Acceptable::MIMETypes.lookup(extname, @default_media)
        @app.call(env)
      end

    end

  end
end

# EOF