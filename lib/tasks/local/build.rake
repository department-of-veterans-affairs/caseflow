# frozen_string_literal: true

namespace :local do
  desc "build local development environment"
  task :build do
    puts "Downloading facols image from ECR"
    system("./local/vacols/build_push.sh rake") || abort

    puts "Starting docker containers in the background"
    system("docker-compose up -d") || abort

    puts "Waiting for our FACOLS containers to be ready"
    180.times do
      break if `docker-compose ps | grep 'health: starting'`.strip.chomp.empty?

      print "."
      sleep 1
    end
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
