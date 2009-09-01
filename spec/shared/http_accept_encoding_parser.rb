shared_examples_for "simple HTTP_ACCEPT_ENCODING parser" do

  it "is able to extract Content-Codings and qvalues from the well-formed HTTP_ACCEPT_ENCODING header" do

    qvalues = @parser['gzip, compress']
    qvalues.should == [['gzip', 1.0], ['compress', 1.0]]

    qvalues = @parser['compress;q=0.5, gzip;q=1.0']
    qvalues.should == [['gzip', 1.0], ['compress', 0.5]]

    qvalues = @parser['gzip;q=1.0, identity; q=0.5, *;q=0']
    qvalues.should == [['gzip', 1.0], ['identity', 0.5], ['*', 0]]

  end

end

# EOF