require 'rubygems'
gem 'rack', '~>1.0'
require 'rack'

__DIR__ = File.dirname(__FILE__)

$LOAD_PATH.unshift __DIR__ unless
  $LOAD_PATH.include?(__DIR__) ||
  $LOAD_PATH.include?(File.expand_path(__DIR__))

module Rack #:nodoc:
  module Acceptable

    # common
    autoload :Const           , 'rack-acceptable/const'
    autoload :Utils           , 'rack-acceptable/utils'
    autoload :MIMETypes       , 'rack-acceptable/mimetypes'
    autoload :LanguageTag     , 'rack-acceptable/language_tag'

    # request and mixins
    autoload :Headers         , 'rack-acceptable/mixin/headers'
    autoload :Locales         , 'rack-acceptable/mixin/locales'
    autoload :Media           , 'rack-acceptable/mixin/media'
    autoload :Request         , 'rack-acceptable/request'

    # middleware
    autoload :Formats         , 'rack-acceptable/middleware/formats'
    autoload :Provides        , 'rack-acceptable/middleware/provides'

  end
end

# EOF