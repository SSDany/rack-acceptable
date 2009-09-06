require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Rack::Acceptable::Utils, ".detect_best_encoding" do

  it "figures out which encodings are acceptable" do
    # adapted from rack specs

    helper = lambda do |provides, *accepts|
      Rack::Acceptable::Utils.detect_best_encoding(provides, accepts)
    end

    helper[%w(identity)               , ['*', 0.0]                        ].should == nil
    helper[%w(compress gzip identity) , ['*', 1.0]                        ].should == 'compress'
    helper[%w()                       , ['compress', 1.0]                 ].should == nil
    helper[%w(identity)               , ['identity', 0.0]                 ].should == nil
    helper[%w(identity)               , ['compress', 1.0], ['gzip', 1.0]  ].should == 'identity'
    helper[%w(compress gzip identity)                                     ].should == 'identity'
    helper[%w(compress gzip)                                              ].should == nil
    helper[%w(compress gzip identity) , ['*',1.0], ['compress',0.9]       ].should == 'gzip'
    helper[%w(compress gzip identity) , ['*',0.0], ['identity',0.1]       ].should == 'identity'
    helper[%w(compress gzip identity) , ['compress',0.0], ['gzip',0.0]    ].should == 'identity'

    helper[%w(compress gzip identity) , ['compress',1.0], ['gzip',1.0]    ].should == 'compress'
    helper[%w(compress gzip identity) , ['gzip',1.0], ['compress',0.5]    ].should == 'gzip'
    helper[%w(compress gzip identity) , ['gzip',0.5], ['compress',1.0]    ].should == 'compress'
    helper[%w(compress gzip identity) , ['*',0.0], ['identity',0.1]       ].should == 'identity'
    helper[%w(compress gzip identity) , ['identity',0.1], ['*',0.0]       ].should == 'identity'
    helper[%w(compress gzip identity) , ['gzip',0.5], ['identity',0.1]    ].should == 'gzip'
    helper[%w(compress gzip identity) , ['identity',0.1], ['gzip',0.5]    ].should == 'gzip'
    helper[%w(compress gzip)          , ['identity',0.1], ['*',0.0]       ].should == nil

    # stable sorting:

    helper[%w(compress gzip identity) , ['compress',1.0], ['gzip',1.0]  ].should == 'compress'
    helper[%w(compress gzip identity) , ['gzip',1.0], ['compress',1.0]  ].should == 'gzip'

    helper[%w(compress gzip identity) , ['compress',0.5], ['gzip',0.5], ['deflate', 1.0]  ].should == 'compress'
    helper[%w(compress gzip identity) , ['gzip',0.5], ['compress',0.5], ['deflate', 1.0]  ].should == 'gzip'
    helper[%w(compress gzip identity) , ['deflate', 0.3], ['compress',0.5], ['gzip',0.5]  ].should == 'compress'
    helper[%w(compress gzip identity) , ['deflate', 0.3], ['gzip',0.5], ['compress',0.5]  ].should == 'gzip'

  end

end

# EOF