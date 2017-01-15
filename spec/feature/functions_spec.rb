require "rails_helper"

RSpec.feature "Change Functions" do
  scenario "As a system admin" do
    User.authenticate!(roles: ["System Admin"])
    visit "/"
    click_on "DSUSER (DSUSER)"
    click_on "Change Functions"
    expect(page).to have_content "Establish Claim (Disabled)"
    expect(page).to have_content "Manage Claim Establishment (Disabled)"
    expect(page).to have_content "Certify Appeal (Disabled)"

    click_link("establish_claim")
    click_link("certify_appeal")

    expect(page).to have_content "Establish Claim (Enabled)"
    expect(page).to have_content "Manage Claim Establishment (Disabled)"
    expect(page).to have_content "Certify Appeal (Enabled)"

    click_link("establish_claim")
    expect(page).to have_content "Establish Claim (Disabled)"
    click_link("certify_appeal")

    visit "/certifications/new/123C"
    expect(page).to have_content("You aren't authorized to use this part of Caseflow yet.")
  end

  scenario "As a non system admin" do
    User.authenticate!(roles: ["Certify Appeal"])
    visit "/"
    click_on "DSUSER (DSUSER)"
    expect(page).to_not have_content "Change Functions"
    visit "/functions"
    expect(page).to have_content("You aren't authorized to use this part of Caseflow yet.")
  end
end
