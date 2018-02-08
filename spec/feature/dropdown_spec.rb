require "rails_helper"

RSpec.feature "Dropdown" do
  let!(:current_user) { User.authenticate! }
  let(:appeal) { Generators::Appeal.build(vacols_record: :ready_to_certify) }

  scenario "Dropdown works on both erb and react pages" do
    User.authenticate!

    visit "certifications/new/#{appeal.vacols_id}"
    click_on "DSUSER (DSUSER)"
    expect(page).to have_content("Sign out")

    visit "dispatch/establish-claim"
    click_on "Menu"
    expect(page).to have_content("Help")
  end
end
