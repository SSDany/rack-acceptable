require 'pathname'
require 'rubygems'

begin

  gem 'rspec', '~>1.2'
  require 'spec'

  SPEC_ROOT = Pathname(__FILE__).dirname.expand_path

  require SPEC_ROOT + 'lib' + 'fake_factory'
  require SPEC_ROOT + 'lib' + 'fake_request'

  SHARED_EXAMPLES_ROOT = SPEC_ROOT + 'shared'

  require SHARED_EXAMPLES_ROOT + 'qvalues_parser'
  require SHARED_EXAMPLES_ROOT + 'comma_separated_list_parser'
  require SHARED_EXAMPLES_ROOT + 'http_accept_language_parser'
  require SHARED_EXAMPLES_ROOT + 'http_accept_charset_parser'
  require SHARED_EXAMPLES_ROOT + 'http_accept_encoding_parser'
  require SHARED_EXAMPLES_ROOT + 'http_accept_parser'

  dir = SPEC_ROOT.parent.join('lib').to_s
  $:.unshift(dir) unless $:.include?(dir)
  require 'rack/acceptable'

rescue LoadError
end

# EOF