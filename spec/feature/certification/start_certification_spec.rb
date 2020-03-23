# frozen_string_literal: true

RSpec.feature "Start Certification", :all_dbs do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  let(:appeal_ready) do
    create(:legacy_appeal, vacols_case: vacols_case)
  end

  let(:vacols_case) do
    create(:case_with_ssoc, bfdsoc: 181.days.ago)
  end

  let(:appeal_ready_exact_match) do
    create(:legacy_appeal, vacols_case: vacols_case_exact)
  end

  let(:vacols_case_exact) do
    create(:case_with_ssoc)
  end

  let(:appeal_mismatched_documents) do
    create(:legacy_appeal, vacols_case: vacols_case_mismatch)
  end

  let(:vacols_case_mismatch) do
    create(:case_with_ssoc, bfdsoc: 1.day.ago)
  end

  let(:appeal_already_certified) do
    create(:legacy_appeal, vacols_case: vacols_case_certified)
  end

  let(:vacols_case_certified) do
    create(:case_with_ssoc, :certified)
  end

  let(:appeal_not_ready) do
    create(:legacy_appeal, vacols_case: vacols_case_not_ready)
  end

  let(:vacols_case_not_ready) do
    create(:case_with_nod)
  end

  context "As a user who's not logged in" do
    scenario "Starting a certification redirects to help page" do
      visit "certifications/new/#{appeal_ready.vacols_id}"
      expect(page).to have_current_path("/help")
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
      expect(page).to have_content("SOC 07/04/2014 07/01/2014")

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
      certification = Certification.find_by_vacols_id(appeal_ready_exact_match.vacols_id)
      certification.update(loading_data_failed: true)
      expect(page).to have_content("Technical Difficulties", wait: 30)
    end

    scenario "When appeal is not ready for certificaition" do
      visit "certifications/new/#{appeal_not_ready.vacols_id}"
      expect(page).to have_content("Appeal is not ready for certification.")
    end

    scenario "Appeal is already certified" do
      visit "certifications/new/#{appeal_already_certified.vacols_id}"
      expect(page).to have_content "Appeal has already been certified"
    end

    scenario "There is a dependency outage" do
      # Banner is showing when degraded dependency is relevant
      allow(DependenciesReportService).to receive(:dependencies_report).and_return(["VACOLS"])
      visit "certifications/new/#{appeal_ready.vacols_id}"
      expect(page).to have_content "We've detected technical issues in our system"
      # Banner is not showing when degraded dependency is irrelevant
      allow(DependenciesReportService).to receive(:dependencies_report).and_return(["VVA"])
      visit "certifications/new/#{appeal_ready.vacols_id}"
      expect(page).to_not have_content "We've detected technical issues in our system"
      User.unauthenticate!
      visit "certifications/new/#{appeal_ready.vacols_id}"
      expect(page).not_to have_content "We've detected technical issues in our system"
    end
  end
end
