require "rails_helper"

RSpec.feature "RAMP Intake" do
  before do
    FeatureToggle.enable!(:intake)

    Time.zone = "America/New_York"
    Timecop.freeze(Time.utc(2017, 8, 8))
  end

  let!(:veteran) do
    Generators::Veteran.build(file_number: "12341234", first_name: "Ed", last_name: "Merica")
  end

  context "As a user with Mail Intake role" do
    let!(:current_user) do
      User.authenticate!(roles: ["Mail Intake"])
    end

    scenario "Search for a veteran that does not exist in BGS" do
      visit "/intake"
      fill_in "Search small", with: "5678"
      click_on "Search"

      expect(page).to have_current_path("/intake")
      expect(page).to have_content("Veteran ID not found")
    end

    scenario "Search for a veteran that has not received a RAMP election" do
      visit "/intake"
      fill_in "Search small", with: "12341234"
      click_on "Search"

      expect(page).to have_current_path("/intake")
      expect(page).to have_content("A RAMP Opt-in Notice Letter was not sent to this Veteran.")
    end

    scenario "Search for a veteran that has received a RAMP election" do
      RampElection.create!(veteran_file_number: "12341234", notice_date: 5.days.ago)

      # Validate you're redirected back to the search page if you haven't started yet
      visit "/intake/completed"
      expect(page).to have_content("Welcome to Caseflow Intake!")

      visit "/intake/review-request"
      fill_in "Search small", with: "12341234"
      click_on "Search"

      expect(page).to have_current_path("/intake/review-request")
      expect(page).to have_content("Review Ed Merica's opt-in request")

      intake = RampIntake.find_by(veteran_file_number: "12341234")
      expect(intake).to_not be_nil
      expect(intake.started_at).to eq(Time.zone.now)
      expect(intake.user).to eq(current_user)
    end

    scenario "Cancel an intake" do
      RampElection.create!(veteran_file_number: "12341234", notice_date: Date.new(2017, 8, 7))

      intake = RampIntake.new(veteran_file_number: "12341234", user: current_user)
      intake.start!

      visit "/intake"

      safe_click ".cf-submit.usa-button"
      expect(find(".cf-modal-title")).to have_content("Cancel Intake?")
      safe_click "#close-modal"
      expect(page).to_not have_css(".cf-modal-title")

      safe_click ".cf-submit.usa-button"
      safe_click ".cf-modal-body .cf-submit"

      expect(page).to have_content("Welcome to Caseflow Intake!")
      expect(page).to_not have_css(".cf-modal-title")

      intake.reload
      expect(intake.completed_at).to eq(Time.zone.now)
      expect(intake).to be_canceled
    end

    scenario "Start intake and go back and edit option" do
      Generators::Appeal.build(vbms_id: "12341234C", vacols_record: :ready_to_certify)
      RampElection.create!(veteran_file_number: "12341234", notice_date: Date.new(2017, 8, 7))
      intake = RampIntake.new(veteran_file_number: "12341234", user: current_user)
      intake.start!

      # Validate that visiting the finish page takes you back to
      # the review request page if you haven't yet reviewed the intake
      visit "/intake/completed"

      # Validate validation
      fill_in "What is the Receipt Date for this election form?", with: "08/06/2017"
      click_on "Continue to next step"

      expect(page).to have_content("Please select an option.")
      expect(page).to have_content(
        "Receipt date cannot be earlier than the election notice date of 08/07/2017"
      )

      within_fieldset("Which election did the Veteran select?") do
        find("label", text: "Higher Level Review without DRO hearing request").click
      end
      fill_in "What is the Receipt Date for this election form?", with: "08/07/2017"
      safe_click "#button-submit-review"

      expect(page).to have_content("Finish processing Higher-Level Review election")
      expect(page).to have_content("Create an EP 682 RAMP – Higher Level Review Rating in VBMS.")

      click_label "confirm-finish"
      page.go_back

      expect(page).to_not have_content("Please select an option.")

      within_fieldset("Which election did the Veteran select?") do
        find("label", text: "Supplemental Claim").click
      end
      safe_click "#button-submit-review"

      expect(find("#confirm-finish", visible: false)).to_not be_checked

      expect(page).to have_content("Finish processing Supplemental Claim election")
      expect(page).to have_content("Create an EP 683 RAMP – Supplemental Claim Review Rating in VBMS.")
    end

    scenario "Complete intake for RAMP Election form" do
      appeal = Generators::Appeal.build(vbms_id: "12341234C", vacols_record: :ready_to_certify)

      election = RampElection.create!(
        veteran_file_number: "12341234",
        notice_date: Date.new(2017, 8, 7)
      )

      intake = RampIntake.new(veteran_file_number: "12341234", user: current_user)
      intake.start!

      # Validate that visiting the finish page takes you back to
      # the review request page if you haven't yet reviewed the intake
      visit "/intake/finish"

      within_fieldset("Which election did the Veteran select?") do
        find("label", text: "Higher Level Review with DRO hearing request").click
      end

      fill_in "What is the Receipt Date for this election form?", with: "08/07/2017"
      safe_click "#button-submit-review"

      expect(page).to have_content("Finish processing Higher-Level Review election")

      election.reload
      expect(election.option_selected).to eq("higher_level_review_with_hearing")
      expect(election.receipt_date).to eq(Date.new(2017, 8, 7))

      # Validate the app redirects you to the appropriate location
      visit "/intake"
      expect(page).to have_content("Finish processing Higher-Level Review election")

      expect(Fakes::AppealRepository).to receive(:close!).with(
        appeal: Appeal.find_or_create_by_vacols_id(appeal.vacols_id),
        user: current_user,
        closed_on: Time.zone.today,
        disposition_code: "P"
      )

      safe_click "button#button-submit-review"

      expect(page).to have_content("You must confirm you've completed the steps")
      expect(page).to_not have_content("Intake completed")

      click_label("confirm-finish")
      safe_click "button#button-submit-review"

      expect(page).to have_content("Intake completed")

      intake.reload
      expect(intake.completed_at).to eq(Time.zone.now)
      expect(intake).to be_success

      # Validate that the intake is no longer able to be worked on
      visit "/intake/finish"
      expect(page).to have_content("Welcome to Caseflow Intake!")
    end
  end

  context "As a user without Mail Intake role" do
    let!(:current_user) do
      User.authenticate!(roles: ["Not Mail Intake"])
    end

    scenario "Attempts to view establish claim pages" do
      visit "/intake"
      expect(page).to have_content("You aren't authorized")
    end
  end
end
