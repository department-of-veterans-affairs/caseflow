require "fileutils"
Rails.application.configure do
  config.after_initialize do
    Bullet.enable        = false
    Bullet.bullet_logger = true
    Bullet.rails_logger  = true
    Bullet.raise = true
    Bullet.unused_eager_loading_enable = false
  end
  # Settings specified here will take precedence over those in config/application.rb.

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  cache_dir = Rails.root.join("tmp", "cache", "test_#{ENV['TEST_SUBCATEGORY']}", $$.to_s)
  FileUtils.mkdir_p(cache_dir) unless File.exists?(cache_dir)
  config.cache_store = :file_store, cache_dir

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => 'public, max-age=#{1.hour.seconds.to_i}'
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = true

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false
  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Setup S3
  config.s3_enabled = false

  config.vacols_db_name = "VACOLS_TEST"

  if ENV['TEST_SUBCATEGORY']
    assets_cache_path = Rails.root.join("tmp/cache/assets/#{ENV['TEST_SUBCATEGORY']}")
    config.assets.configure do |env|
      env.cache = Sprockets::Cache::FileStore.new(assets_cache_path)
    end
  end

  # Allows rake scripts to be run without querying VACOLS on startup
  if ENV['DISABLE_FACTORY_BOT_INITIALIZERS']
    config.factory_bot.definition_file_paths = []
  end

  unless ENV['RAILS_ENABLE_TEST_LOG']
    config.logger = Logger.new(nil)
    config.log_level = :error
  end

  config.action_mailer.delivery_method = :test

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  ENV["VA_DOT_GOV_API_URL"] = "https://staging-api.va.gov/"

  # For testing uncertification methods
  ENV["TEST_USER_ID"] = "TEST_USER_ID"
  ENV["TEST_APPEAL_IDS"] = "123C,456D,678E"
  ENV["FULL_GRANT_IDS"] = "VACOLS123,VACOLS234,VACOLS345,VACOLS456"
  ENV["PARTIAL_AND_REMAND_IDS"] = "VACOLS321,VACOLS432,VACOLS543,VACOLS654"

  config.active_job.queue_adapter = :test

  # Disable SqlTracker from creating tmp/sql_tracker-*.json files -- https://github.com/steventen/sql_tracker/pull/10
  SqlTracker::Config.enabled = false
end
