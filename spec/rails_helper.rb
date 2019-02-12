# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= "test"
require "simplecov"

require File.expand_path("../config/environment", __dir__)

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

require "spec_helper"
require "fake_date_helper"
require "rspec/rails"
require "react_on_rails"
require_relative "support/fake_pdf_service"
require_relative "support/sauce_driver"
require_relative "support/database_cleaner"
require_relative "support/download_helper"
require_relative "support/clear_cache"
require_relative "support/feature_helper"
require_relative "support/date_time_helper"
require "timeout"

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
# Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Checks for pending migration and applies them before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

require "capybara"
require "capybara/rspec"
require "capybara-screenshot/rspec"
Sniffybara::Driver.configuration_file = File.expand_path("support/VA-axe-configuration.json", __dir__)

download_directory = Rails.root.join("tmp/downloads_#{ENV['TEST_SUBCATEGORY'] || 'all'}")
cache_directory = Rails.root.join("tmp/browser_cache_#{ENV['TEST_SUBCATEGORY'] || 'all'}")

Dir.mkdir download_directory unless File.directory?(download_directory)
if File.directory?(cache_directory)
  FileUtils.rm_r cache_directory
else
  Dir.mkdir cache_directory
end

ENV["TZ"] ||= "America/New York"

Capybara.register_driver(:parallel_sniffybara) do |app|
  chrome_options = ::Selenium::WebDriver::Chrome::Options.new

  chrome_options.add_preference(:download,
                                prompt_for_download: false,
                                default_directory: download_directory)

  chrome_options.add_preference(:browser,
                                disk_cache_dir: cache_directory)

  options = {
    port: 51_674,
    browser: :chrome,
    options: chrome_options
  }
  Sniffybara::Driver.current_driver = Sniffybara::Driver.new(app, options)
end

Capybara.register_driver(:sniffybara_headless) do |app|
  chrome_options = ::Selenium::WebDriver::Chrome::Options.new

  chrome_options.add_preference(:download,
                                prompt_for_download: false,
                                default_directory: download_directory)

  chrome_options.add_preference(:browser,
                                disk_cache_dir: cache_directory)
  chrome_options.args << "--headless"
  chrome_options.args << "--disable-gpu"

  options = {
    port: 51_674,
    browser: :chrome,
    options: chrome_options
  }
  Sniffybara::Driver.current_driver = Sniffybara::Driver.new(app, options)
end

Capybara::Screenshot.register_driver(:parallel_sniffybara) do |driver, path|
  driver.browser.save_screenshot(path)
end

Capybara::Screenshot.register_driver(:sniffybara_headless) do |driver, path|
  driver.browser.save_screenshot(path)
end

Capybara.default_driver = ENV["SAUCE_SPECS"] ? :sauce_driver : :parallel_sniffybara
# the default default_max_wait_time is 2 seconds
Capybara.default_max_wait_time = 5

# This allows for active job expectations
ActiveJob::Base.queue_adapter = :test

# Convenience methods for stubbing current user
module StubbableUser
  module ClassMethods
    attr_writer :stub

    def clear_stub!
      Functions.delete_all_keys!
      @stub = nil
      @system_user = nil
    end

    def authenticate!(css_id: nil, roles: nil, user: nil)
      Functions.grant!("System Admin", users: ["DSUSER"]) if roles&.include?("System Admin")

      if user.nil?
        user = User.from_session(
          "user" =>
            { "id" => css_id || "DSUSER",
              "name" => "Lauren Roth",
              "station_id" => "283",
              "email" => "test@example.com",
              "roles" => roles || ["Certify Appeal"] }
        )
      end

      RequestStore.store[:current_user] = user
      self.stub = user
    end

    def tester!(roles: nil)
      self.stub = User.from_session(
        "user" =>
          { "id" => ENV["TEST_USER_ID"],
            "station_id" => "283",
            "email" => "test@example.com",
            "roles" => roles || ["Certify Appeal"] }
      )
    end

    def current_user
      @stub
    end

    def clear_current_user
      clear_stub!
    end

    def unauthenticate!
      Functions.delete_all_keys!
      self.stub = nil
    end

    def from_session(session)
      @stub || super(session)
    end
  end

  def self.prepended(base)
    class << base
      prepend ClassMethods
    end
  end
end

User.prepend(StubbableUser)

def clean_application!
  User.clear_stub!
  Fakes::CAVCDecisionRepository.clean!
  Fakes::BGSService.clean!
  Fakes::VBMSService.clean!
end

def current_user
  User.current_user
end

# Utility functions for reading CSV data
def dateshift_field(items, date_shift, key)
  items.map! do |item|
    item[key] = item[key] + date_shift if item[key]
    item
  end
end

def truncate_string(items, sql_type, key)
  max_index = /\((\d*)\)/.match(sql_type)[1].to_i - 1
  items.map! do |item|
    item[key] = item[key][0..max_index] if item[key]
    item
  end
end

def read_csv(klass, date_shift)
  items = []
  klass.delete_all
  CSV.foreach(Rails.root.join("local/vacols", klass.name + "_dump.csv"), headers: true) do |row|
    h = row.to_h
    items << klass.new(row.to_h) if klass.primary_key.nil? || !h[klass.primary_key].nil?
  end
  klass.columns_hash.each do |k, v|
    if v.type == :datetime
      dateshift_field(items, date_shift, k)
    elsif v.type == :string
      truncate_string(items, v.sql_type, k)
    end
  end

  klass.import(items)
end

User.authentication_service = Fakes::AuthenticationService
CAVCDecision.repository = Fakes::CAVCDecisionRepository

RSpec.configure do |config|
  # This checks whether compiled webpack assets already exist
  # If it does, it will not execute ReactOnRails, since that slows down tests
  # Thus this will only run once (to initially compile assets) and not on
  # subsequent test runs
  if !File.exist?("#{::Rails.root}/app/assets/javascripts/webpack-bundle.js") &&
     ENV["REACT_ON_RAILS_ENV"] != "HOT"
    ReactOnRails::TestHelper.ensure_assets_compiled
  end
  config.before(:all) do
    User.unauthenticate!

    # We need the VFTYPES and ISSREF tables to do any queries for issues. This code is borrowed from the
    # local:vacols:seed rake task to load all of our dumped data for the VFTYPES and ISSREF tables.
    date_shift = Time.now.utc.beginning_of_day - Time.utc(2017, 11, 1)

    read_csv(VACOLS::Vftypes, date_shift)
    read_csv(VACOLS::Issref, date_shift)
    read_csv(VACOLS::Actcode, date_shift)
  end

  config.before(:each) do
    @spec_time_zone = Time.zone
  end

  config.after(:each) do
    Timecop.return
    Fakes::BGSService.clean!
    Time.zone = @spec_time_zone
  end

  # Allows us to use shorthand FactoryBot methods.
  config.include FactoryBot::Syntax::Methods

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")
end

def be_titled(title)
  have_xpath("//title[contains(.,'#{title}')]", visible: false)
end

def hang
  puts "Hanging the test indefinitely so you can debug in the browser."
  sleep(10_000)
end

# Wrap this around your test to run it many times and ensure that it passes consistently.
# Note: do not merge to master like this, or the tests will be slow! Ha.
def ensure_stable
  repeat_count = ENV["TRAVIS"] ? 100 : 20
  repeat_count.times do
    yield
  end
end

def safe_click(selector)
  scroll_element_in_to_view(selector)
  page.first(selector).click
end

def click_label(label_for)
  safe_click("label[for='#{label_for}']")
end

def scroll_element_in_to_view(selector)
  expect do
    scroll_to_element_in_view_with_script(selector)
  end.to become_truthy, "Could not find element #{selector}"
end

def get_computed_styles(selector, style_key)
  sanitized_selector = selector.gsub("'", "\\\\'")

  page.evaluate_script <<-EOS
    function() {
      var elem = document.querySelector('#{sanitized_selector}');
      if (!elem) {
        // It would be nice to throw an actual error but I am not sure Capybara will
        // process that well.
        return 'query selector `#{sanitized_selector}` did not match any elements';
      }
      return window.getComputedStyle(elem)['#{style_key}'];
    }();
  EOS
end

def scroll_to_element_in_view_with_script(selector)
  page.evaluate_script <<-EOS
    function() {
      var elem = document.querySelector('#{selector.gsub("'", "\\\\'")}');
      if (!elem) {
        return false;
      }
      elem.scrollIntoView();
      return true;
    }();
  EOS
end

# We generally avoid writing our own polling code, since proper Cappybara use generally
# doesn't require it. That said, there may be some situations (such as evaluating javascript)
# that require a spinning test. We got the following matcher from
# https://gist.github.com/showaltb/0456ce0002842c88c3fc06db43f3ee7b
RSpec::Matchers.define :become_truthy do |wait: Capybara.default_max_wait_time|
  supports_block_expectations

  match do |block|
    Timeout.timeout(wait) do
      # rubocop:disable AssignmentInCondition
      sleep(0.1) until value = block.call
      # rubocop:enable AssignmentInCondition
      value
    end
  rescue TimeoutError
    false
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
