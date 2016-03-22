require "selenium-webdriver"

Capybara.register_driver :sauce_driver do |app|
  caps = Selenium::WebDriver::Remote::Capabilities.internet_explorer
  caps["platform"] = "Windows 7"
  caps["version"] = "9.0"
  caps["tunnel-identifier"] = ENV["TRAVIS_JOB_NUMBER"] if ENV["TRAVIS_JOB_NUMBER"]

  Capybara::Selenium::Driver.new(
    app,
    browser: :remote,
    url: "http://#{ENV['SAUCE_USERNAME']}:#{ENV['SAUCE_ACCESS_KEY']}@ondemand.saucelabs.com:80/wd/hub",
    desired_capabilities: caps
  )
end
