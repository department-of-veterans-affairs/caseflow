require "rails_helper"

RSpec.feature "Cancel certification" do
  context "Cancellation certification" do
    scenario "Click cancel link and confirm modal" do
      User.authenticate!

      Fakes::AppealRepository.records = {
        "5555C" => Fakes::AppealRepository.appeal_ready_to_certify
      }
      certification = Certification.create!(vacols_id: "5555C")

      visit "certifications/new/5555C"
      click_on "Cancel Certification"
      expect(page).to have_content("Please explain why this case cannot be certified with Caseflow.")

      # Test validation errors
      within(".modal-container") do
        click_on "Cancel certification"
      end
      expect(page).to have_content("Make sure you've selected an option below.")
      expect(page).to have_content("Make sure you’ve entered a valid email address below.")

      within_fieldset("Why can't be this case certified in Caseflow") do
        find("label", text: "Other").click
      end
      fill_in "What's your VA email address?", with: "fk@va.gov"
      expect(page).to_not have_css(".usa-input-error")
      fill_in "What's your VA email address?", with: "fk@va"
      within(".modal-container") do
        click_on "Cancel certification"
      end
      expect(page).to have_content("Make sure you’ve filled out the comment box below.")
      expect(page).to have_content("Make sure you’ve entered a valid email address below.")

      within_fieldset("Why can't be this case certified in Caseflow") do
        find("label", text: "Other").click
      end
      fill_in "Tell us more about your situation.", with: "Test"
      fill_in "What's your VA email address?", with: "fk@va.gov"
      expect(page).to_not have_css(".usa-input-error")
      within(".modal-container") do
        click_on "Cancel certification"
      end
      expect(page).to_not have_css(".usa-input-error")

      # Test resulting page
      expect(page).to have_content("The certification has been cancelled")

      # Test CertificationCancellation resulting record
      expect(CertificationCancellation.last.id).to eq(certification.id)
      expect(CertificationCancellation.last.cancellation_reason).to eq("Other")
      expect(CertificationCancellation.last.other_reason).to eq("Test")
      expect(CertificationCancellation.last.email).to eq("fk@va.gov")
    end

    scenario "Click cancel when certification has mistmatched documents" do
      User.authenticate!

      Fakes::AppealRepository.records = {
        "7777D" => Fakes::AppealRepository.appeal_mismatched_docs
      }

      visit "certifications/new/7777D"
      expect(page).to have_content("No Matching Document")
      click_on "Cancel Certification"
      expect(page).to have_content("Please explain why this case cannot be certified with Caseflow.")
      within_fieldset("Why can't be this case certified in Caseflow") do
        find("label", text: "Missing document could not be found").click
      end
      fill_in "What's your VA email address?", with: "fk@va.gov"
      within(".modal-container") do
        click_on "Cancel certification"
      end
      expect(page).to have_content("The certification has been cancelled")
    end
  end
end
