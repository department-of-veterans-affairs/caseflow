namespace :local do
  desc "build local development environment"
  task :build do
    puts "Building docker services from configuration"
    `docker-compose build --no-cache`

    puts "Starting docker containers in the background"
    `docker-compose up -d`

    puts "Setting up FACOLS"
    Rake::Task["local:vacols:setup"].invoke

    puts "Enabling feature flags"
    `bundle exec rails runner scripts/enable_features_dev.rb`

    puts "Setting up local caseflow database"
    Rake::Task["db:setup"].invoke

    puts "Seeding local caseflow database"
    Rake::Task["db:seed"].invoke

    puts "Seeding FACOLS"
    Rake::Task["local:vacols:seed"].invoke
  end
end
