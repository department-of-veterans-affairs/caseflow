# frozen_string_literal: true

require_relative "stubbable_user"

RSpec.configure do |config|
  config.use_transactional_fixtures = false

  vacols_tables_to_preserve = %w[vftypes issref]

  # IMPORTANT that in all these hook defs, the "primary" connection comes last.

  config.before(:suite) do
    DatabaseCleaner[:active_record, { db: :etl }].clean_with(:truncation)
    DatabaseCleaner[:active_record, { db: :vacols }]
      .clean_with(:deletion, except: vacols_tables_to_preserve)
    DatabaseCleaner[:active_record, { db: :primary }].clean_with(:truncation)
  end

  config.before(:each) do |example|
    # Allows seeded data to persist for use across threads
    # You will need to manually clean the data once the threads under test close.
    unless example.metadata[:bypass_cleaner]
      DatabaseCleaner[:active_record, { db: :vacols }].strategy = :transaction
      DatabaseCleaner[:active_record, { db: :primary }].strategy = :transaction
    end
  end

  config.before(:each, db_clean: :truncation) do |example|
    unless example.metadata[:bypass_cleaner]
      DatabaseCleaner[:active_record, { db: :vacols }].strategy =
        :deletion, { except: vacols_tables_to_preserve }
      DatabaseCleaner[:active_record, { db: :primary }].strategy = :truncation
    end
  end

  config.before(:each, type: :feature) do
    # :rack_test driver's Rack app under test shares database connection
    # with the specs, so continue to use transaction strategy for speed.
    driver_shares_db_connection_with_specs = Capybara.current_driver == :rack_test

    unless driver_shares_db_connection_with_specs
      # Driver is probably for an external browser with an app
      # under test that does *not* share a database connection with the
      # specs, so use truncation strategy.
      DatabaseCleaner[:active_record, { db: :vacols }].strategy =
        :deletion, { except: vacols_tables_to_preserve }
      DatabaseCleaner[:active_record, { db: :primary }].strategy = :truncation
    end
  end

  config.before(:each) do |example|
    unless example.metadata[:bypass_cleaner]
      DatabaseCleaner[:active_record, { db: :vacols }].start
      DatabaseCleaner[:active_record, { db: :primary }].start
    end
  end

  config.append_after(:each) do
    DatabaseCleaner[:active_record, { db: :vacols }].clean
    DatabaseCleaner[:active_record, { db: :primary }].clean
    clean_application!
  end

  # ETL is never used in feature tests and there are only a few, so we tag those with :etl
  # ETL db uses deletion strategy everywhere because syncing runs in a transaction.
  config.before(:each, :etl) do
    DatabaseCleaner[:active_record, { db: :etl }].strategy = :deletion
  end

  config.before(:each, :etl, db_clean: :truncation) do
    DatabaseCleaner[:active_record, { db: :etl }].strategy = :truncation
  end

  config.before(:each, :etl) do
    Rails.logger.info("DatabaseCleaner.start ETL")
    DatabaseCleaner[:active_record, { db: :etl }].start
  end

  config.append_after(:each, :etl) do
    DatabaseCleaner[:active_record, { db: :etl }].clean
    Rails.logger.info("DatabaseCleaner.clean ETL")
  end
end
