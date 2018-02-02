require "rails_helper"

RSpec.feature "Help" do
  let!(:current_user) { User.authenticate! }
  scenario "user goes to the help page" do
    User.authenticate!
    visit "/help"
    expect(page).to have_content("Caseflow Help")
  end

  scenario "user goes to the Certification Help page" do
    visit "/certification/help"
    expect(page).to have_content("Welcome to the Certification Help Page!")
  end

  scenario "user goes to the Dispatch Help page" do
    visit "/dispatch/help"
    expect(page).to have_content("Welcome to the Dispatch Help Page!")
  end

  scenario "user goes to the Intake Help page" do
    visit "/intake/help"
    expect(page).to have_content("Welcome to the Intake Help Page!")
  end

  scenario "user goes to the Reader Help page" do
    visit "/reader/help"
    expect(page).to have_content("Welcome to the Reader Help Page!")
  end

  scenario "user goes to the Hearings Help page" do
    visit "/hearings/help"
    expect(page).to have_content("Welcome to the Hearings Help Page!")
  end

  scenario "logo properly goes to homepage" do
    visit "/help"
    find(".cf-application-title").click
    expect(page).to have_current_path("/")
  end
end
