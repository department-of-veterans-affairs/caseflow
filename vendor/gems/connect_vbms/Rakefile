require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec)

task default: [:build_java, :spec, :rubocop]

task :build_java do
  sh "make -C src build"
end

task :docs do
  sh "make -C docs html"
end

desc 'Run RuboCop on the src directory'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.patterns = ['src/**/*.rb', 'spec/**/*.rb']
  # Trigger failure for CI
  task.fail_on_error = true
end

Rake::Task[:build].prerequisites << Rake::Task[:build_java]
