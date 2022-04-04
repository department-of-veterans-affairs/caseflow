require 'rubygems'
require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
unless defined?(JRUBY_VERSION)
  require 'rubygems/tasks'
  require 'rubygems/tasks/scm'
  Gem::Tasks.new
end
require 'yard'

YARD::Rake::YardocTask.new do |t|
  t.files = ['lib/**/*.rb']
end

RSpec::Core::RakeTask.new(:spec)

task default: :spec
