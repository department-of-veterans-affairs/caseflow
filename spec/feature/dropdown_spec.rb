require "rails_helper"

RSpec.feature "Dropdown" do
  scenario "What's new indicator is reset after visiting /whats-new" do
    Fakes::AppealRepository.records = { "1234C" => Fakes::AppealRepository.appeal_mismatched_docs }
    User.authenticate!

    visit "certifications/new/1234C"
    expect(page).to have_css("#whats-new-item.cf-nav-whatsnew", visible: false)
    visit "/whats-new"
    expect(page).to_not have_css("#whats-new-item.cf-nav-whatsnew", visible: false)
  end

  scenario "Dropdown works on both erb and react pages" do
    User.authenticate!

    visit "certifications/new/1234C"
    click_on "DSUSER (DSUSER)"
    expect(page).to have_content("Sign out")

    visit "dispatch/establish-claim"
    click_on "DSUSER (DSUSER)"
    expect(page).to have_content("Sign out")
  end
end
