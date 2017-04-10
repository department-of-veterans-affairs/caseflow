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
      soc_date: soc.received_at,
      form9_date: form9.received_at
    }
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

  context "As an authorized user for Certification V2" do
    let!(:current_user) { User.authenticate!(roles: ["Certify Appeal", "CertificationV2"]) }

    scenario "Starting a Certification v2" do
      visit "certifications/new/#{appeal_ready.vacols_id}"
      expect(page).to have_current_path("/certifications/#{appeal_ready.vacols_id}/check_documents")
      expect(page).to have_content("All documents detected!")

      click_button("Continue")
      expect(page).to have_content("Review data from BGS about the appellant's representative")

      click_button("Continue")
      expect(page).to have_content("Check the appellant's eFolder for a hearing cancellation")

      within_fieldset("Was a hearing cancellation or request added after #{form9.received_at}?") do
        find("label", text: "Yes").click
      end
      expect(page).to have_content("What did the appellant request in the document you found")

      within_fieldset("Was a hearing cancellation or request added after #{form9.received_at}?") do
        find("label", text: "No").click
      end
      within_fieldset("Caseflow found the document below, labeled as a Form 9") do
        find("label", text: "Statement in lieu of Form 9").click
      end
      expect(page).to have_content("What optional board hearing preference, if any")
    end
  end

  context "As an authorized user to Certify Appeal" do
    let!(:current_user) { User.authenticate!(roles: ["Certify Appeal"]) }

    scenario "When some documents aren't matching shows missing documents page" do
      visit "certifications/new/#{appeal_mismatched_documents.vacols_id}"

      expect(find("#correspondent-name")).to have_content("Crockett, Davy")
      expect(find("#appeal-type-header")).to have_content("Original")
      expect(find("#file-type-header")).to have_content("VVA")
      expect(find("#vso-header")).to have_content("The American Legion")

      expect(find("#page-title")).to have_content "Mismatched Documents"
      expect(find("#nod-match")).to have_content "Not found"
      expect(find("#soc-match")).to_not have_content "Not found"
      expect(find("#soc-match")).to have_content "09/06/1987"
      expect(find("#form-9-match")).to have_content "Not found"
      expect(find("#ssoc-1-match")).to have_content "Not found"
      expect(find("#ssoc-2-match")).to have_content "SSOC 2"
      expect(find("#ssoc-2-match")).to have_content "Not found"

      expect(Certification.last).to have_attributes(
        vacols_id: appeal_mismatched_documents.vacols_id,
        nod_matching_at: nil,
        soc_matching_at: Time.zone.now,
        form9_matching_at: nil,
        ssocs_required: true,
        ssocs_matching_at: nil,
        form8_started_at: nil
      )
    end

    scenario "When appeal is not ready for certificaition" do
      visit "certifications/new/#{appeal_not_ready.vacols_id}"
      expect(page).to have_content("Appeal is not ready for certification.")
    end

    scenario "Clicking the refresh button" do
      visit "certifications/new/#{appeal_mismatched_documents.vacols_id}"

      # Overwrite AppealRepository data with an appeal with matching documents
      Generators::Appeal.build(
        vacols_id: appeal_mismatched_documents.vacols_id,
        vbms_id: appeal_mismatched_documents.vbms_id,
        vacols_record: vacols_record,
        documents: documents
      )

      click_on "Refresh page"
      expect(page).to have_content "Complete Electronic Form 8"
    end

    scenario "Starting a certifications with all documents matching" do
      visit "certifications/new/#{appeal_ready.vacols_id}"

      expect(page).to have_content "Complete Electronic Form 8"

      expect(page).to have_field "Name of Appellant", with: "Susie, Crockett"
      expect(page).to have_field "Relationship to Veteran", with: "Daughter"
      expect(page).to have_field "File Number", with: appeal_ready.vbms_id
      expect(page).to have_field "Full Veteran Name", with: "Crockett, Davy, X"
      expect(page).to have_selector("#question5B.hidden-field", visible: false)
      expect(page).to have_selector("#question6B.hidden-field", visible: false)
      expect(page).to have_selector("#question7B.hidden-field", visible: false)

      expect(Certification.last).to have_attributes(
        vacols_id: appeal_ready.vacols_id,
        form8_started_at: Time.zone.now
      )
    end

    scenario "VBMS-specific 500 on vbms error" do
      visit "certifications/new/#{appeal_vbms_error.vacols_id}"
      expect(page).to have_content("Unable to communicate with the VBMS system at this time.")
    end

    scenario "404's if appeal doesn't exist in VACOLS" do
      # It's awkward that we have to do this in order to trigger a RecordNotFound
      Fakes::AppealRepository.records = {}

      visit "certifications/new/4444NNNN"
      expect(page).to have_content("Page not found")
    end

    scenario "Appeal is already certified" do
      visit "certifications/new/#{appeal_already_certified.vacols_id}"
      expect(find("#page-title")).to have_content "Already Certified"
      expect(page).to have_content "Appeal has already been Certified"
    end
  end
end
