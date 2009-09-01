shared_examples_for "simple HTTP_ACCEPT_CHARSET parser" do

  it "is able to extract Charsets and qvalues from the well-formed HTTP_ACCEPT_CHARSET header" do

    qvalues = @parser['unicode-1-1, iso-8859-5']
    qvalues.should == [['unicode-1-1', 1.0], ['iso-8859-5', 1.0]]

    qvalues = @parser['iso-8859-5;q=0.5, unicode-1-1;q=1.0']
    qvalues.should == [['unicode-1-1', 1.0], ['iso-8859-5', 0.5]]

    qvalues = @parser['unicode-1-1;q=1.0, iso-8859-5;q=0.5, *;q=0']
    qvalues.should == [['unicode-1-1', 1.0], ['iso-8859-5', 0.5], ['*', 0]]

  end

end

# EOF