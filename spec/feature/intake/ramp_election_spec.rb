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

  let!(:inactive_appeal) do
    Generators::Appeal.build(
      vbms_id: "77776666C",
      vacols_record: :full_grant_decided
    )
  end

  let!(:ineligible_appeal) do
    Generators::Appeal.build(
      vbms_id: "77778888C",
      vacols_record: :activated,
      issues: issues
    )
  end

  let(:ep_already_exists_error) do
    VBMS::HTTPError.new("500", "<faultstring>Claim not established. " \
      "A duplicate claim for this EP code already exists in CorpDB. Please " \
      "use a different EP code modifier. GUID: 13fcd</faultstring>")
  end

  # let(:unknown_error) do
  #   VBMS::HTTPError.new("500", "<faultstring>Unknown</faultstring>")
  # end

  let!(:current_user) do
    User.authenticate!(roles: ["Mail Intake"])
  end

  context "RAMP Election" do
    scenario "Search for a veteran with an no active appeals" do
      RampElection.create!(veteran_file_number: "77776666", notice_date: 5.days.ago)

      visit "/intake"

      within_fieldset("Which form are you processing?") do
        find("label", text: "RAMP Opt-In Election Form").click
      end
      safe_click ".cf-submit.usa-button"

      fill_in "Search small", with: "77776666"
      click_on "Search"

      expect(page).to have_current_path("/intake/search")
      expect(page).to have_content("Ineligible to participate in RAMP: no active appeals")
    end

    scenario "Search for a veteran with an ineligible appeal" do
      RampElection.create!(veteran_file_number: "77778888", notice_date: 5.days.ago)

      visit "/intake"

      within_fieldset("Which form are you processing?") do
        find("label", text: "RAMP Opt-In Election Form").click
      end
      safe_click ".cf-submit.usa-button"

      fill_in "Search small", with: "77778888"
      click_on "Search"

      expect(page).to have_current_path("/intake/search")
      expect(page).to have_content("Ineligible to participate in RAMP: appeal is at the Board")
    end

    scenario "Search for a veteran that has a RAMP election already processed" do
      RampElection.create!(
        veteran_file_number: "12341234",
        notice_date: 7.days.ago,
        receipt_date: 5.days.ago,
        established_at: 2.days.ago
      )

      # Validate you're redirected back to the form select page if you haven't started yet
      visit "/intake/completed"
      expect(page).to have_content("Welcome to Caseflow Intake!")

      visit "/intake/review-request"

      within_fieldset("Which form are you processing?") do
        find("label", text: "RAMP Opt-In Election Form").click
      end
      safe_click ".cf-submit.usa-button"

      fill_in "Search small", with: "12341234"
      click_on "Search"

      expect(page).to have_content("Search for Veteran by ID")
      expect(page).to have_content(
        "A RAMP opt-in with the receipt date 12/02/2017 was already processed"
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

      within_fieldset("Which form are you processing?") do
        find("label", text: "RAMP Opt-In Election Form").click
      end
      safe_click ".cf-submit.usa-button"

      fill_in "Search small", with: "12341234"
      click_on "Search"

      expect(page).to have_current_path("/intake/review-request")
      expect(page).to have_content("Review Ed Merica's Opt-In Election Form")

      intake = RampElectionIntake.find_by(veteran_file_number: "12341234")
      expect(intake).to_not be_nil
      expect(intake.started_at).to eq(Time.zone.now)
      expect(intake.user).to eq(current_user)
    end

    scenario "Start intake and go back and edit option" do
      RampElection.create!(veteran_file_number: "12341234", notice_date: Date.new(2017, 11, 7))
      intake = RampElectionIntake.new(veteran_file_number: "12341234", user: current_user)
      intake.start!

      # Validate that visiting the finish page takes you back to
      # the review request page if you haven't yet reviewed the intake
      visit "/intake/completed"

      # Validate validation
      fill_in "What is the Receipt Date of this form?", with: "08/06/2017"
      safe_click "#button-submit-review"

      expect(page).to have_content("Please select an option.")
      expect(page).to have_content(
        "Receipt Date cannot be earlier than RAMP start date, 11/01/2017"
      )

      within_fieldset("Which review lane did the veteran select?") do
        find("label", text: "Higher Level Review", match: :prefer_exact).click
      end
      fill_in "What is the Receipt Date of this form?", with: "11/07/2017"
      safe_click "#button-submit-review"

      expect(page).to have_content("Finish processing Higher-Level Review election")

      click_label "confirm-finish"

      ## Validate error message when complete intake fails
      allow(Appeal).to receive(:close).and_raise("A random error. Oh no!")
      safe_click "button#button-submit-review"
      expect(page).to have_content("Something went wrong")

      page.go_back

      expect(page).to_not have_content("Please select an option.")

      within_fieldset("Which review lane did the veteran select?") do
        find("label", text: "Supplemental Claim").click
      end
      safe_click "#button-submit-review"

      expect(find("#confirm-finish", visible: false)).to_not be_checked
      expect(page).to_not have_content("Something went wrong")

      expect(page).to have_content("Finish processing Supplemental Claim election")

      # Validate the appeal & issue also shows up
      expect(page).to have_content("This Veteran has 1 eligible appeal, with the following issues")
      expect(page).to have_content("5252 - Thigh, limitation of flexion of")
      expect(page).to have_content("low back condition")
    end

    scenario "Complete intake for RAMP Election form" do
      Fakes::VBMSService.end_product_claim_id = "SHANE9642"

      election = RampElection.create!(
        veteran_file_number: "12341234",
        notice_date: Date.new(2017, 11, 7)
      )

      intake = RampElectionIntake.new(veteran_file_number: "12341234", user: current_user)
      intake.start!

      # Validate that visiting the finish page takes you back to
      # the review request page if you haven't yet reviewed the intake
      visit "/intake/finish"

      within_fieldset("Which review lane did the veteran select?") do
        find("label", text: "Higher Level Review with Informal Conference").click
      end

      fill_in "What is the Receipt Date of this form?", with: "11/07/2017"
      safe_click "#button-submit-review"

      expect(page).to have_content("Finish processing Higher-Level Review election")

      election.reload
      expect(election.option_selected).to eq("higher_level_review_with_hearing")
      expect(election.receipt_date).to eq(Date.new(2017, 11, 7))

      # Validate the app redirects you to the appropriate location
      visit "/intake"
      safe_click "#button-submit-review"
      expect(page).to have_content("Finish processing Higher-Level Review election")

      expect(Fakes::AppealRepository).to receive(:close_undecided_appeal!).with(
        appeal: Appeal.find_or_create_by_vacols_id(appeal.vacols_id),
        user: current_user,
        closed_on: Time.zone.today,
        disposition_code: "P"
      )

      safe_click "button#button-submit-review"

      expect(page).to have_content("You must confirm you've completed the steps")
      expect(page).to_not have_content("Intake completed")
      expect(page).to have_button("Cancel intake", disabled: false)
      click_label("confirm-finish")

      Fakes::VBMSService.hold_request!
      safe_click "button#button-submit-review"

      expect(page).to have_button("Cancel intake", disabled: true)

      Fakes::VBMSService.resume_request!

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

    scenario "Complete intake for RAMP Election form fails due to duplicate EP" do
      allow(VBMSService).to receive(:establish_claim!).and_raise(ep_already_exists_error)

      RampElection.create!(
        veteran_file_number: "12341234",
        notice_date: Date.new(2017, 11, 7)
      )

      intake = RampElectionIntake.new(veteran_file_number: "12341234", user: current_user)
      intake.start!

      visit "/intake"

      within_fieldset("Which review lane did the veteran select?") do
        find("label", text: "Higher Level Review with Informal Conference").click
      end

      fill_in "What is the Receipt Date of this form?", with: "11/07/2017"
      safe_click "#button-submit-review"

      expect(page).to have_content("Finish processing Higher-Level Review election")

      click_label("confirm-finish")
      safe_click "button#button-submit-review"

      expect(page).to have_content("An EP 682 for this Veteran's claim was created outside Caseflow.")
    end
  end
end
