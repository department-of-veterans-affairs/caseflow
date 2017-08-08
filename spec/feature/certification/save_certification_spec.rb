require "rails_helper"

RSpec.feature "Save Certification" do
  before do
    Form8.pdf_service = FakePdfService
    Timecop.freeze(Time.utc(2017, 2, 2, 20, 59, 0))
    allow(Fakes::PowerOfAttorneyRepository).to receive(:update_vacols_rep_name!).and_call_original
  end

  after do
    # Clean up generated PDF
    expected_form8 = Form8.new(vacols_id: appeal.vacols_id)
    form8_location = Form8.pdf_service.output_location_for(expected_form8)
    File.delete(form8_location) if File.exist?(form8_location)
  end

  let(:nod) { Generators::Document.build(type: "NOD") }
  let(:soc) { Generators::Document.build(type: "SOC", received_at: Date.new(1987, 9, 6)) }
  let(:form9) { Generators::Document.build(type: "Form 9") }
  let(:vacols_record) do
    {
      template: :ready_to_certify,
      nod_date: nod.received_at,
      soc_date: soc.received_at,
      form9_date: form9.received_at,
      notification_date: 1.day.ago
    }
  end

  let(:appeal) do
    Generators::Appeal.build(vacols_record: vacols_record, documents: [nod, soc, form9])
  end

  context "As an authorized user for Certification V1" do
    let!(:current_user) { User.authenticate! }

    scenario "Submit form while missing required values" do
      visit "certifications/new/#{appeal.vacols_id}"
      expect(page).to have_css("#question3 label .cf-required")
      expect(page).to have_css("#question10A legend .cf-required")

      fill_in "Full Veteran Name", with: "     "
      within_fieldset("8A Representative Type") do
        find("label", text: "Other").click
      end
      click_on "Preview Completed Form 8"

      expect(page).to have_current_path(new_certification_path(vacols_id: appeal.vacols_id))

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
      visit "certifications/new/#{appeal.vacols_id}"

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

      visit "certifications/new/#{appeal.vacols_id}"
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
        expect(find_field("Decision Review Officer", visible: false)).to be_checked
      end

      click_on "Preview Completed Form 8"
      expect(page).to have_current_path(certification_path(id: appeal.vacols_id))
    end

    scenario "Saving a certification and go back and make edits" do
      visit "certifications/new/#{appeal.vacols_id}"

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

      form8 = Form8.find_by(vacols_id: appeal.vacols_id)
      expect(form8.record_outpatient_f.to_b).to eq false
      expect(form8.record_clinical_rec.to_b).to eq false
    end

    scenario "Saving a certification passes the correct values into the PDF service" do
      visit "certifications/new/#{appeal.vacols_id}"

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
        file_number: appeal.vbms_id,
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

      expect(page).to have_current_path(certification_path(id: appeal.vacols_id))
    end

    scenario "Saving a certification saves PDF form to correct location" do
      # Don't fake the Form8PdfService for this one
      Form8.pdf_service = Form8PdfService
      visit "certifications/new/#{appeal.vacols_id}"

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

      expected_form8 = Form8.new(vacols_id: appeal.vacols_id)
      form8_location = Form8.pdf_service.output_location_for(expected_form8)
      expect(File.exist?(form8_location)).to be_truthy
    end
  end

  context "As an authorized user for Certification v2" do
    let!(:current_user) { User.authenticate!(roles: ["Certify Appeal", "CertificationV2"]) }

    let(:vbms_error) do
      VBMS::ClientError.new("<faultstring>Claim not certified.</faultstring>")
    end

    let(:generic_error) do
      StandardError.new("<faultstring>Claim not certified.</faultstring>")
    end

    before(:all) do
      FeatureToggle.enable!(:certification_v2)
    end

    after(:all) do
      FeatureToggle.disable!(:certification_v2)
    end

    context "Save certification data in the DB" do
      scenario "For the confirm case details page" do
        visit "/certifications/#{appeal.vacols_id}/confirm_case_details"
        within_fieldset("Does the representative information from VBMS and VACOLS match?") do
          find("label", text: "No").click
        end
        within_fieldset("Which information source shows the correct representative for this appeal?") do
          find("label", text: "VBMS").click
        end
        click_button("Continue")

        visit "/certifications/#{appeal.vacols_id}/confirm_case_details"
        within_fieldset("Does the representative information from VBMS and VACOLS match?") do
          expect(find_field("No", visible: false)).to be_checked
        end
        within_fieldset("Which information source shows the correct representative for this appeal?") do
          expect(find_field("VBMS", visible: false)).to be_checked
        end
      end

      scenario "For the confirm hearing page" do
        visit "certifications/#{appeal.vacols_id}/confirm_hearing"
        expect(page).to have_current_path("/certifications/#{appeal.vacols_id}/confirm_hearing")

        within_fieldset("Has the appellant requested a change to their " \
                        "hearing preference since submitting the Form 9") do
          find("label", text: "Yes").click
        end

        within_fieldset("What did the appellant request in the document you found?") do
          find("label", text: "They cancelled their hearing request").click
        end

        click_button("Continue")

        visit "certifications/#{appeal.vacols_id}/confirm_hearing"
        within_fieldset("Has the appellant requested a change to their " \
                        "hearing preference since submitting the Form 9") do
          expect(find_field("Yes", visible: false)).to be_checked
        end

        within_fieldset("What did the appellant request in the document you found?") do
          expect(find_field("They cancelled their hearing request", visible: false)).to be_checked
        end

        # path 1 - select 'yes' first question
        visit "certifications/#{appeal.vacols_id}/confirm_hearing"
        within_fieldset("Has the appellant requested a change to their " \
                        "hearing preference since submitting the Form 9") do
          expect(find_field("Yes", visible: false)).to be_checked
        end
        within_fieldset("What did the appellant request in the document you found?") do
          expect(find_field("They cancelled their hearing request", visible: false)).to be_checked
        end

        # path 2 - select 'no' first question and select informal form 9
        within_fieldset("Has the appellant requested a change to their " \
                        "hearing preference since submitting the Form 9") do
          find("label", text: "No").click
        end
        within_fieldset("Caseflow found the document below, labeled as a Form 9") do
          find("label", text: "Statement in lieu of Form 9").click
        end
        within_fieldset("What optional board hearing preference, if any, did the appellant request?") do
          find("label", text: "Wants a board hearing in Washington, DC.").click
        end

        click_button("Continue")

        visit "certifications/#{appeal.vacols_id}/confirm_hearing"
        within_fieldset("Has the appellant requested a change to their " \
                        "hearing preference since submitting the Form 9") do
          expect(find_field("No", visible: false)).to be_checked
        end

        within_fieldset("What optional board hearing preference, if any, did the appellant request?") do
          expect(find_field("Wants a board hearing in Washington, DC.", visible: false)).to be_checked
        end
      end

      scenario "Complete certification" do
        visit "certifications/new/#{appeal.vacols_id}"
        click_button("Continue")
        expect(page).to have_current_path("/certifications/#{appeal.vacols_id}/confirm_case_details")
        within_fieldset("Does the representative information from VBMS and VACOLS match?") do
          find("label", text: "No").click
        end
        within_fieldset("Which information source shows the correct representative for this appeal?") do
          find("label", text: "VBMS").click
        end
        expect(page).to have_content "Great! Caseflow will update the representative name, type, and address in " \
                                         "VACOLS with information from VBMS."
        click_button("Continue")
        expect(page).to have_current_path("/certifications/#{appeal.vacols_id}/confirm_hearing")

        # path 1 - select 'yes' first question
        within_fieldset("Has the appellant requested a change to their " \
                        "hearing preference since submitting the Form 9") do
          find("label", text: "Yes").click
        end

        within_fieldset("What did the appellant request in the document you found?") do
          find("label", text: "They cancelled their hearing request").click
        end
        click_button("Continue")
        expect(page).to have_current_path("/certifications/#{appeal.vacols_id}/sign_and_certify")
        expect(find_field("Name of certifying official").value).to eq "Agent Smith"

        fill_in "Name of certifying official", with: "Tom Cruz"
        within_fieldset("Title of certifying official") do
          find("label", text: "Other").click
        end

        fill_in "Specify other title of certifying official", with: "President"

        expect(page).to have_title("Sign and Certify | Caseflow Certification")

        click_button("Continue")
        expect(page).to have_title("Success! | Caseflow Certification")
        expect(page).to have_content "Success"
        expect(page).to have_content "Representative fields updated in VACOLS"

        expect(Fakes::PowerOfAttorneyRepository).to have_received(:update_vacols_rep_name!).with(
          case_record: nil,
          first_name: "Clarence",
          middle_initial: "",
          last_name: "Darrow"
        )

        # path 2 - select 'no' first question and select informal form 9
        visit "certifications/#{appeal.vacols_id}/confirm_hearing"
        within_fieldset("Has the appellant requested a change to their " \
                        "hearing preference since submitting the Form 9") do
          find("label", text: "No").click
        end
        within_fieldset("Caseflow found the document below, labeled as a Form 9") do
          find("label", text: "Statement in lieu of Form 9").click
        end
        within_fieldset("What optional board hearing preference, if any, did the appellant request?") do
          find("label", text: "Wants a board hearing in Washington, DC.").click
        end

        click_button("Continue")
        expect(page).to have_current_path("/certifications/#{appeal.vacols_id}/sign_and_certify")
        fill_in "Name of certifying official", with: "Tom Cruz"
        within_fieldset("Title of certifying official") do
          find("label", text: "Other").click
        end
        fill_in "Specify other title of certifying official", with: "President"

        click_button("Continue")
        expect(page).to have_content "Success"

        form8 = Form8.find_by(vacols_id: appeal.vacols_id)
        expect(form8.certifying_office).to eq "Digital Service HQ, DC"
        expect(form8.certifying_username).to eq "DSUSER"
        expect(form8.certifying_official_name).to eq "Tom Cruz"
        expect(form8.certification_date.strftime("%m/%d/%Y")).to eq Time.zone.today.strftime("%m/%d/%Y")

        visit "certifications/#{appeal.vacols_id}/sign_and_certify"
        expect(find_field("Name and location of certifying office").value).to eq "Digital Service HQ, DC"
        expect(find_field("Organizational elements certifying appeal").value).to eq "DSUSER"
        expect(find_field("Name of certifying official").value).to eq "Tom Cruz"

        within_fieldset("Title of certifying official") do
          expect(find_field("Other", visible: false)).to be_checked
        end
        expect(find_field("Specify other title of certifying official").value).to eq "President"

        expect(find_field("Date").value).to eq Time.zone.today.strftime("%m/%d/%Y")
      end

      scenario "Trying to skip steps" do
        visit "certifications/#{appeal.vacols_id}/sign_and_certify"
        expect(page).to have_current_path("/certifications/#{appeal.vacols_id}/sign_and_certify")
        fill_in "Name of certifying official", with: "Tom Cruz"
        within_fieldset("Title of certifying official") do
          find("label", text: "Veterans Service Representative").click
        end
        click_button("Continue")
        expect(page).to have_content "Something went wrong"
      end

      scenario "Error cerifying appeal" do
        allow(VBMSService).to receive(:upload_document_to_vbms).and_raise(vbms_error)
        visit "certifications/#{appeal.vacols_id}/sign_and_certify"
        fill_in "Name of certifying official", with: "Tom Cruz"
        within_fieldset("Title of certifying official") do
          find("label", text: "Veterans Service Representative").click
        end
        click_button("Continue")
        expect(page).to have_content "Something went wrong"
        expect(page).to_not have_content "Check Documents"

        allow(Appeal.repository).to receive(:certify).and_raise(generic_error)
        visit "certifications/#{appeal.vacols_id}/sign_and_certify"
        fill_in "Name of certifying official", with: "Tom Cruz"
        within_fieldset("Title of certifying official") do
          find("label", text: "Veterans Service Representative").click
        end
        click_button("Continue")
        expect(page).to have_content "Something went wrong"
        expect(page).to_not have_content "Check Documents"
      end
    end

    context "Confirm validation works" do
      scenario "on the confirm case details page" do
        visit "certifications/#{appeal.vacols_id}/confirm_case_details"
        click_button("Continue")
        expect(page).to have_content "Please select yes or no."
        within_fieldset("Does the representative information from VBMS and VACOLS match?") do
          find("label", text: "No").click
        end
        expect(page).to_not have_content "Please select yes or no."
        click_button("Continue")
        expect(page).to have_content "Please select an option."
        within_fieldset("Which information source shows the correct representative for this appeal?") do
          find("label", text: "None").click
        end
        expect(page).to_not have_content "Please select an option."
        click_button("Continue")
        expect(page).to have_content("Please select a representative type.")
        within_fieldset("What type of representative did the appellant request for this appeal? ") do
          find("label", text: "Service organization").click
        end
        expect(page).to_not have_content("Please select a representative type.")
        click_button("Continue")
        expect(page).to have_content("Please select an organization.")
        select "Unlisted service organization", from: "Service organization name"
        expect(page).to_not have_content("Please select an organization.")
        click_button("Continue")
        expect(page).to have_content("Please enter a service organization's name.")
        fill_in "Enter the service organization's name:", with: "12345678901234567890123456789012345678901"
        expect(page).to_not have_content("Please enter a service organization's name.")
        click_button("Continue")
        expect(page).to have_content("Maximum length of organization name reached.")
        fill_in "Enter the service organization's name:", with: "Test"
        expect(page).to_not have_content("Please enter a service organization's name.")
      end

      scenario "on the confirm hearing page" do
        visit "certifications/#{appeal.vacols_id}/confirm_hearing"
        click_button("Continue")
        expect(page).to have_content "Please select yes or no."
        within_fieldset("Has the appellant requested a change to their " \
                        "hearing preference since submitting the Form 9") do
          find("label", text: "Yes").click
        end
        click_button("Continue")
        expect(page).to have_content "Please select a hearing preference."
        within_fieldset("Has the appellant requested a change to their " \
                        "hearing preference since submitting the Form 9") do
          find("label", text: "No").click
        end
        click_button("Continue")
        expect(page).to have_content "Please select Form 9 or a statement."
        within_fieldset("Caseflow found the document below, labeled as a Form 9") do
          find("label", text: "Statement in lieu of Form 9").click
        end
        click_button("Continue")
        expect(page).to have_content "Please select a hearing preference."
      end

      scenario "on the save and certify page" do
        visit "certifications/#{appeal.vacols_id}/sign_and_certify"
        click_button("Continue")
        expect(page).to have_content "Please enter the name of the certifying official (usually your name)."
        expect(page).to have_content "Please enter the title of the certifying official."
        fill_in "Name of certifying official", with: "12345678901234567890123456789012345678901"
        click_button("Continue")
        expect(page).to have_content("Please enter less than 40 characters")
      end
    end
  end
end
