# rubocop:disable Metrics/LineLength
source ENV["GEM_SERVER_URL"] || "https://rubygems.org"

# State machine
gem "aasm", "4.11.0"
gem "active_model_serializers", "~> 0.10.0"
# Use sqlite3 as the database for Active Record
gem "activerecord-jdbcsqlite3-adapter", platforms: :jruby
gem "acts_as_tree"
# BGS
gem "bgs", git: "https://github.com/department-of-veterans-affairs/ruby-bgs.git", ref: "1af709bbcf61931420db621237f90cb8e21f3c1c"
# Bootsnap speeds up app boot (and started to be a default gem in 5.2).
gem "bootsnap", require: false
gem "business_time", "~> 0.9.3"
gem "caseflow", git: "https://github.com/department-of-veterans-affairs/caseflow-commons", ref: "8dde00d67b7c629e4b871f8dcb3617bfe989b3db"
gem "connect_vbms", git: "https://github.com/department-of-veterans-affairs/connect_vbms.git", ref: "0d56a6c6a2ec314f97bce863f6aeffe837d75a13"
gem "dogstatsd-ruby"
gem "holidays", "~> 6.4"
# Use jquery as the JavaScript library
gem "jquery-rails"
# active_model_serializers has a default dependency on loofah 2.2.2 which has a security vuln (CVE-2018-16468)
gem "loofah", ">= 2.2.3"
gem "moment_timezone-rails"
gem "newrelic_rpm"
# nokogiri versions before 1.8.3 are affected by CVE-2018-8048. Explicitly define nokogiri version here to avoid that.
# https://github.com/sparklemotion/nokogiri/pull/1746
gem "nokogiri", "1.8.5"
gem "paper_trail", "8.1.2"
# Used to speed up reporting
gem "parallel"
# soft delete gem
gem "paranoia", "~> 2.2"
# PDF Tools
gem "pdf-forms"
gem "pdfjs_viewer-rails", git: "https://github.com/senny/pdfjs_viewer-rails.git", ref: "a4249eacbf70175db63b57e9f364d0a9a79e2b43"
gem "pg", platforms: :ruby
gem "prometheus-client", "~> 0.7.1"
# Application server: Puma
# Puma was chosen because it handles load of 40+ concurrent users better than Unicorn and Passenger
# Discussion: https://github.com/18F/college-choice/issues/597#issuecomment-139034834
gem "puma", "~> 3.12.0"
# rack versions before 2.0.6 are affected by CVE-2018-16470 and CVE-2018-16471.
# Explicitly define rack version here to avoid that.
gem "rack", "~> 2.0.6"
gem "rails", "5.1.6.1"
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
gem "sqlite3", platforms: [:ruby, :mswin, :mingw, :mswin, :x64_mingw]
gem "stringex", require: false
# catch problematic migrations at development/test time
gem "strong_migrations"
# execjs runtime
gem "therubyracer", platforms: :ruby
# Use Uglifier as compressor for JavaScript assets
gem "uglifier", ">= 1.3.0"

group :production, :staging, :ssh_forwarding, :development, :test do
  # Oracle DB
  gem "activerecord-oracle_enhanced-adapter"
  # set require: 'oci8' here because bootsnap creates a warning: https://github.com/rails/rails/issues/32811#issuecomment-386541855
  gem "ruby-oci8", require: "oci8"
end

group :test, :development, :demo do
  gem "activerecord-import"
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
  gem "scss_lint", require: false
  gem "simplecov", git: "https://github.com/colszowka/simplecov.git", require: false
  gem "sniffybara", git: "https://github.com/department-of-veterans-affairs/sniffybara.git", branch: "master"
  gem "timecop"
end

group :development do
  gem "dotenv-rails"
  gem "fasterer", require: false
  gem "foreman"
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  # gem 'spring', platforms: :ruby
  # Include the IANA Time Zone Database on Windows, where Windows doesn't ship with a timezone database.
  # POSIX systems should have this already, so we're not going to bring it in on other platforms
  gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
end
# rubocop:enable Metrics/LineLength
