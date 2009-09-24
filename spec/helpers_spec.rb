require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

describe Rack::Acceptable::Helpers do

  it "mixes in all the helpers we have" do
    request = Class.new(Rack::Request) { include Rack::Acceptable::Helpers }
    request.should include Rack::Acceptable::Helpers::Essentials
    request.should include Rack::Acceptable::Helpers::Locales
  end

end

# EOF
