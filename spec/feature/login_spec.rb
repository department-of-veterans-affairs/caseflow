require "rails_helper"

RSpec.feature "Login" do
  before do
    Fakes::AppealRepository.records = {
      "1234C" => Fakes::AppealRepository.appeal_ready_to_certify
    }
    Fakes::AuthenticationService.ssoi_username = "TESTUSER"
    Fakes::AuthenticationService.vacols_regional_offices = { "DSUSER" => "pa55word!" }
  end

  scenario "login with valid credentials" do
    visit "certifications/new/1234C"
    fill_in "VACOLS Login ID", with: "DSUSER"
    fill_in "VACOLS Password", with: "pa55word!"
    click_on "Login"

    expect(page).to have_current_path(new_certification_path(vacols_id: "1234C"))
    expect(find("#menu-trigger")).to have_content("TESTUSER (DSUSER)")
  end

  scenario "login with invalid credentials" do
    visit "certifications/new/1234C"
    fill_in "VACOLS Login ID", with: "DSUSER"
    fill_in "VACOLS Password", with: "bad password"
    click_on "Login"

    expect(page).to have_current_path(login_path)
    expect(find(".usa-alert-body")).to have_content("Login ID and password did not work. Please try again.")

    visit "certifications/new/1234C"
    expect(page).to have_current_path(login_path)
  end

  scenario "logging out redirects to login page" do
    visit "certifications/new/1234C"
    fill_in "VACOLS Login ID", with: "DSUSER"
    fill_in "VACOLS Password", with: "pa55word!"
    click_on "Login"

    click_on "TESTUSER (DSUSER)"
    click_on "Sign out"
    visit "certifications/new/1234C"
    expect(page).to have_current_path(login_path)
  end
end
