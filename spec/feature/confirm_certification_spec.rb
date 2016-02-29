require "rails_helper"

RSpec.feature "Confirm Certification" do
  scenario "Go back and make edits" do
  end

  scenario "Successful confirmation" do
    User.authenticate!
    Form8.pdf_service = FakePdfService

    Fakes::AppealRepository.records = {
      "5555C" => Fakes::AppealRepository.appeal_ready_to_certify
    }

    visit "certifications/5555C"
    expect(page).to have_content("Review Form 8")
    click_on "Upload and certify"

    expect(Fakes::AppealRepository.certified_appeal).to_not be_nil
    expect(Fakes::AppealRepository.certified_appeal.vacols_id).to eq("5555C")
    expect(page).to have_content("Congratulations! The case has been certified.")
  end
end
