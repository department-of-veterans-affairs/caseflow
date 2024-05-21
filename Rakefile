# frozen_string_literal: true

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path("config/application", __dir__)

# Load rake support files
Dir[Rails.root.join("lib/tasks/support/**/*.rb")].sort.each { |f| require f }

Rails.application.load_tasks

task "db:schema:dump:primary": "strong_migrations:alphabetize_columns"
task "db:schema:dump:etl": "strong_migrations:alphabetize_columns"
