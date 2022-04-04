begin
  require 'bundler/gem_tasks'
rescue LoadError # rubocop:disable Lint/HandleExceptions
end

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task default: :spec
rescue LoadError # rubocop:disable Lint/HandleExceptions
end

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
  namespace :rubocop do
    desc "Run 'rubocop --auto-gen-config'"
    task :todo do
      sh 'rubocop --auto-gen-config'
    end
  end
rescue LoadError # rubocop:disable Lint/HandleExceptions
end
