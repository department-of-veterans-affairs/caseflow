# frozen_string_literal: true

require_relative "stubbable_user"

RSpec.configure do |config|
  config.use_transactional_fixtures = false

  etl_connection = "etl_#{Rails.env}".to_sym

  config.before(:suite) do
    DatabaseCleaner[:active_record, { connection: etl_connection }].clean_with(:truncation)
  end

  config.before(:each, :etl) do
    DatabaseCleaner[:active_record, { connection: etl_connection }].strategy = :transaction
  end

  config.before(:each, :etl, db_clean: :truncation) do
    DatabaseCleaner[:active_record, { connection: etl_connection }].strategy = :truncation
  end

  config.before(:each, :etl, type: :feature) do
    # :rack_test driver's Rack app under test shares database connection
    # with the specs, so continue to use transaction strategy for speed.
    driver_shares_db_connection_with_specs = Capybara.current_driver == :rack_test

    unless driver_shares_db_connection_with_specs
      # Driver is probably for an external browser with an app
      # under test that does *not* share a database connection with the
      # specs, so use truncation strategy.

      DatabaseCleaner[:active_record, { connection: etl_connection }].strategy = :truncation
    end
  end

  config.before(:each, :etl) do
    DatabaseCleaner[:active_record, { connection: etl_connection }].start
  end

  config.append_after(:each, :etl) do
    DatabaseCleaner[:active_record, { connection: etl_connection }].clean
    clean_application!
  end
end
