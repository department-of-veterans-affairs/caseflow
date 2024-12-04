# frozen_string_literal: true

namespace :local do
  desc "build local development environment"
  task :build do # rubocop:disable Rails/RakeEnvironment
    puts ">>> BEGIN local:build"
    puts ">>> 01/08 Downloading FACOLS image from ECR"
    system("./docker-bin/oracle_libs/build_push.sh rake") || abort

    puts ">>> 02/08 Starting docker containers in the background"
    system("docker-compose up -d") || abort

    puts ">>> 03/08 Waiting for our FACOLS containers to be ready"
    180.times do
      break if `docker-compose ps | grep 'health: starting'`.strip.chomp.empty?

      print "."
      sleep 1
    end
    # Add a new line so that this script's output is more readable.
    puts ""

    puts ">>> 04/08 Creating development and test caseflow databases"
    system("RAILS_ENV=development bundle exec rake db:create:primary") || abort

    puts ">>> 05/08 Seeding FACOLS"
    system("RAILS_ENV=development bundle exec rake local:vacols:seed") || abort

    puts ">>> 06/08 Seeding FACOLS TEST"
    system("RAILS_ENV=test bundle exec rake spec:setup_vacols") || abort

    puts ">>> 07/08 Loading schema and seeding local caseflow database"
    system("RAILS_ENV=development bundle exec rake db:schema:load:primary db:seed") || abort

    puts ">>> 08/08 Enabling feature flags"
    system("bundle exec rails runner scripts/enable_features_dev.rb") || abort

    puts ">>> END local:build"
  end
end
