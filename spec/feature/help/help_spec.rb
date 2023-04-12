# frozen_string_literal: true

RSpec.feature "Help" do
  before do
    User.authenticate!
  end

  scenario "user goes to the help page" do
    visit "/help"
    expect(page).to have_content("Caseflow Help")
  end

  scenario "user goes to the Certification Help page" do
    visit "/certification/help"
    expect(page).to have_content("Welcome to the Certification Help page!")
  end

  scenario "user goes to the Dispatch Help page" do
    visit "/dispatch/help"
    expect(page).to have_content("Welcome to the Dispatch Help page!")
  end

  scenario "user goes to the Intake Help page" do
    visit "/intake/help"
    expect(page).to have_content("Welcome to the Intake Help page!")
  end

  scenario "user goes to the Reader Help page" do
    visit "/reader/help"
    expect(page).to have_content("Welcome to the Reader Help page!")
  end

  scenario "user goes to the Hearings Help page" do
    visit "/hearing_prep/help"
    expect(page).to have_content("Welcome to the Hearings Help page!")
  end

  scenario "user goes to the VHA Help Page" do
    visit "/vha/help"
    expect(page).to have_content("Welcome to the VHA Help page!")
  end

  scenario "logo properly goes to homepage" do
    visit "/help"
    find(".cf-application-title").click
    expect(page).to have_current_path("/")
  end
end
