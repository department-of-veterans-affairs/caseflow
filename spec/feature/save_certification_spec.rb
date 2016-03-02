require "rails_helper"

RSpec.feature "Save Certification" do
  scenario "Submit form while missing required values" do
    User.authenticate!

    Fakes::AppealRepository.records = {
      "1234C" => Fakes::AppealRepository.appeal_ready_to_certify
    }

    visit "certifications/new/1234C"
    expect(page).to have_css("#question3 label.required")
    expect(page).to have_css("#question10A legend.required")

    fill_in "Full Veteran Name", with: ""
    within_fieldset("8A Representative Type") do
      find("label", text: "Other").click
    end
    click_on "Preview Completed Form 8"

    expect(page).to have_current_path(new_certification_path(vacols_id: "1234C"))

    expect(find("#question3 .usa-input-error-message")).to(
      have_content("Please enter the veteran's full name."))

    fill_in "Full Veteran Name", with: "Paul Joe"
    expect(find("#question3 .usa-input-error-message")).to_not(
      have_content("Please enter the veteran's full name."))

    expect(find("#question11A .usa-input-error-message")).to(
      have_content("Oops! Looks like you missed one!"))

    within_fieldset("11A Are contested claims procedures applicable in this case?") do
      find("label", text: "No").click
    end
    expect(find("#question10A .usa-input-error-message")).to_not(
      have_content("Oops! Looks like you missed one!"))

    expect(page).to have_css("#question8A3.usa-input-error")
  end

  scenario "Saving a certification passes the correct values into the PDF service" do
    User.authenticate!

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
    fill_in "5B Date of notification of action appealed", with: "02/01/2016"
    fill_in "Increased rating for", with: "increased rating stuff"
    fill_in "6B Date of notification of action appealed", with: "08/08/2008"
    fill_in "7A Other", with: "other stuff"
    fill_in "7B Date of notification of action appealed", with: "09/09/2009"
    fill_in "8A Representative Name", with: "Orington Roberts"

    within_fieldset("8A Representative Type") do
      find("label", text: "Attorney").click
    end

    # Validate hidden values don't submit
    within_fieldset("10A Was hearing requested?") do
      find("label", text: "Yes").click
    end
    within_fieldset("10B If the hearing was held, is transcript on file?") do
      find("label", text: "Yes").click
    end
    fill_in "10C If requested, but not held, explain", with: "i'm going to disappear"
    within_fieldset("10A Was hearing requested?") do
      find("label", text: "No").click
    end

    within_fieldset("11A Are contested claims procedures applicable in this case?") do
      find("label", text: "No").click
    end

    within_fieldset("12B Supplemental statement of the case") do
      find("label", text: "Not required").click
    end

    fill_in "17A Name of certifying official", with: "Kavi"
    fill_in "17B Title of certifying official", with: "DRO"

    click_on "Preview Completed Form 8"

    expect(FakePdfService.saved_form8).to have_attributes(
      appellant_name: "Shane Bobby",
      appellant_relationship: "Brother",
      file_number: "VBMS-ID",
      veteran_name: "Micah Bobby",
      insurance_loan_number: "INSURANCE-NO",
      service_connection_for: "service connection stuff",
      service_connection_nod_date: "02/01/2016",
      increased_rating_for: "increased rating stuff",
      increased_rating_nod_date: "08/08/2008",
      other_for: "other stuff",
      other_nod_date: "09/09/2009",
      representative_type: "Attorney",
      hearing_requested: "No",
      hearing_transcript_on_file: nil,
      hearing_requested_explaination: nil,
      contested_claims_procedures_applicable: "No",
      ssoc_required: "Not required",
      certifying_official_name: "Kavi",
      certifying_official_title: "DRO"
    )

    expect(page).to have_current_path(certification_path(id: "1234C"))
  end

  scenario "Saving a certification saves PDF form to correct location" do
    appeal = Fakes::AppealRepository.appeal_ready_to_certify
    expected_form8 = Form8.new(id: "2222C")
    form8_location = Form8PdfService.output_location_for(expected_form8)

    Fakes::AppealRepository.records = { "2222C" => appeal }
    Form8.pdf_service = Form8PdfService
    File.delete(form8_location) if File.exist?(form8_location)

    visit "certifications/new/2222C"

    fill_in "Full Veteran Name", with: "Micah Bobby"
    fill_in "8A Representative Name", with: "Orington Roberts"
    within_fieldset("8A Representative Type") do
      find("label", text: "Attorney").click
    end
    within_fieldset("10A Was hearing requested?") do
      find("label", text: "No").click
    end
    within_fieldset("11A Are contested claims procedures applicable in this case?") do
      find("label", text: "No").click
    end
    within_fieldset("12B Supplemental statement of the case") do
      find("label", text: "Not required").click
    end
    fill_in "17A Name of certifying official", with: "Kavi"
    fill_in "17B Title of certifying official", with: "DRO"

    click_on "Preview Completed Form 8"

    expect(File.exist?(form8_location)).to be_truthy
  end
end
