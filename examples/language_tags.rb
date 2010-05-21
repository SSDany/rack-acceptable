require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

p Rack::Acceptable::LanguageTag.extract_language_info('SL-LATN-ROZAJ') #=> ["sl",nil,"Latn",nil,["rozaj"]]
p Rack::Acceptable::LanguageTag.extract_language_info('sl-Latn-IT-nedis') #=> ['sl', nil, 'Latn', 'IT', ['nedis']]
p Rack::Acceptable::LanguageTag.extract_language_info('zh-Hans') #=> ["zh",nil,"Hans",nil,nil]

langtag = Rack::Acceptable::LanguageTag.parse('SL-LATN-ROZAJ')
p langtag.primary #=> "sl"
p langtag.variants #=> ["rozaj"]
p langtag.script #=> "Latn"

# RFC 4647, sec. 3.3.1 ('Basic Filtering')
#
# A language range matches a
# particular language tag if, in a case-insensitive comparison, it
# exactly equals the tag, or if it exactly equals a prefix of the tag
# such that the first character following the prefix is "-".  For
# example, the language-range "de-de" (German as used in Germany)
# matches the language tag "de-DE-1996" (German as used in Germany,
# orthography of 1996), but not the language tags "de-Deva" (German as
# written in the Devanagari script) or "de-Latn-DE" (German, Latin
# script, as used in Germany).

p langtag.has_prefix?('sl') #=> true
p langtag.has_prefix?('sl-Latn') #=> true
p langtag.has_prefix?('sl-Latn-ro') #=> false
p langtag.matched_by_basic_range?('sl-Latn') #=> true

# RFC 4647, sec. 3.3.2 ('Extended Filtering')
#
# Much like basic filtering, extended filtering selects content with
# arbitrarily long tags that share the same initial subtags as the
# language range.  In addition, extended filtering selects language
# tags that contain any intermediate subtags not specified in the
# language range.  For example, the extended language range "de-*-DE"
# (or its synonym "de-DE") matches all of the following tags:
#
#   de-DE (German, as used in Germany)
#   de-de (German, as used in Germany)
#   de-Latn-DE (Latin script)
#   de-Latf-DE (Fraktur variant of Latin script)
#   de-DE-x-goethe (private-use subtag)
#   de-Latn-DE-1996 (orthography of 1996)
#   de-Deva-DE (Devanagari script)
#
# The same range does not match any of the following tags for the
# reasons shown:
#
#   de (missing 'DE')
#   de-x-DE (singleton 'x' occurs before 'DE')
#   de-Deva ('Deva' not equal to 'DE')

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