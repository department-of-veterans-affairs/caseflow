require "rails_helper"

RSpec.feature "Login" do
  scenario "login with valid credentials" do
    Fakes::AppealRepository.records = {
      "1234C" => Fakes::AppealRepository.appeal_ready_to_certify
    }
    Fakes::AuthenticationService.ssoi_username = "DSUSER"
    Fakes::AuthenticationService.vacols_regional_offices = { "TESTRO" => "pa55word!" }

    visit "certifications/new/1234C"
    fill_in "VACOLS Login ID", with: "TESTRO"
    fill_in "VACOLS Password", with: "pa55word!"
    click_on "Login"

    expect(page).to have_current_path(new_certification_path(vacols_id: "1234C"))
    expect(find("#menu-trigger")).to have_content("DSUSER (TESTRO)")
  end

  scenario "logging out redirects to login page" do
    visit "certifications/new/1234C"
    fill_in "VACOLS Login ID", with: "TESTRO"
    fill_in "VACOLS Password", with: "pa55word!"
    click_on "Login"

    click_on "DSUSER (TESTRO)"
    click_on "Sign out"
    visit "certifications/new/1234C"
    expect(page).to have_current_path(login_path)
  end
end
