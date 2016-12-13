require "rainbow"

desc "Runs the continuous integration scripts"
task ci: [:lint, :security, :spec, :sauceci, "konacha:run", :mocha]

task default: :ci

namespace :test do
  desc "run ruby rspec tests"
  task :rspec do
    Rake::Task[:spec].invoke
  end

  desc "run mocha tests"
  task :mocha do
    Rake::Task[:mocha].invoke
  end
end
