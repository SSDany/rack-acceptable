module SpecHelpers
  module FakeRequest

    def fake_request!(&block)
      @_request = Class.new(Rack::Request,&block)
    end

    def fake_request(options = {})
      env = Rack::MockRequest.env_for('/', options)
      @_request.new(env)
    end

  end
end

# EOF