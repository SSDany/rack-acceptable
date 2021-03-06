require 'yaml'
module SpecHelpers
  module FakeFactory

    attr_reader :response
    attr_reader :app

    def app!(keys, status = 200, headers = {})
      @app = lambda { |env| [status, headers, [YAML.dump(env.values_at(*keys))]] }
    end

    def request!(*args)
      options = args.last.is_a?(::Hash) ? args.pop : {}
      env = Rack::MockRequest.env_for(args.first || "/", options)
      @response = Rack::MockRequest.new(@middleware).request('GET', args.first || "/", options)
    end

    def body
      YAML.load(@response.body)
    end

  end
end

# EOF