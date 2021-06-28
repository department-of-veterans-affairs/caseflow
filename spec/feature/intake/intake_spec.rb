# frozen_string_literal: true

feature "Intake", :all_dbs do
  include IntakeHelpers

  before do
    Timecop.freeze(post_ama_start_date)

    Fakes::BGSService.inaccessible_appeal_vbms_ids = []

    allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original
    allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original
  end

  let!(:veteran) do
    Generators::Veteran.build(file_number: "12341234", first_name: "Ed", last_name: "Merica")
  end

  let(:inaccessible) { false }

  let!(:appeal) do
    create(:legacy_appeal, vacols_case: vacols_case)
  end

  let(:vacols_case) do
    create(
      :case,
      :status_advance,
      bfcorlid: "12341234C",
      case_issues: [create(:case_issue, :compensation)],
      bfdnod: 1.year.ago
    )
  end

  context "As a user with unauthorized role" do
    let!(:current_user) do
      User.authenticate!(roles: ["Not Mail Intake"])
    end

    scenario "Attempts to view establish claim pages" do
      visit "/intake"
      expect(page).to have_content("You aren't authorized")
    end
  end

  context "As a user with Senior Veterans Service Representative job_title" do
    let!(:svsr_user) { create(:user, css_id: "BVAAABSHIRE", station_id: "101") }

    before do
      User.authenticate!(user: svsr_user)
    end

    scenario "Attempts to view establish claim pages" do
      visit "/intake"
      expect(page).to have_content("You aren't authorized")
    end
  end

  context "As a user with Admin Intake role" do
    let!(:current_user) do
      User.authenticate!(roles: ["Admin Intake"])
    end

    scenario "Has access to intake mail" do
      # Admin Intake has the same access as Mail Intake, but to save time,
      # just check that they can access the intake screen
      visit "/intake"

      expect(page).to_not have_content("You aren't authorized")
      expect(page).to have_content("Which form are you processing?")
    end
  end

  context "As a user with Mail Intake role" do
    let!(:current_user) do
      User.authenticate!(roles: ["Mail Intake"])
    end

    context "when restrict appeal intakes enabled" do
      before { FeatureToggle.enable!(:restrict_appeal_intakes) }
      after { FeatureToggle.disable!(:restrict_appeal_intakes) }

      it "does not allow user to intake appeals" do
        visit "/intake"
        select_form(Constants.INTAKE_FORM_NAMES.appeal)

        expect(page).to have_content(COPY::INTAKE_APPEAL_PERMISSIONS_ALERT)
        expect(page).to have_css(".cf-submit[disabled]")

        select_form(Constants.INTAKE_FORM_NAMES.higher_level_review)
        safe_click ".cf-submit.usa-button"

        expect(page).to have_current_path("/intake/search")
      end

      context "when the user is on the BVA Intake team" do
        before { BvaIntake.singleton.add_user(current_user) }

        it "allows the user to intake appeals" do
          visit "/intake"
          select_form(Constants.INTAKE_FORM_NAMES.appeal)

          expect(page).to_not have_content(COPY::INTAKE_APPEAL_PERMISSIONS_ALERT)
          expect(page).to_not have_css(".cf-submit[disabled]")
        end
      end
    end

    context "user has unread Inbox messages" do
      scenario "user sees Alert on Intake start page" do
        create(:message, user: current_user)

        visit "/intake"

        expect(page).to have_content("You have unread messages")
      end
    end

    scenario "User visits help page" do
      visit "/intake/help"
      expect(page).to have_content("Welcome to the Intake Help page!")
    end

    scenario "User clicks on Search Cases" do
      visit "/intake"
      expect(page).to have_content("Search cases")
      new_window = window_opened_by { click_link("Search cases") }
      within_window new_window do
        expect(page).to have_current_path("/search")
      end
    end

    scenario "Search for a veteran that does not exist in BGS" do
      visit "/intake"
      select_form(Constants.INTAKE_FORM_NAMES.higher_level_review)
      safe_click ".cf-submit.usa-button"

      expect(page).to have_css(".cf-submit[disabled]")

      # try to hit enter key on empty search bar
      fill_in search_bar_title, with: ""
      find(".cf-search-input-with-close").native.send_keys(:return)

      # check error message doesn't exist
      expect(page).to have_no_css(".usa-alert-heading")

      fill_in search_bar_title, with: "5678"
      click_on "Search"
      expect(page).to have_current_path("/intake/search")
      expect(page).to have_content("Veteran ID not found")

      # Test that search errors clear when re-starting intake
      safe_click "#page-title"
      safe_click ".cf-submit.usa-button"

      expect(page).to_not have_content("Veteran ID not found")
    end

    scenario "Search for a veteran but search throws an unhandled exception" do
      expect_any_instance_of(Intake).to receive(:start!).and_raise("random error")
      visit "/intake"
      select_form(Constants.INTAKE_FORM_NAMES.higher_level_review)
      safe_click ".cf-submit.usa-button"

      expect(page).to have_content(search_page_title)

      fill_in search_bar_title, with: "5678"
      click_on "Search"

      expect(page).to have_current_path("/intake/search")
      expect(page).to have_content("Something went wrong")
      expect(page).to have_content("Error code 00000000000000000123456789abcdef")
    end

    scenario "Search for a veteran with an incident flash" do
      allow_any_instance_of(Veteran).to receive(:incident_flash?).and_return true
      visit "/intake"
      select_form(Constants.INTAKE_FORM_NAMES.higher_level_review)
      safe_click ".cf-submit.usa-button"

      expect(page).to have_content(search_page_title)

      fill_in search_bar_title, with: "12341234"
      click_on "Search"

      expect(page).to have_current_path("/intake/search")
      expect(page).to have_content("The Veteran has an incident flash")
      expect(page).to have_content(COPY::INCIDENT_FLASH_ERROR_START)
    end

    context "Veteran has too high of a sensitivity level for user" do
      before do
        Fakes::BGSService.mark_veteran_not_accessible(appeal.veteran_file_number)
      end

      scenario "Search for a veteran with a sensitivity error" do
        visit "/intake"
        select_form(Constants.INTAKE_FORM_NAMES.higher_level_review)
        safe_click ".cf-submit.usa-button"
        fill_in search_bar_title, with: "12341234"
        click_on "Search"

        expect(page).to have_current_path("/intake/search")
        expect(page).to have_content("You don't have permission to view this Veteran's information")
      end
    end

    context "Veteran records have been merged and Veteran has multiple active phone numbers in SHARE" do
      before do
        Fakes::BGSService.mark_veteran_not_accessible(appeal.veteran_file_number)
        allow_any_instance_of(Fakes::BGSService).to receive(:fetch_veteran_info)
          .and_raise(BGS::ShareError.new("NonUniqueResultException"))
      end

      scenario "Search for a veteran with multiple active phone numbers" do
        visit "/intake"
        select_form(Constants.INTAKE_FORM_NAMES.higher_level_review)
        safe_click ".cf-submit.usa-button"
        fill_in search_bar_title, with: "12341234"
        click_on "Search"

        expect(page).to have_current_path("/intake/search")
        expect(page).to have_content("The Veteran has multiple active phone numbers")

        cache_key = Fakes::BGSService.new.can_access_cache_key(current_user, "12341234")
        expect(Rails.cache.exist?(cache_key)).to eq(false)

        # retry after SHARE is fixed

        allow_any_instance_of(Fakes::BGSService).to receive(:fetch_veteran_info).and_call_original
        Fakes::BGSService.inaccessible_appeal_vbms_ids = []
        visit "/intake"
        select_form(Constants.INTAKE_FORM_NAMES.higher_level_review)
        safe_click ".cf-submit.usa-button"
        fill_in search_bar_title, with: "12341234"
        click_on "Search"

        expect(page).to have_current_path("/intake/review_request")
        expect(Rails.cache.exist?(cache_key)).to eq(true)
      end
    end

    context "Veteran is an employee at the same station as the User" do
      before do
        allow_any_instance_of(Fakes::BGSService).to receive(:station_conflict?).and_return(true)
      end

      scenario "Search for a Veteran that the user may not modify" do
        visit "/intake"
        select_form(Constants.INTAKE_FORM_NAMES.higher_level_review)
        safe_click ".cf-submit.usa-button"
        fill_in search_bar_title, with: "12341234"
        click_on "Search"

        expect(page).to have_content("You don't have permission to intake this Veteran")
      end
    end

    context "RAMP Veteran has invalid information" do
      before { FeatureToggle.enable!(:ramp_intake) }
      after { FeatureToggle.disable!(:ramp_intake) }

      let(:veteran) do
        Generators::Veteran.build(
          file_number: "12341234",
          sex: nil,
          ssn: nil,
          country: nil,
          address_line1: "this address is more than 20 chars",
          city: "BRISTOW"
        )
      end

      scenario "Search for a veteran with a validation error" do
        visit "/intake"
        select_form(Constants.INTAKE_FORM_NAMES.ramp_election)
        safe_click ".cf-submit.usa-button"

        fill_in search_bar_title, with: "12341234"
        click_on "Search"

        expect(page).to have_current_path("/intake/search")
        expect(page).to have_content("Please fill in the following fields in the Veteran's profile in VBMS or")
        expect(page).to have_content(
          "the corporate database, then retry establishing the EP in Caseflow: country."
        )
        expect(page).to have_content("This Veteran's address is too long. Please edit it in VBMS or SHARE")
      end
    end

    scenario "Search for a veteran whose form is already being processed" do
      create(:higher_level_review, veteran_file_number: "12341234")

      HigherLevelReviewIntake.new(
        veteran_file_number: "12341234",
        user: Generators::User.build(full_name: "David Schwimmer")
      ).start!

      visit "/intake"
      select_form(Constants.INTAKE_FORM_NAMES.higher_level_review)
      safe_click ".cf-submit.usa-button"

      fill_in search_bar_title, with: "12341234"
      click_on "Search"

      expect(page).to have_current_path("/intake/search")
      expect(page).to have_content("David Schwimmer already started processing this form")
    end

    context "the alert_duplicate_veterans feature toggle is enabled" do
      before { FeatureToggle.enable!(:alert_duplicate_veterans, users: [current_user.css_id]) }
      after { FeatureToggle.disable!(:alert_duplicate_veterans) }

      scenario "Search for a veteran who has duplicate records in CorpDB" do
        participant_id1 = "123456"
        participant_id2 = "789012"

        duplicate_veteran_participant_id_finder = instance_double(DuplicateVeteranParticipantIDFinder)
        allow(DuplicateVeteranParticipantIDFinder).to receive(:new).and_return(duplicate_veteran_participant_id_finder)
        allow(duplicate_veteran_participant_id_finder).to receive(:call).and_return([participant_id1, participant_id2])

        visit "/intake"
        select_form(Constants.INTAKE_FORM_NAMES.higher_level_review)
        safe_click ".cf-submit.usa-button"

        fill_in search_bar_title, with: "12341234"
        click_on "Search"

        expect(page).to have_current_path("/intake/search")
        expect(page).to have_content("This Veteran has a duplicate record in the Corporate database")
      end
    end

    scenario "Cancel an intake" do
      create(:higher_level_review, veteran_file_number: "12341234")

      intake = HigherLevelReviewIntake.new(veteran_file_number: "12341234", user: current_user)
      intake.start!

      visit "/intake"
      safe_click "#cancel-intake"
      expect(find("#modal_id-title")).to have_content("Cancel Intake?")
      safe_click ".close-modal"
      expect(page).to_not have_css("#modal_id-title")
      safe_click "#cancel-intake"

      safe_click ".confirm-cancel"
      expect(page).to have_content("Make sure you’ve selected an option below.")
      within_fieldset("Please select the reason you are canceling this intake.") do
        find("label", text: "Other").click
      end
      safe_click ".confirm-cancel"
      expect(page).to have_content("Make sure you’ve filled out the comment box below.")
      fill_in "Tell us more about your situation.", with: "blue!"
      safe_click ".confirm-cancel"

      expect(page).to have_content("Welcome to Caseflow Intake!")
      expect(page).to_not have_css(".cf-modal-title")

      intake.reload
      expect(intake.completed_at).to eq(Time.zone.now)
      expect(intake.cancel_reason).to eq("other")
      expect(intake.cancel_other).to eq("blue!")
      expect(intake).to be_canceled
    end

    context "BGS error" do
      before do
        allow_any_instance_of(Fakes::BGSService).to receive(:find_all_relationships)
          .and_raise(BGS::ShareError, "bgs error")
      end

      scenario "Cancel intake on error" do
        visit "/intake"
        select_form(Constants.INTAKE_FORM_NAMES.higher_level_review)
        safe_click ".cf-submit.usa-button"
        fill_in search_bar_title, with: "12341234"
        click_on "Search"

        expect(page).to have_content("Something went wrong")

        visit "/intake"

        expect(page).to have_content(/Error code: \w+-\w+-\w+-\w+/)
        expect(page).to have_content("Error: bgs error. Intake has been cancelled, please retry.")

        # verify that current intake has been cancelled
        expect(Intake.find_by(completion_status: "canceled", veteran_file_number: "12341234")).to_not be_nil

        # verify user can proceed with new intake
        visit "/intake"
        expect(page).to have_content("Welcome to Caseflow Intake!")
      end
    end

    context "Veteran has reserved file number" do
      let!(:current_user) do
        User.authenticate!(roles: ["Admin Intake"])
      end

      before { allow(Rails).to receive(:deploy_env?).and_return(true) }

      let(:veteran) do
        Generators::Veteran.build(
          file_number: "123456789",
          address_line1: "this address is more than 20 chars",
          first_name: "Ed",
          last_name: "Merica"
        )
      end

      scenario "Search for a veteran with reserved file_number" do
        visit "intake"
        select_form(Constants.INTAKE_FORM_NAMES.higher_level_review)
        safe_click ".cf-submit.usa-button"

        fill_in search_bar_title, with: "123456789"
        click_on "Search"

        expect(page).to have_current_path("/intake/search")
        expect(page).to have_content("Invalid file number")
      end
    end

    context "Invalid characters" do
      context "invalid address characters" do
        let(:veteran) do
          Generators::Veteran.build(
            file_number: "12341234",
            sex: nil,
            ssn: nil,
            country: "USA",
            address_line1: "%&^%",
            city: "BRISTOW"
          )
        end

        scenario "veteran has invalid characters in an address" do
          visit "/intake"
          select_form(Constants.INTAKE_FORM_NAMES.higher_level_review)
          safe_click ".cf-submit.usa-button"

          fill_in search_bar_title, with: "12341234"
          click_on "Search"

          expect(page).to have_current_path("/intake/review_request")
          within_fieldset("What is the Benefit Type?") do
            find("label", text: "Compensation", match: :prefer_exact).click
          end

          expect(page).to have_content("Check the Veteran's profile for invalid information")
          expect(page).to have_content("This Veteran's address has invalid characters")
        end
      end

      context "invalid city characters" do
        let(:veteran) do
          Generators::Veteran.build(
            file_number: "12341234",
            sex: nil,
            ssn: nil,
            country: "USA",
            city: "ÐÐÐÐÐ",
            address_line1: "1234"
          )
        end

        scenario "veteran has city invalid characters" do
          visit "/intake"
          select_form(Constants.INTAKE_FORM_NAMES.higher_level_review)
          safe_click ".cf-submit.usa-button"

          fill_in search_bar_title, with: "12341234"
          click_on "Search"

          expect(page).to have_current_path("/intake/review_request")
          within_fieldset("What is the Benefit Type?") do
            find("label", text: "Compensation", match: :prefer_exact).click
          end

          expect(page).to have_content("Check the Veteran's profile for invalid information")
          expect(page).to have_content("This Veteran's city has invalid characters")
        end
      end

      context "veteran date_of_birth invalid_date_of_birth" do
        let(:veteran) do
          Generators::Veteran.build(
            file_number: "12341234",
            sex: nil,
            ssn: nil,
            country: "USA",
            address_line1: "1234",
            date_of_birth: "01/1/1953"
          )
        end

        scenario "invalid_date_of_birth" do
          visit "/intake"
          select_form(Constants.INTAKE_FORM_NAMES.higher_level_review)
          safe_click ".cf-submit.usa-button"

          fill_in search_bar_title, with: "12341234"
          click_on "Search"

          expect(page).to have_current_path("/intake/review_request")
          within_fieldset("What is the Benefit Type?") do
            find("label", text: "Compensation", match: :prefer_exact).click
          end

          expect(page).to have_content("Check the Veteran's profile for invalid information")
          expect(page).to have_content("Please check that the Veteran's birthdate follows the format \"mm/dd/yyyy\"")
        end
      end

      context "invalid name suffix character" do
        let(:veteran) do
          Generators::Veteran.build(
            file_number: "12341234",
            sex: nil,
            ssn: nil,
            country: "USA",
            address_line1: "1234",
            name_suffix: "JR."
          )
        end

        scenario "veteran has invalid name suffix character" do
          visit "/intake"
          select_form(Constants.INTAKE_FORM_NAMES.higher_level_review)
          safe_click ".cf-submit.usa-button"

          fill_in search_bar_title, with: "12341234"
          click_on "Search"

          expect(page).to have_current_path("/intake/review_request")
          within_fieldset("What is the Benefit Type?") do
            find("label", text: "Compensation", match: :prefer_exact).click
          end

          expect(page).to have_content("Check the Veteran's profile for invalid information")
          expect(page).to have_content(
            "Please check the Veteran's suffix for any punctuations (for example use JR instead of JR.)"
          )
        end
      end

      context "four digit zip" do
        let(:veteran) do
          Generators::Veteran.build(
            file_number: "12341234",

            country: "USA",
            address_line1: "1234",
            zip_code: "1234"
          )
        end

        scenario "veteran has four digit zip" do
          visit "/intake"
          select_form(Constants.INTAKE_FORM_NAMES.higher_level_review)
          safe_click ".cf-submit.usa-button"

          fill_in search_bar_title, with: "12341234"
          click_on "Search"

          expect(page).to have_current_path("/intake/review_request")
          within_fieldset("What is the Benefit Type?") do
            find("label", text: "Compensation", match: :prefer_exact).click
          end

          expect(page).to have_content("Check the Veteran's profile for invalid information")
          expect(page).to have_content(
            "Zip codes in the USA must be 5 characters long. Please check the veteran's address and try again."
          )
        end
      end

      context "not a US address and zipcode" do
        let!(:country) { "CANADA" }
        let!(:zip_code) { "1234" }

        let(:veteran) do
          create(
            :veteran,
            country: country,
            zip_code: zip_code,
            file_number: "12341234"
          )
        end

        scenario "veteran has valid zipcode from different country" do
          visit "/intake"
          select_form(Constants.INTAKE_FORM_NAMES.higher_level_review)
          safe_click ".cf-submit.usa-button"

          fill_in search_bar_title, with: "12341234"
          click_on "Search"

          expect(page).to have_current_path("/intake/review_request")
          within_fieldset("What is the Benefit Type?") do
            find("label", text: "Compensation", match: :prefer_exact).click
          end

          expect(page).not_to have_content("Check the Veteran's profile for invalid information")
        end
      end

      context "invalid pay grade" do
        let(:service) { [{ branch_of_service: "army", pay_grade: "not valid" }] }
        let(:veteran) do
          Generators::Veteran.build(
            file_number: "12341234",
            sex: nil,
            ssn: nil,
            country: "USA",
            address_line1: "1234",
            name_suffix: "JR",
            service: service
          )
        end

        scenario "On an HLR: Error shows on review page for VBMS claims after benefit type is selected" do
          visit "/intake"

          select_form(Constants.INTAKE_FORM_NAMES.higher_level_review)
          safe_click ".cf-submit.usa-button"

          fill_in search_bar_title, with: "12341234"
          click_on "Search"

          expect(page).to have_current_path("/intake/review_request")
          within_fieldset("What is the Benefit Type?") do
            find("label", text: "Compensation", match: :prefer_exact).click
          end

          expect(page).to have_content("Check the Veteran's profile for invalid information")
          expect(page).to have_content(
            "Please check the Veteran's pay grade data in VBMS or SHARE to ensure all values are valid and try again"
          )
        end

        scenario "On an appeal: Error shows on add issues page if an issue is added with a VBMS benefit type" do
          visit "/intake"

          select_form(Constants.INTAKE_FORM_NAMES.appeal)
          safe_click ".cf-submit.usa-button"

          fill_in search_bar_title, with: "12341234"
          click_on "Search"

          expect(page).to have_current_path("/intake/review_request")

          fill_in "What is the Receipt Date of this form?", with: Time.zone.now.mdY

          within_fieldset("Which review option did the Veteran request?") do
            find("label", text: "Evidence Submission", match: :prefer_exact).click
          end

          within_fieldset("Is the claimant someone other than the Veteran?") do
            find("label", text: "No", match: :prefer_exact).click
          end

          select_agree_to_withdraw_legacy_issues(false)
          click_intake_continue

          expect(page).to have_current_path("/intake/add_issues")

          click_intake_add_issue
          add_intake_nonrating_issue(
            benefit_type: "Vocational Rehabilitation and Employment",
            category: "Additional Training",
            description: "Description for Additional Training",
            date: 1.month.ago.mdY,
            legacy_issues: true
          )
          add_intake_rating_issue("No VACOLS issues were found")

          expect(page).to_not have_content("Check the Veteran's profile for invalid information")

          click_intake_add_issue
          add_intake_nonrating_issue(
            benefit_type: "Compensation",
            category: "Active Duty Adjustments",
            description: "Description for Active Duty Adjustments",
            date: 1.month.ago.mdY,
            legacy_issues: true
          )
          add_intake_rating_issue("No VACOLS issues were found")

          expect(page).to have_content("Check the Veteran's profile for invalid information")
          expect(page).to have_content(
            "Please check the Veteran's pay grade data in VBMS or SHARE to ensure all values are valid and try again"
          )
        end
      end
    end
  end
end
