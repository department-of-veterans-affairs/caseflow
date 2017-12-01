# coding: utf-8
require "rails_helper"

RSpec.feature "Start Certification" do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  let(:nod) { Generators::Document.build(type: "NOD") }
  let(:soc) { Generators::Document.build(type: "SOC", received_at: Date.new(1987, 9, 6)) }
  let(:form9) { Generators::Document.build(type: "Form 9") }
  let(:mismatched_nod) { Generators::Document.build(type: "NOD", received_at: 100.days.ago) }

  let(:documents) { [nod, soc, form9] }
  let(:mismatched_documents) { [mismatched_nod, soc] }

  let(:vacols_record) do
    {
      template: :ready_to_certify,
      type: "Original",
      file_type: "VVA",
      representative: "The American Legion",
      veteran_first_name: "Davy",
      veteran_last_name: "Crockett",
      veteran_middle_initial: "X",
      appellant_first_name: "Susie",
      appellant_middle_initial: nil,
      appellant_last_name: "Crockett",
      appellant_relationship: "Daughter",
      nod_date: nod.received_at,
      soc_date: soc.received_at + 4.days,
      form9_date: form9.received_at
    }
  end

  let(:vacols_record_exact_match) do
    {
      template: :ready_to_certify,
      type: "Original",
      file_type: "VVA",
      representative: "The American Legion",
      veteran_first_name: "Davy",
      veteran_last_name: "Crockett",
      veteran_middle_initial: "X",
      appellant_first_name: "Susie",
      appellant_middle_initial: nil,
      appellant_last_name: "Crockett",
      appellant_relationship: "Daughter",
      nod_date: nod.received_at,
      soc_date: soc.received_at,
      form9_date: form9.received_at
    }
  end

  let(:appeal_ready_exact_match) do
    Generators::Appeal.build(vacols_record: vacols_record_exact_match, documents: documents)
  end

  let(:vacols_record_with_ssocs) do
    vacols_record.merge(ssoc_dates: [6.days.from_now, 7.days.from_now])
  end

  let(:appeal_ready) do
    Generators::Appeal.build(vacols_record: vacols_record, documents: documents)
  end

  let(:appeal_mismatched_documents) do
    Generators::Appeal.build(vacols_record: vacols_record_with_ssocs, documents: mismatched_documents)
  end

  let(:appeal_not_ready) do
    Generators::Appeal.build(vacols_record: :not_ready_to_certify, documents: documents)
  end

  # Fakes::AppealRepository is stubbed to raise an error with this id
  let(:appeal_vbms_error) do
    Generators::Appeal.build(
      vbms_id: Fakes::AppealRepository::RAISE_VBMS_ERROR_ID,
      vacols_record: vacols_record,
      documents: documents
    )
  end

  let(:appeal_already_certified) do
    Generators::Appeal.build(vacols_record: :certified, documents: documents)
  end

  context "As a user who's not logged in" do
    scenario "Starting a certification redirects to login page" do
      visit "certifications/new/#{appeal_ready.vacols_id}"
      expect(page).to have_current_path("/login")
    end
  end

  context "As a user who isn't authorized" do
    let!(:current_user) { User.authenticate!(roles: ["Download eFolder"]) }

    scenario "Starting a certification when user isn't assigned 'Certify Appeal' function" do
      visit "certifications/new/#{appeal_ready.vacols_id}"

      expect(page).to have_current_path("/unauthorized")
    end
  end

  context "As an authorized user" do
    let!(:current_user) { User.authenticate!(roles: ["Certify Appeal"]) }

    scenario "Starting a certification with matching documents" do
      visit "certifications/new/#{appeal_ready.vacols_id}"
      expect(page).to have_current_path("/certifications/#{appeal_ready.vacols_id}/check_documents")
      expect(page).to have_title("Check Documents | Caseflow Certification")
      expect(page).to have_content("All documents found with matching VBMS and VACOLS dates.")
      expect(page).to have_content("SOC and SSOC dates in VBMS can be up to 4 days")
      expect(page).to have_content("SOC 09/10/1987 09/06/1987")

      click_button("Continue")
      expect(page).to have_title("Confirm Case Details | Caseflow Certification")
      expect(page).to have_content("Review information about the appellant's representative from VBMS and VACOLS.")

      within_fieldset("Does the representative information from VBMS and VACOLS match?") do
        find("label", text: "No").click
      end
      within_fieldset("Which information source shows the correct representative for this appeal?") do
        find("label", text: "None").click
      end

      within_fieldset("What type of representative did the appellant request for this appeal? ") do
        find("label", text: "Attorney").click
      end
      expect(page).to have_content("Caseflow will update the representative type")
      within_fieldset("What type of representative did the appellant request for this appeal? ") do
        find("label", text: "Agent").click
      end
      expect(page).to have_content("Caseflow will update the representative type")
      within_fieldset("What type of representative did the appellant request for this appeal? ") do
        find("label", text: "Other").click
      end
      expect(page).to have_content("Caseflow will update the representative type")
      within_fieldset("What type of representative did the appellant request for this appeal? ") do
        find("label", text: "No representative").click
      end
      expect(page).to_not have_content("Caseflow will update the representative type")
      within_fieldset("What type of representative did the appellant request for this appeal? ") do
        find("label", text: "Service organization").click
      end
      expect(page).to have_content("Service organization name")
      select "AMVETS", from: "Service organization name"
      expect(page).to have_content("Great! Caseflow will update the representative type")
      click_button("Continue")
      expect(page).to have_content("Check the eFolder for the appellant’s most recent hearing preference")
      page.go_back
      within_fieldset("Does the representative information from VBMS and VACOLS match?") do
        find("label", text: "No").click
      end
      within_fieldset("Which information source shows the correct representative for this appeal?") do
        find("label", text: "None").click
      end
      within_fieldset("What type of representative did the appellant request for this appeal? ") do
        find("label", text: "Service organization").click
      end
      select "Unlisted service organization", from: "Service organization name"
      expect(page).to_not have_content("Since you selected Unlisted")
      fill_in "Enter the service organization's name:", with: "Test"
      click_button("Continue")
      expect(page).to have_title("Confirm Hearing | Caseflow Certification")
      expect(page).to have_content("Check the eFolder for the appellant’s most recent hearing preference")

      # go back to the case details page
      page.go_back
      expect(page).to have_title("Confirm Case Details | Caseflow Certification")
      within_fieldset("Does the representative information from VBMS and VACOLS match?") do
        expect(find_field("No", visible: false)).to be_checked
      end
      within_fieldset("Which information source shows the correct representative for this appeal?") do
        expect(find_field("None", visible: false)).to be_checked
      end
      within_fieldset("What type of representative did the appellant request for this appeal?") do
        expect(find_field("Service organization", visible: false)).to be_checked
      end
      expect(page).to have_content("Unlisted service organization")
      expect(find_field("Enter the service organization's name:").value).to eq("Test")
      click_button("Continue")

      within_fieldset("Has the appellant requested a change to their " \
                      "hearing preference since submitting the Form 9?") do
        find("label", text: "Yes").click
      end
      expect(page).to have_content("What did the appellant request in the document you found")

      within_fieldset("Has the appellant requested a change to their " \
                      "hearing preference since submitting the Form 9?") do
        find("label", text: "No").click
      end
      within_fieldset("Caseflow found the document below, labeled as a Form 9") do
        find("label", text: "Statement in lieu of Form 9").click
      end
      expect(page).to have_content("What optional board hearing preference, if any")
    end

    scenario "When documents are found and have exactly matching dates" do
      visit "certifications/new/#{appeal_ready_exact_match.vacols_id}"
      expect(page).to have_content("All documents found with matching VBMS and VACOLS dates.")
      expect(page).to_not have_content("SOC and SSOC dates in VBMS can be up to 4 days")
    end

    scenario "When some documents aren't matching shows missing documents page" do
      visit "certifications/new/#{appeal_mismatched_documents.vacols_id}"
      expect(page).to have_content("Some documents could not be found in VBMS.")
      expect(page).to_not have_selector(:link_or_button, "Continue")
      expect(page).to have_selector(:link_or_button, "Refresh page")
      expect(page).to have_selector(:link_or_button, "cancel this certification")
      click_button("Refresh page")
      expect(page).to have_content("Some documents could not be found in VBMS.")
    end

    scenario "When user tries to skip by manually entering URL" do
      visit "certifications/#{appeal_already_certified.vacols_id}/confirm_case_details"
      expect(page).to have_current_path("/certifications/#{appeal_already_certified.vacols_id}/check_documents")
      visit "certifications/#{appeal_already_certified.vacols_id}/confirm_hearing"
      expect(page).to have_current_path("/certifications/#{appeal_already_certified.vacols_id}/check_documents")
      visit "certifications/#{appeal_already_certified.vacols_id}/sign_and_certify"
      expect(page).to have_current_path("/certifications/#{appeal_already_certified.vacols_id}/check_documents")

      visit "certifications/#{appeal_not_ready.vacols_id}/confirm_case_details"
      expect(page).to have_current_path("/certifications/#{appeal_not_ready.vacols_id}/check_documents")
      visit "certifications/#{appeal_not_ready.vacols_id}/confirm_hearing"
      expect(page).to have_current_path("/certifications/#{appeal_not_ready.vacols_id}/check_documents")
      visit "certifications/#{appeal_not_ready.vacols_id}/sign_and_certify"
      expect(page).to have_current_path("/certifications/#{appeal_not_ready.vacols_id}/check_documents")

      visit "certifications/#{appeal_mismatched_documents.vacols_id}/confirm_case_details"
      expect(page).to have_current_path("/certifications/#{appeal_mismatched_documents.vacols_id}/check_documents")
      visit "certifications/#{appeal_mismatched_documents.vacols_id}/confirm_hearing"
      expect(page).to have_current_path("/certifications/#{appeal_mismatched_documents.vacols_id}/check_documents")
      visit "certifications/#{appeal_mismatched_documents.vacols_id}/sign_and_certify"
      expect(page).to have_current_path("/certifications/#{appeal_mismatched_documents.vacols_id}/check_documents")
    end

    scenario "loading a certification and having it error" do
      allow(StartCertificationJob).to receive(:perform_now).and_return(true)
      visit "certifications/new/#{appeal_ready_exact_match.vacols_id}"
      expect(page).to have_content("Loading")
      certification = Certification.find_by(vacols_id: appeal_ready_exact_match.vacols_id)
      certification.update_attributes(loading_data_failed: true)
      page.execute_script("window.reloadCertification()")
      expect(page).to have_content("Technical Difficulties")
    end

    scenario "When appeal is not ready for certificaition" do
      visit "certifications/new/#{appeal_not_ready.vacols_id}"
      expect(page).to have_content("Appeal is not ready for certification.")
    end

    scenario "Appeal is already certified" do
      visit "certifications/new/#{appeal_already_certified.vacols_id}"
      expect(page).to have_content "Appeal has already been Certified"
    end

    scenario "There is a dependency outage" do
      allow(DependenciesReportService).to receive(:outage_present?).and_return(true)
      visit "certifications/new/#{appeal_ready.vacols_id}"
      expect(page).to have_content "We've detected technical issues in our system"
      User.unauthenticate!
      visit "certifications/new/#{appeal_ready.vacols_id}"
      expect(page).not_to have_content "We've detected technical issues in our system"
    end
  end
end
