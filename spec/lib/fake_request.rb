module SpecHelpers
  module FakeRequest

    def fake_request!(base = Rack::Request, &block)
      @_request = block_given? ? Class.new(base, &block) : Class.new(base)
    end

    def fake_request(options = {})
      env = Rack::MockRequest.env_for('/', options)
      @_request.new(env)
    end

  end
end

# EOF