require "rails_helper"

RSpec.feature "Save Certification" do
  class FakePdfService
    def self.save_form!(form:, values:)
      @saved_form = form
      @saved_values = values
    end

    class << self
      attr_reader :saved_values
    end
  end

  scenario "Saving a certification generates PDF form" do
    Form8.pdf_service = FakePdfService
    Fakes::AppealRepository.records = {
      "1234C" => Fakes::AppealRepository.appeal_ready_to_certify
    }

    visit "certifications/new/1234C"

    fill_in "Name of Appellant", with: "Shane Bobby"
    fill_in "Relationship to Veteran", with: "Brother"
    expect(find("#question2 input")["readonly"]).to be_truthy
    fill_in "Full Veteran Name", with: "Micah Bobby"
    fill_in "Insurance file number", with: "INSURANCE-NO"
    fill_in "Service connection for", with: "service connection stuff"
    fill_in "5B", with: "02/01/2016"
    fill_in "Increased rating for", with: "increased rating stuff"
    fill_in "6B", with: "08/08/2008"
    fill_in "7A", with: "other stuff"
    fill_in "7B", with: "09/09/2009"

    click_on "Preview Completed Form 8"

    expect(FakePdfService.saved_values["appellant"]).to eq("Shane Bobby")
    expect(FakePdfService.saved_values["appellant_relationship"]).to eq("Brother")
    expect(FakePdfService.saved_values["file_number"]).to eq("VBMS-ID")
    expect(FakePdfService.saved_values["veteran_name"]).to eq("Micah Bobby")
    expect(FakePdfService.saved_values["insurance_loan_number"]).to eq("INSURANCE-NO")
    expect(FakePdfService.saved_values["service_connection_for"]).to eq("service connection stuff")
    expect(FakePdfService.saved_values["service_connection_nod_date"]).to eq("02/01/2016")
    expect(FakePdfService.saved_values["increased_rating_for"]).to eq("increased rating stuff")
    expect(FakePdfService.saved_values["increased_rating_nod_date"]).to eq("08/08/2008")
    expect(FakePdfService.saved_values["other_for"]).to eq("other stuff")
    expect(FakePdfService.saved_values["other_nod_date"]).to eq("09/09/2009")
  end
end
