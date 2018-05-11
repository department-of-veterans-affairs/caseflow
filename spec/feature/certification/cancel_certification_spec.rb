require "rails_helper"

RSpec.feature "Cancel certification" do
  let!(:current_user) { User.authenticate! }

  let(:nod) { Generators::Document.build(type: "NOD") }
  let(:soc) { Generators::Document.build(type: "SOC") }
  let(:form9) { Generators::Document.build(type: "Form 9") }

  let(:appeal) do
    Generators::Appeal.build(
      vacols_record: {
        template: :ready_to_certify,
        nod_date: nod.received_at,
        soc_date: soc.received_at,
        form9_date: form9.received_at
      },
      documents: [nod, soc, form9]
    )
  end

  let(:appeal_mismatched_docs) do
    Generators::Appeal.build(
      vacols_record: {
        template: :ready_to_certify,
        nod_date: nod.received_at,
        soc_date: soc.received_at,
        form9_date: form9.received_at
      },
      documents: []
    )
  end

  context "As an authorized user" do
    let!(:current_user) { User.authenticate!(roles: ["Certify Appeal", "CertificationV2"]) }

    before(:all) do
      FeatureToggle.enable!(:certification_v2)
    end

    after(:all) do
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

    scenario "Click cancel when certification has mistmatched documents" do
      visit "certifications/new/#{appeal_mismatched_docs.vacols_id}"
      expect(page).to have_content("Not found")
      click_on "Cancel Certification"
      expect(page).to have_content("Please explain why this case cannot be certified with Caseflow.")
      within_fieldset("Why can't this case be certified in Caseflow?") do
        find("label", text: "Missing document could not be found").click
      end
      fill_in "What's your VA email address?", with: "fk@va.gov"
      click_button "Cancel certification"
      expect(page).to have_content("The certification has been cancelled")
      visit "certifications/new/#{appeal_mismatched_docs.vacols_id}"
      expect(page).to have_content("Some documents could not be found in VBMS.")
      click_link("cancel this certification")
      expect(page).to have_content("Please explain why")
      click_button("Go back")
      expect(page).to_not have_content("Please explain why")
      click_link("cancel this certification")
      click_button("Cancel-Certification-button-id-close")
      expect(page).to_not have_content("Please explain why")
      click_link("cancel this certification")
      within_fieldset("Why can't this case be certified in Caseflow?") do
        find("label", text: "Missing document could not be found").click
      end
      fill_in "What's your VA email address?", with: "fk@va.gov"
      click_button "Cancel certification"
      expect(page).to have_content("The certification has been cancelled")
    end
  end
end
