dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
$:.unshift(dir) unless $:.include?(dir)

require 'rack/acceptable'
require 'rubygems'

begin
  require 'rbench'
rescue LoadError
  $stderr << "You should have rbench installed in order to run benchmarks.\n" \
             "Try $gem in rbench\n" \
             "or take a look at http://github.com/somebee/rbench\n"
end

# EOF