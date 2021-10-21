Rails.application.configure do
  config.after_initialize do
    Bullet.enable        = true
    Bullet.bullet_logger = true
    Bullet.console       = true
    Bullet.rails_logger  = true
    Bullet.unused_eager_loading_enable = false
  end
  # Settings specified here will take precedence over those in config/application.rb.

  # Disable SqlTracker from creating tmp/sql_tracker-*.json files -- https://github.com/steventen/sql_tracker/pull/10
  SqlTracker::Config.enabled = false

  # workaround https://groups.google.com/forum/#!topic/rubyonrails-security/IsQKvDqZdKw
  config.secret_key_base = SecureRandom.hex(64)

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = true

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true

  # Enable/disable caching. By default caching is disabled.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true
    config.cache_store = :redis_store, Rails.application.secrets.redis_url_cache, { expires_in: 24.hours }
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.seconds.to_i}"
    }
  else
    config.action_controller.perform_caching = false
    config.cache_store = :null_store
  end

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

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

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  config.action_mailer.delivery_method = :test

  # eFolder API URL to retrieve appeal documents
  config.efolder_url = "http://localhost:4000"
  config.efolder_key = "token"

  config.google_analytics_account = "UA-74789258-5"
end
