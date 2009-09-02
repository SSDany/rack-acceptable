require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Rack::Acceptable::Utils, ".detect_best_charset" do

  before :all do
    @helper = lambda do |provides, *accepts|
      Rack::Acceptable::Utils.detect_best_charset(provides, accepts)
    end
  end

  it "figures out which encodings are acceptable (in definitive cases)" do

    pending "standard samples" do

      @helper[%w(iso-8859-1)                         , ['*', 0.0]                         ].should == nil
      @helper[%w(iso-8859-1)                         , ['*', 1.0]                         ].should == 'iso-8859-1'
      @helper[%w(unicode-1-1 iso-8859-1)             , ['*', 0.0]                         ].should == nil
      @helper[%w(unicode-1-1 iso-8859-1)             , ['*', 1.0]                         ].should == 'unicode-1-1'
      @helper[%w(unicode-1-1)                        , ['*', 0.0]                         ].should == nil
      @helper[%w(unicode-1-1)                        , ['*', 1.0]                         ].should == 'unicode-1-1'

      @helper[%w(unicode-1-1 iso-8859-1 iso-8859-5)  , ['iso-8859-1', 0.0]                ].should == nil
      @helper[%w(unicode-1-1 iso-8859-1 iso-8859-5)  , ['iso-8859-1', 0.5]                ].should == 'iso-8859-1'
      @helper[%w(unicode-1-1 iso-8859-1 iso-8859-5)  , ['iso-8859-1', 1.0]                ].should == 'iso-8859-1'
      @helper[%w(unicode-1-1 iso-8859-1 iso-8859-5)  , ['iso-8859-5', 0.0], ['*', 0.0]    ].should == nil
      @helper[%w(unicode-1-1 iso-8859-1 iso-8859-5)  , ['iso-8859-5', 0.3], ['*', 0.5]    ].should == 'unicode-1-1'
      @helper[%w(unicode-1-1 iso-8859-1 iso-8859-5)  , ['iso-8859-5', 1.0], ['*', 0.5]    ].should == 'iso-8859-5'

    end

  end

  it "figures out which encodings are acceptable (when iso-8859-1 and wildcard is NOT explicitly mentioned)" do

    pending "RFC-ish shamanism with iso-8859-1" do

      @helper[%w(unicode-1-1 iso-8859-1)             , ['unicode-1-1', 0.0]               ].should == 'iso-8859-1'
      @helper[%w(unicode-1-1 iso-8859-1)             , ['unicode-1-1', 0.3]               ].should == 'iso-8859-1'
      @helper[%w(unicode-1-1 iso-8859-1)             , ['unicode-1-1', 1.0]               ].should == 'unicode-1-1' # more specific

      @helper[%w(unicode-1-1 iso-8859-1)             , ['iso-8859-5', 0.0]                ].should == 'iso-8859-1'
      @helper[%w(unicode-1-1 iso-8859-1)             , ['iso-8859-5', 0.3]                ].should == 'iso-8859-1'
      @helper[%w(unicode-1-1 iso-8859-1)             , ['iso-8859-5', 1.0]                ].should == 'iso-8859-1'

    end

  end

end

# EOF