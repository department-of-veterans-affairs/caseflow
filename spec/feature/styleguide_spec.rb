require "rails_helper"
Capybara.register_driver :slow_sniffybara do |app|
  chrome_options = ::Selenium::WebDriver::Chrome::Options.new

  chrome_options.add_preference(:download,
                                prompt_for_download: false,
                                default_directory: download_directory)

  chrome_options.add_preference(:browser,
                                disk_cache_dir: cache_directory)

  client = Selenium::WebDriver::Remote::Http::Default.new
  client.timeout = 120 # instead of the default 60

  options = {
    port: 51_674,
    browser: :chrome,
    options: chrome_options,
    client: client
  }

  Sniffybara::Driver.current_driver = Sniffybara::Driver.new(app, options)
end

RSpec.feature "Style Guide" do
  scenario "renders and is accessible" do
    Sniffybara::Driver.current_driver = :slow_sniffybara
    visit "/styleguide"
    expect(page).to have_content("Caseflow Commons")
  end
end
