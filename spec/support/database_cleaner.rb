# frozen_string_literal: true

require "capybara/rspec"

RSpec.configure do |config|
  config.use_transactional_fixtures = false

  config.before(:suite) do
    if config.use_transactional_fixtures?
      fail(<<-MSG)
        Delete line `config.use_transactional_fixtures = true` from rails_helper.rb
        (or set it to false) to prevent uncommitted transactions being used in
        JavaScript-dependent specs.

        During testing, the app-under-test that the browser driver connects to
        uses a different database connection to the database connection used by
        the spec. The app's database connection would not be able to access
        uncommitted transaction data setup over the spec's database connection.
      MSG
    end

    # ActiveRecord::Base.logger = Logger.new($stdout)
    DatabaseCleaner[:active_record, { connection: "#{Rails.env}_vacols".to_sym }]
      .clean_with(:deletion, except: %w[vftypes issref])
    DatabaseCleaner[:active_record, { connection: Rails.env.to_s.to_sym }].clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner[:active_record, { connection: "#{Rails.env}_vacols".to_sym }].strategy = :transaction
    DatabaseCleaner[:active_record, { connection: Rails.env.to_s.to_sym }].strategy = :transaction
  end

  config.before(:each, db_clean: :truncation) do
    DatabaseCleaner[:active_record, { connection: "#{Rails.env}_vacols".to_sym }].strategy =
      :deletion, { except: %w[vftypes issref] }
    DatabaseCleaner[:active_record, { connection: Rails.env.to_s.to_sym }].strategy = :truncation
  end

  config.before(:each, type: :feature) do
    # :rack_test driver's Rack app under test shares database connection
    # with the specs, so continue to use transaction strategy for speed.
    driver_shares_db_connection_with_specs = Capybara.current_driver == :rack_test

    unless driver_shares_db_connection_with_specs
      # Driver is probably for an external browser with an app
      # under test that does *not* share a database connection with the
      # specs, so use truncation strategy.
      DatabaseCleaner[:active_record, { connection: "#{Rails.env}_vacols".to_sym }].strategy =
        :deletion, { except: %w[vftypes issref] }
      DatabaseCleaner[:active_record, { connection: Rails.env.to_s.to_sym }].strategy = :truncation
    end
  end

  config.before(:each) do
    DatabaseCleaner[:active_record, { connection: "#{Rails.env}_vacols".to_sym }].start
    DatabaseCleaner[:active_record, { connection: Rails.env.to_s.to_sym }].start
  end

  config.append_after(:each) do
    DatabaseCleaner[:active_record, { connection: "#{Rails.env}_vacols".to_sym }].clean
    DatabaseCleaner[:active_record, { connection: Rails.env.to_s.to_sym }].clean
    clean_application!
  end
end
