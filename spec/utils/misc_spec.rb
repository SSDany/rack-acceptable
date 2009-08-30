require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Rack::Acceptable::Utils, '.blank?' do

  it "returns true when the String it was passed is empty" do
    Rack::Acceptable::Utils.blank?("").should be_true
  end

  it "returns true when the String it was passed is blank" do
    Rack::Acceptable::Utils.blank?("   ").should be_true
    Rack::Acceptable::Utils.blank?("\t").should be_true
    Rack::Acceptable::Utils.blank?("\r\n").should be_true
  end

  it "returns false otherwise" do
    Rack::Acceptable::Utils.blank?("whatever").should be_false
  end

end

# EOF