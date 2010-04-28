namespace :benchmarks do

  RUN_BENCHMARKS = lambda do |pattern|
    Dir[ROOT.join(pattern).to_s].each do |file|
      system "ruby #{file}"
      puts
    end
  end

  task :default => :tb

  desc "Bench Rack::Accrptable against other tools"
  task :tb do
    RUN_BENCHMARKS['benchmarks/tb/*_bench.rb']
  end

  desc "Run 'simple' benchmarks"
  task :simple do
    RUN_BENCHMARKS['benchmarks/simple/*_bench.rb']
  end

  desc "Run inner benchmarks"
  task :inner do
    RUN_BENCHMARKS['benchmarks/*_bench.rb']
  end

  desc "Run all benchmarks"
  task :all do
    RUN_BENCHMARKS['benchmarks/**/*_bench.rb']
  end

end

# EOF