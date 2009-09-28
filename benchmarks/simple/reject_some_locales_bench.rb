require "benchmark"

ARRAY = [['x', 0.1], ['i', 0.1]]
('aa'..'az').each { |s| ARRAY.unshift [s, 0.5] }

PRIVATEUSE    = 'x'.freeze
GRANDFATHERED = 'i'.freeze
WILDCARD      = '*'.freeze

UNDESIRABLE = [PRIVATEUSE,GRANDFATHERED].freeze

TIMES = ARGV[0] ? ARGV[0].to_i : 20_000

Benchmark.bmbm do |x|
  x.report("check if in array")     { TIMES.times { ARRAY.dup.reject!{ |l,_| UNDESIRABLE.include?(l) }}}
  x.report("couple of comparisons") { TIMES.times { ARRAY.dup.reject!{ |l,_| l == PRIVATEUSE || l == GRANDFATHERED }}}
  x.report("check length #1")       { TIMES.times { ARRAY.dup.reject!{ |l,_| l != WILDCARD && l.length == 1 }}}
  x.report("check length #2")       { TIMES.times { ARRAY.dup.reject!{ |l,_| l.length == 1 && l != WILDCARD }}}
end

# EOF