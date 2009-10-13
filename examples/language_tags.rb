require 'rubygems'
require 'rack'
require 'rack/acceptable'

p Rack::Acceptable::LanguageTag.extract_language_info('SL-LATN-ROZAJ') #=> ["sl",nil,"Latn",nil,["rozaj"]]
p Rack::Acceptable::LanguageTag.extract_language_info('sl-Latn-IT-nedis') #=> ['sl', nil, 'Latn', 'IT', ['nedis']]
p Rack::Acceptable::LanguageTag.extract_language_info('zh-Hans') #=> ["zh",nil,"Hans",nil,nil]

langtag = Rack::Acceptable::LanguageTag.parse('SL-LATN-ROZAJ')
p langtag.variants #=> ["rozaj"]
p langtag.script #=> "Latn"

# basic filtering (RFC 4647)
p langtag.has_prefix?('sl-Latn') #=> true
p langtag.matched_by_basic_range?('sl-Latn') #=> true
p langtag.has_prefix?('sl-Latn-ro') #=> false
p langtag.has_prefix?('sl') #=> true

# extended filtering (RFC 4647)
p langtag.matched_by_extended_range?('*') #=> true
p langtag.matched_by_extended_range?('sl-*') #=> true
p langtag.matched_by_extended_range?('*-Latn') #=> true
p langtag.matched_by_extended_range?('sl-rozaj') #=> true
p langtag.matched_by_extended_range?('sl-nedis') #=> false

# modification and recomposition
p langtag.nicecased #=> "sl-Latn-rozaj"
p langtag.tag #=> "sl-Latn-rozaj"

langtag.variants = ['nedis']
langtag.privateuse = ['whatever']
langtag.extensions = {'a' => %w(xxx yyy), 'b' => %w(zzz)}

p langtag.tag #=> "sl-Latn-rozaj" # @tag is a result of the last recomposition.
langtag.recompose

p langtag.tag #=> "sl-Latn-nedis-a-xxx-yyy-b-xxx-x-whatever"
p langtag.singletons #=> ["a","b"]
p langtag.extension?('a') #=> true
p langtag.extension?('z') #=> false
p langtag.has_variant?('rozaj') #=> false
p langtag.has_variant?('nedis') #=> true
p langtag.has_variant?('Nedis') #=> true
p langtag.privateuse #=> ["whatever"]

# validation
p langtag.valid? #=> true
langtag.variants = ['bogus!']
p langtag.valid? #=> false

# EOF