require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Rack::Acceptable::MIMETypes, ".qualify_mime_type" do

  def qualify(type, subtype, params)
    Rack::Acceptable::MIMETypes.qualify_mime_type([type, subtype, params], @accepts)
  end

  it "qualifies MIME-Types correctly" do

    @accepts =  ['text', 'plain', {'b' => '2'}, 0.5, {}],
                ['text', 'plain', {'a' => '1'}, 0.3, {}]
                # text/plain;a=1;b=2;q=0.3, text/plain;a=1;q=0.5

    qualify('text', 'plain', {'a' => '1'}                           ).should == 0.3 # text/plain;a=1
    qualify('text', 'plain', {'a' => '2'}                           ).should == 0.0 # text/plain;a=2
    qualify('text', 'plain', {'b' => '1'}                           ).should == 0.0 # text/plain;b=1
    qualify('text', 'plain', {'b' => '2'}                           ).should == 0.5 # text/plain;b=2
    qualify('text', 'plain', {'a' => '1', 'b' => '2'}               ).should == 0.5 # text/plain;a=1;b=2

    @accepts =  ['text', 'plain', {'a' => '1'}, 0.3, {}],
                ['text', 'plain', {'b' => '2'}, 0.5, {}]
                # text/plain;a=1;b=2;q=0.3, text/plain;a=1;q=0.5

    qualify('text', 'plain', {'a' => '1'}                           ).should == 0.3 # text/plain;a=1
    qualify('text', 'plain', {'a' => '2'}                           ).should == 0.0 # text/plain;a=2
    qualify('text', 'plain', {'b' => '1'}                           ).should == 0.0 # text/plain;b=1
    qualify('text', 'plain', {'b' => '2'}                           ).should == 0.5 # text/plain;b=2
    qualify('text', 'plain', {'a' => '1', 'b' => '2'}               ).should == 0.5 # text/plain;a=1;b=2

    @accepts =  ['text', 'plain', {}, 1.0, {}],
                ['text', 'plain', {'a' => '1', 'b' => '2'}, 0.5, {}],
                ['text', 'plain', {'a' => '1'}, 0.3, {}]
                # text/plain;a=1;b=2;q=0.5, text/plain;a=1;q=0.3, text/plain;q=1.0

    qualify('text', 'plain', {}                                     ).should == 1.0 # text/plain
    qualify('text', 'plain', {'a' => '1'}                           ).should == 0.3 # text/plain;a=1
    qualify('text', 'plain', {'a' => '2'}                           ).should == 1.0 # text/plain;a=2
    qualify('text', 'plain', {'b' => '1'}                           ).should == 1.0 # text/plain;b=1
    qualify('text', 'plain', {'b' => '2'}                           ).should == 1.0 # text/plain;b=2
    qualify('text', 'plain', {'a' => '1', 'b' => '1'}               ).should == 0.3 # text/plain;a=1;b=1
    qualify('text', 'plain', {'a' => '1', 'b' => '2'}               ).should == 0.5 # text/plain;a=1;b=2
    qualify('text', 'plain', {'a' => '2', 'b' => '1'}               ).should == 1.0 # text/plain;a=2;b=1
    qualify('text', 'plain', {'a' => '2', 'b' => '2'}               ).should == 1.0 # text/plain;a=2;b=2
    qualify('text', 'plain', {'a' => '1', 'b' => '2', 'c' => '3'}   ).should == 0.5 # text/plain;a=1;b=2;c=3
    qualify('text', 'plain', {'a' => '1', 'c' => '3'}               ).should == 0.3 # text/plain;a=1;c=3
    qualify('text', 'plain', {'b' => '2', 'c' => '3'}               ).should == 1.0 # text/plain;b=2;c=3
    qualify('text', 'plain', {'c' => '3'}                           ).should == 1.0 # text/plain;c=3

    @accepts =  ['text', 'plain', {}, 1.0, {}],
                ['text', 'plain', {'a' => '1'}, 0.5, {}],
                ['text', 'plain', {'a' => '1', 'b' => '2'}, 0.3, {}]
                # text/plain;a=1;b=2;q=0.3, text/plain;a=1;q=0.5, text/plain;q=1.0

    qualify('text', 'plain', {}                                     ).should == 1.0 # text/plain
    qualify('text', 'plain', {'a' => '1'}                           ).should == 0.5 # text/plain;a=1
    qualify('text', 'plain', {'a' => '2'}                           ).should == 1.0 # text/plain;a=2
    qualify('text', 'plain', {'b' => '1'}                           ).should == 1.0 # text/plain;b=1
    qualify('text', 'plain', {'b' => '2'}                           ).should == 1.0 # text/plain;b=2
    qualify('text', 'plain', {'a' => '1', 'b' => '1'}               ).should == 0.5 # text/plain;a=1;b=1
    qualify('text', 'plain', {'a' => '1', 'b' => '2'}               ).should == 0.3 # text/plain;a=1;b=2
    qualify('text', 'plain', {'a' => '2', 'b' => '1'}               ).should == 1.0 # text/plain;a=2;b=1
    qualify('text', 'plain', {'a' => '2', 'b' => '2'}               ).should == 1.0 # text/plain;a=2;b=2
    qualify('text', 'plain', {'a' => '1', 'b' => '2', 'c' => '3'}   ).should == 0.3 # text/plain;a=1;b=2;c=3
    qualify('text', 'plain', {'a' => '1', 'c' => '3'}               ).should == 0.5 # text/plain;a=1;c=3
    qualify('text', 'plain', {'b' => '2', 'c' => '3'}               ).should == 1.0 # text/plain;b=2;c=3
    qualify('text', 'plain', {'c' => '3'}                           ).should == 1.0 # text/plain;c=3

    @accepts =  ['text', 'plain', {'a' => '1', 'b' => '2'}, 0.3, {}],
                ['text', 'plain', {'a' => '1'}, 0.5, {}],
                ['text', 'plain', {}, 1.0, {}]
                # text/plain;a=1;b=2;q=0.3, text/plain;a=1;q=0.5, text/plain;q=1.0

    qualify('text', 'plain', {}                                     ).should == 1.0 # text/plain
    qualify('text', 'plain', {'a' => '1'}                           ).should == 0.5 # text/plain;a=1
    qualify('text', 'plain', {'a' => '2'}                           ).should == 1.0 # text/plain;a=2
    qualify('text', 'plain', {'b' => '1'}                           ).should == 1.0 # text/plain;b=1
    qualify('text', 'plain', {'b' => '2'}                           ).should == 1.0 # text/plain;b=2
    qualify('text', 'plain', {'a' => '1', 'b' => '1'}               ).should == 0.5 # text/plain;a=1;b=1
    qualify('text', 'plain', {'a' => '1', 'b' => '2'}               ).should == 0.3 # text/plain;a=1;b=2
    qualify('text', 'plain', {'a' => '2', 'b' => '1'}               ).should == 1.0 # text/plain;a=2;b=1
    qualify('text', 'plain', {'a' => '2', 'b' => '2'}               ).should == 1.0 # text/plain;a=2;b=2
    qualify('text', 'plain', {'a' => '1', 'b' => '2', 'c' => '3'}   ).should == 0.3 # text/plain;a=1;b=2;c=3
    qualify('text', 'plain', {'a' => '1', 'c' => '3'}               ).should == 0.5 # text/plain;a=1;c=3
    qualify('text', 'plain', {'b' => '2', 'c' => '3'}               ).should == 1.0 # text/plain;b=2;c=3
    qualify('text', 'plain', {'c' => '3'}                           ).should == 1.0 # text/plain;c=3

  end

  it "in compliance with RFC2616#14 standards" do

    @accepts =  ['text' , 'html'  , {'level' => '1'}, 1.0, {}],
                ['text' , 'html'  , {}, 0.7, {}],
                ['*'    , '*'     , {}, 0.5, {}],
                ['text' , 'html'  , {'level' => '2'}, 0.4, {}],
                ['text' , '*'     , {}, 0.3, {}]
                # text/*;q=0.3, text/html;q=0.7, text/html;level=1, text/html;level=2;q=0.4, */*;q=0.5

    qualify('text' , 'html'  , {'level' => '1'} ).should == 1.0 # text/html;level=1
    qualify('text' , 'html'  , {}               ).should == 0.7 # text/html
    qualify('text' , 'plain' , {}               ).should == 0.3 # text/plain
    qualify('image', 'jpeg'  , {}               ).should == 0.5 # image/jpeg
    qualify('text' , 'html'  , {'level' => '2'} ).should == 0.4 # text/html;level=2
    qualify('text' , 'html'  , {'level' => '3'} ).should == 0.7 # text/html;level=3

    @accepts =  ['text' , '*'     , {}, 0.3, {}],
                ['text' , 'html'  , {}, 0.7, {}],
                ['text' , 'html'  , {'level' => '1'}, 1.0, {}],
                ['text' , 'html'  , {'level' => '2'}, 0.4, {}],
                ['*'    , '*'     , {}, 0.5, {}]
                # text/*;q=0.3, text/html;q=0.7, text/html;level=1, text/html;level=2;q=0.4, */*;q=0.5

    qualify('text' , 'html'  , {'level' => '1'} ).should == 1.0 # text/html;level=1
    qualify('text' , 'html'  , {}               ).should == 0.7 # text/html
    qualify('text' , 'plain' , {}               ).should == 0.3 # text/plain
    qualify('image', 'jpeg'  , {}               ).should == 0.5 # image/jpeg
    qualify('text' , 'html'  , {'level' => '2'} ).should == 0.4 # text/html;level=2
    qualify('text' , 'html'  , {'level' => '3'} ).should == 0.7 # text/html;level=3

  end

  it "supports wildcards" do
    @accepts =  ['text' , 'html'  , {'level' => '1'}, 1.0, {}],
                ['text' , 'html'  , {}, 0.7, {}],
                ['*'    , '*'     , {}, 0.5, {}],
                ['text' , '*'     , {}, 0.3, {}]

    qualify('text'  , 'html'  , {'level' => '1'} ).should == 1.0 # match: text/html;level=1
    qualify('text'  , 'html'  , {}               ).should == 0.7 # match: text/html

    # most sensible example:
    # the best candidate for the 'text/*' pattern is a 'text/html;q=0.7'
    # but for the 'text/plain' it's a 'text/*;q=0.3'
    #
    # i.e, the non-zero weight of the 'text/*' pattern
    # should be treated as: "at least one 'text' MIME-Type without
    # parameters is acceptable"

    qualify('text'  , '*'     , {}               ).should == 0.7 # match: text/html
    qualify('text'  , 'plain' , {}               ).should == 0.3 # match: text/*

    qualify('text'  , '*'     , {'level' => '1'} ).should == 1.0 # match: text/html;level=1
    qualify('video' , '*'     , {}               ).should == 0.5 # match: */*
    qualify('*'     , '*'     , {}               ).should == 0.7 # match: text/html
    qualify('*'     , '*'     , {'level' => '1'} ).should == 1.0 # match: text/html;level=1

    @accepts =  ['text' , 'html'  , {'level' => '1'}, 0.7, {}],
                ['text' , 'html'  , {}, 0.5, {}],
                ['*'    , '*'     , {}, 1.0, {}],
                ['text' , '*'     , {}, 0.3, {}]

    qualify('text'  , 'html'  , {'level' => '1'} ).should == 0.7 # match: text/html;level=1
    qualify('text'  , 'html'  , {}               ).should == 0.5 # match: text/html
    qualify('text'  , '*'     , {}               ).should == 0.5 # match: text/html
    qualify('text'  , '*'     , {'level' => '1'} ).should == 0.7 # match: text/html;level=1
    qualify('video' , '*'     , {}               ).should == 1.0 # match: */*
    qualify('*'     , '*'     , {}               ).should == 1.0 # match: */*
    qualify('*'     , '*'     , {'level' => '1'} ).should == 0.7 # match: text/html;level=1

  end
end

# EOF