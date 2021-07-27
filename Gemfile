# frozen_string_literal: true

# rubocop:disable Metrics/LineLength
source ENV["GEM_SERVER_URL"] || "https://rubygems.org"

# State machine
gem "aasm", "4.11.0"
gem "activerecord-import"
gem "acts_as_tree"
# BGS

gem "bgs", git: "https://github.com/department-of-veterans-affairs/ruby-bgs.git", ref: "7d7c67f7bad5e5aa03e257f0d8e57a4aa1a6cbbf"
# Bootsnap speeds up app boot (and started to be a default gem in 5.2).
gem "bootsnap", require: false
gem "business_time", "~> 0.9.3"
gem "caseflow", git: "https://github.com/department-of-veterans-affairs/caseflow-commons", ref: "fb6fa9658825c143eb8d202b87128f34ca7e210b"
gem "connect_vbms", git: "https://github.com/department-of-veterans-affairs/connect_vbms.git", ref: "049b3c5068fa6c6d1cae0b58654529316b84be57"
gem "console_tree_renderer", git: "https://github.com/department-of-veterans-affairs/console-tree-renderer.git", tag: "v0.1.1"
gem "countries"
gem "ddtrace"
gem "dogstatsd-ruby"
gem "dry-schema", "~> 1.4"
gem "fast_jsonapi"
gem "fuzzy_match"
gem "govdelivery-tms", require: "govdelivery/tms/mail/delivery_method"
gem "holidays", "~> 6.4"
gem "icalendar"
gem "kaminari"
gem "logstasher"
gem "moment_timezone-rails"
# Rails 6 has native support for multiple dbs, so prefer that over multiverse after upgrade.
# https://github.com/ankane/multiverse#upgrading-to-rails-6
gem "multiverse"
gem "newrelic_rpm"
gem "nokogiri", ">= 1.11.0.rc4"
gem "paper_trail", "~> 10"
# Used to speed up reporting
gem "parallel"
# soft delete gem
gem "paranoia", "~> 2.2"
# PDF Tools
gem "pdf-forms"
gem "pdfjs_viewer-rails", git: "https://github.com/senny/pdfjs_viewer-rails.git", ref: "a4249eacbf70175db63b57e9f364d0a9a79e2b43"
gem "pg", platforms: :ruby
# Application server: Puma
# Puma was chosen because it handles load of 40+ concurrent users better than Unicorn and Passenger
# Discussion: https://github.com/18F/college-choice/issues/597#issuecomment-139034834
gem "puma", "~> 5"
gem "rack", "~> 2.2.3"
gem "rails", "5.2.4.6"
# Used to colorize output for rake tasks
gem "rainbow"
# React
gem "react_on_rails", "11.3.0"
gem "redis-namespace"
gem "redis-rails", "~> 5.0.2"
gem "request_store"
gem "roo", "~> 2.7"
# Use SCSS for stylesheets
gem "sass-rails", "~> 5.0"
# Error reporting to Sentry
gem "sentry-raven"
gem "shoryuken", "3.1.11"
gem "stringex", require: false
# catch problematic migrations at development/test time
gem "strong_migrations"
# execjs runtime
gem "therubyracer", platforms: :ruby
# print trees
gem "tty-tree"
gem "tzinfo"
# Use Uglifier as compressor for JavaScript assets
gem "uglifier", ">= 1.3.0"
gem "validates_email_format_of"
gem "ziptz"

group :production, :staging, :ssh_forwarding, :development, :test do
  # Oracle DB
  gem "activerecord-oracle_enhanced-adapter", "~> 5.2.0"
  gem "ruby-oci8", "~> 2.2"
end

group :test, :development, :demo do
  # Security scanners
  gem "brakeman"
  gem "bullet"
  gem "bundler-audit"
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: :ruby
  # Testing tools
  gem "capybara"
  gem "capybara-screenshot"
  gem "danger", "~> 6.0"
  gem "database_cleaner"
  gem "factory_bot_rails", "~> 5.2"
  gem "faker"
  gem "guard-rspec"
  gem "immigrant"
  # Linters
  gem "jshint", platforms: :ruby
  gem "pry"
  gem "pry-byebug"
  gem "rails-erd"
  gem "rb-readline"
  gem "rspec"
  gem "rspec-rails"
  # For CircleCI test metadata analysis
  gem "rspec_junit_formatter"
  gem "rubocop", "= 0.79", require: false
  gem "rubocop-performance"
  gem "rubocop-rails"
  gem "scss_lint", require: false
  gem "simplecov", require: false
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
  gem "derailed_benchmarks"
  gem "dotenv-rails"
  gem "fasterer", require: false
  gem "foreman"
  gem "meta_request"
  gem "ruby-prof", "~> 1.4"
end

group :test do
  gem "knapsack_pro"
  # For retrying failed feature tests. Read more: https://github.com/NoRedInk/rspec-retry
  gem "rspec-retry"
  gem "webmock"
end
# rubocop:enable Metrics/LineLength

gem "json_schemer", "~> 0.2.16"
