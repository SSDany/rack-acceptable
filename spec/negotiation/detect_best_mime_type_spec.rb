require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Rack::Acceptable::MIMETypes, ".detect_best_mime_type" do

  it "figures out which MIME-Types are acceptable" do

    helper = lambda do |header|
      env = Rack::MockRequest.env_for('/', 'HTTP_ACCEPT' => header)
      accepts = Rack::Acceptable::Request.new(env).acceptable_media
      Rack::Acceptable::MIMETypes.detect_best_mime_type(@snippets, accepts, false)
    end

    @snippets = ["application/xbel+xml", "application/xml"]

    helper[""                                                     ].should == 'application/xbel+xml'
    helper["*/*; q=1"                                             ].should == 'application/xbel+xml'
    helper["*/*; q=0"                                             ].should == nil
    helper["application/*; q=0"                                   ].should == nil
    helper["application/*; q=1"                                   ].should == 'application/xbel+xml'

    helper["application/xbel+xml"                                 ].should == 'application/xbel+xml'
    helper["application/xbel+xml; q=1"                            ].should == 'application/xbel+xml'
    helper["application/xbel+xml; q=0"                            ].should == nil
    helper["text/html,application/atom+xml; q=0.9"                ].should == nil
    helper["application/xbel+xml; q=0, application/xml; q=0.3"    ].should == 'application/xml'
    helper["application/xbel+xml; q=0.5, application/xml; q=0.3"  ].should == 'application/xbel+xml' # quality wins
    helper["application/xbel+xml; q=0.3, application/xml; q=0.5"  ].should == 'application/xml' # quality wins
    helper["application/xml; q=0.5, application/xbel+xml; q=0.3"  ].should == 'application/xml' # quality wins
    helper["application/xbel+xml; q=0.3, application/*; q=0.5"    ].should == 'application/xml' # quality wins
    helper["application/*; q=0.5, application/xbel+xml; q=0.3"    ].should == 'application/xml' # quality wins
    helper["application/xbel+xml; q=0.3, */*; q=0.5"              ].should == 'application/xml' # quality wins
    helper["application/xml, */*"                                 ].should == 'application/xml' # specificity wins
    helper["application/xml, application/*"                       ].should == 'application/xml' # specificity wins
    helper["application/*, application/xml"                       ].should == 'application/xml' # specificity wins

    @snippets = ["application/json", "text/html"]

    helper["application/json;q=0.5, text/html;q=0.5, text/plain;q=1"    ].should == "application/json"
    helper["text/html;q=0.5, application/json;q=0.5, text/plain;q=1"    ].should == "text/html"
    helper["text/plain;q=0.1, application/json;q=0.5, text/html;q=0.5"  ].should == "application/json"
    helper["text/plain;q=0.1, text/html;q=0.5, application/json;q=0.5"  ].should == "text/html"

    @snippets = ["application/json", "text/html;level=1", "text/html;level=2"]

    helper["application/json, text/javascript, */*"               ].should == "application/json"
    helper["application/json, text/html;q=0.9"                    ].should == "application/json"
    helper["text/html;level=2;q=0.5, text/html;level=1;q=0.3"     ].should == "text/html;level=2" # quality wins
    helper["text/html;level=2;q=0.5, text/html;level=1;q=0.5"     ].should == "text/html;level=2" # order (in header) wins
    helper["text/html;level=2;q=0.5, text/html;q=0.5"             ].should == "text/html;level=2" # specificity wins

    @snippets = ["*/*"]
    helper["application/json, text/html;q=0.9"                    ].should == "*/*"

    @snippets = ["text/*"]
    helper["application/json, text/html;q=0.9"                    ].should == "text/*"

    @snippets = ["text/*", "*/*"]
    helper["application/json, text/html;q=0.9"                    ].should == "*/*"
    helper["application/json;q=0.9, text/html"                    ].should == "text/*"

    @snippets = ["text/plain", "text/xml"]
    helper["text/*, text/xml"                                     ].should == "text/xml"
    helper["text/xml, text/*"                                     ].should == "text/xml"
    helper["text/xml, text/plain"                                 ].should == "text/xml"
    helper["text/plain, text/xml"                                 ].should == "text/plain"
    helper["text/*, text/plain"                                   ].should == "text/plain"
    helper["text/plain, text/plain"                               ].should == "text/plain"

  end

  it "respects the by_qvalue_only option" do

    helper = lambda do |header|
      env = Rack::MockRequest.env_for('/', 'HTTP_ACCEPT' => header)
      accepts = Rack::Acceptable::Request.new(env).acceptable_media
      Rack::Acceptable::MIMETypes.detect_best_mime_type(@snippets, accepts, true)
    end

    @snippets = ["application/xbel+xml", "application/xml"]

    helper[""                                                     ].should == 'application/xbel+xml'
    helper["*/*; q=1"                                             ].should == 'application/xbel+xml'
    helper["*/*; q=0"                                             ].should == nil
    helper["application/*; q=0"                                   ].should == nil
    helper["application/*; q=1"                                   ].should == 'application/xbel+xml'

    helper["application/xbel+xml"                                 ].should == 'application/xbel+xml'
    helper["application/xbel+xml; q=1"                            ].should == 'application/xbel+xml'
    helper["application/xbel+xml; q=0"                            ].should == nil
    helper["text/html,application/atom+xml; q=0.9"                ].should == nil
    helper["application/xbel+xml; q=0, application/xml; q=0.3"    ].should == 'application/xml'
    helper["application/xbel+xml; q=0.5, application/xml; q=0.3"  ].should == 'application/xbel+xml'
    helper["application/xbel+xml; q=0.3, application/xml; q=0.5"  ].should == 'application/xml'
    helper["application/xml; q=0.5, application/xbel+xml; q=0.3"  ].should == 'application/xml'
    helper["application/xbel+xml; q=0.3, application/*; q=0.5"    ].should == 'application/xml'
    helper["application/*; q=0.5, application/xbel+xml; q=0.3"    ].should == 'application/xml'
    helper["application/xbel+xml; q=0.3, */*; q=0.5"              ].should == 'application/xml'

    helper["application/xml, */*"                                 ].should == 'application/xbel+xml' # order of @snippets wins
    helper["application/xml, application/*"                       ].should == 'application/xbel+xml' # order of @snippets wins
    helper["application/*, application/xml"                       ].should == 'application/xbel+xml' # order of @snippets wins

    @snippets = ["application/json", "text/html"]

    helper["application/json;q=0.5, text/html;q=0.5, text/plain;q=1"    ].should == "application/json"
    helper["text/html;q=0.5, application/json;q=0.5, text/plain;q=1"    ].should == "application/json" # order of @snippets wins
    helper["text/plain;q=0.1, application/json;q=0.5, text/html;q=0.5"  ].should == "application/json" # order of @snippets wins
    helper["text/plain;q=0.1, text/html;q=0.5, application/json;q=0.5"  ].should == "application/json" # order of @snippets wins

    @snippets = ["application/json", "text/html;level=1", "text/html;level=2"]

    helper["application/json, text/javascript, */*"               ].should == "application/json"
    helper["application/json, text/html;q=0.9"                    ].should == "application/json"
    helper["text/html;level=2;q=0.5, text/html;level=1;q=0.3"     ].should == "text/html;level=2"
    helper["text/html;level=2;q=0.5, text/html;level=1;q=0.5"     ].should == "text/html;level=1" # order of @snippets wins
    helper["text/html;level=2;q=0.5, text/html;q=0.5"             ].should == "text/html;level=1" # order of @snippets wins

    @snippets = ["*/*"]
    helper["application/json, text/html;q=0.9"                    ].should == "*/*"

    @snippets = ["text/*"]
    helper["application/json, text/html;q=0.9"                    ].should == "text/*"

    @snippets = ["text/*", "*/*"]
    helper["application/json, text/html;q=0.9"                    ].should == "*/*"
    helper["application/json;q=0.9, text/html"                    ].should == "text/*"

    @snippets = ["text/plain", "text/xml"]
    helper["text/*, text/xml"                                     ].should == "text/plain"
    helper["text/xml, text/*"                                     ].should == "text/plain"
    helper["text/xml, text/plain"                                 ].should == "text/plain"
    helper["text/plain, text/xml"                                 ].should == "text/plain"
    helper["text/*, text/plain"                                   ].should == "text/plain"
    helper["text/plain, text/plain"                               ].should == "text/plain"

  end

end

# EOF