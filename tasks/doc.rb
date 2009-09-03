begin

  gem 'rdoc', '>=2.3'
  require 'rdoc'
  require 'rake/rdoctask'

  desc 'Build RDoc'
  Rake::RDocTask.new(:rdoc) do |rdoc|
    rdoc.rdoc_dir = "doc"
    rdoc.main     = "README.rdoc"
    rdoc.title    = "Rack-Acceptable #{Rack::Acceptable::VERSION} Documentation"
    rdoc.options  << %w(--charset=utf-8 --force-update --line-numbers)
    rdoc.rdoc_files.add FileList['lib/**/*.rb','README.rdoc']
  end

  task :clobber => "clobber_rdoc"

rescue LoadError
end

# EOF