require "rails_helper"

Appeal.repository = Fakes::AppealRepository

RSpec.feature "Start Certification" do
  scenario "Starting a certification with missing documents" do
    appeal = Fakes::AppealRepository.appeal_not_ready
    Fakes::AppealRepository.records = {
      "1234C" => appeal
    }
    appeal.ssoc_dates = [6.days.from_now, 7.days.from_now]
    visit "certifications/new/1234C"

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
end
