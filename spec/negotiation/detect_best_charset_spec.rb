require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Rack::Acceptable::Utils, ".detect_best_charset" do

  before :all do
    @helper = lambda do |provides, *accepts|
      Rack::Acceptable::Utils.detect_best_charset(provides, accepts)
    end
  end

  it "figures out which Charsets are acceptable (when iso-8859-1 and wildcard is NOT explicitly mentioned)" do

    @helper[%w(utf-8 iso-8859-1)                        ].should == 'utf-8'
    @helper[%w()                  , ['utf-8', 0.3]      ].should == nil

    @helper[%w(utf-8 iso-8859-1)  , ['utf-8', 0.0]      ].should == 'iso-8859-1'
    @helper[%w(utf-8 iso-8859-1)  , ['utf-8', 0.3]      ].should == 'iso-8859-1'
    @helper[%w(utf-8 iso-8859-1)  , ['utf-8', 1.0]      ].should == 'utf-8' # more specific
    @helper[%w(iso-8859-1, utf-8) , ['utf-8', 1.0]      ].should == 'utf-8' # once again: more specific

    @helper[%w(utf-8 iso-8859-1)  , ['iso-8859-5', 0.0] ].should == 'iso-8859-1'
    @helper[%w(utf-8 iso-8859-1)  , ['iso-8859-5', 0.3] ].should == 'iso-8859-1'
    @helper[%w(utf-8 iso-8859-1)  , ['iso-8859-5', 1.0] ].should == 'iso-8859-1'

    # iso-8859-1 is acceptable, but NOT available
    provides = %w(utf-8 windows-1252 iso-8859-5)
    @helper[provides  , ['iso-8859-5', 0.0], ['windows-1252', 0.0]  ].should == nil
    @helper[provides  , ['iso-8859-5', 0.3], ['windows-1252', 0.5]  ].should == 'windows-1252' 
    @helper[provides  , ['iso-8859-5', 0.5], ['windows-1252', 0.3]  ].should == 'iso-8859-5'

    # stable sorting:
    @helper[provides  , ['iso-8859-5', 0.5], ['windows-1252', 0.5]  ].should == 'iso-8859-5'
    @helper[provides  , ['windows-1252', 0.5], ['iso-8859-5', 0.5]  ].should == 'windows-1252'

    # iso-8859-1 is acceptable and available
    provides = %w(utf-8 windows-1252 iso-8859-1 iso-8859-5)
    @helper[provides  , ['iso-8859-5', 0.0], ['windows-1252', 0.0]  ].should == 'iso-8859-1'
    @helper[provides  , ['iso-8859-5', 0.3], ['windows-1252', 0.5]  ].should == 'iso-8859-1'
    @helper[provides  , ['iso-8859-5', 0.5], ['windows-1252', 0.3]  ].should == 'iso-8859-1'

  end

  it "figures out which charsets are acceptable (when iso-8859-1 or wildcard is explicitly mentioned)" do

    @helper[%w()                          , ['*', 1.0]  ].should == nil
    @helper[%w(iso-8859-1)                , ['*', 0.0]  ].should == nil
    @helper[%w(iso-8859-1)                , ['*', 1.0]  ].should == 'iso-8859-1'
    @helper[%w(utf-8 iso-8859-1)          , ['*', 0.0]  ].should == nil
    @helper[%w(utf-8 iso-8859-1)          , ['*', 1.0]  ].should == 'utf-8'
    @helper[%w(utf-8)                     , ['*', 0.0]  ].should == nil
    @helper[%w(utf-8)                     , ['*', 1.0]  ].should == 'utf-8'

    provides = %w(utf-8 iso-8859-1 iso-8859-5)

    @helper[provides  , ['iso-8859-1', 0.0]                 ].should == nil
    @helper[provides  , ['iso-8859-1', 0.5]                 ].should == 'iso-8859-1'
    @helper[provides  , ['iso-8859-1', 1.0]                 ].should == 'iso-8859-1'

    @helper[provides  , ['iso-8859-1', 0.3], ['utf-8', 0.5] ].should == 'utf-8'
    @helper[provides  , ['iso-8859-1', 0.5], ['utf-8', 0.3] ].should == 'iso-8859-1'

    @helper[provides  , ['iso-8859-5', 0.5], ['*', 0.5]     ].should == 'iso-8859-5'
    @helper[provides  , ['*', 0.5], ['iso-8859-5', 0.5]     ].should == 'utf-8' # wildcard is the first one in header.

    @helper[provides  , ['iso-8859-5', 0.3], ['*', 0.5]     ].should == 'utf-8'
    @helper[provides  , ['iso-8859-5', 0.5], ['*', 0.3]     ].should == 'iso-8859-5'
    @helper[provides  , ['iso-8859-5', 0.0], ['*', 0.0]     ].should == nil

    provides = %w(utf-8 windows-1252 iso-8859-5)

    @helper[provides  , ['windows-1252', 0.5], ['iso-8859-5', 0.5], ['*', 0.1]  ].should == 'windows-1252'
    @helper[provides  , ['iso-8859-5', 0.5], ['windows-1252', 0.5], ['*', 0.1]  ].should == 'iso-8859-5'

    # stable sorting
    @helper[provides  , ['*', 0.1], ['windows-1252', 0.5], ['iso-8859-5', 0.5]  ].should == 'windows-1252'
    @helper[provides  , ['*', 0.1], ['iso-8859-5', 0.5], ['windows-1252', 0.5]  ].should == 'iso-8859-5'

    @helper[provides  , ['iso-8859-5', 0.3], ['windows-1252', 0.5], ['*', 0.1]  ].should == 'windows-1252'
    @helper[provides  , ['iso-8859-5', 0.5], ['windows-1252', 0.3], ['*', 0.1]  ].should == 'iso-8859-5'
    @helper[provides  , ['iso-8859-5', 0.3], ['*', 0.5]                         ].should == 'utf-8'
    @helper[provides  , ['iso-8859-5', 0.3], ['*', 0.5], ['windows-1252', 0.6]  ].should == 'windows-1252'

  end

end

# EOF