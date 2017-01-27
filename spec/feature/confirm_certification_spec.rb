require "rails_helper"

RSpec.feature "Confirm Certification" do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
    User.authenticate!
    Form8.pdf_service = FakePdfService

    Fakes::AppealRepository.records = {
      "5555C" => Fakes::AppealRepository.appeal_ready_to_certify,
      ENV["TEST_APPEAL_ID"] => Fakes::AppealRepository.appeal_ready_to_certify
    }

    certification = Certification.create!(vacols_id: "5555C")
    certification.form8.update_from_appeal(certification.appeal)
    certification.form8.save_pdf!
  end

  scenario "Screen reader user visits pdf link" do
    visit "certifications/5555C"
    # We want this content to only appear for screen reader users, so
    # it will not be visible, but it **should** be in the DOM.

    expect(page).to have_content("The PDF viewer in your browser may not be accessible.")
    expect(page).to have_css(".usa-sr-only", visible: false)

    # Sending click or keypress events to elements that are not in the DOM doesn't seem to work,
    # so let's find the hidden link's href and visit it manually to check that the pdf can be
    # found there.
    pdf_href = page.find("#sr-download-link")["href"]
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
    expect(Fakes::AppealRepository.uploaded_form8.vacols_id).to eq("5555C")
    expect(Fakes::AppealRepository.uploaded_form8_appeal.vacols_id).to eq("5555C")

    expect(page).to have_content("Congratulations!")

    certification = Certification.find_or_create_by_vacols_id("5555C")
    expect(certification.reload.completed_at).to eq(Time.zone.now)
  end

  context "Test appeal" do
    let(:test_appeal_id) { ENV["TEST_APPEAL_ID"] }

    before do
      test_certification = Certification.create!(vacols_id: test_appeal_id)
      test_certification.form8.update_from_appeal(test_certification.appeal)
      test_certification.form8.save_pdf!

      ENV["DEPLOY_ENV"] = "uat"
    end

    scenario "is not able to be uncertified by a non-test user" do
      visit "certifications/#{test_appeal_id}"
      click_on("Upload and certify")

      certification = Certification.find_or_create_by_vacols_id(test_appeal_id)
      expect(certification.reload.completed_at).to eq(Time.zone.now)
      expect(page).not_to have_content("Uncertify Appeal")
    end

    scenario "is able to uncertified by test user" do
      User.clear_stub!
      User.tester!

      visit "certifications/#{test_appeal_id}"
      click_on("Upload and certify")

      certification = Certification.find_or_create_by_vacols_id(test_appeal_id)
      expect(certification.reload.completed_at).to eq(Time.zone.now)
      expect(page).to have_content("Uncertify Appeal")
      click_link("Uncertify Appeal")
      expect(Certification.where(id: certification.id).count).to eq(0)
    end
  end
end
