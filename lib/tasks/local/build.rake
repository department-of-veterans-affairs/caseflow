# frozen_string_literal: true

namespace :local do
  desc "build local development environment"
  task :build do
    system("bundle exec rake local:vacols:wait_for_connection") || abort

    # Add a new line so that this scipt's output is more readable.
    puts ""

    puts "Creating local caseflow dbs"
    system("bundle exec rake db:create db:schema:load") || abort

    puts "Seeding FACOLS"
    system("RAILS_ENV=development bundle exec rake local:vacols:seed") || abort

    puts "Enabling feature flags"
    system("bundle exec rails runner scripts/enable_features_dev.rb") || abort

    puts "Setting up local caseflow database"
    system("RAILS_ENV=development bundle exec rake db:setup") || abort

    puts "Seeding local caseflow database"
    system("RAILS_ENV=development bundle exec rake db:seed") || abort
  end
end
