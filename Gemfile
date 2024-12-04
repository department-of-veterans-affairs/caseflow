# frozen_string_literal: true

# rubocop:disable Layout/LineLength
source ENV["GEM_SERVER_URL"] || "https://rubygems.org"

# State machine
gem "aasm", "4.11.0"
gem "activerecord-import", "1.0.3"
gem "acts_as_tree"

# amoeba gem for cloning appeals
gem "amoeba"
gem "aws-sdk"
# BGS
gem "bgs", git: "https://github.com/department-of-veterans-affairs/ruby-bgs.git", ref: "a2e055b5a52bd1e2bb8c2b3b8d5820b1a404cd3d"
# Bootsnap speeds up app boot (and started to be a default gem in 5.2).
gem "bootsnap", require: false
gem "browser"
gem "business_time", "~> 0.9.3"
gem "caseflow", git: "https://github.com/department-of-veterans-affairs/caseflow-commons", ref: "dbd86859856d161d84b0bba4d67a8b62e4684996"
gem "connect_mpi", git: "https://github.com/department-of-veterans-affairs/connect-mpi.git", ref: "a3a58c64f85b980a8b5ea6347430dd73a99ea74c"
gem "connect_vbms", git: "https://github.com/department-of-veterans-affairs/connect_vbms.git", ref: "9807d9c9f0f3e3494a60b6693dc4f455c1e3e922"
gem "console_tree_renderer", git: "https://github.com/department-of-veterans-affairs/console-tree-renderer.git", tag: "v0.1.1"
gem "countries"
gem "dry-schema", "~> 1.4"
gem "fast_jsonapi"
gem "fuzzy_match"
gem "govdelivery-tms", require: "govdelivery/tms/mail/delivery_method"
gem "holidays", "~> 6.4"
gem "icalendar"
gem "kaminari"
gem "logstasher"
gem "moment_timezone-rails"
gem "nokogiri", ">= 1.11.0.rc4"

gem "opentelemetry-exporter-otlp", require: false
gem "opentelemetry-sdk", require: false

gem "opentelemetry-instrumentation-action_pack", require: false
gem "opentelemetry-instrumentation-action_view", require: false
gem "opentelemetry-instrumentation-active_job", require: false
gem "opentelemetry-instrumentation-active_model_serializers", require: false
gem "opentelemetry-instrumentation-active_record", require: false
gem "opentelemetry-instrumentation-aws_sdk", require: false
gem "opentelemetry-instrumentation-concurrent_ruby", require: false
gem "opentelemetry-instrumentation-faraday", require: false
gem "opentelemetry-instrumentation-http", require: false
gem "opentelemetry-instrumentation-http_client", require: false
gem "opentelemetry-instrumentation-net_http", require: false
gem "opentelemetry-instrumentation-pg", require: false
gem "opentelemetry-instrumentation-rack", require: false
gem "opentelemetry-instrumentation-rails", require: false
gem "opentelemetry-instrumentation-rake", require: false
gem "opentelemetry-instrumentation-redis", require: false

gem "httparty", "~> 0.22.0"
gem "paper_trail", "~> 12.0"
# Used to speed up reporting
gem "parallel"
# soft delete gem
gem "paranoia", "~> 2.2"
# PDF Tools
gem "pdf-forms"
# Used in Caseflow Dispatch
gem "pdfjs_viewer-rails", git: "https://github.com/senny/pdfjs_viewer-rails.git", ref: "a4249eacbf70175db63b57e9f364d0a9a79e2b43"
# Used to build out PDF files on the backend
# https://github.com/pdfkit/pdfkit
gem "pdfkit"
gem "pg", "~> 1.5.7", platforms: :ruby
# Application server: Puma
# Puma was chosen because it handles load of 40+ concurrent users better than Unicorn and Passenger
# Discussion: https://github.com/18F/college-choice/issues/597#issuecomment-139034834
gem "puma", "5.6.4"
gem "rack", "~> 2.2.6.2"
gem "rails", "6.1.7.7"
# Used to colorize output for rake tasks
gem "rainbow"
gem "rcredstash", "~> 1.1.0"
# React
gem "react_on_rails", "11.3.0"
gem "redis-mutex"
gem "redis-namespace", "~> 1.11.0"
gem "redis-rails", "~> 5.0.2"
gem "request_store"
gem "roo", "~> 2.7"
gem "rswag-api"
gem "rswag-ui"
gem "rtf"
gem "ruby_claim_evidence_api", git: "https://github.com/department-of-veterans-affairs/ruby_claim_evidence_api.git", ref: "fed623802afe7303f4b8b5fe27cff0e903699873"
# Use SCSS for stylesheets
gem "sass-rails", "~> 5.0"
# Error reporting to Sentry
gem "sentry-raven"
gem "shoryuken", "3.1.11"
gem "statsd-instrument"
gem "stringex", require: false
# catch problematic migrations at development/test time
gem "strong_migrations"
# print trees
gem "tty-tree"
gem "tzinfo", "~> 2.0"
# Use Uglifier as compressor for JavaScript assets
gem "uglifier", ">= 1.3.0"
gem "validates_email_format_of"
gem "webvtt-ruby"
gem "ziptz"

group :production, :staging, :ssh_forwarding, :development, :test do
  # Oracle DB
  gem "activerecord-oracle_enhanced-adapter", "~> 6.1.0"
  gem "ruby-oci8", "~> 2.2.14"
end

group :test, :development, :demo, :make_docs do
  # Security scanners
  gem "brakeman"
  gem "bullet", "~> 6.1.0"
  gem "bundler-audit"
  # Testing tools
  gem "capybara"
  gem "capybara-screenshot"
  gem "danger", "~> 6.2.2"
  gem "database_cleaner-active_record", "2.0.0"
  gem "factory_bot_rails", "~> 5.2"
  gem "faker"
  gem "guard-rspec"
  gem "immigrant"
  # Linters
  gem "pluck_to_hash"
  gem "pry", "~> 0.13.0"
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "pry-byebug", "~> 3.9"
  gem "rails-erd"
  gem "rb-readline"
  gem "rspec"
  # For CircleCI test metadata analysis
  gem "rspec-rails"
  gem "rspec_junit_formatter"
  gem "rswag-specs"
  gem "rubocop", "= 0.83", require: false
  gem "rubocop-performance"
  gem "rubocop-rails"
  gem "scss_lint", require: false
  gem "simplecov", require: false
  gem "simplecov-lcov", require: false
  gem "single_cov"
  gem "sniffybara", git: "https://github.com/department-of-veterans-affairs/sniffybara.git"
  gem "sql_tracker"
  gem "test-prof"
  gem "timecop"
  gem "webdrivers"
end

group :development do
  gem "anbt-sql-formatter"
  gem "bummr", require: false
  gem "debase"
  gem "derailed_benchmarks"
  gem "dotenv-rails"
  gem "fasterer", require: false
  gem "foreman"
  gem "meta_request"
  gem "ruby-debug-ide"
  gem "ruby-prof", "~> 1.4"
  gem "solargraph"
end

group :test do
  gem "knapsack_pro", "~> 3.8"
  gem "rspec-github", require: false
  # For retrying failed feature tests. Read more: https://github.com/NoRedInk/rspec-retry
  gem "rspec-retry"
  gem "shoulda-matchers"
  gem "webmock"
end
# rubocop:enable Layout/LineLength

gem "json_schemer", "~> 0.2.16"
