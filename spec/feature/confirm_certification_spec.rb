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

  scenario "Screen reader user visits pdf link" do
    Certification.create!(vacols_id: "5555C")
    visit "certifications/5555C"
    # We want this content to only appear for screen reader users, so
    # it will not be visible, but it **should** be in the DOM.

    expect(page).to have_content("The PDF viewer in your browser may not be accessible.")
    expect(page).to have_css(".usa-sr-only", visible: false)

    # Sending click or keypress events to elements that are not in the DOM doesn't seem to work,
    # so let's find the hidden link's href and visit it manually to check that the pdf can be
    # found there.
    pdf_href = page.find('#sr-download-link')["href"]
    visit(pdf_href)
    content_header = page.response_headers["Content-Disposition"]

    expect(content_header.include?("form8-TEST.pdf")).to be true
  end

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
