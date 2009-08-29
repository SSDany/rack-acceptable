require 'pathname'
require 'rubygems'

begin

  gem 'rspec', '~>1.2'
  require 'spec'

  SPEC_ROOT = Pathname(__FILE__).dirname.expand_path
  require SPEC_ROOT.parent + 'lib/rack-acceptable'

rescue LoadError
end

# EOF