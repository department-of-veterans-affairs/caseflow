require "rails_helper"

Appeal.repository = Fakes::AppealRepository

RSpec.feature "Start Certification" do
  scenario "Starting a certification with missing documents" do
    Fakes::AppealRepository.records = {
      "1234C" => Fakes::AppealRepository.appeal_not_ready
    }

    visit "certifications/new/1234C"
    expect(page).to have_content "Missing documents"
  end

  scenario "Starting a certifications with all documents matching" do
    Fakes::AppealRepository.records = {
      "1234C" => Fakes::AppealRepository.appeal_ready_to_certify
    }

    visit "certifications/new/1234C"
    expect(page).to have_content "Gotem"
  end
end
