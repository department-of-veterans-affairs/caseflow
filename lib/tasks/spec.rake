require "rspec/core/rake_task"

def run_command_and_print_output(command)
  output_stream = open("|#{command}", "r")

  output = ""
  output_stream.each do |line|
    output << line
    print "."
    $stdout.flush
  end
  puts output
end

namespace :spec do
  feature_spec_folders = Dir.entries("./spec/feature").select do |file|
    ![".", ".."].include?(file) && File.directory?(File.join("./spec/feature", file))
  end

  spec_names = feature_spec_folders + %w(other unit)

  # Tasks for setting up the environment and running the tests without
  # immediately printing output to the screen. This prevents output from overrunning
  # each other when run in parallel
  desc "Run all spec categories in parallel"
  task parallel: "parallel:all"

  namespace :parallel do
    namespace :setup do
      task default: :all

      spec_names.map(&:to_sym).each do |spec_name|
        desc "Set the database environment for #{spec_name} tests"

        task spec_name do
          envs = "export TEST_SUBCATEGORY=#{spec_name}; export RAILS_ENV=test;"

          ["rake db:create", "rake db:schema:load"].each do |cmd|
            run_command_and_print_output("#{envs} #{cmd}")
          end
        end
      end

      multitask all: spec_names
    end

    desc "Set the database environment for all parallel testing environments"
    task setup: "setup:all"

    spec_names.map(&:to_sym).each do |spec_name|
      desc "Run all #{spec_name} #{spec_name == :unit ? '' : 'feature '}tests. \
            Configured to run in parallel with other parallel spec tasks."

      task spec_name do
        envs = "export TEST_SUBCATEGORY=#{spec_name};"

        run_command_and_print_output("#{envs} rake spec:#{spec_name}")
      end
    end

    multitask all: spec_names
  end

  # Customized rspec rake tasks. These are used by the specs defined above,
  # so the proper environment variables can be set.
  desc "Run all unit specs"
  RSpec::Core::RakeTask.new(:unit) do |t|
    t.pattern = "spec/**/*_spec.rb"
    t.exclude_pattern = "spec/feature/**/*"
    t.rspec_opts = "--tty --color"
  end

  desc "Run all uncategorized feature specs"
  RSpec::Core::RakeTask.new(:other) do |t|
    t.pattern = "spec/feature/*_spec.rb"
    t.rspec_opts = "--tty --color"
  end

  feature_spec_folders.each do |folder|
    desc "Run all #{feature_spec_folders} feature specs"
    RSpec::Core::RakeTask.new(folder.to_s.to_sym) do |t|
      t.pattern = "spec/feature/#{folder}/**/*_spec.rb"
      t.rspec_opts = "--tty --color"
    end
  end
end
