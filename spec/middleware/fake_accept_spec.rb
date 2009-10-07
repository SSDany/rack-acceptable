require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Rack::Acceptable::FakeAccept do

  include FakeFactory

  before :all do
    Rack::Acceptable::MIMETypes.reset
    app!(%w(HTTP_ACCEPT rack-acceptable.fake_accept.original_HTTP_ACCEPT))
  end

  it "replaces the Accept request-header" do
    app!(%w(HTTP_ACCEPT rack-acceptable.fake_accept.original_HTTP_ACCEPT))
    @middleware = Rack::Acceptable::FakeAccept.new(app)

    request!('/whatever.in.json', 'HTTP_ACCEPT' => 'text/plain,*/*;q=0.9')
    body.should == ['application/json', 'text/plain,*/*;q=0.9']

    request!('/whatever.in.xml', 'HTTP_ACCEPT' => 'text/plain,*/*;q=0.9')
    body.should == ['application/xml', 'text/plain,*/*;q=0.9']
  end

  it "uses the default specified" do
    @middleware = Rack::Acceptable::FakeAccept.new(app, 'application/json')

    request!('/', 'HTTP_ACCEPT' => 'text/plain,*/*;q=0.9')
    body.should == ['application/json', 'text/plain,*/*;q=0.9']

    request!('/whatever', 'HTTP_ACCEPT' => 'text/plain,*/*;q=0.9')
    body.should == ['application/json', 'text/plain,*/*;q=0.9']

    request!('/whatever.bogus', 'HTTP_ACCEPT' => 'text/plain,*/*;q=0.9')
    body.should == ['application/json', 'text/plain,*/*;q=0.9']
  end

  it "uses 'text/html', if there's no default" do
    @middleware = Rack::Acceptable::FakeAccept.new(app)

    request!('/', 'HTTP_ACCEPT' => 'text/plain,*/*;q=0.9')
    body.should == ['text/html', 'text/plain,*/*;q=0.9']

    request!('/whatever', 'HTTP_ACCEPT' => 'text/plain,*/*;q=0.9')
    body.should == ['text/html', 'text/plain,*/*;q=0.9']

    request!('/whatever.bogus', 'HTTP_ACCEPT' => 'text/plain,*/*;q=0.9')
    body.should == ['text/html', 'text/plain,*/*;q=0.9']
  end

  after :all do
    Rack::Acceptable::MIMETypes.clear
  end

end

# EOF