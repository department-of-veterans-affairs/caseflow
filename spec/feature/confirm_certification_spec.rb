require "rails_helper"

RSpec.feature "Confirm Certification" do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))

    Certification.delete_all
    User.authenticate!
    Form8.pdf_service = FakePdfService

    Fakes::AppealRepository.records = {
      "5555C" => Fakes::AppealRepository.appeal_ready_to_certify
    }
  end

  after { Timecop.return }

  scenario "Successful confirmation" do
    visit "certifications/5555C"
    expect(page).to have_content("Review Form 8")
    click_on "Upload and certify"

    expect(Fakes::AppealRepository.certified_appeal).to_not be_nil
    expect(Fakes::AppealRepository.certified_appeal.vacols_id).to eq("5555C")
    expect(page).to have_content("Congratulations! The case has been certified.")
  end

  scenario "Successful confirmation with certification record" do
    certification = Certification.create!(vacols_id: "5555C")
    visit "certifications/5555C"
    click_on "Upload and certify"

    expect(certification.reload.completed_at).to eq(Time.zone.now)
  end
end
