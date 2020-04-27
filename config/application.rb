require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# We need this because the autoload pathing to VBMS::HTTPError is messed up in connect_vbms
require "vbms"

module CaseflowCertification
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    # config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # setup the deploy env environment variable
    ENV['DEPLOY_ENV'] ||= Rails.env

    config.eager_load_paths << Rails.root.join('lib')
    config.eager_load_paths += Dir[Rails.root.join('app', 'models', '{**}', '{**}')]
    config.eager_load_paths += Dir[Rails.root.join('app', 'serializers', '{**}')]

    config.exceptions_app = self.routes

    config.cache_store = :redis_store, Rails.application.secrets.redis_url_cache, { expires_in: 24.hours }
    config.sso_service_disabled = ENV["SSO_SERVICE_DISABLED"]

    config.google_analytics_account = nil

    config.bgs_environment = ENV["BGS_ENVIRONMENT"] || "beplinktest"

    # Used by the application to determine whether webpack hot reloading is active
    config.webpack_hot = (ENV["REACT_ON_RAILS_ENV"] == "HOT")
    config.use_efolder_locally = false

    # eFolder API URL to retrieve appeal documents
    config.efolder_url = ENV["EFOLDER_EXPRESS_URL"]
    config.efolder_key = ENV["EFOLDER_API_KEY"]
    config.active_job.queue_adapter = :shoryuken

    config.vacols_db_name = "VACOLS"

    # filter out X-Forwarded-For and friends
    config.middleware.insert_before 0, Rack::HeadersFilter

    # config for which SQS endpoint we should use. Override this for local testing
    config.sqs_create_queues = false
    config.sqs_endpoint = nil

    # sqs details
    config.active_job.queue_name_prefix = "caseflow_" + ENV['DEPLOY_ENV']

    # it's a safe assumption we're running on us-gov-west-1
    ENV["AWS_REGION"] ||= "us-gov-west-1"

    # :nocov:
    if %w[development ssh_forwarding staging].include?(Rails.env)
      # configure pry
      silence_warnings do
        begin
          require 'pry'
          config.console = Pry
          unless defined? Pry::ExtendCommandBundle
            Pry::ExtendCommandBundle = Module.new
          end
          require "rails/console/app"
          require "rails/console/helpers"
          require_relative "../lib/helpers/console_methods"

          TOPLEVEL_BINDING.eval('self').extend ::Rails::ConsoleMethods
          TOPLEVEL_BINDING.eval('self').extend ConsoleMethods
        rescue LoadError
        end
      end
    end
    # :nocov:
  end
end
