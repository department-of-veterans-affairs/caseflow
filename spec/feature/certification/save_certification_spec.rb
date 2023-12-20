# frozen_string_literal: true

RSpec.feature "Save Certification", :all_dbs do
  before do
    Form8.pdf_service = FakePdfService
    Timecop.freeze(Time.utc(2017, 2, 2, 20, 59, 0))
  end

  after do
    # Clean up generated PDF
    expected_form8 = Form8.new(vacols_id: appeal.vacols_id)
    form8_location = Form8.pdf_service.output_location_for(expected_form8)
    File.delete(form8_location) if File.exist?(form8_location)
  end

  let(:appeal) do
    create(:legacy_appeal, vacols_case: vacols_case)
  end

  let(:vacols_case) do
    create(:case_with_ssoc, bfregoff: "DSUSER")
  end

  let(:default_user) do
    create(:default_user)
  end

  def uncertify_appeal
    vacols_case.reload
    vacols_case.update!(bf41stat: nil)
  end

  context "As an authorized user" do
    let!(:current_user) { User.authenticate!(user: default_user) }

    let(:vbms_error) do
      VBMS::ClientError.new("<faultstring>Claim not certified.</faultstring>")
    end

    let(:generic_error) do
      StandardError.new("<faultstring>Claim not certified.</faultstring>")
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
        expect(find_field("Name of certifying official").value).to eq "Lauren Roth"

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

        representative = VACOLS::Representative.find(vacols_case.bfkey)
        expect(representative.repfirst).to be_eql("Clarence")
        expect(representative.repmi).to be_nil
        expect(representative.replast).to be_eql("Darrow")

        # path 2 - select 'no' first question and select informal form 9

        uncertify_appeal
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

        uncertify_appeal
        visit "certifications/#{appeal.vacols_id}/sign_and_certify"
        expect(find_field("Name and location of certifying office").value).to eq "Digital Service HQ, DC"
        expect(find_field("Organizational elements certifying appeal").value).to eq "DSUSER"
        expect(find_field("Name of certifying official").value).to eq "Lauren Roth"

        within_fieldset("Title of certifying official") do
          expect(find_field("Other", visible: false)).to be_checked
        end
        expect(find_field("Specify other title of certifying official").value).to eq "President"

        expect(find_field("Date").value).to eq Time.zone.today.strftime("%m/%d/%Y")
      end

      scenario "Trying to skip steps" do
        uncertify_appeal
        visit "certifications/#{appeal.vacols_id}/sign_and_certify"
        expect(page).to have_current_path("/certifications/#{appeal.vacols_id}/sign_and_certify")
        fill_in "Name of certifying official", with: "Tom Cruz"
        within_fieldset("Title of certifying official") do
          find("label", text: "Veterans Service Representative").click
        end
        click_button("Continue")
        expect(page).to have_content "Something went wrong"
      end

      scenario "Error certifying appeal" do
        allow(VBMSService).to receive(:upload_document_to_vbms).and_raise(vbms_error)
        visit "certifications/#{appeal.vacols_id}/sign_and_certify"
        fill_in "Name of certifying official", with: "Tom Cruz"
        within_fieldset("Title of certifying official") do
          find("label", text: "Veterans Service Representative").click
        end
        click_button("Continue")
        expect(page).to have_content "Something went wrong"
        expect(page).to_not have_content "Check Documents"

        allow(LegacyAppeal.repository).to receive(:certify).and_raise(generic_error)
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
        expect(page).to have_content "Please enter the title of the certifying official."
        fill_in "Name of certifying official", with: "12345678901234567890123456789012345678901"
        click_button("Continue")
        expect(page).to have_content("Please enter less than 40 characters")
      end
    end
  end
end
