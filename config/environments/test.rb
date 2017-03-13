require "fileutils"
Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  cache_dir = Rails.root.join("tmp", "cache", "paralleltests#{ENV['TEST_ENV_NUMBER']}")
  FileUtils.mkdir_p(cache_dir) unless File.exists?(cache_dir)
  config.cache_store = :file_store, cache_dir

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure static file server for tests with Cache-Control for performance.
  config.serve_static_files   = true
  config.static_cache_control = 'public, max-age=3600'

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = true

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Randomize the order test cases are executed.
  config.active_support.test_order = :random

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Setup S3
  config.s3_enabled = false

  if ENV['TEST_ENV_NUMBER']
    assets_cache_path = Rails.root.join("tmp/cache/assets/paralleltests#{ENV['TEST_ENV_NUMBER']}")
    config.assets.configure do |env|
      env.cache = Sprockets::Cache::FileStore.new(assets_cache_path)
    end
  end

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true
  #
  ENV["CASEFLOW_FEEDBACK_URL"] = "test.feedback.url"

  ENV["METRICS_USERNAME"] = "caseflow"
  ENV["METRICS_PASSWORD"] = "caseflow"

  # For testing uncertification methods
  ENV["TEST_USER_ID"] = "TEST_USER_ID"
  ENV["TEST_APPEAL_IDS"] = "123C,456D,678E"
  ENV["FULL_GRANT_IDS"] = "VACOLS123,VACOLS234,VACOLS345,VACOLS456"
  ENV["PARTIAL_AND_REMAND_IDS"] = "VACOLS321,VACOLS432,VACOLS543,VACOLS654"
end
