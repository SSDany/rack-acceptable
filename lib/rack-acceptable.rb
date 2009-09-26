require 'rubygems'
gem 'rack', '~>1.0'
require 'rack'

__DIR__ = File.dirname(__FILE__)

$LOAD_PATH.unshift __DIR__ unless
  $LOAD_PATH.include?(__DIR__) ||
  $LOAD_PATH.include?(File.expand_path(__DIR__))

module Rack #:nodoc:
  module Acceptable

    autoload :Const           , 'rack-acceptable/constants'

    autoload :Utils           , 'rack-acceptable/utils'
    autoload :Encodings       , 'rack-acceptable/encodings'
    autoload :Charsets        , 'rack-acceptable/charsets'
    autoload :Languages       , 'rack-acceptable/languages'
    autoload :MIMETypes       , 'rack-acceptable/mimetypes'

    autoload :LanguageTag     , 'rack-acceptable/language_tag'

    autoload :Formats         , 'rack-acceptable/middleware/formats'
    autoload :Helpers         , 'rack-acceptable/helpers'

  end
end

# EOF