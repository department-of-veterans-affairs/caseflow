require "rails_helper"

RSpec.feature "Style Guide" do
  before do
    Capybara.current_driver = :selenium_chrome_headless
  end
  after do
    Capybara.use_default_driver
  end
  scenario "renders and is accessible" do
    visit "/styleguide"
    expect(page).to have_content("Caseflow Commons")
  end
end
