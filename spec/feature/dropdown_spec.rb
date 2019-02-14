require "rails_helper"

RSpec.feature "Dropdown" do
  let!(:current_user) { User.authenticate! }
  let(:appeal) { create(:legacy_appeal, vacols_case: create(:case)) }

  scenario "Dropdown works on both erb and react pages" do
    User.authenticate!

    visit "certifications/new/#{appeal.vacols_id}"
    find("a", text: "DSUSER (DSUSER)") .click
    expect(page).to have_content("Sign Out")

    visit "dispatch/establish-claim"
    find("a", text: "Menu") .click
    expect(page).to have_content("Help")
  end
end
