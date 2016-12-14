source ENV['GEM_SERVER_URL'] || 'https://rubygems.org'

gem "caseflow", git: "https://github.com/department-of-veterans-affairs/caseflow-commons", ref: "b743c64"
gem "moment_timezone-rails"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.7.1'
# Use sqlite3 as the database for Active Record
gem 'sqlite3', platforms: [:ruby,:mswin,:mingw, :mswin, :x64_mingw]
gem 'activerecord-jdbcsqlite3-adapter', platforms: :jruby
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# Use jquery as the JavaScript library
gem 'jquery-rails'

# Logging
gem 'rails_stdout_logging'

# React
gem "react_on_rails", "~> 6"

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Application server: Puma
# Puma was chosen because it handles load of 40+ concurrent users better than Unicorn and Passenger
# Discussion: https://github.com/18F/college-choice/issues/597#issuecomment-139034834
gem "puma", "~> 2.16.0"

# Style
gem 'us_web_design_standards', git: 'https://github.com/harrisj/us_web_design_standards_gem.git', branch: 'rails-assets-fixes'

# PDF Tools
gem 'pdf-forms'
gem 'pdfjs_viewer-rails'

# Error reporting to Sentry
gem "sentry-raven"

# Used to colorize output for rake tasks
gem "rainbow"

# Used to speed up reporting
gem "parallel"

# execjs runtime
gem 'therubyracer', platforms: :ruby

gem 'pg', platforms: :ruby

gem 'connect_vbms', git: "https://github.com/department-of-veterans-affairs/connect_vbms.git", ref: "d71251eb3d066748b395d58633af5bd5863ef928"

gem 'redis-rails'

gem 'sidekiq'
gem "sidekiq-cron", "~> 0.4.0"

group :production, :staging do
  # Oracle DB
  gem 'activerecord-oracle_enhanced-adapter'
  gem 'ruby-oci8'
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: :ruby
  gem 'pry'

  # Linters
  gem 'rubocop', '~> 0.36.0', require: false
  gem 'scss_lint', require: false
  gem 'jshint', platforms: :ruby

  # Security scanners
  gem 'brakeman'
  gem 'bundler-audit'

  # Testing tools
  gem 'rspec'
  gem 'rspec-rails'
  gem 'guard-rspec'
  gem 'capybara'
  gem 'sniffybara', git: 'https://github.com/department-of-veterans-affairs/sniffybara.git', branch: "axe"
  gem 'simplecov', require: false
  gem 'timecop'
  gem 'konacha'
  gem 'database_cleaner'
  gem 'parallel_tests'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0', platforms: :ruby

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  # gem 'spring', platforms: :ruby

  # Include the IANA Time Zone Database on Windows, where Windows doens't ship with a timezone database.
  # POSIX systems should have this already, so we're not going to bring it in on other platforms
  gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
end
