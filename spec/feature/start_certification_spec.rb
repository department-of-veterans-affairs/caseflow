require "rails_helper"

RSpec.feature "Start Certification" do
  scenario "Starting a certification before logging in redirects to login page" do
    Fakes::AppealRepository.records = { "ABCD" => Fakes::AppealRepository.appeal_ready_to_certify }

    visit "certifications/new/ABCD"
    expect(page).to have_current_path(login_path)
  end

  scenario "Starting a certification with missing documents" do
    User.authenticate!

    appeal = Appeal.new(
      type: "Original",
      file_type: "VVA",
      representative: "The American Legion",
      nod_date: 1.day.ago,
      soc_date: Date.new(1987, 9, 6),
      form9_date: 1.day.ago,
      ssoc_dates: [6.days.from_now, 7.days.from_now],
      documents: [Fakes::AppealRepository.nod_document, Fakes::AppealRepository.soc_document],
      veteran_first_name: "Davy",
      veteran_last_name: "Crockett"
    )
    Fakes::AppealRepository.records = { "1234C" => appeal }

    visit "certifications/new/1234C"

    expect(find("#correspondent-name")).to have_content("Crockett, Davy")
    expect(find("#appeal-type-header")).to have_content("Original")
    expect(find("#file-type-header")).to have_content("VVA")
    expect(find("#vso-header")).to have_content("The American Legion")

    expect(find("#page-title")).to have_content "Mismatched Documents"
    expect(find("#nod-match")).to have_content "No Matching Document"
    expect(find("#soc-match")).to_not have_content "No Matching Document"
    expect(find("#soc-match")).to have_content "09/06/1987"
    expect(find("#form-9-match")).to have_content "No Matching Document"
    expect(find("#form-9-match")).to have_content "No Matching Document"
    expect(find("#ssoc-2-match")).to have_content "SSOC 2"
    expect(find("#ssoc-2-match")).to have_content "No Matching Document"
  end

  scenario "Clicking the refresh button" do
    User.authenticate!

    Fakes::AppealRepository.records = { "1234C" => Fakes::AppealRepository.appeal_not_ready }
    visit "certifications/new/1234C"

    Fakes::AppealRepository.records = { "1234C" => Fakes::AppealRepository.appeal_ready_to_certify }
    click_on "Refresh Page"
    expect(page).to have_content "Complete Electronic Form 8"
  end

  scenario "Starting a certifications with all documents matching" do
    User.authenticate!

    appeal = Appeal.new(
      type: "Original",
      file_type: "VBMS",
      vbms_id: "VBMS-ID",
      representative: "Military Order of the Purple Heart",
      nod_date: 3.days.ago,
      soc_date: Date.new(1987, 9, 6),
      form9_date: 1.day.ago,
      documents: [
        Document.new(type: :nod, received_at: 3.days.ago),
        Document.new(type: :soc, received_at: Date.new(1987, 9, 6)),
        Document.new(type: :form9, received_at: 1.day.ago)
      ],
      veteran_first_name: "Davy",
      veteran_last_name: "Crockett",
      veteran_middle_initial: "X",
      appellant_first_name: "Susie",
      appellant_last_name: "Crockett",
      appellant_relationship: "Daughter"
    )
    Fakes::AppealRepository.records = { "5678C" => appeal }

    visit "certifications/new/5678C"

    expect(page).to have_content "Complete Electronic Form 8"

    expect(page).to have_field "Name of Appellant", with: "Susie, Crockett"
    expect(page).to have_field "Relationship to Veteran", with: "Daughter"
    expect(page).to have_field "File No.", with: "VBMS-ID"
    expect(page).to have_field "Full Veteran Name", with: "Crockett, Davy, X"
    expect(page).to have_selector("#question5B.hidden-field", visible: false)
    expect(page).to have_selector("#question6B.hidden-field", visible: false)
    expect(page).to have_selector("#question7B.hidden-field", visible: false)
  end

  scenario "404's if appeal doesn't exist in VACOLS" do
    User.authenticate!

    visit "certifications/new/4444NNNN"
    expect(page.status_code).to eq(404)
  end
end
