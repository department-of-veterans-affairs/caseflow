# frozen_string_literal: true

# rubocop:disable Metrics/LineLength
source ENV["GEM_SERVER_URL"] || "https://rubygems.org"

# State machine
gem "aasm", "4.11.0"
gem "activerecord-import"
gem "acts_as_tree"
# BGS
gem "bgs", git: "https://github.com/department-of-veterans-affairs/ruby-bgs.git", ref: "e8285d246b9123301f3516228c6c273d0fd8f900"
# Bootsnap speeds up app boot (and started to be a default gem in 5.2).
gem "bootsnap", require: false
gem "business_time", "~> 0.9.3"
gem "caseflow", git: "https://github.com/department-of-veterans-affairs/caseflow-commons", ref: "ffb77dd0395cbd5b7c1a5729f7f8275b5ec681fa"
gem "connect_vbms", git: "https://github.com/department-of-veterans-affairs/connect_vbms.git", ref: "6cc4243fac69e0aa6bc6a55293c165d848d5c06f"
gem "console_tree_renderer", git: "https://github.com/department-of-veterans-affairs/console-tree-renderer.git", tag: "v0.1.1"
gem "dogstatsd-ruby"
gem "fast_jsonapi"
gem "govdelivery-tms", require: "govdelivery/tms/mail/delivery_method"
gem "holidays", "~> 6.4"
gem "icalendar"
gem "kaminari"
gem "moment_timezone-rails"
# Rails 6 has native support for multiple dbs, so prefer that over multiverse after upgrade.
# https://github.com/ankane/multiverse#upgrading-to-rails-6
gem "multiverse"
gem "newrelic_rpm"
# nokogiri versions before 1.10.4 are vulnerable to CVE-2019-5477.
# https://github.com/sparklemotion/nokogiri/issues/1915
# nokogiri 1.10.4 is vulnerable to CVE-2019-13117, CVE-2019-13118, CVE-2019-18197.
# https://github.com/sparklemotion/nokogiri/issues/1943
gem "nokogiri", "~> 1.10.8"
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
gem "puma", "~> 3.12.0"
# rack versions before 2.0.6 are affected by CVE-2018-16470 and CVE-2018-16471.
# Explicitly define rack version here to avoid that.
gem "rack", "~> 2.0.6"
gem "rails", "5.2.4.1"
# Used to colorize output for rake tasks
gem "rainbow"
# React
gem "react_on_rails", "8.0.6"
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
# Use Uglifier as compressor for JavaScript assets
gem "uglifier", ">= 1.3.0"
gem "validates_email_format_of"

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
  gem "danger", "~> 5.10"
  gem "database_cleaner"
  gem "factory_bot_rails", "~> 4.8"
  gem "faker"
  gem "guard-rspec"
  # Linters
  gem "jshint", platforms: :ruby
  gem "pry"
  gem "pry-byebug"
  gem "rb-readline"
  gem "rspec"
  gem "rspec-rails"
  # For CircleCI test metadata analysis
  gem "rspec_junit_formatter"
  gem "rubocop", "~> 0.52", require: false
  gem "rubocop-performance"
  gem "scss_lint", require: false
  gem "simplecov", git: "https://github.com/colszowka/simplecov.git", require: false
  gem "single_cov"
  gem "sniffybara", git: "https://github.com/department-of-veterans-affairs/sniffybara.git"
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
  gem "rails-erd"
end

group :test do
  gem "webmock"
end
# rubocop:enable Metrics/LineLength
