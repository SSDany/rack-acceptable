require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Rack::Acceptable::Media do

  before :all do
    @_request = Class.new(Rack::Request) { include Rack::Acceptable::Media }
  end

  def fake_request(opts = {})
    env = Rack::MockRequest.env_for('/', opts)
    @_request.new(env)
  end

  describe "#accept_media?" do

    it "returns true, if the MIME-Type passed acceptable" do
      request = fake_request('HTTP_ACCEPT' => 'application/xml, text/*;q=0.3')
      request.accept_media?('text/plain').should == true
      request.accept_media?('text/css').should == true
      request.accept_media?('application/xml').should == true
    end

    it "returns false otherwise" do
      request = fake_request('HTTP_ACCEPT' => 'application/xml, text/*;q=0.3')
      request.accept_media?('video/quicktime').should == false
      request.accept_media?('image/jpeg').should == false

      request = fake_request('HTTP_ACCEPT' => 'text/plain;q=0,text/*')
      request.accept_media?('text/plain').should == false
    end

    it "even if the thing passed is not a well-formed MIME-Type" do
      request = fake_request('HTTP_ACCEPT' => 'application/xml, text/*;q=0.3')
      request.accept_media?('bogus!').should == false
      request.accept_media?(42).should == false
    end

  end

  describe "#best_media_for" do

    it "returns the best match, if there's a compliant media in Accept request-header" do
      request = fake_request('HTTP_ACCEPT' => 'text/plain;q=0.7, text/*;q=0.3')
      request.best_media_for( 'text/plain'      ).should == ['text' , 'plain' , {}, 0.7, nil]
      request.best_media_for( 'text/html'       ).should == ['text' , '*'     , {}, 0.3, nil]
      request.best_media_for( 'text/*'          ).should == ['text' , 'plain' , {}, 0.7, nil]
      request.best_media_for( '*/*'             ).should == ['text' , 'plain' , {}, 0.7, nil]

      request = fake_request('HTTP_ACCEPT' => 'text/plain;q=0.3, text/*;q=0.7')
      request.best_media_for( 'text/plain'      ).should == ['text' , 'plain' , {}, 0.3, nil]
      request.best_media_for( 'text/html'       ).should == ['text' , '*'     , {}, 0.7, nil]
      request.best_media_for( 'text/*'          ).should == ['text' , '*'     , {}, 0.7, nil]
      request.best_media_for( '*/*'             ).should == ['text' , '*'     , {}, 0.7, nil]
    end

    it "returns nil, if there's no compliant media in Accept request-header" do
      request = fake_request('HTTP_ACCEPT' => 'application/xml, text/plain;q=0.7, text/*;q=0.3')
      request.best_media_for('video/quicktime').should == nil
    end

  end

end

# EOF