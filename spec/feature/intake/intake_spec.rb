# frozen_string_literal: true

require "rails_helper"
require "support/intake_helpers"

feature "Intake" do
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
      expect(page).to have_content(/Error code \w+-\w+-\w+-\w+/)
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
        Fakes::BGSService.inaccessible_appeal_vbms_ids << appeal.veteran_file_number
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
        Fakes::BGSService.inaccessible_appeal_vbms_ids << appeal.veteran_file_number
        allow_any_instance_of(Fakes::BGSService).to receive(:fetch_veteran_info)
          .and_raise(BGS::ShareError, message: "NonUniqueResultException")
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

    context "RAMP Veteran has invalid information" do
      before { FeatureToggle.enable!(:ramp_intake) }
      after { FeatureToggle.disable!(:ramp_intake) }

      let(:veteran) do
        Generators::Veteran.build(
          file_number: "12341234",
          sex: nil,
          ssn: nil,
          country: nil,
          address_line1: "this address is more than 20 chars"
        )
      end

      scenario "Search for a veteran with a validation error" do
        visit "/intake"
        select_form(Constants.INTAKE_FORM_NAMES.ramp_election)
        safe_click ".cf-submit.usa-button"

        fill_in search_bar_title, with: "12341234"
        click_on "Search"

        expect(page).to have_current_path("/intake/search")
        expect(page).to have_content("Please fill in the following field(s) in the Veteran's profile in VBMS or")
        expect(page).to have_content(
          "the corporate database, then retry establishing the EP in Caseflow: ssn, country."
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

      before do
        FeatureToggle.enable!(:intake_reserved_file_number, users: [current_user.css_id])
      end

      after do
        FeatureToggle.disable!(:intake_reserved_file_number, users: [current_user.css_id])
      end

      let(:veteran) do
        Generators::Veteran.build(
          file_number: "123456789",
          address_line1: "this address is more than 20 chars",
          first_name: "Ed",
          last_name: "Merica"
        )
      end

      scenario "Search for a veteran with reserved file_number" do
        visit "/intake"
        select_form(Constants.INTAKE_FORM_NAMES.higher_level_review)
        safe_click ".cf-submit.usa-button"

        fill_in search_bar_title, with: "123456789"
        click_on "Search"

        expect(page).to have_current_path("/intake/search")
        expect(page).to have_content("Invalid file number")
      end
    end
  end
end
