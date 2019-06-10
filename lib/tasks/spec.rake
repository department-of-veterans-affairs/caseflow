# frozen_string_literal: true

require "rspec/core/rake_task"

namespace :spec do
  DEFAULT_RSPEC_OPTS = "--tty --color"

  feature_spec_folders = Dir.entries("./spec/feature").select do |file|
    ![".", ".."].include?(file) && File.directory?(File.join("./spec/feature", file))
  end

  spec_names = [*feature_spec_folders, "unit", "other"].flat_map { |n| [n, "#{n}_no_ui"] }

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
          envs = "export TEST_SUBCATEGORY=#{spec_name} && export RAILS_ENV=test &&"

          ["rake db:create", "rake db:schema:load"].each do |cmd|
            ShellCommand.run_and_batch_output("#{envs} #{cmd}")
          end
        end
      end

      multitask all: spec_names
    end

    desc "Set the database environment for all parallel testing environments"
    task setup: "setup:all"

    spec_names.map(&:to_sym).each do |spec_name|
      desc "Run all #{spec_name} #{(spec_name == :unit) ? '' : 'feature '}tests. \
            Configured to run in parallel with other parallel spec tasks."

      task spec_name do
        envs = "export TEST_SUBCATEGORY=#{spec_name};"

        ShellCommand.run_and_batch_output("#{envs} rake spec:#{spec_name}")
      end
    end

    multitask all: spec_names
  end

  # Customized rspec rake tasks. These are used by the specs defined above,
  # so the proper environment variables can be set.

  make_rake_task = proc do |name:, desc:, pattern:, exclude_pattern:|
    [
      { name_suffix: nil, extra_rspec_opts: nil },
      { name_suffix: "_no_ui", extra_rspec_opts: "--tag ~ui_test" }
    ].each do |name_suffix:, extra_rspec_opts:|
      desc "#{desc}#{extra_rspec_opts ? " (#{extra_rspec_opts})" : ''}"
      RSpec::Core::RakeTask.new("#{name}#{name_suffix}".to_sym) do |t|
        t.pattern = pattern if pattern
        t.exclude_pattern = exclude_pattern if exclude_pattern
        t.rspec_opts = "#{DEFAULT_RSPEC_OPTS} #{extra_rspec_opts}"
      end
    end
  end

  [
    {
      name: "unit",
      desc: "Run all unit specs",
      pattern: "spec/**/*_spec.rb",
      exclude_pattern: "spec/feature/**/*"
    },
    {
      name: "other",
      desc: "Run all uncategorized feature specs",
      pattern: "spec/feature/*_spec.rb",
      exclude_pattern: nil
    }
  ].each(&make_rake_task)

  feature_spec_folders.each do |folder|
    make_rake_task[
      name: folder.to_s,
      desc: "Run all #{feature_spec_folders} feature specs",
      pattern: "spec/feature/#{folder}/**/*_spec.rb",
      exclude_pattern: nil
    ]
  end
end
