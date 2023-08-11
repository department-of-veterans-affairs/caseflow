# frozen_string_literal: true

require "capybara/rspec"
require "capybara-screenshot/rspec"
require "selenium-webdriver"
require "webdrivers"

Webdrivers.logger.level = :debug if ENV["DEBUG"]

Sniffybara::Driver.run_configuration_file = File.expand_path("VA-axe-run-configuration.json", __dir__)

download_directory = Rails.root.join("tmp/downloads_#{ENV['TEST_SUBCATEGORY'] || 'all'}")
cache_directory = Rails.root.join("tmp/browser_cache_#{ENV['TEST_SUBCATEGORY'] || 'all'}")

Dir.mkdir download_directory unless File.directory?(download_directory)
if File.directory?(cache_directory)
  FileUtils.rm_r cache_directory
else
  Dir.mkdir cache_directory
end

# Source: https://jtway.co/optimize-your-chrome-options-for-testing-to-get-x1-25-impact-4f19f071bf45
BASE_CHROME_ARGS = {
  "allow-running-insecure-content" => nil,
  "autoplay-policy" => "user-gesture-required",
  "disable-add-to-shelf" => nil,
  "disable-background-networking" => nil,
  "disable-background-timer-throttling" => nil,
  "disable-backgrounding-occluded-windows" => nil,
  "disable-breakpad" => nil,
  "disable-checker-imaging" => nil,
  "disable-client-side-phishing-detection" => nil,
  "disable-component-extensions-with-background-pages" => nil,
  "disable-datasaver-prompt" => nil,
  "disable-default-apps" => nil,
  "disable-desktop-notifications" => nil,
  "disable-dev-shm-usage" => nil,
  "disable-domain-reliability" => nil,
  "disable-extensions" => nil,
  "disable-features" => "TranslateUI,BlinkGenPropertyTrees",
  "disable-hang-monitor" => nil,
  "disable-infobars" => nil,
  "disable-ipc-flooding-protection" => nil,
  "disable-notifications" => nil,
  "disable-popup-blocking" => nil,
  "disable-prompt-on-repost" => nil,
  "disable-renderer-backgrounding" => nil,
  "disable-setuid-sandbox" => nil,
  "disable-site-isolation-trials" => nil,
  "disable-sync" => nil,
  "disable-web-security" => nil,
  "enable-automation" => nil,
  "force-color-profile" => "srgb",
  "force-device-scale-factor" => "1",
  "ignore-certificate-errors" => nil,
  "js-flags" => "--random-seed=1157259157",
  "disable-logging" => nil,
  "metrics-recording-only" => nil,
  "mute-audio" => nil,
  "no-default-browser-check" => nil,
  "no-first-run" => nil,
  "no-sandbox" => nil,
  "password-store" => "basic",
  "test-type" => nil,
  "use-mock-keychain" => nil
}.map { |k, v| ["--#{k}", v].compact.join("=") }.freeze

chrome_options = ::Selenium::WebDriver::Chrome::Options.new

chrome_options.args.merge(BASE_CHROME_ARGS)

Capybara.register_driver(:parallel_sniffybara) do |app|
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

Capybara::Screenshot.register_filename_prefix_formatter(:rspec) do |example|
  "screenshot_#{example.description.tr(' ', '-').gsub(/^.*\/spec\//, '')}"
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

Capybara.default_driver = ENV["CI"] ? :sniffybara_headless : :parallel_sniffybara
# the default default_max_wait_time is 2 seconds
Capybara.default_max_wait_time = 5
# Capybara uses puma by default, but for some reason, some of our tests don't
# pass with puma. See: https://github.com/teamcapybara/capybara/issues/2170
Capybara.server = :webrick
