require "rails_helper"

RSpec.feature "Help" do
  scenario "user goes to the help page" do
    visit "/help"
    expect(page).to have_content("Caseflow Certification Help")
  end

  scenario "logo properly goes to homepage" do
    visit "/help"
    find("#cf-logo-link").click
    expect(page).to have_current_path("/")
  end
end
