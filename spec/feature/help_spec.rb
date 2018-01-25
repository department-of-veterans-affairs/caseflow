require "rails_helper"

RSpec.feature "Help" do
  let!(:current_user) { User.authenticate! }
  scenario "user goes to the help page" do
    User.authenticate!
    visit "/help"
    expect(page).to have_content("Caseflow Help")
  end

  scenario "logo properly goes to homepage" do
    visit "/help"
    find(".cf-application-title").click
    expect(page).to have_current_path("/")
  end
end