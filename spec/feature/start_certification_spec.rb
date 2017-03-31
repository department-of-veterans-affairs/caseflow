require "rails_helper"

RSpec.feature "Start Certification" do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  scenario "Starting a certification before logging in redirects to login page" do
    Fakes::AppealRepository.records = { "ABCD" => Fakes::AppealRepository.appeal_ready_to_certify }

    visit "certifications/new/ABCD"
    expect(page).to have_current_path("/login")
  end

  scenario "Starting a certification when user isn't assigned 'Certify Appeal' function" do
    User.authenticate!(roles: ["Download eFolder"])
    visit "certifications/new/ABCD"

    expect(page).to have_current_path("/unauthorized")
  end

  scenario "Starting a Certification v2" do
    User.authenticate!(roles: ["Certify Appeal", "CertificationV2"])
    Fakes::AppealRepository.records = { "ABCD" => Fakes::AppealRepository.appeal_ready_to_certify }

    visit "certifications/new/ABCD"
    expect(page).to have_current_path("/certifications/ABCD/check_documents")
    expect(page).to have_content("All documents detected!")
    click_button("Continue")
    expect(page).to have_content("Review data from BGS about the appellant's representative")
    click_button("Continue")
    expect(page).to have_content("Check the appellant's eFolder for a hearing cancellation")
    page.find(".cf-form-radio-option", text: "Yes").click
    expect(page).to have_content("What did the appellant request in the document you found")
    page.find(".cf-form-radio-option", text: "No").click
    expect(page).to have_content("Caseflow found the document below, labeled as a Form 9")
    page.find(".cf-form-radio-option", text: "Statement in lieu of Form 9").click
    expect(page).to have_content("What optional board hearing preference, if any")
  end

  scenario "Starting a certification with missing documents" do
    User.authenticate!(roles: ["Certify Appeal"])

    appeal_hash = {
      type: "Original",
      file_type: "VVA",
      representative: "The American Legion",
      nod_date: 1.day.ago,
      soc_date: Date.new(1987, 9, 6),
      form9_date: 1.day.ago,
      ssoc_dates: [6.days.from_now, 7.days.from_now],
      documents: [Fakes::AppealRepository.nod_document, Fakes::AppealRepository.soc_document],
      veteran_first_name: "Davy",
      veteran_last_name: "Crockett",
      regional_office_key: "DSUSER"
    }
    Fakes::AppealRepository.records = { "1234C" => appeal_hash }

    visit "certifications/new/1234C"

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

    certification = Certification.last
    expect(certification.vacols_id).to eq("1234C")
    expect(certification.nod_matching_at).to be_nil
    expect(certification.soc_matching_at).to eq(Time.zone.now)
    expect(certification.form9_matching_at).to be_nil
    expect(certification.ssocs_required).to be_truthy
    expect(certification.ssocs_matching_at).to be_nil
    expect(certification.form8_started_at).to be_nil
  end

  scenario "Clicking the refresh button" do
    User.authenticate!

    Fakes::AppealRepository.records = { "1234C" => Fakes::AppealRepository.appeal_mismatched_docs }
    visit "certifications/new/1234C"

    Fakes::AppealRepository.records = { "1234C" => Fakes::AppealRepository.appeal_ready_to_certify }
    click_on "Refresh page"
    expect(page).to have_content "Complete Electronic Form 8"
  end

  scenario "Starting a certifications with all documents matching" do
    User.authenticate!

    appeal_hash = {
      type: "Original",
      file_type: "VBMS",
      vbms_id: "VBMS-ID",
      representative: "Military Order of the Purple Heart",
      nod_date: 3.days.ago,
      soc_date: Date.new(1987, 9, 6),
      form9_date: 1.day.ago,
      documents: [
        Document.new(type: "NOD", received_at: 3.days.ago),
        Document.new(type: "SOC", received_at: Date.new(1987, 9, 6)),
        Document.new(type: "Form 9", received_at: 1.day.ago)
      ],
      veteran_first_name: "Davy",
      veteran_last_name: "Crockett",
      veteran_middle_initial: "X",
      appellant_first_name: "Susie",
      appellant_last_name: "Crockett",
      appellant_relationship: "Daughter",
      regional_office_key: "DSUSER"
    }
    Fakes::AppealRepository.records = { "5678C" => appeal_hash }

    visit "certifications/new/5678C"

    expect(page).to have_content "Complete Electronic Form 8"

    expect(page).to have_field "Name of Appellant", with: "Susie, Crockett"
    expect(page).to have_field "Relationship to Veteran", with: "Daughter"
    expect(page).to have_field "File Number", with: "VBMS-ID"
    expect(page).to have_field "Full Veteran Name", with: "Crockett, Davy, X"
    expect(page).to have_selector("#question5B.hidden-field", visible: false)
    expect(page).to have_selector("#question6B.hidden-field", visible: false)
    expect(page).to have_selector("#question7B.hidden-field", visible: false)

    certification = Certification.last
    expect(certification.vacols_id).to eq("5678C")
    expect(certification.form8_started_at).to eq(Time.zone.now)
  end

  scenario "404's if appeal doesn't exist in VACOLS" do
    User.authenticate!
    Fakes::AppealRepository.records = {}

    visit "certifications/new/4444NNNN"
    expect(page).to have_content("Page not found")
  end

  scenario "VBMS-specific 500 on vbms error" do
    User.authenticate!
    appeal = Fakes::AppealRepository.appeal_raises_vbms_error
    Fakes::AppealRepository.records = { "ABCD" => appeal }

    visit "certifications/new/ABCD"
    expect(page).to have_content("Unable to communicate with the VBMS system at this time.")
  end

  scenario "Appeal missing data" do
    User.authenticate!
    appeal = Fakes::AppealRepository.appeal_missing_data
    Fakes::AppealRepository.records = { "ABCD" => appeal }

    visit "certifications/new/ABCD"
    expect(page).to have_content("Appeal is not ready for certification.")
  end

  scenario "Appeal is already certified" do
    User.authenticate!
    appeal = Fakes::AppealRepository.appeal_already_certified
    Fakes::AppealRepository.records = { "1234" => appeal }

    visit "certifications/new/1234"
    expect(find("#page-title")).to have_content "Already Certified"
    expect(page).to have_content "Appeal has already been Certified"
  end
end
