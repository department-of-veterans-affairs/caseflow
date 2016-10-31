require "rails_helper"

RSpec.feature "Login" do
  before do
    Fakes::AppealRepository.records = {
      "1234C" => Fakes::AppealRepository.appeal_ready_to_certify
    }

    Fakes::AuthenticationService.vacols_regional_offices = { "DSUSER" => "pa55word!" }
    Fakes::AuthenticationService.user_session = {
      "id" => "ANNE MERICA", "roles" => ["Certify Appeal"], "station_id" => "405"
    }
  end

  after do
    Rails.application.config.sso_service_disabled = false
  end

  scenario "User who's station ID has one RO doesn't require login" do
    Fakes::AuthenticationService.user_session = {
      "id" => "ANNE MERICA", "roles" => ["Certify Appeal"], "station_id" => "314"
    }
    visit "certifications/new/1234C"

    expect(page).to have_current_path(new_certification_path(vacols_id: "1234C"))
    expect(find("#menu-trigger")).to have_content("ANNE MERICA (RO14)")
  end

  scenario "with valid credentials" do
    visit "certifications/new/1234C"

    # vacols login
    expect(page).to have_content("VACOLS credentials")
    fill_in "VACOLS Login ID", with: "DSUSER"
    fill_in "VACOLS Password", with: "pa55word!"
    click_on "Login"

    expect(page).to have_current_path(new_certification_path(vacols_id: "1234C"))
    expect(find("#menu-trigger")).to have_content("ANNE MERICA (DSUSER)")
  end

  scenario "login with invalid credentials" do
    visit "certifications/new/1234C"

    # vacols login
    fill_in "VACOLS Login ID", with: "DSUSER"
    fill_in "VACOLS Password", with: "bad password"
    click_on "Login"

    expect(page).to have_current_path(login_path)
    expect(find(".usa-alert-body")).to have_content("The username and password you entered don't match")

    visit "certifications/new/1234C"
    expect(page).to have_current_path(login_path)
  end

  scenario "logging out redirects to home page" do
    visit "certifications/new/1234C"

    # vacols login
    expect(page).to have_content("VACOLS credentials")
    fill_in "VACOLS Login ID", with: "DSUSER"
    fill_in "VACOLS Password", with: "pa55word!"
    click_on "Login"

    click_on "ANNE MERICA (DSUSER)"
    click_on "Sign out"
    visit "certifications/new/1234C"
    expect(page).to have_current_path("/login")
  end

  scenario "Single Sign On is down" do
    Rails.application.config.sso_service_disabled = true
    visit "certifications/new/1234C"

    expect(page).to have_content("Login Service Unavailable")
  end
end
