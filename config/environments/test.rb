require "active_support/core_ext/integer/time"
require "fileutils"
require_relative "../../lib/deprecation_warnings"

# The test environment is used exclusively to run your application's
# test suite. You never need to work with it otherwise. Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs. Don't rely on the data there!

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Turn false under Spring and add config.action_view.cache_template_loading = true.
  config.cache_classes = true


  # Eager loading loads your whole application. When running a single test locally,
  # this probably isn't necessary. It's a good idea to do in a continuous integration
  # system, or in some way before deploying your code.
  config.eager_load = false

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=#{1.hour.to_i}"
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = false

  cache_dir = Rails.root.join("tmp/cache/test_#{ENV['TEST_SUBCATEGORY']}", $$.to_s)
  FileUtils.mkdir_p(cache_dir) unless File.exists?(cache_dir)
  config.cache_store = :file_store, cache_dir

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = true

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Store uploaded files on the local file system in a temporary directory.
  config.active_storage.service = :test

  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = DeprecationWarnings::DISALLOWED_DEPRECATION_WARNING_REGEXES

  unless ENV['RAILS_ENABLE_TEST_LOG']
    config.logger = Logger.new(nil)
    config.log_level = :error
  end

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  #=====================================================================================================================
  # Please keep custom config settings below this comment.
  #   This will ensure cleaner diffs when generating config file changes during Rails upgrades.
  #=====================================================================================================================

  config.after_initialize do
    Bullet.enable        = false
    Bullet.bullet_logger = true
    Bullet.rails_logger  = true
    Bullet.raise = true
    Bullet.unused_eager_loading_enable = false
  end

  ENV["VA_DOT_GOV_API_URL"] = "https://sandbox-api.va.gov/"

  # For testing uncertification methods
  ENV["TEST_USER_ID"] = "TEST_USER_ID"
  ENV["TEST_APPEAL_IDS"] = "123C,456D,678E"
  ENV["FULL_GRANT_IDS"] = "VACOLS123,VACOLS234,VACOLS345,VACOLS456"
  ENV["PARTIAL_AND_REMAND_IDS"] = "VACOLS321,VACOLS432,VACOLS543,VACOLS654"

  ENV["AWS_ACCESS_KEY_ID"] ||= "dummykeyid"
  ENV["AWS_SECRET_ACCESS_KEY"] ||= "dummysecretkey"

  # BatchProcess ENVs
  # priority_ep_sync
  ENV["BATCH_PROCESS_JOB_DURATION"] ||= "50" # Number of minutes the job will run for
  ENV["BATCH_PROCESS_SLEEP_DURATION"] ||= "0" # Number of seconds between loop iterations
  ENV["BATCH_PROCESS_BATCH_LIMIT"]||= "100" # Max number of records in a batch
  ENV["BATCH_PROCESS_ERROR_DELAY"] ||= "3" # In number of hours
  ENV["BATCH_PROCESS_MAX_ERRORS_BEFORE_STUCK"] ||= "3" # When record errors for X time, it's declared stuck

  # RequestIssue paginates_per offset (vbms intake)
  ENV["REQUEST_ISSUE_PAGINATION_OFFSET"] ||= "10"
  ENV["REQUEST_ISSUE_DEFAULT_UPPER_BOUND_PER_PAGE"] ||= "50"

  config.active_job.queue_adapter = :test

  # Disable SqlTracker from creating tmp/sql_tracker-*.json files -- https://github.com/steventen/sql_tracker/pull/10
  SqlTracker::Config.enabled = false

  # Setup S3
  config.s3_enabled = false

  config.vacols_db_name = "VACOLS_TEST"

  if ENV["TEST_SUBCATEGORY"]
    assets_cache_path = Rails.root.join("tmp/cache/assets/#{ENV['TEST_SUBCATEGORY']}")
    config.assets.configure do |env|
      env.cache = Sprockets::Cache::FileStore.new(assets_cache_path)
    end
  end

  # Allows rake scripts to be run without querying VACOLS on startup
  if ENV["DISABLE_FACTORY_BOT_INITIALIZERS"]
    config.factory_bot.definition_file_paths = []
  end

  # VA Notify environment variables
  ENV["VA_NOTIFY_API_URL"] ||= "https://staging-api.va.gov/vanotify"
  ENV["VA_NOTIFY_API_KEY"] ||= "secret-key"
  ENV["VA_NOTIFY_SERVICE_ID"] ||= "fake-service-id"
  ENV["VA_NOTIFY_TOKEN_ALG"] ||= "my-secret-algorithm"
  ENV["VA_NOTIFY_STATUS_UPDATE_BATCH_LIMIT"] ||= "650"

  # One time Appeal States migration for Legacy & AMA Appeal Batch Sizes
  ENV["STATE_MIGRATION_JOB_BATCH_SIZE"] ||= "1000"

  # Syncing decided appeals in select batch sizes
  ENV["VACOLS_QUERY_BATCH_SIZE"] ||= "800"

  # Travel Board Sync Batch Size
  ENV["TRAVEL_BOARD_HEARING_SYNC_BATCH_LIMIT"] ||= "250"

  # Time in seconds before the sync lock expires
  LOCK_TIMEOUT = ENV["SYNC_LOCK_MAX_DURATION"] ||= "60"

  # Notifications page eFolder link
  ENV["CLAIM_EVIDENCE_EFOLDER_BASE_URL"] ||= "https://vefs-claimevidence-ui-uat.stage.bip.va.gov"

  ENV['TEST_VACOLS_HOST'] ||= "localhost"

  # Pacman environment variables
  ENV["PACMAN_API_TOKEN_ALG"] ||= "HS512"
  ENV["PACMAN_API_URL"] ||= "https://pacman-uat.dev.bip.va.gov"
  ENV["PACMAN_API_SAML_TOKEN"] ||= "our-saml-token"
  ENV["PACMAN_API_TOKEN_SECRET"] ||= "client-secret"
  ENV["PACMAN_API_TOKEN_ISSUER"] ||= "issuer-of-our-token"
  ENV["PACMAN_API_SYS_ACCOUNT"] ||= "CSS_ID_OF_OUR_ACCOUNT"

  # Webex environment variables
  ENV["WEBEX_PORT"] ||= "443"
  ENV["WEBEX_HOST_IC"] ||= "mtg-broker."
  ENV["WEBEX_HOST_MAIN"] ||= "api-usgov."
  ENV["WEBEX_HOST_STATS"] ||= "status."
  ENV["WEBEX_DOMAIN_IC"] ||= "gov.ciscospark.com"
  ENV["WEBEX_DOMAIN_MAIN"] ||= "webex.com"
  ENV["WEBEX_API_IC"] ||= "/api/v2/joseencrypt"
  ENV["WEBEX_API_MAIN"] ||= "/v1/"

  # Pexip environment variables
  ENV["VIRTUAL_HEARING_PIN_KEY"] ||= "mysecretkey"
  ENV["VIRTUAL_HEARING_URL_HOST"] ||= "example.va.gov"
  ENV["VIRTUAL_HEARING_URL_PATH"] ||= "/sample"

  # Dynatrace variables
  ENV["STATSD_ENV"] = "test"

  config.sqs_create_queues = true
  config.sqs_endpoint = ENV["CI"] ? 'http://localstack:4566' : 'http://localhost:4566'
end
