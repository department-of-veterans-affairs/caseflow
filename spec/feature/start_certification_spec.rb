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
      correspondent: Correspondent.new(full_name: "Davy Crockett")
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
    Fakes::AppealRepository.records = {
      "1234C" => Fakes::AppealRepository.appeal_ready_to_certify
    }

    visit "certifications/new/1234C"
    expect(page).to have_content "Complete Electronic Form 8"
  end

  scenario "404's if appeal doesn't exist in VACOLS" do
    visit "certifications/new/4444NNNN"
    expect(page.status_code).to eq(404)
  end
end
