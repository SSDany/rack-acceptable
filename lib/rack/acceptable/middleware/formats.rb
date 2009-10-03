require 'rack/acceptable/utils'

module Rack #:nodoc:
  module Acceptable #:nodoc:

    # * Fishes out all acceptable formats (in the appropriate order).
    #   The idea is to let the user decide about the preferred one,
    #   since the Accept request-header is not only thing the response
    #   depends on.
    # * Stops processing and responds with 406 'Not Acceptable' *only*
    #   if there's no acceptable formats *and* wildcard has a zero quality
    #   or not explicitly mentioned; i.e, decreases (slightly) the the
    #   number of application calls in compliance with notes in
    #   RFC 2616, sec. 10.4.7.
    #
    # ==== Example
    #
    #   @provides = {
    #     :json => %w(text/x-json application/json),
    #     :xml  => %w(application/xml text/xml),
    #     :text => %w(text/plain text/*)
    #     }
    #
    #   use Rack::Acceptable::Formats @provides
    #
    class Formats

      CANDIDATES = 'rack-acceptable.formats.candidates'

      #--
      # RFC 2616, section 10.4.7:
      # Note: HTTP/1.1 servers are allowed to return responses which are
      # not acceptable according to the accept headers sent in the
      # request. In some cases, this may even be preferable to sending a
      # 406 response. User agents are encouraged to inspect the headers of
      # an incoming response to determine if it is acceptable.
      #++

      def initialize(app, provides)
        @app, @types = app, {}
        provides.each { |f,types| types.each { |t| @types[t] = f } }
        @types.update(Const::MEDIA_RANGE_WILDCARD => :all)
      end

      def call(env)
        if accepts = env[Const::ENV_HTTP_ACCEPT]
          accepts = Utils.extract_qvalues(accepts)
          i = 0
          accepts = accepts.sort_by { |_,q| [-q,i+=1] }
          accepts.reject! { |t,q| q == 0 || !@types.key?(t) }
          if accepts.empty?
            return Const::NOT_ACCEPTABLE_RESPONSE
          else
            accepts.map! { |t,_| @types[t] }.uniq!
            env[CANDIDATES] = accepts
          end
        else
          env[CANDIDATES] = [:all]
        end
        @app.call(env)
      #rescue
      #  @app.call(env)
      end

    end
  end
end

# EOF