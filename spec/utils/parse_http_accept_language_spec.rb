require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Rack::Acceptable::Utils, ".parse_http_accept_language" do

  it "raises an ArgumentError when Language-Range is malformed" do
    malformed = %w(mastahofshock en11 master-disaster-andsomethingmalformed en_gb *foo foo*)
    malformed.each do |snippet|
      lambda { Rack::Acceptable::Utils.parse_http_accept_language(snippet) }.
      should raise_error ArgumentError, %r{Malformed Language-Range}
    end
  end

end

# EOF