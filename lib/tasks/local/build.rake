namespace :local do
  desc "build local development environment"
  task :build do
    puts "Building docker services from configuration"
    `docker-compose build --no-cache`
    abort unless $?.success?

    puts "Starting docker containers in the background"
    `docker-compose up -d`
    abort unless $?.success?

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
    abort unless $?.success?

    puts "Setting up local caseflow database"
    `RAILS_ENV=development bundle exec rake db:setup`
    abort unless $?.success?

    puts "Seeding local caseflow database"
    `RAILS_ENV=development bundle exec rake db:seed`
    abort unless $?.success?

    puts "Enabling feature flags"
    `bundle exec rails runner scripts/enable_features_dev.rb`
    abort unless $?.success?

    puts "Seeding FACOLS"
    `RAILS_ENV=development bundle exec rake local:vacols:seed`
    abort unless $?.success?

    puts "Setting up test FACOLS"
    `RAILS_ENV=test bundle exec rake local:vacols:setup`
    abort unless $?.success?
  end
end
