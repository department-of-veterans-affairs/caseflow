require "rails_helper"

RSpec.feature "RAMP Intake" do
  before do
    FeatureToggle.enable!(:intake)

    Time.zone = "America/New_York"
    Timecop.freeze(Time.utc(2017, 12, 8))

    allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original
    allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original
  end

  let(:veteran) do
    Generators::Veteran.build(file_number: "12341234", first_name: "Ed", last_name: "Merica")
  end

  let(:issues) do
    [
      Generators::Issue.build
    ]
  end

  let(:inaccessible) { false }

  let!(:appeal) do
    Generators::Appeal.build(
      vbms_id: "12341234C",
      issues: issues,
      vacols_record: :ready_to_certify,
      veteran: veteran,
      inaccessible: inaccessible,
      nod_date: 1.year.ago
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

    scenario "Search for a veteran that does not exist in BGS" do
      visit "/intake"

      within_fieldset("Which form are you processing?") do
        find("label", text: "RAMP Selection (VA Form 21-4138)").click
      end
      safe_click ".cf-submit.usa-button"

      fill_in "Search small", with: "5678"
      click_on "Search"

      expect(page).to have_current_path("/intake/search")
      expect(page).to have_content("Veteran ID not found")
    end

    scenario "Search for a veteran but search throws an unhandled exception" do
      expect_any_instance_of(IntakesController).to receive(:create).and_raise("random error")
      visit "/intake"

      within_fieldset("Which form are you processing?") do
        find("label", text: "RAMP Opt-In Election Form").click
      end
      safe_click ".cf-submit.usa-button"

      expect(page).to have_content("Enter the Veteran's ID below to process this RAMP Opt-In Election Form.")

      fill_in "Search small", with: "5678"
      click_on "Search"

      expect(page).to have_current_path("/intake/search")
      expect(page).to have_content("Something went wrong")
    end

    context "Veteran has too high of a sensitivity level for user" do
      let(:inaccessible) { true }

      scenario "Search for a veteran with a sensitivity error" do
        visit "/intake"

        within_fieldset("Which form are you processing?") do
          find("label", text: "RAMP Selection (VA Form 21-4138)").click
        end
        safe_click ".cf-submit.usa-button"

        fill_in "Search small", with: "12341234"
        click_on "Search"

        expect(page).to have_current_path("/intake/search")
        expect(page).to have_content("You don't have permission to view this veteran's information")
      end
    end

    context "Veteran has missing information" do
      let(:veteran) do
        Generators::Veteran.build(file_number: "12341234", sex: nil, ssn: nil)
      end

      scenario "Search for a veteran with a validation error" do
        visit "/intake"

        within_fieldset("Which form are you processing?") do
          find("label", text: "RAMP Selection (VA Form 21-4138)").click
        end
        safe_click ".cf-submit.usa-button"

        fill_in "Search small", with: "12341234"
        click_on "Search"

        expect(page).to have_current_path("/intake/search")
        expect(page).to have_content("Please fill in the following field(s) in the Veteran's profile in VBMS or")
        expect(page).to have_content("the corporate database, then retry establishing the EP in Caseflow: ssn, sex.")
      end
    end

    scenario "Search for a veteran who's form is already being processed" do
      RampElection.create!(veteran_file_number: "12341234", notice_date: Date.new(2017, 8, 7))

      RampElectionIntake.new(
        veteran_file_number: "12341234",
        user: Generators::User.build(full_name: "David Schwimmer")
      ).start!

      visit "/intake"

      within_fieldset("Which form are you processing?") do
        find("label", text: "RAMP Opt-In Election Form").click
      end
      safe_click ".cf-submit.usa-button"

      fill_in "Search small", with: "12341234"
      click_on "Search"

      expect(page).to have_current_path("/intake/search")
      expect(page).to have_content("David Schwimmer already started processing this form")
    end

    scenario "Cancel an intake" do
      RampElection.create!(veteran_file_number: "12341234", notice_date: Date.new(2017, 8, 7))

      intake = RampElectionIntake.new(veteran_file_number: "12341234", user: current_user)
      intake.start!

      visit "/intake"
      safe_click "#cancel-intake"
      expect(find(".cf-modal-title")).to have_content("Cancel Intake?")
      safe_click ".close-modal"
      expect(page).to_not have_css(".cf-modal-title")
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
  end
end
