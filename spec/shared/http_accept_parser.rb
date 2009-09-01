shared_examples_for "simple HTTP_ACCEPT parser" do

  it "is able to extract (full) Media-Ranges and qvalues from the well-formed HTTP_ACCEPT header" do

    qvalues = @parser['text/plain, text/xml']
    qvalues.should == [['text/plain', 1.0], ['text/xml', 1.0]]

    qvalues = @parser['text/xml;q=0.5, text/plain;q=1.0']
    qvalues.should == [['text/xml', 0.5], ['text/plain', 1.0]]

    qvalues = @parser['text/plain;q=1.0, text/xml;q=0.5, *;q=0']
    qvalues.should == [['text/plain', 1.0], ['text/xml', 0.5], ['*', 0]]

    qvalues = @parser['text/plain;level=1;q=0.3, text/xml;q=0.5, *;q=0']
    qvalues.should == [['text/plain;level=1', 0.3], ['text/xml', 0.5], ['*', 0]] 

    # parameter is a part of media range, so it may be necessary.
    # http://tools.ietf.org/html/rfc2616#section-14.1

  end

end

# EOF