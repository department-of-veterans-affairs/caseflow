# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= "test"
require "simplecov"

require File.expand_path("../../config/environment", __FILE__)

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

require "spec_helper"
require "rspec/rails"
require "react_on_rails"
require_relative "support/fake_pdf_service"
require_relative "support/sauce_driver"
require_relative "support/database_cleaner"
require_relative "support/download_helper"
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
# ActiveRecord::Migration.maintain_test_schema!

require "capybara"
Sniffybara::Driver.configuration_file = File.expand_path("../support/VA-axe-configuration.json", __FILE__)

download_directory = Rails.root.join("tmp/downloads")
cache_directory = Rails.root.join("tmp/browser_cache")

Dir.mkdir download_directory unless File.directory?(download_directory)
if File.directory?(cache_directory)
  FileUtils.rm_r cache_directory
else
  Dir.mkdir cache_directory
end

Capybara.register_driver(:parallel_sniffybara) do |app|
  options = {
    port: 51_674 + (ENV["TEST_ENV_NUMBER"] || 1).to_i,
    browser: :chrome,
    args: ["no-sandbox"],
    prefs: {
      download: {
        prompt_for_download: false,
        default_directory: download_directory
      },
      browser: {
        disk_cache_dir: cache_directory
      }
    }
  }

  Sniffybara::Driver.current_driver = Sniffybara::Driver.new(app, options)
end

Capybara.default_driver = ENV["SAUCE_SPECS"] ? :sauce_driver : :parallel_sniffybara

ActiveRecord::Migration.maintain_test_schema!

# Convenience methods for stubbing current user
module StubbableUser
  module ClassMethods
    def clear_stub!
      @stub = nil
    end

    def stub=(user)
      @stub = user
    end

    def authenticate!(roles: nil)
      admin_roles = roles && roles.include?("System Admin") ? ["System Admin"] : []
      self.stub = User.from_session(
        { "user" =>
          { "id" => "DSUSER",
            "station_id" => "283",
            "email" => "test@example.com",
            "roles" => roles || ["Certify Appeal"],
            "admin_roles" => admin_roles }
        }, OpenStruct.new(remote_ip: "127.0.0.1"))
    end

    def tester!(roles: nil)
      self.stub = User.from_session(
        { "user" =>
          { "id" => ENV["TEST_USER_ID"],
            "station_id" => "283",
            "email" => "test@example.com",
            "roles" => roles || ["Certify Appeal"] }
        }, OpenStruct.new(remote_ip: "127.0.0.1"))
    end

    def current_user
      @stub
    end

    def before_set_user
      clear_stub!
    end

    def unauthenticate!
      self.stub = nil
    end

    def from_session(session, request)
      @stub || super(session, request)
    end
  end

  def self.prepended(base)
    class << base
      prepend ClassMethods
    end
  end
end

User.prepend(StubbableUser)

def reset_application!
  User.clear_stub!
  Fakes::AppealRepository.clean!
  Fakes::HearingRepository.clean!
  Fakes::CAVCDecisionRepository.clean!
  Fakes::BGSService.clean!
end

def current_user
  User.current_user
end

# Setup fakes
Appeal.repository = Fakes::AppealRepository
PowerOfAttorney.repository = Fakes::PowerOfAttorneyRepository
Hearing.repository = Fakes::HearingRepository
User.authentication_service = Fakes::AuthenticationService
CAVCDecision.repository = Fakes::CAVCDecisionRepository

RSpec.configure do |config|
  # This checks whether compiled webpack assets already exist
  # If it does, it will not execute ReactOnRails, since that slows down tests
  # Thus this will only run once (to initially compile assets) and not on
  # subsequent test runs
  if Dir["#{::Rails.root}/app/assets/webpack/*"].empty?
    ReactOnRails::TestHelper.ensure_assets_compiled
  end
  config.before(:all) do
    User.unauthenticate!
  end

  config.after(:each) do
    Timecop.return
    Rails.cache.clear
  end

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

# Wrap this around your test to run it many times and ensure that it passes consistently.
# Note: do not merge to master like this, or the tests will be slow! Ha.
def ensure_stable
  10.times do
    yield
  end
end

# We generally avoid writing our own polling code, since proper Cappybara use generally
# doesn't require it. That said, there may be some situations (such as evaluating javascript)
# that require a spinning test. We got the following matcher from https://gist.github.com/jnicklas/4129937
RSpec::Matchers.define :become_truthy do |_event_name|
  supports_block_expectations

  match do |block|
    begin
      Timeout.timeout(Capybara.default_max_wait_time) do
        sleep(0.1) until block.call
        true
      end
    rescue TimeoutError
      false
    end
  end
end
