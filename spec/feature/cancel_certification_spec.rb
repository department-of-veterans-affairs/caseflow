require "rails_helper"

RSpec.feature "Cancel certification" do
  scenario "Click cancel link and confirm modal" do
    User.authenticate!

    Fakes::AppealRepository.records = {
      "5555C" => Fakes::AppealRepository.appeal_ready_to_certify
    }

    visit "certifications/new/5555C"
    click_on "Cancel"
    expect(page).to have_content("Are you sure you can't certify this case?")
    click_on "Yes, I'm sure"
    expect(page).to have_content("Case not certified")
  end

  scenario "Click cancel when certification has mistmatched documents" do
    User.authenticate!

    Fakes::AppealRepository.records = {
      "7777D" => Fakes::AppealRepository.appeal_mismatched_docs
    }

    visit "certifications/new/7777D"
    expect(page).to have_content("No Matching Document")
    click_on "Cancel"
    expect(page).to have_content("Are you sure you can't certify this case?")
    click_on "Yes, I'm sure"
    expect(page).to have_content("Case not certified")
  end
end
