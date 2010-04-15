begin

  namespace :spec do

    gem 'rspec', '~>1.2'
    require 'spec'
    require 'spec/rake/spectask'

    def run_spec(name, files, rcov = false)
      Spec::Rake::SpecTask.new(name) do |t|
        t.spec_opts << '--options' << 'spec/spec.opts' if File.exists?('spec/spec.opts')
        t.spec_files = Pathname.glob(ENV['FILES'] || files.to_s).map { |file| file.to_s }
        t.rcov = rcov
        t.rcov_opts << '--exclude' << 'spec' << '--exclude' << 'gems'
        t.rcov_opts << '--text-report'
        t.rcov_opts << '--sort' << 'coverage' << '--sort-reverse'
        t.rcov_dir = 'coverage'
      end
    end

    begin
      gem 'rcov', '~>0.8'
      desc 'Run specifications with RCov'
      run_spec(:rcov, ROOT + 'spec/**/*_spec.rb', true)
    rescue LoadError
    end

  end

  desc 'Run specifications'
  run_spec(:spec, ROOT + 'spec/**/*_spec.rb')

  task :clobber => "spec:clobber_rcov" if Rake::Task.task_defined? 'spec:clobber_rcov'

rescue LoadError
end

# EOF