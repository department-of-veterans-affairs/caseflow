require "rails_helper"

RSpec.feature "Save Certification" do
  before do
    User.authenticate!
    Timecop.freeze(Time.utc(2017, 2, 2, 20, 59, 0))
  end

  scenario "Submit form while missing required values" do
    Fakes::AppealRepository.records = {
      "1234C" => Fakes::AppealRepository.appeal_ready_to_certify
    }

    visit "certifications/new/1234C"
    expect(page).to have_css("#question3 label .cf-required")
    expect(page).to have_css("#question10A legend .cf-required")

    fill_in "Full Veteran Name", with: "     "
    within_fieldset("8A Representative Type") do
      find("label", text: "Other").click
    end
    click_on "Preview Completed Form 8"

    expect(page).to have_current_path(new_certification_path(vacols_id: "1234C"))

    expect(find("#question3 .usa-input-error-message")).to(
      have_content("Please enter the veteran's full name.")
    )

    fill_in "Full Veteran Name", with: "Paul Joe"
    expect(find("#question3 .usa-input-error-message")).to_not(
      have_content("Please enter the veteran's full name.")
    )

    expect(find("#question11A .usa-input-error-message")).to(
      have_content("Oops! Looks like you missed one!")
    )

    within_fieldset("11A Are contested claims procedures applicable in this case?") do
      find("label", text: "No").click
    end
    expect(find("#question10A .usa-input-error-message")).to_not(
      have_content("Oops! Looks like you missed one!")
    )

    expect(page).to have_css("#question8A3.usa-input-error")
  end

  scenario "Repopulates form 8 values with saved values" do
    Form8.pdf_service = FakePdfService
    Fakes::AppealRepository.records = {
      "5555C" => Fakes::AppealRepository.appeal_ready_to_certify
    }

    visit "certifications/new/5555C"

    fill_in "5A Service connection for", with: "Wonderful World"
    expect(find_field("5B Date of notification of action appealed").value).to eq "02/01/2017"
    page.execute_script("$('#question5B input').val('08/08/2016')")

    fill_in "6A Increased rating for", with: "Can be better"
    expect(find_field("6B Date of notification of action appealed").value).to eq "02/01/2017"

    # 7A question is empty so question 7B should not be visible
    expect(page).to_not have_content("7B Date of notification of action appealed")

    fill_in "Full Veteran Name", with: "Joe Patriot"
    fill_in "8A Representative Name", with: "Jane Patriot"
    within_fieldset("8A Representative Type") do
      find("label", text: "Attorney").click
    end
    within_fieldset("10A Was BVA hearing requested?") do
      find("label", text: "Yes").click
    end
    within_fieldset("10B Was the hearing held?") do
      find("label", text: "Yes").click
    end
    within_fieldset("Is the hearing transcript on file?") do
      find("label", text: "No").click
    end
    within_fieldset("11A Are contested claims procedures applicable in this case?") do
      find("label", text: "No").click
    end
    within_fieldset("12B Supplemental statement of the case") do
      find("label", text: "Not required").click
    end
    within_fieldset("13 Records to be forwarded to Board of Veterans' Appeals") do
      find("label", text: "OTHER").click
    end
    fill_in "Specify other", with: "Records"
    fill_in "17A Name of certifying official", with: "Gieuseppe"
    within_fieldset("17B Title of certifying official") do
      find("label", text: "Decision Review Officer").click
    end

    click_on "Preview Completed Form 8"

    visit "certifications/new/5555C"
    expect(find_field("Full Veteran Name").value).to eq("Joe Patriot")

    expect(find_field("5A Service connection for").value).to eq "Wonderful World"
    expect(find_field("5B Date of notification of action appealed").value).to eq "08/08/2016"

    expect(find_field("6A Increased rating for").value).to eq "Can be better"
    expect(find_field("6B Date of notification of action appealed").value).to eq "02/01/2017"

    expect(page).to_not have_content("7B Date of notification of action appealed")
    expect(find_field("8A Representative Name").value).to eq("Jane Patriot")

    within_fieldset("8A Representative Type") do
      expect(find_field("Attorney", visible: false)).to be_checked
    end
    within_fieldset("10A Was BVA hearing requested?") do
      expect(find_field("Yes", visible: false)).to be_checked
    end
    within_fieldset("10B Was the hearing held?") do
      expect(find_field("Yes", visible: false)).to be_checked
    end
    within_fieldset("11A Are contested claims procedures applicable in this case?") do
      expect(find_field("No", visible: false)).to be_checked
    end
    within_fieldset("12B Supplemental statement of the case") do
      expect(find_field("Not required", visible: false)).to be_checked
    end
    within_fieldset("13 Records to be forwarded to Board of Veterans' Appeals") do
      expect(find_field("OTHER", visible: false)).to be_checked
    end
    expect(find_field("Specify other").value).to eq("Records")

    expect(find_field("17A Name of certifying official").value).to eq("Gieuseppe")
    within_fieldset("17B Title of certifying official") do
      expect(find_field("Decision Review Officer")).to be_checked
    end

    click_on "Preview Completed Form 8"
    expect(page).to have_current_path(certification_path(id: "5555C"))
  end

  scenario "Does not repopulate saved form for another appeal" do
    Form8.pdf_service = FakePdfService
    Fakes::AppealRepository.records = {
      "5555C" => Fakes::AppealRepository.appeal_ready_to_certify,
      "6666C" => Fakes::AppealRepository.appeal_ready_to_certify
    }

    visit "certifications/new/5555C"
    fill_in "Full Veteran Name", with: "Joe Patriot"
    fill_in "8A Representative Name", with: "Jane Patriot"
    within_fieldset("8A Representative Type") do
      find("label", text: "Attorney").click
    end
    within_fieldset("10A Was BVA hearing requested?") do
      find("label", text: "No").click
    end
    within_fieldset("11A Are contested claims procedures applicable in this case?") do
      find("label", text: "No").click
    end
    within_fieldset("12B Supplemental statement of the case") do
      find("label", text: "Not required").click
    end
    fill_in "17A Name of certifying official", with: "Gieuseppe"
    within_fieldset("17B Title of certifying official") do
      find("label", text: "Decision Review Officer").click
    end
    click_on "Preview Completed Form 8"

    visit "certifications/new/6666C"
    expect(find_field("Full Veteran Name").value).to eq("Crockett, Davy, Q")
  end

  scenario "Saving a certification and go back and make edits" do
    Fakes::AppealRepository.records = {
      "12345C" => Fakes::AppealRepository.appeal_ready_to_certify
    }

    visit "certifications/new/12345C"

    fill_in "5A Service connection for", with: "Wonderful World"
    page.execute_script("$('#question5B input').val('08/08/2016')")
    # fill out the text and leave the default date
    fill_in "7A Other", with: "other stuff"

    within_fieldset("9A Is VA Form 646, or equivalent, of record?") do
      find("label", text: "Yes").click
    end

    within_fieldset("11A Are contested claims procedures applicable in this case?") do
      find("label", text: "No").click
    end

    within_fieldset("13 Records to be forwarded to Board of Veterans' Appeals") do
      find("label", text: "OUTPATIENT F").click
      find("label", text: "CLINICAL REC").click
    end

    fill_in "17A Name of certifying official", with: "Kavi"
    within_fieldset("17B Title of certifying official") do
      find("label", text: "Other").click
    end
    fill_in "Specify other title of certifying official", with: "Ray Romano"

    click_on "Preview Completed Form 8"
    click_on "Go back and make edits"

    expect(find_field("5B Date of notification of action appealed").value).to eq "08/08/2016"
    expect(page).to_not have_content("6B Date of notification of action appealed")
    expect(find_field("7B Date of notification of action appealed").value).to eq "02/01/2017"

    within_fieldset("13 Records to be forwarded to Board of Veterans' Appeals") do
      expect(find_field("OUTPATIENT F", visible: false)).to be_checked
      expect(find_field("CLINICAL REC", visible: false)).to be_checked
    end

    # uncheck boxes
    within_fieldset("13 Records to be forwarded to Board of Veterans' Appeals") do
      find("label", text: "OUTPATIENT F").click
      find("label", text: "CLINICAL REC").click
    end
    click_on "Preview Completed Form 8"

    form8 = Form8.find_by(vacols_id: "12345C")
    expect(form8.record_outpatient_f.to_b).to eq false
    expect(form8.record_clinical_rec.to_b).to eq false
  end

  scenario "Saving a certification passes the correct values into the PDF service" do
    Form8.pdf_service = FakePdfService
    Fakes::AppealRepository.records = {
      "12345C" => Fakes::AppealRepository.appeal_ready_to_certify
    }

    visit "certifications/new/12345C"

    fill_in "Name of Appellant", with: "Shane Bobby"
    fill_in "Relationship to Veteran", with: "Brother"
    expect(find("#question2 input")["readonly"]).to be_truthy
    fill_in "Full Veteran Name", with: "Micah Bobby"
    fill_in "Insurance file number", with: "INSURANCE-NO"
    fill_in "Service connection for", with: "service connection stuff"
    page.execute_script("$('#question5B input').val('02/01/2016')")
    fill_in "Increased rating for", with: "increased rating stuff"
    page.execute_script("$('#question6B input').val('08/08/2008')")
    fill_in "7A Other", with: "other stuff"
    page.execute_script("$('#question7B input').val('09/09/2009')")
    fill_in "8A Representative Name", with: "Orington Roberts"

    within_fieldset("8A Representative Type") do
      find("label", text: "Attorney").click
    end

    # Validate hidden values don't submit
    within_fieldset("10A Was BVA hearing requested?") do
      find("label", text: "Yes").click
    end
    within_fieldset("10B Was the hearing held?") do
      find("label", text: "Yes").click
    end
    within_fieldset("Is the hearing transcript on file?") do
      find("label", text: "Yes").click
    end
    fill_in "10C If requested, but not held, explain", with: "i'm going to disappear"
    within_fieldset("10A Was BVA hearing requested?") do
      find("label", text: "No").click
    end

    within_fieldset("11A Are contested claims procedures applicable in this case?") do
      find("label", text: "No").click
    end

    within_fieldset("12B Supplemental statement of the case") do
      find("label", text: "Not required").click
    end

    fill_in "17A Name of certifying official", with: "Kavi"
    within_fieldset("17B Title of certifying official") do
      find("label", text: "Other").click
    end
    fill_in "Specify other title of certifying official", with: "Ray Romano"

    click_on "Preview Completed Form 8"

    expect(FakePdfService.saved_form8).to have_attributes(
      appellant_name: "Shane Bobby",
      appellant_relationship: "Brother",
      file_number: "VBMS-ID",
      veteran_name: "Micah Bobby",
      insurance_loan_number: "INSURANCE-NO",
      service_connection_for: "service connection stuff",
      service_connection_notification_date: Date.strptime("02/01/2016", "%m/%d/%Y"),
      increased_rating_for: "increased rating stuff",
      increased_rating_notification_date: Date.strptime("08/08/2008", "%m/%d/%Y"),
      other_for: "other stuff",
      other_notification_date: Date.strptime("09/09/2009", "%m/%d/%Y"),
      representative_type: "Attorney",
      hearing_requested: "No",
      hearing_transcript_on_file: "Yes",
      hearing_requested_explanation: nil,
      contested_claims_procedures_applicable: "No",
      ssoc_required: "Not required",
      certifying_official_name: "Kavi",
      certifying_official_title: "Other",
      certifying_official_title_specify_other: "Ray Romano"
    )

    expect(page).to have_current_path(certification_path(id: "12345C"))
  end

  scenario "Saving a certification saves PDF form to correct location" do
    appeal = Fakes::AppealRepository.appeal_ready_to_certify
    expected_form8 = Form8.new(vacols_id: "2222C")
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
    within_fieldset("10A Was BVA hearing requested?") do
      find("label", text: "No").click
    end
    within_fieldset("11A Are contested claims procedures applicable in this case?") do
      find("label", text: "No").click
    end
    within_fieldset("12B Supplemental statement of the case") do
      find("label", text: "Not required").click
    end
    fill_in "17A Name of certifying official", with: "Kavi"
    within_fieldset("17B Title of certifying official") do
      find("label", text: "Decision Review Officer").click
    end

    click_on "Preview Completed Form 8"

    expect(File.exist?(form8_location)).to be_truthy
  end
end
