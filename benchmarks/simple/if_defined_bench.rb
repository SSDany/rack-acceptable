require "benchmark"

module Experimental

  def self.one
    @_var1 ||= begin
      2^10
    end
  end

  def self.two
    return @_var2 if defined? @_var2
    @_var2 = 2^10
  end

  def self.three
    if defined? @_var3
      @_var3
    else
      @_var3 = 2^10
    end
  end

end

TIMES = ARGV[0] ? ARGV[0].to_i : 1_000_000

Benchmark.bmbm do |x|

  x.report("one") do
    TIMES.times { Experimental.one }
  end

  x.report("two") do
    TIMES.times { Experimental.two }
  end

  x.report("three") do
    TIMES.times { Experimental.two }
  end

end

# EOF