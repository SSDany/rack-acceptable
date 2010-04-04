module Rack #:nodoc:
  module Acceptable #:nodoc:
    module Const

      WILDCARD                  = '*'.freeze
      MEDIA_RANGE_WILDCARD      = '*/*'.freeze
      IDENTITY                  = 'identity'.freeze
      ISO_8859_1                = 'iso-8859-1'.freeze
      TEXT                      = 'text'.freeze

      COMMA                     = ','.freeze
      EMPTY_STRING              = ''.freeze
      HYPHEN                    = '-'.freeze
      SEMICOLON                 = ';'.freeze
      SLASH                     = '/'.freeze

      ENV_HTTP_ACCEPT           = 'HTTP_ACCEPT'.freeze
      ENV_HTTP_ACCEPT_ENCODING  = 'HTTP_ACCEPT_ENCODING'.freeze
      ENV_HTTP_ACCEPT_CHARSET   = 'HTTP_ACCEPT_CHARSET'.freeze
      ENV_HTTP_ACCEPT_LANGUAGE  = 'HTTP_ACCEPT_LANGUAGE'.freeze

      CHARSET                   = 'charset'.freeze
      CONTENT_TYPE              = 'Content-Type'.freeze
      CONTENT_LENGTH            = 'Content-Length'.freeze

      TEXT_SLASH_PLAIN          = 'text/plain'.freeze

      NOT_ACCEPTABLE            = "An appropriate representation of the requested resource could not be found.\n".freeze
      NOT_ACCEPTABLE_RESPONSE   = [406, {
        CONTENT_TYPE => TEXT_SLASH_PLAIN, CONTENT_LENGTH => '76' },
        [NOT_ACCEPTABLE]].freeze

    end
  end
end

# EOF