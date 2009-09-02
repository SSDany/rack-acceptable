module Rack #:nodoc:
  module Acceptable #:nodoc:
    module Const

      WILDCARD                  = '*'.freeze
      MEDIA_RANGE_WILDCARD      = '*/*'.freeze
      IDENTITY                  = 'identity'.freeze
      ISO_8859_1                = 'iso-8859-1'.freeze

      COMMA_SPLITTER            = /\s*,\s*/.freeze
      SEMICOLON_SPLITTER        = /\s*;\s*/.freeze

      ENV_HTTP_ACCEPT           = 'HTTP_ACCEPT'.freeze
      ENV_HTTP_ACCEPT_ENCODING  = 'HTTP_ACCEPT_ENCODING'.freeze
      ENV_HTTP_ACCEPT_CHARSET   = 'HTTP_ACCEPT_CHARSET'.freeze
      ENV_HTTP_ACCEPT_LANGUAGE  = 'HTTP_ACCEPT_LANGUAGE'.freeze

      ENV_ACCEPTABLE_ENCODINGS  = 'rack-acceptable.encodings'.freeze
      ENV_ACCEPTABLE_CHARSETS   = 'rack-acceptable.charsets'.freeze
      ENV_ACCEPTABLE_LANGUAGES  = 'rack-acceptable.languages'.freeze
      ENV_ACCEPTABLE_MIME_TYPES = 'rack-acceptable.mime-types'.freeze

    end
  end
end

# EOF