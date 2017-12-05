require "rails_helper"

RSpec.feature "RAMP Intake" do
  before do
    FeatureToggle.enable!(:intake)

    Time.zone = "America/New_York"
    Timecop.freeze(Time.utc(2017, 8, 8))

    allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original
  end

  let(:veteran) do
    Generators::Veteran.build(file_number: "12341234", first_name: "Ed", last_name: "Merica")
  end

  let(:issues) do
    [
      Generators::Issue.build(
        description: [
          "15 - Service connection",
          "03 - All Others",
          "5252 - Knee, limitation of flexion of"
        ],
        note: "knee movement"
      )
    ]
  end

  let!(:appeal) do
    Generators::Appeal.build(
      vbms_id: "12341234C",
      issues: issues,
      vacols_record: :ready_to_certify,
      veteran: veteran
    )
  end

  let!(:inactive_appeal) do
    Generators::Appeal.build(
      vbms_id: "77776666C",
      vacols_record: :full_grant_decided
    )
  end

  let!(:ineligible_appeal) do
    Generators::Appeal.build(
      vbms_id: "77778888C",
      vacols_record: :activated
    )
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

    scenario "Search for a veteran with an no active appeals" do
      RampElection.create!(veteran_file_number: "77776666", notice_date: 5.days.ago)

      visit "/intake"
      fill_in "Search small", with: "77776666"
      click_on "Search"

      expect(page).to have_current_path("/intake")
      expect(page).to have_content("Ineligible to participate in RAMP: no active appeals")
    end

    scenario "Search for a veteran with an ineligible appeal" do
      RampElection.create!(veteran_file_number: "77778888", notice_date: 5.days.ago)

      visit "/intake"
      fill_in "Search small", with: "77778888"
      click_on "Search"

      expect(page).to have_current_path("/intake")
      expect(page).to have_content("Ineligible to participate in RAMP: appeal is at the Board")
    end

    scenario "Search for a veteran that has a RAMP election already processed" do
      ramp_election = RampElection.create!(
        veteran_file_number: "12341234",
        notice_date: 5.days.ago
      )

      RampIntake.create!(
        user: current_user,
        detail: ramp_election,
        completed_at: Time.zone.now,
        completion_status: :success
      )

      # Validate you're redirected back to the search page if you haven't started yet
      visit "/intake/completed"
      expect(page).to have_content("Welcome to Caseflow Intake!")

      visit "/intake/review-request"
      fill_in "Search small", with: "12341234"
      click_on "Search"

      expect(page).to have_content("Welcome to Caseflow Intake!")
      expect(page).to have_content(
        "A RAMP opt-in with the notice date 08/02/2017 was already processed"
      )

      error_intake = Intake.last
      expect(error_intake.completion_status).to eq("error")
      expect(error_intake.error_code).to eq("ramp_election_already_complete")
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
      expect(page).to have_content("Review Ed Merica's opt-in election")

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
      RampElection.create!(veteran_file_number: "12341234", notice_date: Date.new(2017, 8, 7))
      intake = RampIntake.new(veteran_file_number: "12341234", user: current_user)
      intake.start!

      # Validate that visiting the finish page takes you back to
      # the review request page if you haven't yet reviewed the intake
      visit "/intake/completed"

      # Validate validation
      fill_in "What is the Receipt Date for this election form?", with: "08/06/2017"
      safe_click "#button-submit-review"

      expect(page).to have_content("Please select an option.")
      expect(page).to have_content(
        "Receipt date cannot be earlier than the election notice date of 08/07/2017"
      )

      within_fieldset("Which election did the Veteran select?") do
        find("label", text: "Higher Level Review", match: :prefer_exact).click
      end
      fill_in "What is the Receipt Date for this election form?", with: "08/07/2017"
      safe_click "#button-submit-review"

      expect(page).to have_content("Finish processing Higher-Level Review election")

      click_label "confirm-finish"

      ## Validate error message when complete intake fails
      allow(Appeal).to receive(:close).and_raise("A random error. Oh no!")
      safe_click "button#button-submit-review"
      expect(page).to have_content("Something went wrong")

      page.go_back

      expect(page).to_not have_content("Please select an option.")

      within_fieldset("Which election did the Veteran select?") do
        find("label", text: "Supplemental Claim").click
      end
      safe_click "#button-submit-review"

      expect(find("#confirm-finish", visible: false)).to_not be_checked
      expect(page).to_not have_content("Something went wrong")

      expect(page).to have_content("Finish processing Supplemental Claim election")

      # Validate the appeal & issue also shows up
      expect(page).to have_content("This Veteran has 1 active appeal, with the following issues")
      expect(page).to have_content("5252 - Knee, limitation of flexion of")
      expect(page).to have_content("knee movement")
    end

    scenario "Complete intake for RAMP Election form" do
      Fakes::VBMSService.end_product_claim_id = "SHANE9642"

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
        find("label", text: "Higher Level Review with Informal Conference").click
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
      expect(page).to have_content(
        "Established EP: 682HLRRRAMP - Higher Level Review Rating for Station 397"
      )

      expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
        claim_hash: {
          benefit_type_code: "1",
          payee_code: "00",
          predischarge: false,
          claim_type: "Claim",
          station_of_jurisdiction: "397",
          date: election.receipt_date.to_date,
          end_product_modifier: "682",
          end_product_label: "Higher Level Review Rating",
          end_product_code: "682HLRRRAMP",
          gulf_war_registry: false,
          suppress_acknowledgement_letter: false
        },
        veteran_hash: intake.veteran.to_vbms_hash
      )

      # Validate that you can not go back to previous steps
      page.go_back
      expect(page).to have_content("Intake completed")

      page.go_back
      expect(page).to have_content("Welcome to Caseflow Intake!")

      intake.reload
      expect(intake.completed_at).to eq(Time.zone.now)
      expect(intake).to be_success

      election.reload
      expect(election.end_product_reference_id).to eq("SHANE9642")

      # Validate that the intake is no longer able to be worked on
      visit "/intake/finish"
      expect(page).to have_content("Welcome to Caseflow Intake!")
    end

    context "when ramp reentry form is enabled" do
      before { FeatureToggle.enable!(:intake_reentry_form) }
      after { FeatureToggle.disable!(:intake_reentry_form) }

      scenario "flow starts with form selection" do
        visit "/intake"

        within_fieldset("Which form are you processing?") do
          find("label", text: "21-4138 RAMP Selection Form").click
        end
        safe_click ".cf-submit.usa-button"

        expect(page).to have_current_path("/intake/search")
      end
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
