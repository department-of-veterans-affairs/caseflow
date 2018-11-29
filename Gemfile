# rubocop:disable Metrics/LineLength
source ENV["GEM_SERVER_URL"] || "https://rubygems.org"

gem "caseflow", git: "https://github.com/department-of-veterans-affairs/caseflow-commons", ref: "8dde00d67b7c629e4b871f8dcb3617bfe989b3db"

gem "moment_timezone-rails"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "5.1.6.1"
# Use sqlite3 as the database for Active Record
gem "activerecord-jdbcsqlite3-adapter", platforms: :jruby
gem "sqlite3", platforms: [:ruby, :mswin, :mingw, :mswin, :x64_mingw]
# Use SCSS for stylesheets
gem "sass-rails", "~> 5.0"
# Use Uglifier as compressor for JavaScript assets
gem "uglifier", ">= 1.3.0"

# Use jquery as the JavaScript library
gem "jquery-rails"

# React
gem "react_on_rails", "8.0.6"

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder", "~> 2.0"
# bundle exec rake doc:rails generates the API under doc/api.
gem "sdoc", "~> 0.4.0", group: :doc

gem "active_model_serializers", "~> 0.10.0"
# active_model_serializers has a default dependency on loofah 2.2.2 which has a security vuln (CVE-2018-16468)
gem "loofah", ">= 2.2.3"

# soft delete gem
gem "paranoia", "~> 2.2"

gem "dogstatsd-ruby"

gem "acts_as_tree"

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Application server: Puma
# Puma was chosen because it handles load of 40+ concurrent users better than Unicorn and Passenger
# Discussion: https://github.com/18F/college-choice/issues/597#issuecomment-139034834
gem "puma", "~> 3.12.0"

# use to_b method to convert string to boolean
gem "wannabe_bool"

# BGS
gem "bgs", git: "https://github.com/department-of-veterans-affairs/ruby-bgs.git", ref: "2d0e08ea4157b725242777a6f876fc199f503b61"

# PDF Tools
gem "pdf-forms"
#
gem "pdfjs_viewer-rails", git: "https://github.com/senny/pdfjs_viewer-rails.git", ref: "a4249eacbf70175db63b57e9f364d0a9a79e2b43"

# Error reporting to Sentry
gem "sentry-raven"

gem "newrelic_rpm"

# Used to colorize output for rake tasks
gem "rainbow"

# Used to speed up reporting
gem "parallel"

# execjs runtime
gem "therubyracer", platforms: :ruby

gem "pg", platforms: :ruby

gem "connect_vbms", git: "https://github.com/department-of-veterans-affairs/connect_vbms.git", ref: "c9568319e5982f239b918bb4c3b07527d2c35cec"

gem "redis-rails", "~> 5.0.2"

gem "prometheus-client", "~> 0.7.1"

gem "request_store"

# State machine
gem "aasm", "4.11.0"

gem "redis-namespace"

# catch problematic migrations at development/test time
gem "zero_downtime_migrations"

# nokogiri versions before 1.8.3 are affected by CVE-2018-8048. Explicitly define nokogiri version here to avoid that.
# https://github.com/sparklemotion/nokogiri/pull/1746
gem "nokogiri", "1.8.5"

# rack versions before 2.0.6 are affected by CVE-2018-16470 and CVE-2018-16471.
# Explicitly define rack version here to avoid that.
gem "rack", "~> 2.0.6"

group :production, :staging, :ssh_forwarding, :development, :test do
  # Oracle DB
  gem "activerecord-oracle_enhanced-adapter"
  # set require: 'oci8' here because bootsnap creates a warning: https://github.com/rails/rails/issues/32811#issuecomment-386541855
  gem "ruby-oci8", require: "oci8"
end

# Development was ommited due to double logging issue (https://github.com/heroku/rails_stdout_logging/issues/1)
group :production, :staging do
  gem "rails_stdout_logging"
end

group :test, :development, :demo do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: :ruby
  gem "pry"
  gem "pry-byebug"
  gem "rb-readline"

  # Linters
  gem "jshint", platforms: :ruby
  gem "rubocop", "~> 0.52.1", require: false
  gem "scss_lint", require: false

  # Security scanners
  gem "brakeman"
  gem "bundler-audit"

  # Testing tools
  gem "capybara"
  gem "capybara-screenshot"
  gem "faker"
  gem "guard-rspec"
  gem "rspec"
  gem "rspec-rails"
  gem "simplecov", git: "https://github.com/colszowka/simplecov.git", require: false
  gem "sniffybara", git: "https://github.com/department-of-veterans-affairs/sniffybara.git", branch: "master"
  gem "timecop"

  gem "database_cleaner"

  # to save and open specific page in capybara tests
  gem "launchy"

  gem "activerecord-import"

  gem "danger", "5.5.5"

  # For CircleCI test metadata analysis
  gem "rspec_junit_formatter"

  # Added at 2018-05-16 22:09:10 -0400 by mdbenjam:
  gem "factory_bot_rails", "~> 4.8"
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem "dotenv-rails"
  gem "foreman"

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  # gem 'spring', platforms: :ruby

  # Include the IANA Time Zone Database on Windows, where Windows doesn't ship with a timezone database.
  # POSIX systems should have this already, so we're not going to bring it in on other platforms
  gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
end

gem "shoryuken", "3.1.11"

gem "paper_trail", "8.1.2"

gem "holidays", "~> 6.4"

gem "roo", "~> 2.7"
gem "rubyzip", "~> 1.2.2"

gem "business_time", "~> 0.9.3"

# Bootsnap speeds up app boot (and started to be a default gem in 5.2).
gem "bootsnap", require: false

# rubocop:enable Metrics/LineLength
