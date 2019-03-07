# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Login" do
  let(:appeal) { create(:legacy_appeal, vacols_case: create(:case)) }

  before do
    @old_session = Fakes::AuthenticationService.user_session
    Fakes::AuthenticationService.user_session = {
      "id" => "ANNE MERICA", "roles" => ["Certify Appeal"], "station_id" => "405", "email" => "test@example.com"
    }
  end

  after do
    Fakes::AuthenticationService.user_session = @old_session
  end

  after(:all) do
    Rails.application.config.sso_service_disabled = false
  end

  scenario "User whose station ID has one RO doesn't require login" do
    user = User.create(css_id: "ANNE MERICA", station_id: "314")
    Fakes::AuthenticationService.user_session = {
      "id" => "ANNE MERICA", "roles" => ["Certify Appeal"], "station_id" => "314", "email" => "world@example.com"
    }
    visit "certifications/new/#{appeal.vacols_id}"

    expect(page).to have_current_path("/certifications/#{appeal.vacols_id}/check_documents")
    expect(find("#menu-trigger")).to have_content("ANNE MERICA (RO14)")
    expect(user.reload.email).to eq "world@example.com"
    expect(user.selected_regional_office).to be_nil
  end

  def select_ro_from_dropdown
    find(".Select-control").click
    find("#react-select-2--option-0").click
  end

  # :nocov:
  # https://stackoverflow.com/questions/36472930/session-sometimes-not-persisting-in-capybara-selenium-test
  scenario "with valid credentials",
           skip: "This test sometimes fails because sessions do not persist across requests" do
    visit "certifications/new/#{appeal.vacols_id}"
    expect(page).to have_content("Please select the regional office you are logging in from.")
    select_ro_from_dropdown
    click_on "Log in"
    expect(page).to have_current_path(new_certification_path(vacols_id: appeal.vacols_id))
    expect(find("#menu-trigger")).to have_content("ANNE MERICA (RO05)")
  end

  scenario "logging out redirects to home page",
           skip: "This test sometimes fails because sessions do not persist across requests" do
    visit "certifications/new/#{appeal.vacols_id}"

    # vacols login
    expect(page).to have_content("Please select the regional office you are logging in from.")
    select_ro_from_dropdown
    click_on "Log in"

    click_on "ANNE MERICA (RO05)"
    click_on "Sign out"
    visit "certifications/new/#{appeal.vacols_id}"
    expect(page).to have_current_path("/login")
  end
  # :nocov:

  scenario "email and selected regional office should be set on login" do
    user = User.create(css_id: "ANNE MERICA", station_id: "405")
    visit "certifications/new/#{appeal.vacols_id}"
    select_ro_from_dropdown
    click_on "Log in"
    # Automatically wait for elements to disappear (but actually wait for asynchronous code to return)
    expect(page).not_to have_content("Logging in")
    expect(user.reload.email).to eq "test@example.com"
    expect(user.selected_regional_office).to eq "RO05"
  end

  # :nocov:
  scenario "Single Sign On is down",
           skip: "This test sometimes fails because it cannot find the expected text" do
    Rails.application.config.sso_service_disabled = true
    visit "certifications/new/#{appeal.vacols_id}"

    expect(page).to have_content("Login Service Unavailable")
  end
  # :nocov:
end
