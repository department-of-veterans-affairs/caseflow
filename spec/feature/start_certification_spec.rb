require "rails_helper"

Appeal.repository = Fakes::AppealRepository

RSpec.feature "Start Certification" do
  scenario "Starting a certification with missing documents" do
    appeal = Appeal.new(
      type: :original,
      file_type: :vva,
      vso_name: "The American Legion",
      nod_date: 1.day.ago,
      soc_date: Date.new(1987, 9, 6),
      form9_date: 1.day.ago,
      ssoc_dates: [6.days.from_now, 7.days.from_now],
      documents: [Fakes::AppealRepository.nod_document, Fakes::AppealRepository.soc_document],
      veteran_name: "Davy Crockett"
    )
    Fakes::AppealRepository.records = { "1234C" => appeal }

    visit "certifications/new/1234C"

    expect(find("#correspondent-name")).to have_content("Davy Crockett")
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

  scenario "Starting a certifications with all documents matching" do
    appeal = Appeal.new(
      type: :original,
      file_type: :vbms,
      vbms_id: "VBMS-ID",
      vso_name: "Military Order of the Purple Heart",
      nod_date: 3.days.ago,
      soc_date: Date.new(1987, 9, 6),
      form9_date: 1.day.ago,
      documents: [
        Document.new(type: :nod, received_at: 3.days.ago),
        Document.new(type: :soc, received_at: Date.new(1987, 9, 6)),
        Document.new(type: :form9, received_at: 1.day.ago)
      ],
      veteran_name: "Davy Crockett",
      appellant_name: "Susie Crockett",
      appellant_relationship: "Daughter"
    )
    Fakes::AppealRepository.records = { "5678C" => appeal }

    visit "certifications/new/5678C"

    expect(page).to have_content "Complete Electronic Form 8"

    expect(page).to have_field "Name of Appellant", with: "Susie Crockett"
    expect(page).to have_field "Relationship to Veteran", with: "Daughter"
    expect(page).to have_field "File No.", with: "VBMS-ID"
    expect(page).to have_field "Full Veteran Name", with: "Davy Crockett"
    expect(page).to have_selector("#question5B.hidden-field", visible: false)
  end

  scenario "404's if appeal doesn't exist in VACOLS" do
    visit "certifications/new/4444NNNN"
    expect(page.status_code).to eq(404)
  end
end
