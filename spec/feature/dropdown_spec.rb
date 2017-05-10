require "rails_helper"

RSpec.feature "Dropdown" do
  let!(:current_user) { User.authenticate! }
  let(:appeal) { Generators::Appeal.build(vacols_record: :ready_to_certify) }

  scenario "What's new indicator is reset after visiting /whats-new" do
    User.authenticate!

    visit "certifications/new/#{appeal.vacols_id}"
    expect(page).to have_css("#whats-new-item.cf-nav-whatsnew", visible: false)
    visit "/whats-new"
    expect(page).to_not have_css("#whats-new-item.cf-nav-whatsnew", visible: false)
  end

  scenario "Dropdown works on both erb and react pages" do
    User.authenticate!

    visit "certifications/new/#{appeal.vacols_id}"
    click_on "DSUSER (DSUSER)"
    expect(page).to have_content("Sign out")

    visit "dispatch/establish-claim"
    click_on "DSUSER (DSUSER)"
    expect(page).to have_content("Sign out")
  end
end
