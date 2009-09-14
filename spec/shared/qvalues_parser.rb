shared_examples_for 'simple qvalues parser' do

  it "extracts well-formed quality factors" do
    @qvalue[ "#{@sample};q=0"     ].should == 0.000
    @qvalue[ "#{@sample};q=1"     ].should == 1.000
    @qvalue[ "#{@sample};q=0.000" ].should == 0.000
    @qvalue[ "#{@sample};q=1.000" ].should == 1.000
    @qvalue[ "#{@sample};q=0.3"   ].should == 0.300
    @qvalue[ "#{@sample};q=0.33"  ].should == 0.330
    @qvalue[ "#{@sample};q=0.333" ].should == 0.333
    @qvalue[ "#{@sample};q=1."    ].should == 1.000
    @qvalue[ "#{@sample};q=0."    ].should == 0.000
  end

  it "defaults the quality factor to 1.0" do
    @qvalue[@sample].should == 1.0
  end

  it "raises an ArgumentError when there's a malformed quality factor" do
    lambda { @qvalue["#{@sample};q=42"]     }.should raise_error ArgumentError, @message
    lambda { @qvalue["#{@sample};q=bogus"]  }.should raise_error ArgumentError, @message
    lambda { @qvalue["#{@sample};q=.3"]     }.should raise_error ArgumentError, @message
    lambda { @qvalue["#{@sample};q=0.3333"] }.should raise_error ArgumentError, @message
    lambda { @qvalue["#{@sample};q=2.22"]   }.should raise_error ArgumentError, @message
    lambda { @qvalue["#{@sample};q=1.01"]   }.should raise_error ArgumentError, @message
  end

end

# EOF