require "rails_helper"

RSpec.feature "Login" do
  before do
    Fakes::AppealRepository.records = {
        "1234C" => Fakes::AppealRepository.appeal_ready_to_certify
    }

    Fakes::AuthenticationService.vacols_regional_offices = { "TESTRO" => "pa55word!" }
  end

  scenario "login with valid credentials" do
    visit "certifications/new/1234C"

    # SSOI login
    expect(page).to have_content("User Info")
    fill_in "Name:", with: "Joe"
    fill_in "Email:", with: "xyz@va.gov"
    click_on "Sign In"

    # vacols login
    expect(page).to have_content("VACOLS credentials")
    fill_in "VACOLS Login ID", with: "TESTRO"
    fill_in "VACOLS Password", with: "pa55word!"
    click_on "Login"

    expect(page).to have_current_path(new_certification_path(vacols_id: "1234C"))
    expect(find("#menu-trigger")).to have_content("xyz@va.gov (TESTRO)")
  end

  scenario "logging out redirects to login page" do
    visit "certifications/new/1234C"

    # SSOI login
    expect(page).to have_content("User Info")
    fill_in "Name:", with: "Joe"
    fill_in "Email:", with: "xyz@va.gov"
    click_on "Sign In"

    # vacols login
    expect(page).to have_content("VACOLS credentials")
    fill_in "VACOLS Login ID", with: "TESTRO"
    fill_in "VACOLS Password", with: "pa55word!"
    click_on "Login"

    click_on "xyz@va.gov (TESTRO)"
    click_on "Sign out"
    visit "certifications/new/1234C"
    expect(page).to have_current_path(Rails.application.config.ssoi_login_path)
  end
end