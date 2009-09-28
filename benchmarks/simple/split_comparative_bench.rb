# encoding: binary

require 'rubygems'
require 'rbench'

SNIPPETS = []

SNIPPETS << ''
SNIPPETS << 'foo'
SNIPPETS << 'foo-bar'
SNIPPETS << 'foo-bar-baz'
SNIPPETS << 'foo-bar-baz-whatever'

S_SPLITTER = '-'.freeze
R_SPLITTER = /-/.freeze

TIMES = ARGV[0] ? ARGV[0].to_i : 100_000

RBench.run(TIMES) do

  column :times
  column :by_regex,   :title => 'regex'
  column :by_string,  :title => 'string'
  column :diff,       :title => '#2/#1', :compare => [:by_string, :by_regex]

  SNIPPETS.each do |snippet|
    report snippet.inspect do
      by_regex  { snippet.split(R_SPLITTER) }
      by_string { snippet.split(S_SPLITTER) } # faster on 1.9.1+
    end
  end

end

# EOF