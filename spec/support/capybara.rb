# frozen_string_literal: true

require "capybara/rspec"
require "capybara-screenshot/rspec"
require "selenium-webdriver"
require "webdrivers"

Webdrivers.logger.level = :DEBUG if ENV["DEBUG"]

# Latest Edge Driver for Linux
#
# https://developer.microsoft.com/en-us/microsoft-edge/tools/webdriver/
#
# Note: This was determined by running
#
#   /usr/bin/microsoft-edge --version
#
# in the CircleCI container. You run CircleCI tests and have it start an SSH
# server, which enables you to check the actual version of Microsoft Edge
# on the container.
Webdrivers::Edgedriver.required_version = "90.0.782.0"

Sniffybara::Driver.run_configuration_file = File.expand_path("VA-axe-run-configuration.json", __dir__)

download_directory = Rails.root.join("tmp/downloads_#{ENV['TEST_SUBCATEGORY'] || 'all'}")
cache_directory = Rails.root.join("tmp/browser_cache_#{ENV['TEST_SUBCATEGORY'] || 'all'}")

Dir.mkdir download_directory unless File.directory?(download_directory)
if File.directory?(cache_directory)
  FileUtils.rm_r cache_directory
else
  Dir.mkdir cache_directory
end

# Using Edge as your webdriver to run feature tests (DEFAULT):
#
#   export CASEFLOW_WEBDRIVER=edge
#
# Using Chrome as your webdriver to run feature tests:
#
#   export CASEFLOW_WEBDRIVER=chrome
#
webdriver_name = ENV.fetch("CASEFLOW_WEBDRIVER", "edge")

webdriver_options_class = case webdriver_name
                          when "edge"
                            ::Selenium::WebDriver::Edge::Options
                          when "chrome"
                            ::Selenium::WebDriver::Chrome::Options
                          else
                            fail "Unknown Webdriver"
                          end
webdriver_service_builder = case webdriver_name
                            when "edge"
                              proc { |args| ::Selenium::WebDriver::Service.edge(args) }
                            when "chrome"
                              proc { |args| ::Selenium::WebDriver::Service.chrome(args) }
                            end
webdriver_selenium_driver = case webdriver_name
                            when "edge"
                              Capybara::Selenium::Driver::EdgeDriver
                            when "chrome"
                              Capybara::Selenium::Driver::ChromeDriver
                            end

Capybara.register_driver(:parallel_sniffybara) do |app|
  browser_options = webdriver_options_class.new

  browser_options.add_preference(:download,
                                 prompt_for_download: false,
                                 default_directory: download_directory)

  browser_options.add_preference(:browser,
                                 disk_cache_dir: cache_directory)

  options = {
    service: webdriver_service_builder.call(args: { port: 51_674 }),
    browser: webdriver_name.to_sym,
    options: browser_options
  }
  Sniffybara::Driver.register_specialization(
    webdriver_name.to_sym, webdriver_selenium_driver
  )
  Sniffybara::Driver.current_driver = Sniffybara::Driver.new(app, options)
end

Capybara.register_driver(:sniffybara_headless) do |app|
  browser_options = webdriver_options_class.new(
    args: ["headless", "disable-gpu", "window-size=1200,1200"]
  )

  browser_options.add_preference(:download,
                                 prompt_for_download: false,
                                 default_directory: download_directory)

  browser_options.add_preference(:browser,
                                 disk_cache_dir: cache_directory)

  options = {
    service: webdriver_service_builder.call(args: { port: 51_674 }),
    browser: webdriver_name.to_sym,
    options: browser_options
  }

  Sniffybara::Driver.register_specialization(
    webdriver_name.to_sym, webdriver_selenium_driver
  )
  Sniffybara::Driver.current_driver = Sniffybara::Driver.new(app, options)
end

Capybara::Screenshot.register_driver(:parallel_sniffybara) do |driver, path|
  driver.browser.save_screenshot(path)
end

Capybara::Screenshot.register_driver(:sniffybara_headless) do |driver, path|
  driver.browser.save_screenshot(path)
end

Capybara.default_driver = ENV["CI"] ? :sniffybara_headless : :parallel_sniffybara
# the default default_max_wait_time is 2 seconds
Capybara.default_max_wait_time = 5
# Capybara uses puma by default, but for some reason, some of our tests don't
# pass with puma. See: https://github.com/teamcapybara/capybara/issues/2170
Capybara.server = :webrick
