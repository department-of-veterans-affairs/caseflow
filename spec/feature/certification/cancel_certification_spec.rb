# frozen_string_literal: true

RSpec.feature "Cancel certification", :all_dbs do
  let!(:current_user) { User.authenticate! }

  let(:appeal) do
    create(:legacy_appeal, vacols_case: vacols_case)
  end

  let(:vacols_case) do
    create(:case_with_ssoc)
  end

  let(:appeal_mismatched_docs) do
    create(:legacy_appeal, vacols_case: vacols_case_mismatched)
  end

  let(:vacols_case_mismatched) do
    create(:case_with_ssoc, bfd19: 2.months.ago)
  end

  let(:default_user) do
    create(:default_user, roles: ["Certify Appeal", "CertificationV2"])
  end

  context "As an authorized user" do
    let!(:current_user) { User.authenticate!(user: default_user) }

    before do
      FeatureToggle.enable!(:certification_v2)
    end

    after do
      FeatureToggle.disable!(:certification_v2)
    end

    scenario "Validate Input Fields" do
      visit "certifications/new/#{appeal.vacols_id}"
      click_on "Cancel Certification"
      expect(page).to have_content("Please explain why this case cannot be certified with Caseflow.")

      # Test validation errors
      click_button "Cancel certification"
      expect(page).to have_content("Make sure you’ve selected an option below.")
      expect(page).to have_content("Make sure you’ve entered a valid email address below.")

      within_fieldset("Why can't this case be certified in Caseflow?") do
        find("label", text: "Other").click
      end
      fill_in "What's your VA email address?", with: "fk@va.gov"
      expect(page).to_not have_css(".usa-input-error")
      fill_in "What's your VA email address?", with: "fk@va"
      click_button "Cancel certification"
      expect(page).to have_content("Make sure you’ve filled out the comment box below.")
      expect(page).to have_content("Make sure you’ve entered a valid email address below.")

      within_fieldset("Why can't this case be certified in Caseflow?") do
        find("label", text: "Other").click
      end
      fill_in "Tell us more about your situation.", with: " "
      click_button "Cancel certification"
      expect(page).to have_content("Make sure you’ve filled out the comment box below.")

      within_fieldset("Why can't this case be certified in Caseflow?") do
        find("label", text: "Other").click
      end
      fill_in "Tell us more about your situation.", with: "Test"
      fill_in "What's your VA email address?", with: "fk@va.gov"
      expect(page).to_not have_css(".usa-input-error")
      click_button "Cancel certification"
      expect(page).to_not have_css(".usa-input-error")

      # Test resulting page
      expect(page).to have_content("The certification has been cancelled")

      # Test CertificationCancellation resulting record
      expect(CertificationCancellation.last.certification_id).to eq(Certification.last.id)
      expect(CertificationCancellation.last.cancellation_reason).to eq("Other")
      expect(CertificationCancellation.last.other_reason).to eq("Test")
      expect(CertificationCancellation.last.email).to eq("fk@va.gov")
    end
  end
end
