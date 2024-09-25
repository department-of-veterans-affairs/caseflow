# frozen_string_literal: true

require "database_cleaner-active_record"

# because db/seeds is not in the autoload path, we must load them explicitly here
# base.rb needs to be loaded first because the other seeds inherit from it


require Rails.root.join("db/seeds/base.rb").to_s

# filtered_files.each { |f| require f }

class GenericFullSuiteSeeds
  def seed
    excluded_files = %w[
      db/seeds/hearings.rb
    ]

    all_files = Dir[Rails.root.join("db/seeds/*.rb")].sort

    filtered_files = all_files.reject do |file|
      excluded_files.include?(file.sub("#{Rails.root}/", ""))
    end

    filtered_files.each do |file|
      # Extract the base name without the directory and extension
      file_name = File.basename(file, '.rb') # e.g., "demo_non_aod_hearing_case_lever_test_data"

      # Construct the Rake task name
      task_name = "db:seed:#{file_name}"

      # Re-enable and invoke the Rake task
      Rake::Task[task_name].reenable
      Rake::Task[task_name].invoke
    end

  end

end

GenericFullSuiteSeeds.new.seed
