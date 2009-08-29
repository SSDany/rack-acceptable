require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Rack::Acceptable::Utils, ".extract_qvalues" do

  describe "when parsing standalone snippet" do

    def qvalue_at(snippet)
      Rack::Acceptable::Utils.extract_qvalues(snippet).first.at(1)
    end

    it "defaults quality factor to 1.0" do
      qvalue_at('compress').should == 1.0
      qvalue_at('whatever').should == 1.0
    end

    it "picks out the FIRST 'q' parameter (if any)" do
      qvalue_at('application/xml;q=0.5;p=q;q=557;a=42').should == 0.5
    end

    it "extracts well-formed quality factors" do
      qvalue_at('compress;q=0').should     == 0.000
      qvalue_at('compress;q=1').should     == 1.000
      qvalue_at('compress;q=0.000').should == 0.000
      qvalue_at('compress;q=1.000').should == 1.000
      qvalue_at('compress;q=0.333').should == 0.333
      qvalue_at('compress;q=0.3').should   == 0.300
      qvalue_at('compress;q=1.').should    == 1.000
      qvalue_at('compress;q=0.').should    == 0.000
    end

    it "but raises an ArgumentError when the quality factor is malformed" do
      malformed = ["42", "bogus", "", ".3", "-0.4", "1/3", "0.3333", "1.01", "2.22"]
      malformed.each do |qvalue|
        snippet = "compress;q=#{qvalue}"
        lambda { Rack::Acceptable::Utils.extract_qvalues(snippet) }.
        should raise_error ArgumentError, %r{^Malformed quality factor}
      end
    end

  end

  it "returns an empty array if the value it was passed is an empty string" do
    Rack::Acceptable::Utils.extract_qvalues('').should == []
  end

  it "is able to extract quality factors from the HTTP_ACCEPT header" do

    qvalues = Rack::Acceptable::Utils.extract_qvalues('text/plain, text/xml')
    qvalues.should == [['text/plain', 1.0], ['text/xml', 1.0]]

    qvalues = Rack::Acceptable::Utils.extract_qvalues('text/xml;q=0.5, text/plain;q=1.0')
    qvalues.should == [['text/plain', 1.0], ['text/xml', 0.5]]

    qvalues = Rack::Acceptable::Utils.extract_qvalues('text/plain;q=1.0, text/xml;q=0.5, *;q=0')
    qvalues.should == [['text/plain', 1.0], ['text/xml', 0.5], ['*', 0]]

  end

  it "is able to extract quality factors from the HTTP_ACCEPT_ENCODING header" do

    qvalues = Rack::Acceptable::Utils.extract_qvalues('gzip, compress')
    qvalues.should == [['gzip', 1.0], ['compress', 1.0]]

    qvalues = Rack::Acceptable::Utils.extract_qvalues('compress;q=0.5, gzip;q=1.0')
    qvalues.should == [['gzip', 1.0], ['compress', 0.5]]

    qvalues = Rack::Acceptable::Utils.extract_qvalues('gzip;q=1.0, identity; q=0.5, *;q=0')
    qvalues.should == [['gzip', 1.0], ['identity', 0.5], ['*', 0]]

  end

  it "is able to extract quality factors from the HTTP_ACCEPT_LANGUAGE header" do

    qvalues = Rack::Acceptable::Utils.extract_qvalues('en-gb, en-us')
    qvalues.should == [['en-gb', 1.0], ['en-us', 1.0]]

    qvalues = Rack::Acceptable::Utils.extract_qvalues('en-us;q=0.5, en-gb;q=1.0')
    qvalues.should == [['en-gb', 1.0], ['en-us', 0.5]]

    qvalues = Rack::Acceptable::Utils.extract_qvalues('en-gb;q=1.0, en-us;q=0.5, *;q=0')
    qvalues.should == [['en-gb', 1.0], ['en-us', 0.5], ['*', 0]]

  end

  it "is able to extract quality factors from the HTTP_ACCEPT_CHARSET header" do

    qvalues = Rack::Acceptable::Utils.extract_qvalues('unicode-1-1, iso-8859-5')
    qvalues.should == [['unicode-1-1', 1.0], ['iso-8859-5', 1.0]]

    qvalues = Rack::Acceptable::Utils.extract_qvalues('iso-8859-5;q=0.5, unicode-1-1;q=1.0')
    qvalues.should == [['unicode-1-1', 1.0], ['iso-8859-5', 0.5]]

    qvalues = Rack::Acceptable::Utils.extract_qvalues('unicode-1-1;q=1.0, iso-8859-5;q=0.5, *;q=0')
    qvalues.should == [['unicode-1-1', 1.0], ['iso-8859-5', 0.5], ['*', 0]]

  end

end

# EOF