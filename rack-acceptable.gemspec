GEMSPEC = Gem::Specification.new do |s|

  s.name = 'acceptable'
  s.rubyforge_project = 'acceptable'
  s.version = '0.2.3'
  s.platform = Gem::Platform::RUBY
  s.homepage = 'http://github.com/SSDany/rack-acceptable'
  s.has_rdoc = true
  s.extra_rdoc_files = %w(README.rdoc)
  s.summary = 'HTTP Accept parsers for Rack.'
  s.description = <<-DESCR
Provides definitive support for Accept-* headers, strictly compliant with RFC 2616.
Includes negotiation algorithms for Media-Types, Charsets and Content-Codings.
Also realizes perfectionistic LanguageTags support with basic/extended filtering (RFC 5646, RFC 4647).
DESCR
  s.authors = %w[SSDany]
  s.email = 'inadsence@gmail.com'
  s.require_path = 'lib'
  s.files = s.extra_rdoc_files + [
    "lib/rack/acceptable/const.rb",
    "lib/rack/acceptable/language_tag.rb",
    "lib/rack/acceptable/middleware/fake_accept.rb",
    "lib/rack/acceptable/middleware/formats.rb",
    "lib/rack/acceptable/middleware/provides.rb",
    "lib/rack/acceptable/mimetypes.rb",
    "lib/rack/acceptable/mixin/charsets.rb",
    "lib/rack/acceptable/mixin/encodings.rb",
    "lib/rack/acceptable/mixin/headers.rb",
    "lib/rack/acceptable/mixin/languages.rb",
    "lib/rack/acceptable/mixin/media.rb",
    "lib/rack/acceptable/request.rb",
    "lib/rack/acceptable/utils.rb",
    "lib/rack/acceptable/version.rb",
    "lib/rack/acceptable.rb",
    'lib/rack/acceptable/data/mime.types'
    ]

  s.add_dependency 'rack', '>=1.0.0'
end

# EOF