desc "Runs benchmarks"

task :benchmarks do
  Dir[ROOT.join('benchmarks/*_bench.rb').to_s].each do |file|
    system "ruby #{file}"
    puts
  end
end

# EOF