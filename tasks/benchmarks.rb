desc "Runs benchmarks"
task :benchmarks do
  Dir[ROOT.join('benchmarks/**/*_bench.rb')].each do |file|
    puts "Running #{File.basename(file).sub(/_bench\.rb$/, '').inspect} benchmark."
    puts `ruby #{file} 2>/dev/null`
    puts
  end
end

# EOF