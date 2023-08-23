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
    config.load_defaults 6.0

    # Override new 'zeitwerk' autoloading default to preserve 'classic' behavior.
    # We must transition to 'zeitwerk' when upgrading to Rails 7.0.
    config.autoloader = :classic

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    #===================================================================================================================
    # Rails default overrides
    #   These settings override the defaults set by `config.load_defaults`. If and as appropriate, we can transition
    #   these overrides one-by-one to migrate to their respective defaults.
    #   See the Rails Guides: Configuring Rails Applications for more info on each option.
    #   https://guides.rubyonrails.org/configuring.html
    #
    # ==================================================================================================================
    # Rails 5.0 default overrides
    # ------------------------------------------------------------------------------------------------------------------

    # Enable per-form CSRF tokens.
    # Default (starting v5.0): true
    config.action_controller.per_form_csrf_tokens = false

    # Enable origin-checking CSRF mitigation.
    # Default as of 5.0: true
    config.action_controller.forgery_protection_origin_check = false

    # Make Ruby 2.4 preserve the timezone of the receiver when calling `to_time`.
    # Default as of 5.0: true
    ActiveSupport.to_time_preserves_timezone = false

    # Require `belongs_to` associations by default.
    # Default as of 5.0: true
    config.active_record.belongs_to_required_by_default = false

    # ==================================================================================================================
    # Rails 5.1 default overrides
    # ------------------------------------------------------------------------------------------------------------------

    # Make `form_with` generate non-remote forms.
    # Default as of 5.1: true
    # Default as of 6.1: false
    Rails.application.config.action_view.form_with_generates_remote_forms = false

    # ==================================================================================================================
    # Rails 5.2 default overrides
    # ------------------------------------------------------------------------------------------------------------------

    # Use AES-256-GCM authenticated encryption for encrypted cookies.
    # Also, embed cookie expiry in signed or encrypted cookies for increased security.
    #
    # This option is not backwards compatible with earlier Rails versions.
    # It's best enabled when your entire app is migrated and stable on 5.2.
    #
    # Existing cookies will be converted on read then written with the new scheme.
    # Default as of 5.2: true
    Rails.application.config.action_dispatch.use_authenticated_cookie_encryption = false
    #
    # Use AES-256-GCM authenticated encryption as default cipher for encrypting messages
    # instead of AES-256-CBC, when use_authenticated_message_encryption is set to true.
    # Default as of 5.2: true
    Rails.application.config.active_support.use_authenticated_message_encryption = false

    # Add default protection from forgery to ActionController::Base instead of in ApplicationController.
    # Default as of 5.2: true
    Rails.application.config.action_controller.default_protect_from_forgery = false

    # Store boolean values in sqlite3 databases as 1 and 0 instead of 't' and 'f' after migrating old data.
    # Default as of 5.2: true
    Rails.application.config.active_record.sqlite3.represent_boolean_as_integer = false

    # ==================================================================================================================
    # Rails 6.0 default overrides
    # ------------------------------------------------------------------------------------------------------------------

    # Don't force requests from old versions of IE to be UTF-8 encoded.
    # Default as of 6.0: false
    Rails.application.config.action_view.default_enforce_utf8 = true

    # Embed purpose and expiry metadata inside signed and encrypted
    # cookies for increased security.
    #
    # This option is not backwards compatible with earlier Rails versions.
    # It's best enabled when your entire app is migrated and stable on 6.0.
    # Default as of 6.0: true
    Rails.application.config.action_dispatch.use_cookies_with_metadata = false

    # Change the return value of `ActionDispatch::Response#content_type` to Content-Type header without modification.
    # Rails.application.config.action_dispatch.return_only_media_type_on_content_type = false

    # Return false instead of self when enqueuing is aborted from a callback.
    # Rails.application.config.active_job.return_false_on_aborted_enqueue = true

    # Send Active Storage analysis and purge jobs to dedicated queues.
    # Rails.application.config.active_storage.queues.analysis = :active_storage_analysis
    # Rails.application.config.active_storage.queues.purge    = :active_storage_purge

    # When assigning to a collection of attachments declared via `has_many_attached`, replace existing
    # attachments instead of appending. Use #attach to add new attachments without replacing existing ones.
    # Rails.application.config.active_storage.replace_on_assign_to_many = true

    # Use ActionMailer::MailDeliveryJob for sending parameterized and normal mail.
    #
    # The default delivery jobs (ActionMailer::Parameterized::DeliveryJob, ActionMailer::DeliveryJob),
    # will be removed in Rails 6.1. This setting is not backwards compatible with earlier Rails versions.
    # If you send mail in the background, job workers need to have a copy of
    # MailDeliveryJob to ensure all delivery jobs are processed properly.
    # Make sure your entire app is migrated and stable on 6.0 before using this setting.
    # Rails.application.config.action_mailer.delivery_job = "ActionMailer::MailDeliveryJob"

    # Enable the same cache key to be reused when the object being cached of type
    # `ActiveRecord::Relation` changes by moving the volatile information (max updated at and count)
    # of the relation's cache key into the cache version to support recycling cache key.
    # Default as of 6.0: true
    Rails.application.config.active_record.collection_cache_versioning = false

    # ==================================================================================================================

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

    # config for which SQS endpoint we should use. Override this for local testing
    config.sqs_create_queues = false
    config.sqs_endpoint = nil

    # sqs details
    config.active_job.queue_name_prefix = "caseflow_" + ENV['DEPLOY_ENV']

    # it's a safe assumption we're running on us-gov-west-1
    ENV["AWS_REGION"] ||= "us-gov-west-1"

    if Rails.env.development? && ENV["PERFORMANCE_PROFILE"].present?
      config.middleware.use(
        Rack::RubyProf,
        path: './tmp/profile',
        printers: {
          ::RubyProf::CallTreePrinter => 'test-callgrind'
        }
      )
    end

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

    # https://stackoverflow.com/questions/13506690/how-to-determine-if-rails-is-running-from-cli-console-or-as-server
    if defined?(Rails::Console)
      require_relative "../lib/helpers/production_console_methods"
      require_relative "../lib/helpers/finder_console_methods.rb"
      TOPLEVEL_BINDING.eval("self").extend ProductionConsoleMethods
      TOPLEVEL_BINDING.eval("self").extend FinderConsoleMethods
    end
    # :nocov:
  end
end
