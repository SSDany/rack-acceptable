require 'rubygems'
gem 'rack', '>=1.0.0'
require 'rack'

module Rack #:nodoc:
  module Acceptable

    # common
    autoload :Const           , 'rack/acceptable/const'
    autoload :Utils           , 'rack/acceptable/utils'
    autoload :MIMETypes       , 'rack/acceptable/mimetypes'
    autoload :LanguageTag     , 'rack/acceptable/language_tag'

    # request and mixins
    autoload :Headers         , 'rack/acceptable/mixin/headers'
    autoload :Locales         , 'rack/acceptable/mixin/locales'
    autoload :Media           , 'rack/acceptable/mixin/media'
    autoload :Request         , 'rack/acceptable/request'

    # middleware
    autoload :Formats         , 'rack/acceptable/middleware/formats'
    autoload :Provides        , 'rack/acceptable/middleware/provides'

  end
end

# EOF