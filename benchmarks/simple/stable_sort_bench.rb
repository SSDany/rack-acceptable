require "benchmark"

ARRAY = [['foo', 0.1], ['bar', 0.1], ['baz', 0.3]]

TIMES = ARGV[0] ? ARGV[0].to_i : 100_000

Benchmark.bmbm do |x|

  x.report("simple") do
    TIMES.times do
      i = 0
      ARRAY.sort_by { |_,q| [-q,i+=1] }
    end
  end

  x.report("each_with_index") do
    TIMES.times do
      ARRAY.sort_by.each_with_index { |(_,q),i| [-q,i] }
    end
  end

end

# EOF