require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Rack::Acceptable::MIMETypes, ".detect_best_mime_type" do

  it "figures out which MIME-Types are acceptable" do

    helper = lambda do |header|
      accepts = Rack::Acceptable::MIMETypes::parse_accept(header) #FIXME
      Rack::Acceptable::MIMETypes.detect_best_mime_type(@snippets, accepts)
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
    helper["application/xbel+xml; q=0.3, application/*; q=0.5"    ].should == 'application/xml' # quality wins
    helper["application/xbel+xml; q=0.3, */*; q=0.5"              ].should == 'application/xml' # quality wins
    helper["application/xml, */*"                                 ].should == 'application/xml' # specificity wins
    helper["application/xml, application/*"                       ].should == 'application/xml' # specificity wins
    helper["application/*, application/xml"                       ].should == 'application/xml' # specificity wins

    @snippets = ["application/json", "text/html"]

    # stable sorting
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

  end

end

# EOF