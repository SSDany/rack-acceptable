require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

describe Rack::Acceptable::Utils, ".extract_qvalues" do

  before :all do
    @qvalue = lambda { |thing| Rack::Acceptable::Utils.extract_qvalues(thing).first.last }
    @parser = lambda { |thing| Rack::Acceptable::Utils.extract_qvalues(thing) }
    @sample = 'whatever'
    @message = %r{Malformed quality factor}
  end

  describe "when parsing standalone snippet" do

    it_should_behave_like 'simple qvalues parser'

    it "picks out the FIRST 'q' parameter (if any)" do
      @qvalue['application/xml;q=0.5;p=q;q=557;a=42'].should == 0.5
    end

  end

  it "returns an empty Array when there's an empty header" do
    Rack::Acceptable::Utils.extract_qvalues("").should == []
  end

  it_should_behave_like 'simple HTTP_ACCEPT_LANGUAGE parser'
  it_should_behave_like 'simple HTTP_ACCEPT_CHARSET parser'
  it_should_behave_like 'simple HTTP_ACCEPT_ENCODING parser'
  it_should_behave_like 'simple HTTP_ACCEPT parser'

end

describe Rack::Acceptable::Utils, ".blank?" do

  it "returns true when there's an empty String" do
    Rack::Acceptable::Utils.blank?("").should be_true
  end

  it "returns true when there's a blank String" do
    Rack::Acceptable::Utils.blank?("   ").should be_true
    Rack::Acceptable::Utils.blank?("\t").should be_true
    Rack::Acceptable::Utils.blank?("\r\n").should be_true
  end

  it "returns false otherwise" do
    Rack::Acceptable::Utils.blank?("whatever").should be_false
  end

end

describe Rack::Acceptable::Utils, ".normalize_header" do

  it "removes leading and trailing whitespaces" do
    Rack::Acceptable::Utils.normalize_header("").should == ""
    Rack::Acceptable::Utils.normalize_header("\t").should == ""
    Rack::Acceptable::Utils.normalize_header("\r\n ").should == ""
    Rack::Acceptable::Utils.normalize_header(" whatever ").should == "whatever"
    Rack::Acceptable::Utils.normalize_header("\r\nwhatever\r\n").should == "whatever"
  end

  it "collapses comma-separated lists" do
    Rack::Acceptable::Utils.normalize_header("en,da,it , \r\n, ,, ").should == "en,da,it"
    Rack::Acceptable::Utils.normalize_header(" , \r\n, ,, en,da,it").should == "en,da,it"
    Rack::Acceptable::Utils.normalize_header("en, , \r\n, ,, da,it").should == "en,da,it"
  end

end

# EOF