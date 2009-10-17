require "benchmark"

TIMES = ARGV[0] ? ARGV[0].to_i : 100_000

QVALUE_REGEX1 = /\A(?:0(?:\.\d{0,3})?|1(?:\.0{0,3})?)\z/.freeze
QVALUE_REGEX2 = /^0$|^0\.\d{0,3}$|^1$|^1\.0{0,3}$/.freeze

SNIPPETS = %w(0.42 0.000 1.000 0.333) * 10

Benchmark.bmbm do |x|
  x.report("nothing") { }
  x.report("each") { TIMES.times { SNIPPETS.each { } } }
  x.report("new regex") { TIMES.times { SNIPPETS.each { |s| QVALUE_REGEX1 === s } } }
  x.report("old regex") { TIMES.times { SNIPPETS.each { |s| QVALUE_REGEX2 === s } } }
end

# EOF