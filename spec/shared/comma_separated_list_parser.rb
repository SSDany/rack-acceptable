shared_examples_for "simple parser of 1#(element) lists" do

  it "returns an empty array when there's an empty header (assume the header is not present)" do
    @parser[""].should == []
  end

  it "ignores both leading and trailing whitespaces" do
    @parser["  #{@sample};q=0.1"].should == [[@sample, 0.1]]
    @parser["#{@sample};q=0.1  "].should == [[@sample, 0.1]]
  end

  it "ignores whitespaces before/after commas and semicolons" do
    @parser["#{@sample} ;q=0.1,#{@sample} ;q=0.3"].should == [[@sample, 0.1], [@sample, 0.3]]
    @parser["#{@sample}; q=0.1,#{@sample}; q=0.3"].should == [[@sample, 0.1], [@sample, 0.3]]
    @parser["#{@sample};q=0.1 , #{@sample};q=0.3"].should == [[@sample, 0.1], [@sample, 0.3]]
  end

  it "raises an ArgumentError when the header passed is not empty, but blank (acc. to 1#-rule)" do
    lambda { @parser[" "]     }.should raise_error ArgumentError, @message
    lambda { @parser["\r\n"]  }.should raise_error ArgumentError, @message
  end

  it "raises an ArgumentError when the header passed contains empty entries " \
    "(i.e, it's a well-formed, but NOT conveniently collapsed comma-separated list)" do
    lambda { @parser[" #{@sample}, ,, "] }.should raise_error ArgumentError, @message
  end

end

# EOF