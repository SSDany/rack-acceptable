module Rack #:nodoc:
  module Acceptable #:nodoc:
    module Const

      WILDCARD                  = '*'.freeze
      MEDIA_RANGE_WILDCARD      = '*/*'.freeze
      IDENTITY                  = 'identity'.freeze
      ISO_8859_1                = 'iso-8859-1'.freeze

      COMMA                     = ','.freeze
      EMPTY_STRING              = ''.freeze
      HYPHEN                    = '-'.freeze
      SEMICOLON                 = ';'.freeze

      ENV_HTTP_ACCEPT           = 'HTTP_ACCEPT'.freeze
      ENV_HTTP_ACCEPT_ENCODING  = 'HTTP_ACCEPT_ENCODING'.freeze
      ENV_HTTP_ACCEPT_CHARSET   = 'HTTP_ACCEPT_CHARSET'.freeze
      ENV_HTTP_ACCEPT_LANGUAGE  = 'HTTP_ACCEPT_LANGUAGE'.freeze

      ENV_PARSED_ENCODINGS      = 'rack-acceptable.encodings'.freeze
      ENV_PARSED_CHARSETS       = 'rack-acceptable.charsets'.freeze
      ENV_PARSED_MIME_TYPES     = 'rack-acceptable.mime-types'.freeze
      ENV_PARSED_MEDIA_RANGES   = 'rack-acceptable.media-ranges'.freeze

      ENV_PREFERRED_LOCALES     = 'rack-acceptable.preferred_locales'.freeze
      ENV_UNDESIRABLE_LOCALES   = 'rack-acceptable.undesirable_locales'.freeze

    end
  end
end

# EOF