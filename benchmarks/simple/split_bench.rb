# encoding: binary

require 'benchmark'

SNIPPETS = []

SNIPPETS << ''
SNIPPETS << 'foo'
SNIPPETS << 'foo-bar'
SNIPPETS << 'foo-bar-baz'
SNIPPETS << 'foo-bar-baz-whatever'

S_SPLITTER = '-'.freeze
R_SPLITTER = /-/.freeze

TIMES = ARGV[0] ? ARGV[0].to_i : 100_000

Benchmark.bmbm do |x|
  x.report("nothing") { }
  SNIPPETS.each do |snippet|
    x.report(snippet.inspect) { TIMES.times { snippet.split(S_SPLITTER) } }
  end
end

Benchmark.bmbm do |x|
  x.report("nothing") { }
  SNIPPETS.each do |snippet|
    x.report(snippet.inspect) { TIMES.times { snippet.split(R_SPLITTER) } }
  end
end

# EOF