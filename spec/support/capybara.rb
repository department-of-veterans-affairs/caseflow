# frozen_string_literal: true

require "capybara/rspec"
require "capybara-screenshot/rspec"
require "selenium-webdriver"
require "webdrivers"

Webdrivers.logger.level = :DEBUG if ENV["DEBUG"]

Sniffybara::Driver.run_configuration_file = File.expand_path("VA-axe-run-configuration.json", __dir__)

download_directory = Rails.root.join("tmp/downloads_#{ENV['TEST_SUBCATEGORY'] || 'all'}")
cache_directory = Rails.root.join("tmp/browser_cache_#{ENV['TEST_SUBCATEGORY'] || 'all'}")

Dir.mkdir download_directory unless File.directory?(download_directory)
if File.directory?(cache_directory)
  FileUtils.rm_r cache_directory
else
  Dir.mkdir cache_directory
end

Capybara.register_driver(:parallel_sniffybara) do |app|
  chrome_options = ::Selenium::WebDriver::Chrome::Options.new

  chrome_options.add_preference(:download,
                                prompt_for_download: false,
                                default_directory: download_directory)

  chrome_options.add_preference(:browser,
                                disk_cache_dir: cache_directory)

  options = {
    service: ::Selenium::WebDriver::Service.chrome(args: { port: 51_674 }),
    browser: :chrome,
    options: chrome_options
  }
  Sniffybara::Driver.register_specialization(
    :chrome, Capybara::Selenium::Driver::ChromeDriver
  )
  Sniffybara::Driver.current_driver = Sniffybara::Driver.new(app, options)
end

Capybara.register_driver(:sniffybara_headless) do |app|
  chrome_options = ::Selenium::WebDriver::Chrome::Options.new

  chrome_options.add_preference(:download,
                                prompt_for_download: false,
                                default_directory: download_directory)

  chrome_options.add_preference(:browser,
                                disk_cache_dir: cache_directory)

  chrome_options.args << "--headless"
  chrome_options.args << "--disable-gpu"
  chrome_options.args << "--window-size=1200,1200"

  options = {
    service: ::Selenium::WebDriver::Service.chrome(args: { port: 51_674 }),
    browser: :chrome,
    options: chrome_options
  }

  Sniffybara::Driver.register_specialization(
    :chrome, Capybara::Selenium::Driver::ChromeDriver
  )
  Sniffybara::Driver.current_driver = Sniffybara::Driver.new(app, options)
end

Capybara::Screenshot.register_driver(:parallel_sniffybara) do |driver, path|
  driver.browser.save_screenshot(path)
end

Capybara::Screenshot.register_driver(:sniffybara_headless) do |driver, path|
  driver.browser.save_screenshot(path)
end

Capybara.register_driver :logging_selenium_chrome do |app|
  caps = Selenium::WebDriver::Remote::Capabilities.chrome(loggingPrefs: { browser: "ALL" })
  browser_options = ::Selenium::WebDriver::Chrome::Options.new
  # browser_options.args << '--some_option' # add whatever browser args and other options you need (--headless, etc)
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: browser_options, desired_capabilities: caps)
end

Capybara.javascript_driver = :logging_selenium_chrome

if ENV["STANDALONE_CHROME"]
  Webdrivers::ChromeDriver.required_version = ENV["CHROME_VERSION"] || '106.0.5249.61'

  Capybara.register_driver :remote_selenium_headless do |app|
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument("--headless")
    options.add_argument("--window-size=1400,1400")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")

    Capybara::Selenium::Driver.new(
      app,
      browser: :chrome,
      url: "http://#{ENV["SELENIUM_HOST"]}:4444/wd/hub",
      options: options,
    )
  end

  Capybara.default_driver = :remote_selenium_headless

  selenium_app_host = ENV.fetch("SELENIUM_APP_HOST") do
    Socket.ip_address_list
          .find(&:ipv4_private?)
          .ip_address
  end

  Capybara.configure do |config|
    config.server = :puma, { Silent: true }
    config.server_host = selenium_app_host
    config.server_port = 4000
  end
else
  Capybara.default_driver = ENV["CI"] ? :sniffybara_headless : :parallel_sniffybara
end

# the default default_max_wait_time is 2 seconds
Capybara.default_max_wait_time = 5
# Capybara uses puma by default, but for some reason, some of our tests don't
# pass with puma. See: https://github.com/teamcapybara/capybara/issues/2170
Capybara.server = :webrick



