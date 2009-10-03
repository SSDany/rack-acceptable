require 'rake/gempackagetask'

Thread.new {
  require 'rubygems/specification'
  $spec = eval("$SAFE=3\n#{File.read('rack-acceptable.gemspec')}")
}.join

Rake::GemPackageTask.new($spec) { |pkg| pkg.gem_spec = $spec }

# EOF