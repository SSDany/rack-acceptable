shared_examples_for "simple HTTP_ACCEPT_LANGUAGE parser" do

  it "is able to extract Language-Ranges and qvalues from the well-formed HTTP_ACCEPT_LANGUAGE header" do

    qvalues = @parser['en-gb, en-us']
    qvalues.should == [['en-gb', 1.0], ['en-us', 1.0]]

    qvalues = @parser['en-us;q=0.5, en-gb;q=1.0']
    qvalues.should == [['en-us', 0.5], ['en-gb', 1.0]]

    qvalues = @parser['en-gb;q=1.0, en-us;q=0.5, *;q=0.3']
    qvalues.should == [['en-gb', 1.0], ['en-us', 0.5], ['*', 0.3]]

  end

end

# EOF