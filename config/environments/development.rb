Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Eager load code on boot.
  config.eager_load = true

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join('tmp', 'caching-dev.txt').exist?
    config.action_controller.perform_caching = true
    config.cache_store = :redis_store, Rails.application.secrets.redis_url_cache, { expires_in: 24.hours }
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options)
  config.active_storage.service = :local

  if ENV["WITH_TEST_EMAIL_SERVER"]
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      port: ENV["TEST_MAIL_SERVER_PORT"] || 1025,
      address: 'localhost'
    }
  else
    # Don't care if the mailer can't send.
    config.action_mailer.raise_delivery_errors = false

    config.action_mailer.perform_caching = false
    config.action_mailer.delivery_method = :test
  end

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  #=====================================================================================================================
  # Please keep custom config settings below this comment.
  #   This will ensure cleaner diffs when generating config file changes during Rails upgrades.
  #=====================================================================================================================

  config.after_initialize do
    Bullet.enable        = true
    Bullet.bullet_logger = true
    Bullet.console       = true
    Bullet.rails_logger  = true
    Bullet.unused_eager_loading_enable = false
  end

  # Disable SqlTracker from creating tmp/sql_tracker-*.json files -- https://github.com/steventen/sql_tracker/pull/10
  SqlTracker::Config.enabled = false

  # Setup S3
  config.s3_enabled = !ENV['AWS_BUCKET_NAME'].nil?
  config.s3_bucket_name = "caseflow-cache"

  config.vacols_db_name = "VACOLS_DEV"

  # Set to true to get the documents from efolder running locally on port 4000.
  config.use_efolder_locally = false

  # set to true to create queues and override the sqs endpiont
  config.sqs_create_queues = true

  config.sqs_endpoint = ENV.has_key?('DOCKERIZED') ? 'http://localstack:4576' : 'http://localhost:4576'

  # since we mock aws using localstack, provide dummy creds to the aws gem
  ENV["AWS_ACCESS_KEY_ID"] ||= "dummykeyid"
  ENV["AWS_SECRET_ACCESS_KEY"] ||= "dummysecretkey"

  # Necessary vars needed to create virtual hearing links
  # Used by VirtualHearings::LinkService
  ENV["VIRTUAL_HEARING_PIN_KEY"] ||= "mysecretkey"
  ENV["VIRTUAL_HEARING_URL_HOST"] ||= "example.va.gov"
  ENV["VIRTUAL_HEARING_URL_PATH"] ||= "/sample"

  # One time Appeal States migration for Legacy & AMA Appeal Batch Sizes
  ENV["STATE_MIGRATION_JOB_BATCH_SIZE"] ||= "1000"

  # Quarterly Notifications Batch Sizes
  ENV["QUARTERLY_NOTIFICATIONS_JOB_BATCH_SIZE"] ||= "1000"

  # Travel Board Sync Batch Size
  ENV["TRAVEL_BOARD_HEARING_SYNC_BATCH_LIMIT"] ||= "250"

  # Notifications page eFolder link
  ENV["CLAIM_EVIDENCE_EFOLDER_BASE_URL"] ||= "https://vefs-claimevidence-ui-uat.stage.bip.va.gov"

  ENV["PACMAN_API_SAML_TOKEN"] ||= "our-saml-token"
  ENV["PACMAN_API_TOKEN_SECRET"] ||= "client-secret"
  ENV["PACMAN_API_TOKEN_ALG"] ||= "HS512"
  ENV["PACMAN_API_TOKEN_ISSUER"] ||= "issuer-of-our-token"
  ENV["PACMAN_API_SYS_ACCOUNT"] ||= "CSS_ID_OF_OUR_ACCOUNT"
  ENV["PACMAN_API_URL"] ||= "https://pacman-uat.dev.bip.va.gov/"

  # eFolder API URL to retrieve appeal documents
  config.efolder_url = "http://localhost:4000"
  config.efolder_key = "token"

  config.google_analytics_account = "UA-74789258-5"
end
