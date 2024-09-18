require "active_support/core_ext/integer/time"
require_relative "../../lib/deprecation_warnings"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # When `config.assets.debug == true`, there is an edge case where the length of the Link header could become
  # exceptionally long, due to the way concatenated assets are split and included separately, thus exceeding the
  # maximum 8192 bytes for HTTP response headers. To preclude this from happening, we override the default here:
  config.action_view.preload_links_header = false

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
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
    config.action_controller.enable_fragment_cache_logging = true
    config.cache_store = :redis_store, Rails.application.secrets.redis_url_cache, { expires_in: 24.hours }
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    # config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options).
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

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = DeprecationWarnings::DISALLOWED_DEPRECATION_WARNING_REGEXES

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

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # Bypass DNS rebinding protection for all `demo` sub-domains
  config.hosts << ".demo.appeals.va.gov"

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

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

  # set to true to create queues and override the sqs endpoint
  config.sqs_create_queues = true

  config.sqs_endpoint = ENV.has_key?('DOCKERIZED') ? 'http://localstack:4566' : 'http://localhost:4566'

  # since we mock aws using localstack, provide dummy creds to the aws gem
  ENV["AWS_ACCESS_KEY_ID"] ||= "dummykeyid"
  ENV["AWS_SECRET_ACCESS_KEY"] ||= "dummysecretkey"

  # BatchProcess ENVs
  # priority_ep_sync
  ENV["BATCH_PROCESS_JOB_DURATION"] ||= "50" # Number of minutes the job will run for
  ENV["BATCH_PROCESS_SLEEP_DURATION"] ||= "5" # Number of seconds between loop iterations
  ENV["BATCH_PROCESS_BATCH_LIMIT"]||= "100" # Max number of records in a batch
  ENV["BATCH_PROCESS_ERROR_DELAY"] ||= "3" # In number of hours
  ENV["BATCH_PROCESS_MAX_ERRORS_BEFORE_STUCK"] ||= "3" # When record errors for X time, it's declared stuck

  # RequestIssue paginates_per offset (vbms intake)
  ENV["REQUEST_ISSUE_PAGINATION_OFFSET"] ||= "10"
  ENV["REQUEST_ISSUE_DEFAULT_UPPER_BOUND_PER_PAGE"] ||= "50"

  # Necessary vars needed to create virtual hearing links
  # Used by VirtualHearings::PexipLinkService
  ENV["VIRTUAL_HEARING_PIN_KEY"] ||= "mysecretkey"
  ENV["VIRTUAL_HEARING_URL_HOST"] ||= "example.va.gov"
  ENV["VIRTUAL_HEARING_URL_PATH"] ||= "/sample"

  # One time Appeal States migration for Legacy & AMA Appeal Batch Sizes
  ENV["STATE_MIGRATION_JOB_BATCH_SIZE"] ||= "1000"

  # Syncing decided appeals in select batch sizes
  ENV["VACOLS_QUERY_BATCH_SIZE"] ||= "800"

  # Travel Board Sync Batch Size
  ENV["TRAVEL_BOARD_HEARING_SYNC_BATCH_LIMIT"] ||= "250"

  # Time in seconds before the sync lock expires
  LOCK_TIMEOUT = ENV["SYNC_LOCK_MAX_DURATION"] ||= "60"

  ENV["CASEFLOW_BASE_URL"] ||= "http://localhost:3000"

  # Notifications page eFolder link
  ENV["CLAIM_EVIDENCE_EFOLDER_BASE_URL"] ||= "https://vefs-claimevidence-ui-uat.stage.bip.va.gov"

  ENV["PACMAN_API_SAML_TOKEN"] ||= "our-saml-token"
  ENV["PACMAN_API_TOKEN_SECRET"] ||= "client-secret"
  ENV["PACMAN_API_TOKEN_ALG"] ||= "HS512"
  ENV["PACMAN_API_TOKEN_ISSUER"] ||= "issuer-of-our-token"
  ENV["PACMAN_API_SYS_ACCOUNT"] ||= "CSS_ID_OF_OUR_ACCOUNT"
  ENV["PACMAN_API_URL"] ||= "https://pacman-uat.dev.bip.va.gov/"

  # Dynatrace variables
  ENV["STATSD_ENV"] = "development"

  # eFolder API URL to retrieve appeal documents
  config.efolder_url = "http://localhost:4000"
  config.efolder_key = "token"

  config.google_analytics_account = "UA-74789258-5"

  # Appeals Consumer
  config.hosts << "host.docker.internal"
end
