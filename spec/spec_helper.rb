require 'pathname'
require 'rubygems'

begin

  gem 'rspec', '~>1.2'
  require 'spec'

  SPEC_ROOT = Pathname(__FILE__).dirname.expand_path
  SHARED_EXAMPLES_ROOT = SPEC_ROOT + 'shared'

  require SHARED_EXAMPLES_ROOT + 'qvalues_parser'
  require SHARED_EXAMPLES_ROOT + 'http_accept_language_parser'
  require SHARED_EXAMPLES_ROOT + 'http_accept_charset_parser'
  require SHARED_EXAMPLES_ROOT + 'http_accept_encoding_parser'
  require SHARED_EXAMPLES_ROOT + 'http_accept_parser'

  require SPEC_ROOT.parent + 'lib/rack-acceptable'

rescue LoadError
end

# EOF