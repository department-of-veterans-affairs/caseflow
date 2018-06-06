namespace :local do
  desc "build local development environment"
  task :build do
    puts "Building docker services from configuration"
    `docker-compose build --no-cache`

    puts "Starting docker containers in the background"
    `docker-compose up -d`

    puts "Waiting for our FACOLS containers to be ready"
    180.times do
      break if `docker-compose ps | grep 'health: starting'`.strip.chomp.empty?
      print "."
      sleep 1
    end
    # Add a new line so that this scipt's output is more readable.
    puts ""

    puts "Setting up development FACOLS"
    `RAILS_ENV=development bundle exec rake local:vacols:setup`

    puts "Setting up local caseflow database"
    `RAILS_ENV=development bundle exec rake db:setup`

    puts "Seeding local caseflow database"
    `RAILS_ENV=development bundle exec rake db:seed`

    puts "Enabling feature flags"
    `bundle exec rails runner scripts/enable_features_dev.rb`

    puts "Seeding FACOLS"
    `RAILS_ENV=development bundle exec rake local:vacols:seed`

    puts "Setting up test FACOLS"
    `RAILS_ENV=test bundle exec rake local:vacols:setup`
  end
end
