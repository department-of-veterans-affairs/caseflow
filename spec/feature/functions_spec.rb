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

    find("#establish_claim", "Enable").click
    find("#certify_appeal", "Enable").click

    expect(page).to have_content "Establish Claim (Enabled)"
    expect(page).to have_content "Manage Claim Establishment (Disabled)"
    expect(page).to have_content "Certify Appeal (Enabled)"

    find("#establish_claim", "Disable").click
    expect(page).to have_content "Establish Claim (Disabled)"
    find("#certify_appeal", "Disable").click

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
