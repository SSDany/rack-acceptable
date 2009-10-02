desc "Runs benchmarks"

task :benchmarks do
  Dir[ROOT.join('benchmarks/*_bench.rb').to_s].each do |file|
    system "ruby1.9 #{file}"
    puts
  end
end

# EOF