# frozen_string_literal: true

require_relative "stubbable_user"

# ETL db uses truncation strategy everywhere because syncing runs in a transaction
#

RSpec.configure do |config|
  config.use_transactional_fixtures = false

  etl_connection = "etl_#{Rails.env}".to_sym

  config.before(:suite) do
    DatabaseCleaner[:active_record, { connection: etl_connection }].clean_with(:truncation)
  end

  config.before(:each, :etl) do
    DatabaseCleaner[:active_record, { connection: etl_connection }].strategy = :truncation
  end

  config.before(:each, :etl, db_clean: :truncation) do
    DatabaseCleaner[:active_record, { connection: etl_connection }].strategy = :truncation
  end

  config.before(:each, :etl) do
    DatabaseCleaner[:active_record, { connection: etl_connection }].start
  end

  config.append_after(:each, :etl) do
    DatabaseCleaner[:active_record, { connection: etl_connection }].clean
    clean_application!
  end
end
