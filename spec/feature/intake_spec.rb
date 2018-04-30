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

  let(:unknown_error) do
    VBMS::HTTPError.new("500", "<faultstring>Unknown</faultstring>")
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

    context "RAMP Refiling" do
      scenario "Attempt to start RAMP refiling for a veteran without a complete RAMP election" do
        # Create an incomplete RAMP election
        RampElection.create!(
          veteran_file_number: "12341234",
          notice_date: 3.days.ago
        )

        # Validate that you can't go directly to search
        visit "/intake"

        # Validate that you can't move forward without selecting a form
        scroll_element_in_to_view(".cf-submit.usa-button")
        expect(find(".cf-submit.usa-button")["disabled"]).to eq("true")

        within_fieldset("Which form are you processing?") do
          find("label", text: "RAMP Selection (VA Form 21-4138)").click
        end
        safe_click ".cf-submit.usa-button"

        fill_in "Search small", with: "12341234"
        click_on "Search"

        expect(page).to have_content("No RAMP Opt-In Election")
        expect(RampRefilingIntake.last).to have_attributes(error_code: "no_complete_ramp_election")
      end

      scenario "Attempt to start RAMP refiling for a veteran with an active RAMP Election EP" do
        # Create an RAMP election with a pending EP
        RampElection.create!(
          veteran_file_number: "12341234",
          notice_date: 3.days.ago,
          established_at: 2.days.ago,
          end_product_reference_id: Generators::EndProduct.build(
            veteran_file_number: "12341234",
            bgs_attrs: { status_type_code: "PEND" }
          ).claim_id
        )

        # Validate that you can't go directly to search
        visit "/intake"

        # Validate that you can't move forward without selecting a form
        scroll_element_in_to_view(".cf-submit.usa-button")
        expect(find(".cf-submit.usa-button")["disabled"]).to eq("true")

        within_fieldset("Which form are you processing?") do
          find("label", text: "RAMP Selection (VA Form 21-4138)").click
        end
        safe_click ".cf-submit.usa-button"

        fill_in "Search small", with: "12341234"
        click_on "Search"

        expect(page).to have_content("This Veteran has a pending RAMP EP in VBMS")
        expect(RampRefilingIntake.last).to have_attributes(error_code: "ramp_election_is_active")
      end

      scenario "Start a RAMP refiling with an invalid option" do
        # Create an complete higher level review RAMP election
        ramp_election = RampElection.create!(
          veteran_file_number: "12341234",
          notice_date: 5.days.ago,
          option_selected: "higher_level_review_with_hearing",
          receipt_date: 4.days.ago,
          established_at: 2.days.ago,
          end_product_reference_id: Generators::EndProduct.build(
            veteran_file_number: "12341234",
            bgs_attrs: { status_type_code: "CLR" }
          ).claim_id
        )

        Generators::Contention.build(
          claim_id: ramp_election.end_product_reference_id,
          text: "Left knee"
        )

        intake = RampRefilingIntake.new(
          veteran_file_number: "12341234",
          user: current_user,
          detail: RampRefiling.new(
            veteran_file_number: "12341234",
            ramp_election: ramp_election
          )
        )

        intake.start!

        visit "/intake"

        fill_in "What is the Receipt Date of this form?", with: "11/03/2017"
        within_fieldset("Which review lane did the Veteran select?") do
          find("label", text: "Higher Level Review", match: :prefer_exact).click
        end
        safe_click "#button-submit-review"

        expect(page).to have_content("Ineligible for Higher-Level Review")
        expect(page).to have_button("Continue to next step", disabled: true)
        click_on "Begin next intake"

        # Go back to start page
        expect(page).to have_content("Welcome to Caseflow Intake!")

        # Check there was an error in the DB
        intake.reload
        expect(intake.completion_status).to eq("error")
        expect(intake.error_code).to eq("ineligible_for_higher_level_review")
        expect(intake.detail).to be_nil
      end

      scenario "Complete a RAMP refiling for an appeal" do
        # Create an RAMP election with a cleared EP
        ramp_election = RampElection.create!(
          veteran_file_number: "12341234",
          notice_date: 5.days.ago,
          receipt_date: 4.days.ago,
          established_at: 2.days.ago,
          end_product_reference_id: Generators::EndProduct.build(
            veteran_file_number: "12341234",
            bgs_attrs: { status_type_code: "CLR" }
          ).claim_id
        )

        Generators::Contention.build(
          claim_id: ramp_election.end_product_reference_id,
          text: "Left knee rating increase"
        )

        Generators::Contention.build(
          claim_id: ramp_election.end_product_reference_id,
          text: "Left shoulder service connection"
        )

        # Validate that you can't go directly to search
        visit "/intake/search"

        # Validate that you can't move forward without selecting a form
        scroll_element_in_to_view(".cf-submit.usa-button")
        expect(find(".cf-submit.usa-button")["disabled"]).to eq("true")

        within_fieldset("Which form are you processing?") do
          find("label", text: "RAMP Selection (VA Form 21-4138)").click
        end
        safe_click ".cf-submit.usa-button"

        fill_in "Search small", with: "12341234"
        click_on "Search"

        expect(page).to have_current_path("/intake/review-request")

        # Validate issues have been created based on contentions
        expect(ramp_election.issues.count).to eq(2)

        # Validate validation
        fill_in "What is the Receipt Date of this form?", with: "11/02/2017"

        within_fieldset("Which review lane did the Veteran select?") do
          find("label", text: "Appeal to Board").click
        end

        safe_click "#button-submit-review"

        expect(page).to have_content(
          "Receipt date cannot be earlier than the original RAMP election receipt date of 12/03/2017"
        )

        fill_in "What is the Receipt Date of this form?", with: "12/03/2017"
        safe_click "#button-submit-review"

        expect(page).to have_content("Please select an option")

        within_fieldset("Which type of appeal did the Veteran request?") do
          find("label", text: "Evidence Submission").click
        end

        safe_click "#button-submit-review"
        expect(page).to have_content("Finish processing RAMP Selection form")

        ramp_refiling = RampRefiling.find_by(veteran_file_number: "12341234")
        expect(ramp_refiling).to_not be_nil
        expect(ramp_refiling.ramp_election_id).to eq(ramp_election.id)
        expect(ramp_refiling.option_selected).to eq("appeal")
        expect(ramp_refiling.appeal_docket).to eq("evidence_submission")
        expect(ramp_refiling.receipt_date).to eq(Date.new(2017, 12, 3))

        safe_click "#finish-intake"

        # Check that clicking next without confirmation throws an error
        expect(page).to have_content("Finish processing RAMP Selection form")
        expect(page).to have_content("You must confirm you've completed the steps")

        click_label("confirm-outside-caseflow-steps")

        safe_click "#finish-intake"

        # Check that clicking next without selecting a contention raises an error
        expect(page).to have_content("You must select at least one contention")

        find("label", text: "Left knee rating increase").click
        find("label", text: "Left shoulder service connection").click
        find("label", text: "The veteran's form lists at least one ineligible contention").click

        safe_click "#finish-intake"

        expect(page).to have_content("Appeal record saved in Caseflow")
        expect(Fakes::VBMSService).to_not have_received(:establish_claim!)
        expect(ramp_refiling.issues.count).to eq(2)
        expect(ramp_refiling.issues.first.description).to eq("Left knee rating increase")
        expect(ramp_refiling.issues.last.description).to eq("Left shoulder service connection")
        expect(ramp_refiling.issues.first.contention_reference_id).to be_nil
        expect(ramp_refiling.issues.last.contention_reference_id).to be_nil
      end

      scenario "Complete a RAMP Refiling for a supplemental claim" do
        # Create an complete Higher level review RAMP election
        ramp_election = RampElection.create!(
          veteran_file_number: "12341234",
          notice_date: 5.days.ago,
          option_selected: "higher_level_review_with_hearing",
          receipt_date: 4.days.ago,
          established_at: 2.days.ago,
          end_product_reference_id: Generators::EndProduct.build(
            veteran_file_number: "12341234",
            bgs_attrs: { status_type_code: "CLR" }
          ).claim_id
        )

        Generators::Contention.build(
          claim_id: ramp_election.end_product_reference_id,
          text: "Left knee rating increase"
        )

        intake = RampRefilingIntake.new(
          veteran_file_number: "12341234",
          user: current_user,
          detail: RampRefiling.new(
            veteran_file_number: "12341234",
            ramp_election: ramp_election
          )
        )

        intake.start!

        Fakes::VBMSService.end_product_claim_id = "SHANE9123242"

        visit "/intake"

        fill_in "What is the Receipt Date of this form?", with: "12/07/2017"
        within_fieldset("Which review lane did the Veteran select?") do
          find("label", text: "Supplemental Claim", match: :prefer_exact).click
        end
        safe_click "#button-submit-review"

        click_label("confirm-outside-caseflow-steps")
        find("label", text: "Left knee rating increase").click
        find("label", text: "The veteran's form lists at least one ineligible contention").click

        Fakes::VBMSService.hold_request!
        expect(page).to have_button("Cancel intake", disabled: false)
        safe_click "#finish-intake"
        expect(page).to have_button("Cancel intake", disabled: true)

        Fakes::VBMSService.resume_request!

        expect(page).to have_content("Intake completed")

        ramp_refiling = RampRefiling.find_by(veteran_file_number: "12341234")
        expect(ramp_refiling.has_ineligible_issue).to eq(true)

        expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
          claim_hash: {
            benefit_type_code: "1",
            payee_code: "00",
            predischarge: false,
            claim_type: "Claim",
            station_of_jurisdiction: "397",
            date: ramp_refiling.receipt_date.to_date,
            end_product_modifier: "683",
            end_product_label: "Supplemental Claim Review Rating",
            end_product_code: "683SCRRRAMP",
            gulf_war_registry: false,
            suppress_acknowledgement_letter: false
          },
          veteran_hash: intake.veteran.to_vbms_hash
        )

        expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
          veteran_file_number: "12341234",
          claim_id: "SHANE9123242",
          contention_descriptions: ["Left knee rating increase"]
        )

        expect(ramp_refiling.issues.count).to eq(1)
        expect(ramp_refiling.issues.first.contention_reference_id).to_not be_nil
        expect(page).to have_content(
          "Ed Merica's (ID #12341234) VA Form 21-4138 has been processed."
        )
        expect(page).to have_content(
          "Established EP: 683SCRRRAMP - Supplemental Claim Review Rating for Station 397"
        )
      end

      scenario "Complete a RAMP Refiling with only invalid issues" do
        # Create an complete Higher level review RAMP election
        ramp_election = RampElection.create!(
          veteran_file_number: "12341234",
          notice_date: 5.days.ago,
          option_selected: "higher_level_review_with_hearing",
          receipt_date: 4.days.ago,
          established_at: 2.days.ago,
          end_product_reference_id: Generators::EndProduct.build(
            veteran_file_number: "12341234",
            bgs_attrs: { status_type_code: "CLR" }
          ).claim_id
        )

        Generators::Contention.build(
          claim_id: ramp_election.end_product_reference_id,
          text: "Left knee rating increase"
        )

        intake = RampRefilingIntake.new(
          veteran_file_number: "12341234",
          user: current_user,
          detail: RampRefiling.new(
            veteran_file_number: "12341234",
            ramp_election: ramp_election
          )
        )

        intake.start!

        visit "/intake"

        fill_in "What is the Receipt Date of this form?", with: "12/03/2017"
        within_fieldset("Which review lane did the Veteran select?") do
          find("label", text: "Supplemental Claim", match: :prefer_exact).click
        end
        safe_click "#button-submit-review"

        click_label("confirm-outside-caseflow-steps")
        find("label", text: "The veteran's form lists at least one ineligible contention").click

        safe_click "#finish-intake"

        expect(page).to have_content("Ineligible RAMP request")

        ramp_refiling = RampRefiling.find_by(veteran_file_number: "12341234")
        expect(ramp_refiling.has_ineligible_issue).to eq(true)
        expect(ramp_refiling.issues.count).to eq(0)

        expect(Fakes::VBMSService).to_not have_received(:establish_claim!)
        expect(Fakes::VBMSService).to_not have_received(:create_contentions!)
      end

      scenario "Complete intake for RAMP Refiling fails due to duplicate EP" do
        allow(VBMSService).to receive(:establish_claim!).and_raise(ep_already_exists_error)

        ramp_election = RampElection.create!(
          veteran_file_number: "12341234",
          notice_date: 5.days.ago,
          receipt_date: 4.days.ago,
          established_at: 2.days.ago,
          end_product_reference_id: Generators::EndProduct.build(
            veteran_file_number: "12341234",
            bgs_attrs: { status_type_code: "CLR" }
          ).claim_id
        )

        Generators::Contention.build(
          claim_id: ramp_election.end_product_reference_id,
          text: "Left knee rating increase"
        )

        visit "/intake/search"
        scroll_element_in_to_view(".cf-submit.usa-button")
        within_fieldset("Which form are you processing?") do
          find("label", text: "RAMP Selection (VA Form 21-4138)").click
        end
        safe_click ".cf-submit.usa-button"
        fill_in "Search small", with: "12341234"
        click_on "Search"
        fill_in "What is the Receipt Date of this form?", with: "12/03/2017"
        within_fieldset("Which review lane did the Veteran select?") do
          find("label", text: "Higher Level Review", match: :prefer_exact).click
        end
        safe_click "#button-submit-review"
        click_label("confirm-outside-caseflow-steps")
        find("label", text: "Left knee rating increase").click
        find("label", text: "The veteran's form lists at least one ineligible contention").click
        safe_click "#finish-intake"

        expect(page).to have_content("An EP 682 for this Veteran's claim was created outside Caseflow.")
      end
    end

    context "AMA feature is enabled" do
      before do
        FeatureToggle.enable!(:intakeAma)
        Timecop.freeze(Time.utc(2018, 5, 26))
      end

      after do
        FeatureToggle.disable!(:intakeAma)
      end

      let!(:rating) do
        Generators::Rating.build(participant_id: veteran.participant_id, promulgation_date: 1.month.ago)
      end

      scenario "Supplemental Claim" do
        Fakes::VBMSService.end_product_claim_id = "IAMANEPID"

        visit "/intake"
        safe_click ".Select"
        expect(page).to have_css(".cf-form-dropdown")
        expect(page).to have_content("RAMP Selection (VA Form 21-4138)")
        expect(page).to have_content("Request for Higher-Level Review (VA Form 20-0988)")
        expect(page).to have_content("Supplemental Claim (VA Form 21-526b)")
        expect(page).to have_content("Notice of Disagreement (VA Form 10182)")

        safe_click ".Select"
        fill_in "Which form are you processing?", with: "Supplemental Claim (VA Form 21-526b)"
        find("#form-select").send_keys :enter

        safe_click ".cf-submit.usa-button"

        expect(page).to have_content("process this Supplemental Claim (VA Form 21-526b).")

        fill_in "Search small", with: "12341234"

        click_on "Search"

        expect(page).to have_current_path("/intake/review-request")

        fill_in "What is the Receipt Date of this form?", with: "05/28/2018"
        safe_click "#button-submit-review"
        expect(page).to have_content(
          "Receipt date cannot be in the future."
        )

        fill_in "What is the Receipt Date of this form?", with: "04/20/2018"
        safe_click "#button-submit-review"

        expect(page).to have_current_path("/intake/finish")
        expect(page).to have_content("Finish processing")
        expect(page).to have_content("Decision date: 04/25/2018")
        expect(page).to have_content("Service connection for Emphysema is granted")

        supplemental_claim = SupplementalClaim.find_by(veteran_file_number: "12341234")

        expect(supplemental_claim).to_not be_nil
        expect(supplemental_claim.receipt_date).to eq(Date.new(2018, 4, 20))
        intake = Intake.find_by(veteran_file_number: "12341234")

        find("label", text: "Basic eligibility to Dependents").click
        safe_click "#button-finish-intake"

        expect(page).to_not have_content("Finish processing")

        expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
          claim_hash: {
            benefit_type_code: "1",
            payee_code: "00",
            predischarge: false,
            claim_type: "Claim",
            station_of_jurisdiction: "397",
            date: supplemental_claim.receipt_date.to_date,
            end_product_modifier: "040",
            end_product_label: "Supplemental Claim Review Rating",
            end_product_code: "040SCRAMA",
            gulf_war_registry: false,
            suppress_acknowledgement_letter: false
          },
          veteran_hash: intake.veteran.to_vbms_hash
        )

        intake.reload
        expect(intake.completed_at).to eq(Time.zone.now)

        expect(intake).to be_success

        supplemental_claim.reload
        expect(supplemental_claim.end_product_reference_id).to eq("IAMANEPID")
      end

      scenario "Higher Level Review" do
        Fakes::VBMSService.end_product_claim_id = "IAMANEPID"

        visit "/intake"
        safe_click ".Select"
        expect(page).to have_css(".cf-form-dropdown")
        expect(page).to have_content("RAMP Selection (VA Form 21-4138)")
        expect(page).to have_content("Request for Higher-Level Review (VA Form 20-0988)")
        expect(page).to have_content("Supplemental Claim (VA Form 21-526b)")
        expect(page).to have_content("Notice of Disagreement (VA Form 10182)")

        safe_click ".Select"
        fill_in "Which form are you processing?", with: "Request for Higher-Level Review (VA Form 20-0988)"
        find("#form-select").send_keys :enter

        safe_click ".cf-submit.usa-button"

        expect(page).to have_content("Higher-Level Review (VA Form 20-0988)")

        fill_in "Search small", with: "12341234"

        click_on "Search"

        expect(page).to have_current_path("/intake/review-request")

        fill_in "What is the Receipt Date of this form?", with: "05/28/2018"
        safe_click "#button-submit-review"
        expect(page).to have_content(
          "Receipt date cannot be in the future."
        )
        expect(page).to have_content(
          "Please select an option."
        )

        fill_in "What is the Receipt Date of this form?", with: "04/20/2018"

        within_fieldset("Did the Veteran request an informal conference?") do
          find("label", text: "Yes", match: :prefer_exact).click
        end

        within_fieldset("Did the Veteran request review by the same office?") do
          find("label", text: "No", match: :prefer_exact).click
        end

        safe_click "#button-submit-review"

        expect(page).to have_current_path("/intake/finish")
        expect(page).to have_content("Finish processing")
        expect(page).to have_content("Decision date: 04/25/2018")
        expect(page).to have_content("Service connection for Emphysema is granted")

        higher_level_review = HigherLevelReview.find_by(veteran_file_number: "12341234")
        expect(higher_level_review).to_not be_nil
        expect(higher_level_review.receipt_date).to eq(Date.new(2018, 4, 20))
        expect(higher_level_review.informal_conference).to eq(true)
        expect(higher_level_review.same_office).to eq(false)

        intake = Intake.find_by(veteran_file_number: "12341234")

        find("label", text: "Basic eligibility to Dependents").click
        safe_click "#button-finish-intake"

        expect(page).to_not have_content("Finish processing")

        expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
          claim_hash: {
            benefit_type_code: "1",
            payee_code: "00",
            predischarge: false,
            claim_type: "Claim",
            station_of_jurisdiction: "397",
            date: higher_level_review.receipt_date.to_date,
            end_product_modifier: "030",
            end_product_label: "Higher Level Review Rating",
            end_product_code: "030HLRAMA",
            gulf_war_registry: false,
            suppress_acknowledgement_letter: false
          },
          veteran_hash: intake.veteran.to_vbms_hash
        )

        intake.reload
        expect(intake.completed_at).to eq(Time.zone.now)

        expect(intake).to be_success

        higher_level_review.reload
        expect(higher_level_review.end_product_reference_id).to eq("IAMANEPID")
      end
    end
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
end
