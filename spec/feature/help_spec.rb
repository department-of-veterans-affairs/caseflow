require "rails_helper"

RSpec.feature "Help" do
  scenario "user goes to the help page" do
    visit "/help"
    expect(page).to have_content("Frequently Asked Questions")
  end
end