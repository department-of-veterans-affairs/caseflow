require "rails_helper"

RSpec.feature "Cancel certification", focus: true do
  scenario "Click cancel link and confirm modal" do
    User.authenticate!

    Fakes::AppealRepository.records = {
      "5555C" => Fakes::AppealRepository.appeal_ready_to_certify
    }

    visit "certifications/new/5555C"
    click_on "Cancel certification"
    expect(page).to have_content("Are you sure you can't certify this case?")
    click_on "Yes, I'm sure"
    expect(page).to have_content("Case not certified")
  end
end
