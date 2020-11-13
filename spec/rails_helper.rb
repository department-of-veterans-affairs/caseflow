# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

require "fake_date_helper"
require "react_on_rails"
require "timeout"
require "knapsack_pro"

TMP_RSPEC_XML_REPORT = "tmp/rspec.xml"
FINAL_RSPEC_XML_REPORT = "#{Dir.home}/test-results/rspec/rspec.xml"

KnapsackPro::Adapters::RSpecAdapter.bind
KnapsackPro::Hooks::Queue.after_subset_queue do |_queue_id, _subset_queue_id|
  if File.exist?(TMP_RSPEC_XML_REPORT)
    FileUtils.mv(TMP_RSPEC_XML_REPORT, FINAL_RSPEC_XML_REPORT)
  end
end

KnapsackPro::Hooks::Queue.after_queue do |_queue_id|
  if File.exist?(FINAL_RSPEC_XML_REPORT) && ENV["CIRCLE_TEST_REPORTS"]
    FileUtils.cp(FINAL_RSPEC_XML_REPORT, "#{ENV['CIRCLE_TEST_REPORTS']}/rspec.xml")
  end
end

# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

# because db/seeds is not in the autoload path, we must load them explicitly here
Dir[Rails.root.join("db/seeds/**/*.rb")].sort.each { |f| require f }

# The TZ variable controls the timezone of the browser in capybara tests, so we always define it.
# By default (esp for CI) we use Eastern time, so that it doesn't matter where the developer happens to sit.
ENV["TZ"] ||= "America/New_York"

# Assume the browser and the server are in the same timezone for now. Eventually we should
# use something like https://github.com/alindeman/zonebie to exercise browsers in different timezones.
Time.zone = ENV["TZ"]

User.authentication_service = Fakes::AuthenticationService
CAVCDecision.repository = Fakes::CAVCDecisionRepository

RSpec.configure do |config|
  # This checks whether compiled webpack assets already exist
  # If it does, it will not execute ReactOnRails, since that slows down tests
  # Thus this will only run once (to initially compile assets) and not on
  # subsequent test runs
  if !File.exist?("#{::Rails.root}/app/assets/javascripts/webpack-bundle.js") &&
     ENV["REACT_ON_RAILS_ENV"] != "HOT"

    # Only compile webpack-bundle.js for feature tests.
    # https://github.com/shakacode/react_on_rails/blob/master/docs/basics/rspec-configuration.md#rspec-configuration
    ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config, :requires_webpack_assets)
    config.define_derived_metadata(file_path: %r{spec/feature}) do |metadata|
      metadata[:requires_webpack_assets] = true
    end
  end

  config.before(:each) do
    @spec_time_zone = Time.zone
  end

  config.after(:each) do
    Timecop.return
    Fakes::BGSService.clean!
    Time.zone = @spec_time_zone
    User.unauthenticate!
    RequestStore[:application] = nil
  end

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")
end

# Wrap this around your test to run it many times and ensure that it passes consistently.
# Note: do not merge to master like this, or the tests will be slow! Ha.
def ensure_stable
  repeat_count = ENV.fetch("ENSURE_STABLE", "10").to_i
  repeat_count.times do
    yield
  end
end

# Test that a string does *not* include a provided substring
RSpec::Matchers.define :excluding do |expected|
  match do |actual|
    !actual.include?(expected)
  end
end

RSpec.configure do |config|
  config.include ActionView::Helpers::NumberHelper
  config.include FakeDateHelper
  config.include FeatureHelper, type: :feature
  config.include DateTimeHelper
end
